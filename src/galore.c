// helper C functions for gmime
#define _GNU_SOURCE
#define ENABLE_CRYPTO
#include <glib.h>
#include <gmime/gmime.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <limits.h>
#include <time.h>
#include <sys/time.h>
#include <stdio.h>
#include <gpgme.h>

#define _(x) x

int gmime_is_message_part(GMimeObject *obj){
	return GMIME_IS_MESSAGE_PART(obj);
}

int gmime_is_message_partial(GMimeObject *obj){
	return GMIME_IS_MESSAGE_PARTIAL(obj);
}

int gmime_is_multipart(GMimeObject *obj){
	return GMIME_IS_MULTIPART(obj);
}

int gmime_is_part(GMimeObject *obj){
	return GMIME_IS_PART(obj);
}

int gmime_is_multipart_signed(GMimeObject *obj){
	return GMIME_IS_MULTIPART_SIGNED(obj);
}

int gmime_is_multipart_encrypted(GMimeObject *obj){
	return GMIME_IS_MULTIPART_ENCRYPTED(obj);
}

int internet_address_is_mailbox(InternetAddress *ia) {
	return INTERNET_ADDRESS_IS_MAILBOX(ia);
}

int internet_address_is_group(InternetAddress *ia) {
	return INTERNET_ADDRESS_IS_GROUP(ia);
}

GMimeObject *message_part(GMimeMessage *message){
	return message->mime_part;
}

uint multipart_len(GMimeMultipart *mp){
	return mp->children->len;
}

GMimeObject *multipart_child(GMimeMultipart *mp, int i){
	return mp->children->pdata[i];
}
static void
safe_gethostname (char *hostname, size_t len) {
    char *p;

    if (gethostname (hostname, len) == -1) {
	strncpy (hostname, "unknown", len);
    }
    hostname[len - 1] = '\0';

    for (p = hostname; *p != '\0'; p++) {
	if (*p == '/' || *p == ':')
	    *p = '_';
    }
}

char *make_maildir_id(void) {
    char *filename;
    char hostname[256];
    struct timeval tv;
    pid_t pid;

    /* We follow the Dovecot file name generation algorithm. */
    pid = getpid ();
    safe_gethostname (hostname, sizeof (hostname));
    gettimeofday (&tv, NULL);

    asprintf(&filename, "%ld.M%ldP%d.%s",
				(long) tv.tv_sec, (long) tv.tv_usec, pid, hostname);

    return filename;
}

char *get_domainname(InternetAddressMailbox *mailbox) {
	char *domain = mailbox->addr + mailbox->at + 1;
	return domain;
}

GMimeObject *
g_mime_multipart_encrypted_decrypt_pass (GMimeMultipartEncrypted *encrypted, GMimeDecryptFlags flags,
				    const char *session_key, GMimePasswordRequestFunc request_passwd, 
					GMimeDecryptResult **result, GError **err)
{
	GMimeObject *decrypted, *version_part, *encrypted_part;
	GMimeStream *filtered, *stream, *ciphertext;
	const char *protocol, *supported;
	GMimeContentType *content_type;
	GMimeDataWrapper *content;
	GMimeDecryptResult *res;
	GMimeCryptoContext *ctx;
	GMimeFilter *filter;
	GMimeParser *parser;
	char *mime_type;
	
	g_return_val_if_fail (GMIME_IS_MULTIPART_ENCRYPTED (encrypted), NULL);
	
	if (result)
		*result = NULL;
	
	if (!(protocol = g_mime_object_get_content_type_parameter ((GMimeObject *) encrypted, "protocol"))) {
		g_set_error_literal (err, GMIME_ERROR, GMIME_ERROR_PROTOCOL_ERROR,
				     "Cannot decrypt multipart/encrypted part: unspecified encryption protocol.");
		
		return NULL;
	}
	
	if (!(ctx = g_mime_crypto_context_new (protocol))) {
		g_set_error (err, GMIME_ERROR, GMIME_ERROR_PROTOCOL_ERROR,
			     "Cannot decrypt multipart/encrypted part: unregistered encryption protocol '%s'.",
			     protocol);
		
		return NULL;
	}
	if (request_passwd) {
		g_mime_crypto_context_set_request_password (ctx, request_passwd);
	}
	
	supported = g_mime_crypto_context_get_encryption_protocol (ctx);
	
	/* make sure the protocol matches the crypto encrypt protocol */
	if (!supported || g_ascii_strcasecmp (supported, protocol) != 0) {
		g_set_error (err, GMIME_ERROR, GMIME_ERROR_PROTOCOL_ERROR,
			     "Cannot decrypt multipart/encrypted part: unsupported encryption protocol '%s'.",
			     protocol);
		g_object_unref (ctx);
		
		return NULL;
	}
	
	version_part = g_mime_multipart_get_part ((GMimeMultipart *) encrypted, GMIME_MULTIPART_ENCRYPTED_VERSION);
	
	/* make sure the protocol matches the version part's content-type */
	mime_type = g_mime_content_type_get_mime_type (version_part->content_type);
	if (g_ascii_strcasecmp (mime_type, protocol) != 0) {
		g_set_error_literal (err, GMIME_ERROR, GMIME_ERROR_PARSE_ERROR,
				     "Cannot decrypt multipart/encrypted part: content-type does not match protocol.");
		
		g_object_unref (ctx);
		g_free (mime_type);
		
		return NULL;
	}
	g_free (mime_type);
	
	/* get the encrypted part and check that it is of type application/octet-stream */
	encrypted_part = g_mime_multipart_get_part ((GMimeMultipart *) encrypted, GMIME_MULTIPART_ENCRYPTED_CONTENT);
	content_type = g_mime_object_get_content_type (encrypted_part);
	if (!g_mime_content_type_is_type (content_type, "application", "octet-stream")) {
		g_set_error_literal (err, GMIME_ERROR, GMIME_ERROR_PARSE_ERROR,
				     "Cannot decrypt multipart/encrypted part: unexpected content type.");
		g_object_unref (ctx);
		
		return NULL;
	}
	
	/* get the ciphertext stream */
	content = g_mime_part_get_content ((GMimePart *) encrypted_part);
	ciphertext = g_mime_stream_mem_new ();
	g_mime_data_wrapper_write_to_stream (content, ciphertext);
	g_mime_stream_reset (ciphertext);
	
	stream = g_mime_stream_mem_new ();
	filtered = g_mime_stream_filter_new (stream);
	filter = g_mime_filter_dos2unix_new (FALSE);
	g_mime_stream_filter_add ((GMimeStreamFilter *) filtered, filter);
	g_object_unref (filter);
	
	/* get the cleartext */
	if (!(res = g_mime_crypto_context_decrypt (ctx, flags, session_key, ciphertext, filtered, err))) {
		g_object_unref (ciphertext);
		g_object_unref (filtered);
		g_object_unref (stream);
		g_object_unref (ctx);
		
		return NULL;
	}
	
	g_mime_stream_flush (filtered);
	g_object_unref (ciphertext);
	g_object_unref (filtered);
	g_object_unref (ctx);
	
	g_mime_stream_reset (stream);
	parser = g_mime_parser_new ();
	g_mime_parser_init_with_stream (parser, stream);
	g_object_unref (stream);
	
	decrypted = g_mime_parser_construct_part (parser, NULL);
	g_object_unref (parser);
	
	if (!decrypted) {
		g_set_error_literal (err, GMIME_ERROR, GMIME_ERROR_PARSE_ERROR,
				     "Cannot decrypt multipart/encrypted part: failed to parse decrypted content.");
		
		g_object_unref (res);
		
		return NULL;
	}
	
	if (!result)
		g_object_unref (res);
	else
		*result = res;
	
	return decrypted;
}

// GMimeGpgContext *
gpgme_ctx_t
get_gpg_ctx() {
	gpgme_ctx_t ctx;
	
	/* make sure GpgMe supports the OpenPGP protocols */
	if (gpgme_engine_check_version (GPGME_PROTOCOL_OpenPGP) != GPG_ERR_NO_ERROR)
		return NULL;
	
	/* create the GpgMe context */
	if (gpgme_new (&ctx) != GPG_ERR_NO_ERROR)
		return NULL;
	
	return ctx;
}


// /// maybe this is a bit over the top?
static gboolean
g_mime_gpgme_key_is_usable (gpgme_key_t key, gboolean secret, time_t now, gpgme_error_t *err)
{
	gpgme_subkey_t subkey;
	
	*err = GPG_ERR_NO_ERROR;
	
	/* first, check the state of the key itself... */
	if (key->expired)
		*err = GPG_ERR_KEY_EXPIRED;
	else if (key->revoked)
		*err = GPG_ERR_CERT_REVOKED;
	else if (key->disabled)
		*err = GPG_ERR_KEY_DISABLED;
	else if (key->invalid)
		*err = GPG_ERR_BAD_KEY;
	
	if (*err != GPG_ERR_NO_ERROR)
		return FALSE;
	
	/* now check if there is a subkey that we can use */
	subkey = key->subkeys;
	
	while (subkey) {
		if ((secret && subkey->can_sign) || (!secret && subkey->can_encrypt)) {
			if (subkey->expired || (subkey->expires != 0 && subkey->expires <= now))
				*err = GPG_ERR_KEY_EXPIRED;
			else if (subkey->revoked)
				*err = GPG_ERR_CERT_REVOKED;
			else if (subkey->disabled)
				*err = GPG_ERR_KEY_DISABLED;
			else if (subkey->invalid)
				*err = GPG_ERR_BAD_KEY;
			else
				return TRUE;
		}
		
		subkey = subkey->next;
	}
	
	if (*err == GPG_ERR_NO_ERROR)
		*err = GPG_ERR_BAD_KEY;
	
	return FALSE;
}

gboolean
g_mime_gpgme_key_exists (gpgme_ctx_t ctx, const char *name, gboolean secret, GError **err)
{
	gpgme_error_t key_error = GPG_ERR_NO_ERROR;
	time_t now = time (NULL);
	gpgme_key_t key = NULL;
	gboolean found = FALSE;
	gpgme_error_t error;

	// change to gpgme_op_keylist_ext?
	if ((error = gpgme_op_keylist_start (ctx, name, secret)) != GPG_ERR_NO_ERROR) {
		if (secret) {
			g_set_error (err, GMIME_GPGME_ERROR, error,
				     _("Could not list secret keys for \"%s\": %s"),
				     name, gpgme_strerror (error));
		} else {
			g_set_error (err, GMIME_GPGME_ERROR, error,
				     _("Could not list keys for \"%s\": %s"),
				     name, gpgme_strerror (error));
		}
	
		return FALSE;
	}

	while ((error = gpgme_op_keylist_next (ctx, &key)) == GPG_ERR_NO_ERROR) {
		/* check if this key and the relevant subkey are usable */
		if (g_mime_gpgme_key_is_usable (key, secret, now, &key_error))
			break;
	
		gpgme_key_unref (key);
		found = TRUE;
		key = NULL;
	}

	gpgme_op_keylist_end (ctx);

	if (error != GPG_ERR_NO_ERROR && error != GPG_ERR_EOF) {
		if (secret) {
			g_set_error (err, GMIME_GPGME_ERROR, error,
				     _("Could not list secret keys for \"%s\": %s"),
				     name, gpgme_strerror (error));
		} else {
			g_set_error (err, GMIME_GPGME_ERROR, error,
				     _("Could not list keys for \"%s\": %s"),
				     name, gpgme_strerror (error));
		}
	
		return FALSE;
	}

	if (!key) {
		if (strchr (name, '@')) {
			if (found && key_error != GPG_ERR_NO_ERROR) {
				g_set_error (err, GMIME_GPGME_ERROR, key_error,
					     _("A key for %s is present, but it is expired, disabled, revoked or invalid"),
					     name);
			} else {
				g_set_error (err, GMIME_GPGME_ERROR, GPG_ERR_NOT_FOUND,
					     _("Could not find a suitable key for %s"), name);
			}
		} else {
			if (found && key_error != GPG_ERR_NO_ERROR) {
				g_set_error (err, GMIME_GPGME_ERROR, key_error,
					     _("A key with id %s is present, but it is expired, disabled, revoked or invalid"),
					     name);
			} else {
				g_set_error (err, GMIME_GPGME_ERROR, GPG_ERR_NOT_FOUND,
					     _("Could not find a suitable key with id %s"), name);
			}
		}
	
		return FALSE;
	}

	return TRUE;
}
