/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*  GMime
 *  Copyright (C) 2000-2020 Jeffrey Stedfast
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public License
 *  as published by the Free Software Foundation; either version 2.1
 *  of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free
 *  Software Foundation, 51 Franklin Street, Fifth Floor, Boston, MA
 *  02110-1301, USA.
 */


#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "galore-autocrypt.h"
#include <gpgme.h>
#include <gmime/gmime-filter-charset.h>
#include <gmime/gmime-stream-filter.h>
#include <gmime/gmime-stream-mem.h>
#include <gmime/gmime-stream-fs.h>
#include <gmime/gmime-charset.h>
#include <gmime/gmime-error.h>
#include "galore-gpgme-utils.h"

#ifdef ENABLE_DEBUG
#define d(x) x
#else
#define d(x)
#endif

#define _(x) x


/**
 * SECTION: gmime-gpg-context
 * @title: GaloreAutoCryptContext
 * @short_description: GnuPG crypto contexts
 * @see_also: #GMimeCryptoContext
 *
 * A #GaloreAutoCryptContext is a #GMimeCryptoContext that uses GnuPG to do
 * all of the encryption and digital signatures.
 **/


/**
 * GaloreAutoCryptContext:
 *
 * A GnuPG crypto context.
 **/
struct _GaloreAutoCryptContext {
	GMimeCryptoContext parent_object;
	
	gpgme_ctx_t ctx;
};

struct _GaloreAutoCryptContextClass {
	GMimeCryptoContextClass parent_class;
	
};


static void galore_au_context_class_init (GaloreAutoCryptContextClass *klass);
static void galore_au_context_init (GaloreAutoCryptContext *ctx, GaloreAutoCryptContextClass *klass);
static void galore_au_context_finalize (GObject *object);

static GMimeDigestAlgo au_digest_id (GMimeCryptoContext *ctx, const char *name);
static const char *au_digest_name (GMimeCryptoContext *ctx, GMimeDigestAlgo digest);

static int au_sign (GMimeCryptoContext *ctx, gboolean detach, const char *userid,
		     GMimeStream *istream, GMimeStream *ostream, GError **err);

static const char *au_get_signature_protocol (GMimeCryptoContext *ctx);
static const char *au_get_encryption_protocol (GMimeCryptoContext *ctx);
static const char *au_get_key_exchange_protocol (GMimeCryptoContext *ctx);

static GMimeSignatureList *au_verify (GMimeCryptoContext *ctx, GMimeVerifyFlags flags,
				       GMimeStream *istream, GMimeStream *sigstream,
				       GMimeStream *ostream, GError **err);

static int au_encrypt (GMimeCryptoContext *ctx, gboolean sign, const char *userid, GMimeEncryptFlags flags,
			GPtrArray *recipients, GMimeStream *istream, GMimeStream *ostream, GError **err);

static GMimeDecryptResult *au_decrypt (GMimeCryptoContext *ctx, GMimeDecryptFlags flags, const char *session_key,
					GMimeStream *istream, GMimeStream *ostream, GError **err);

static int au_import_keys (GMimeCryptoContext *ctx, GMimeStream *istream, GError **err);

static int au_export_keys (GMimeCryptoContext *ctx, const char *keys[],
			    GMimeStream *ostream, GError **err);


static GMimeCryptoContextClass *parent_class = NULL;
static char *path = NULL;


GType
galore_au_context_get_type ()
{
	static GType type = 0;
	
	if (!type) {
		static const GTypeInfo info = {
			sizeof (GaloreAutoCryptContextClass),
			NULL, /* base_class_init */
			NULL, /* base_class_finalize */
			(GClassInitFunc) galore_au_context_class_init,
			NULL, /* class_finalize */
			NULL, /* class_data */
			sizeof (GaloreAutoCryptContext),
			0,    /* n_preallocs */
			(GInstanceInitFunc) galore_au_context_init,
		};
		
		type = g_type_register_static (GMIME_TYPE_CRYPTO_CONTEXT, "GMimeAutoCryptContext", &info, 0);
	}
	
	return type;
}


static void
galore_au_context_class_init (GaloreAutoCryptContextClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	GMimeCryptoContextClass *crypto_class = GMIME_CRYPTO_CONTEXT_CLASS (klass);
	
	parent_class = g_type_class_ref (G_TYPE_OBJECT);
	
	object_class->finalize = galore_au_context_finalize;
	
	crypto_class->digest_id = au_digest_id;
	crypto_class->digest_name = au_digest_name;
	crypto_class->sign = au_sign;
	crypto_class->verify = au_verify;
	crypto_class->encrypt = au_encrypt;
	crypto_class->decrypt = au_decrypt;
	crypto_class->import_keys = au_import_keys;
	crypto_class->export_keys = au_export_keys;
	crypto_class->get_signature_protocol = au_get_signature_protocol;
	crypto_class->get_encryption_protocol = au_get_encryption_protocol;
	crypto_class->get_key_exchange_protocol = au_get_key_exchange_protocol;
}

static void
galore_au_context_init (GaloreAutoCryptContext *gpg, GaloreAutoCryptContextClass *klass)
{
	gpg->ctx = NULL;
}

static void
galore_au_context_finalize (GObject *object)
{
	GaloreAutoCryptContext *gpg = (GaloreAutoCryptContext *) object;
	
	if (gpg->ctx)
		gpgme_release (gpg->ctx);
	
	G_OBJECT_CLASS (parent_class)->finalize (object);
}

static GMimeDigestAlgo
au_digest_id (GMimeCryptoContext *ctx, const char *name)
{
	if (name == NULL)
		return GMIME_DIGEST_ALGO_DEFAULT;
	
	if (!g_ascii_strncasecmp (name, "pgp-", 4))
		name += 4;
	
	if (!g_ascii_strcasecmp (name, "md2"))
		return GMIME_DIGEST_ALGO_MD2;
	else if (!g_ascii_strcasecmp (name, "md4"))
		return GMIME_DIGEST_ALGO_MD4;
	else if (!g_ascii_strcasecmp (name, "md5"))
		return GMIME_DIGEST_ALGO_MD5;
	else if (!g_ascii_strcasecmp (name, "sha1"))
		return GMIME_DIGEST_ALGO_SHA1;
	else if (!g_ascii_strcasecmp (name, "sha224"))
		return GMIME_DIGEST_ALGO_SHA224;
	else if (!g_ascii_strcasecmp (name, "sha256"))
		return GMIME_DIGEST_ALGO_SHA256;
	else if (!g_ascii_strcasecmp (name, "sha384"))
		return GMIME_DIGEST_ALGO_SHA384;
	else if (!g_ascii_strcasecmp (name, "sha512"))
		return GMIME_DIGEST_ALGO_SHA512;
	else if (!g_ascii_strcasecmp (name, "ripemd160"))
		return GMIME_DIGEST_ALGO_RIPEMD160;
	else if (!g_ascii_strcasecmp (name, "tiger192"))
		return GMIME_DIGEST_ALGO_TIGER192;
	else if (!g_ascii_strcasecmp (name, "haval-5-160"))
		return GMIME_DIGEST_ALGO_HAVAL5160;
	
	return GMIME_DIGEST_ALGO_DEFAULT;
}

static const char *
au_digest_name (GMimeCryptoContext *ctx, GMimeDigestAlgo digest)
{
	switch (digest) {
	case GMIME_DIGEST_ALGO_MD2:
		return "pgp-md2";
	case GMIME_DIGEST_ALGO_MD4:
		return "pgp-md4";
	case GMIME_DIGEST_ALGO_MD5:
		return "pgp-md5";
	case GMIME_DIGEST_ALGO_SHA1:
		return "pgp-sha1";
	case GMIME_DIGEST_ALGO_SHA224:
		return "pgp-sha224";
	case GMIME_DIGEST_ALGO_SHA256:
		return "pgp-sha256";
	case GMIME_DIGEST_ALGO_SHA384:
		return "pgp-sha384";
	case GMIME_DIGEST_ALGO_SHA512:
		return "pgp-sha512";
	case GMIME_DIGEST_ALGO_RIPEMD160:
		return "pgp-ripemd160";
	case GMIME_DIGEST_ALGO_TIGER192:
		return "pgp-tiger192";
	case GMIME_DIGEST_ALGO_HAVAL5160:
		return "pgp-haval-5-160";
	default:
		return "pgp-sha1";
	}
}

static const char *
au_get_signature_protocol (GMimeCryptoContext *ctx)
{
	return "application/pgp-signature";
}

static const char *
au_get_encryption_protocol (GMimeCryptoContext *ctx)
{
	return "application/pgp-encrypted";
}

static const char *
au_get_key_exchange_protocol (GMimeCryptoContext *ctx)
{
	return "application/pgp-keys";
}

static void
set_passphrase_callback (GMimeCryptoContext *context)
{
	GaloreAutoCryptContext *gpg = (GaloreAutoCryptContext *) context;
	
	if (context->request_passwd)
		gpgme_set_passphrase_cb (gpg->ctx, g_mime_gpgme_passphrase_callback, gpg);
	else
		gpgme_set_passphrase_cb (gpg->ctx, NULL, NULL);
}

static int
au_sign (GMimeCryptoContext *context, gboolean detach, const char *userid,
	  GMimeStream *istream, GMimeStream *ostream, GError **err)
{
	gpgme_sig_mode_t mode = detach ? GPGME_SIG_MODE_DETACH : GPGME_SIG_MODE_CLEAR;
	GaloreAutoCryptContext *gpg = (GaloreAutoCryptContext *) context;
	
	set_passphrase_callback (context);
	
	gpgme_set_textmode (gpg->ctx, !detach);
	
	return g_mime_gpgme_sign (gpg->ctx, mode, userid, istream, ostream, err);
}

static GMimeSignatureList *
au_verify (GMimeCryptoContext *context, GMimeVerifyFlags flags, GMimeStream *istream, GMimeStream *sigstream,
	    GMimeStream *ostream, GError **err)
{
	GaloreAutoCryptContext *gpg = (GaloreAutoCryptContext *) context;
	
	return g_mime_gpgme_verify (gpg->ctx, flags, istream, sigstream, ostream, err);
}

static int
au_encrypt (GMimeCryptoContext *context, gboolean sign, const char *userid, GMimeEncryptFlags flags,
	     GPtrArray *recipients, GMimeStream *istream, GMimeStream *ostream, GError **err)
{
	GaloreAutoCryptContext *gpg = (GaloreAutoCryptContext *) context;
	
	if (sign)
		set_passphrase_callback (context);
	
	return g_mime_gpgme_encrypt (gpg->ctx, sign, userid, flags, recipients, istream, ostream, err);
}

static GMimeDecryptResult *
au_decrypt (GMimeCryptoContext *context, GMimeDecryptFlags flags, const char *session_key,
	     GMimeStream *istream, GMimeStream *ostream, GError **err)
{
	GaloreAutoCryptContext *gpg = (GaloreAutoCryptContext *) context;
	
	set_passphrase_callback (context);
	
	return g_mime_gpgme_decrypt (gpg->ctx, flags, session_key, istream, ostream, err);
}

static int
au_import_keys (GMimeCryptoContext *context, GMimeStream *istream, GError **err)
{
	GaloreAutoCryptContext *gpg = (GaloreAutoCryptContext *) context;
	
	set_passphrase_callback (context);
	
	return g_mime_gpgme_import (gpg->ctx, istream, err);
}

static int
au_export_keys (GMimeCryptoContext *context, const char *keys[], GMimeStream *ostream, GError **err)
{
	GaloreAutoCryptContext *gpg = (GaloreAutoCryptContext *) context;
	
	set_passphrase_callback (context);
	
	// return g_mime_au_export (gpg->ctx, keys, ostream, err);
	return g_mime_gpgme_import (gpg->ctx, ostream, err);
}


/**
 * g_mime_gpg_context_new:
 *
 * Creates a new gpg crypto context object.
 *
 * Returns: (transfer full): a new gpg crypto context object.
 **/
GMimeCryptoContext *
galore_au_context_new (void)
{
	GaloreAutoCryptContext *gpg;
	gpgme_ctx_t ctx;
	
	/* make sure GpgMe supports the OpenPGP protocols */
	if (gpgme_engine_check_version (GPGME_PROTOCOL_OpenPGP) != GPG_ERR_NO_ERROR)
		return NULL;
	
	/* create the GpgMe context */
	if (gpgme_new (&ctx) != GPG_ERR_NO_ERROR)
		return NULL;
	if (gpgme_ctx_set_engine_info(ctx, GPGME_PROTOCOL_OpenPGP, NULL, path) != GPG_ERR_NO_ERROR)
		return NULL;
	
	gpg = g_object_new (GALORE_TYPE_AU_CONTEXT, NULL);
	gpgme_set_protocol (ctx, GPGME_PROTOCOL_OpenPGP);
	gpgme_set_armor (ctx, TRUE);
	gpg->ctx = ctx;
	
	return (GMimeCryptoContext *) gpg;
}
