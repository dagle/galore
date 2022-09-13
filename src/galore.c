// helper C functions for gmime
#define _GNU_SOURCE
#define ENABLE_CRYPTO
#include "gmime/gmime-parser.h"
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

int gmime_is_message_part(void *obj){
	return GMIME_IS_MESSAGE_PART(obj);
}

int gmime_is_message_partial(void *obj){
	return GMIME_IS_MESSAGE_PARTIAL(obj);
}

int gmime_is_multipart(void *obj){
	return GMIME_IS_MULTIPART(obj);
}

int gmime_is_part(void *obj){
	return GMIME_IS_PART(obj);
}

int gmime_is_multipart_signed(void *obj){
	return GMIME_IS_MULTIPART_SIGNED(obj);
}

int gmime_is_multipart_encrypted(void *obj){
	return GMIME_IS_MULTIPART_ENCRYPTED(obj);
}

int gmime_is_object(void *obj){
	return GMIME_IS_OBJECT(obj);
}

int gmime_is_parser(void *obj) {
	return GMIME_IS_PARSER(obj);
}

int gmime_is_message(void *obj) {
	return GMIME_IS_MESSAGE(obj);
}

int gmime_is_filter_from(void *obj) {
	return GMIME_IS_FILTER_FROM(obj);
}

int gmime_is_filter_best(void *obj) {
	return GMIME_IS_FILTER_BEST(obj);
}

int gmime_is_filter_gzip(void *obj) {
	return GMIME_IS_FILTER_GZIP(obj);
}

int gmime_is_filter_strip(void *obj) {
	return GMIME_IS_FILTER_STRIP(obj);
}

int gmime_is_filter_dos2unix(void *obj) {
	return GMIME_IS_FILTER_DOS2UNIX(obj);
}

int gmime_is_filter(void *obj) {
	return GMIME_IS_FILTER(obj);
}

int gmime_is_filter_basic(void *obj) {
	return GMIME_IS_FILTER_BASIC(obj);
}

int gmime_is_filter_enriched(void *obj) {
	return GMIME_IS_FILTER_ENRICHED(obj);
}

int gmime_is_filter_windows(void *obj) {
	return GMIME_IS_FILTER_WINDOWS(obj);
}

int gmime_is_filter_smtp_data(void *obj) {
	return GMIME_IS_FILTER_SMTP_DATA(obj);
}

int gmime_is_filter_openpgp(void *obj) {
	return GMIME_IS_FILTER_OPENPGP(obj);
}

int gmime_is_filter_unix2dos(void *obj) {
	return GMIME_IS_FILTER_UNIX2DOS(obj);
}

int gmime_is_filter_yenc(void *obj) {
	return GMIME_IS_FILTER_YENC(obj);
}

int gmime_is_filter_html(void *obj) {
	return GMIME_IS_FILTER_HTML(obj);
}

int gmime_is_text_part(void *obj) {
	return GMIME_IS_TEXT_PART(obj);
}

int gmime_is_pkcs7_context(void *obj) {
	return GMIME_IS_PKCS7_CONTEXT(obj);
}

int gmime_is_content_type(void *obj) {
	return GMIME_IS_CONTENT_TYPE(obj);
}

int gmime_is_gpg_context(void *obj) {
	return GMIME_IS_GPG_CONTEXT(obj);
}

int gmime_is_crypto_context(void *obj) {
	return GMIME_IS_CRYPTO_CONTEXT(obj);
}

int gmime_is_application_pkcs7_mime(void *obj) {
	return GMIME_IS_APPLICATION_PKCS7_MIME(obj);
}

int gmime_is_data_wrapper(void *obj) {
	return GMIME_IS_DATA_WRAPPER(obj);
}

int gmime_is_content_disposition(void *obj) {
	return GMIME_IS_CONTENT_DISPOSITION(obj);
}

int gmime_is_autocrypt_header(void *obj) {
	return GMIME_IS_AUTOCRYPT_HEADER(obj);
}

int gmime_is_autocrypt_header_list(void *obj) {
	return GMIME_IS_AUTOCRYPT_HEADER_LIST(obj);
}

int internet_address_is_mailbox(void *ia) {
	return INTERNET_ADDRESS_IS_MAILBOX(ia);
}

int internet_address_is_group(void *ia) {
	return INTERNET_ADDRESS_IS_GROUP(ia);
}

int is_internet_address_list(void *obj) {
	return IS_INTERNET_ADDRESS_LIST(obj);
}

int is_internet_address(void *obj) {
	return IS_INTERNET_ADDRESS(obj);
}

int gmime_is_header(void *obj) {
	return GMIME_IS_HEADER(obj);
}

int gmime_is_header_list(void *obj) {
	return GMIME_IS_HEADER_LIST(obj);
}

int gmime_is_certificate(void *obj) {
	return GMIME_IS_CERTIFICATE(obj);
}

int gmime_is_certificate_list(void *obj) {
	return GMIME_IS_CERTIFICATE_LIST(obj);
}

int gmime_is_signature(void *obj) {
	return GMIME_IS_SIGNATURE(obj);
}

int gmime_is_signature_list(void *obj) {
	return GMIME_IS_SIGNATURE_LIST(obj);
}

int gmime_is_param(void *obj) {
	return GMIME_IS_PARAM(obj);
}

int gmime_is_param_list(void *obj) {
	return GMIME_IS_PARAM_LIST(obj);
}

int gmime_is_decrypt_result(void *obj) {
	return GMIME_IS_DECRYPT_RESULT(obj);
}

int gmime_is_stream(void *obj) {
	return GMIME_IS_STREAM(obj);
}

int gmime_is_stream_pipe(void *obj) {
	return GMIME_IS_STREAM_PIPE(obj);
}

int gmime_is_stream_file(void *obj) {
	return GMIME_IS_STREAM_FILE(obj);
}

int gmime_is_stream_gio(void *obj) {
	return GMIME_IS_STREAM_GIO(obj);
}

int gmime_is_stream_mmap(void *obj) {
	return GMIME_IS_STREAM_MMAP(obj);
}

int gmime_is_stream_mem(void *obj) {
	return GMIME_IS_STREAM_MEM(obj);
}

int gmime_is_stream_null(void *obj) {
	return GMIME_IS_STREAM_NULL(obj);
}

int gmime_is_stream_cat(void *obj) {
	return GMIME_IS_STREAM_CAT(obj);
}

int gmime_is_stream_filter(void *obj) {
	return GMIME_IS_STREAM_FILTER(obj);
}

int gmime_is_stream_fs(void *obj) {
	return GMIME_IS_STREAM_FS(obj);
}

int gmime_is_stream_buffer(void *obj) {
	return GMIME_IS_STREAM_BUFFER(obj);
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

// void callback(gint64 offset, GMimeParserWarning errcode, const gchar *item, gpointer user_data) {
//
// }
//
// GMimeMessage *parse_message(const char *path, parse_error **error) {
// 	GMimeParserOptions *options = g_mime_parser_options_new();
// 	g_mime_parser_options_set_warning_callback(options, callback, error);
// 	GMimeStream *stream = g_mime_stream_file_open(path, 0, NULL);
// 	GMimeParser *parser = g_mime_parser_new_with_stream(stream);
// 	GMimeMessage *message = g_mime_parser_construct_message(parser, options);
// 	return message;
// }

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
	} else {
		g_set_error (err, GMIME_ERROR, GMIME_ERROR_PROTOCOL_ERROR,
			     "Cannot set the password function");
		return NULL;
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
