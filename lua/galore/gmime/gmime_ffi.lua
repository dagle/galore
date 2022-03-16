-- XXX (Not needed!) Missing: Part-iter, stream-gio
-- TODO sort enums!

local library_path = (function()
	local dirname = string.sub(debug.getinfo(1).source, 2, #"/gmime_ffi.lua" * -1)
	if package.config:sub(1, 1) == "\\" then
		return dirname .. "../../../build/libgalore.dll"
	else
		return dirname .. "../../../build/libgalore.so"
	end
end)()



local ffi = require("ffi")
local galore = ffi.load(library_path)

--- @class gmime.Message
--- @class gmime.Part
--- @class gmime.Messagepart
--- @class gmime.Messagepartial
--- @class gmime.Multipart
--- @class gmime.MultipartSigned
--- @class gmime.MultipartEncrypted
--- @class gmime.TextPart
--- @class gmime.MimeObject
--- @class gmime.DataWrapper

--- @class gmime.Filter
--- @class gmime.FilterBest
--- @class gmime.FilterGZip
--- @class gmime.FilterYenc
--- @class gmime.FilterOpenPGP
--- @class gmime.OpenPGPData
--- @class gmime.FilterWindows
--- @class gmime.FilterChecksum

--- @class gmime.Stream
--- @class gmime.Parser
--- @class gmime.Format
--- @class gmime.ParserOptions
--- @class gmime.SeekWhence
--- @class gmime.StreamCat
--- @class gmime.StreamMem
--- @class gmime.StreamMmap
--- @class gmime.StreamNull
--- @class gmime.StreamPipe
--- @class gmime.StreamFilter
--- @class gmime.ByteArray

--- @class gmime.Header
--- @class gmime.HeaderList
--- @class gmime.InternetAddress
--- @class gmime.InternetAddressList
--- @class gmime.InternetAddressMailbox
--- @class gmime.InternetAddressGroup
--- @class gmime.ContentDisposition

--- @class gmime.FormatOptions
--- @class gmime.Param
--- @class gmime.ParamList
--- @class gmime.ContentType
--- @class gmime.References
--- @class gmime.EncodingState

--- @class gmime.CryptoContext
--- @class gmime.AutocryptHeader
--- @class gmime.AutocryptHeaderList
--- @class gmime.DecryptResult
--- @class gmime.Certificate
--- @class gmime.CertificateList
--- @class gmime.Signature
--- @class gmime.SignatureList
--- @class gmime.SignatureStatus
--- @class gmime.ApplicationPkcs7Mime

--- @class gmime.ContentEncoding

--- @class gmime.Option

--- @class gmime.Filter

--- TODO should it be an error or can we do "better" / more lua-ish?
--- @class gmime.Error
--- @class iconv

---- enums
--- @class gmime.AddressType [x]

--- @class gmime.ChecksumType [x]

--- @class gmime.StreamBufferMode

--- @class gmime.DecryptFlags [x]
--- @class gmime.EncryptFlags [x]
--- @class gmime.VerifyFlags [x]

--- @class gmime.FilterBestFlags
--- @class gmime.EncodingConstraint [x]
--- @class gmime.FilterFromMode
--- @class gmime.FilterGZipMode

--- @class gmime.ParserWarning
--- @class gmime.NewLineFormat
--- @class gmime.ParamEncodingMethod
--- @class gmime.RfcComplianceMode
--- @class gmime.Trust [x]
--- @class gmime.Validity [x]
--- @class gmime.PubKeyAlgo [x]
--- @class gmime.SecureMimeType
--- @class gmime.DigestAlgo
--- @class gmime.CipherAlgo
--- @class gmime.AutocryptPreferEncrypt
--- @class gmime.SecureMimeType


ffi.cdef([[
/* Messages */
typedef struct {} GMimeMessage;
typedef struct {} GMimePart;
typedef struct {} GMimeMessagePart;
typedef struct {} GMimeMessagePartial;
typedef struct {} GMimeMultipart;
typedef struct {} GMimeMultipartSigned;
typedef struct {} GMimeMultipartEncrypted;
typedef struct {} GMimeTextPart;

/* Filters */
typedef struct {} GMimeFilter;
typedef struct {} GMimeFilterBest;
typedef struct {} GMimeFilterFrom;
typedef struct {} GMimeFilterGZip;
typedef struct {} GMimeFilterHTML;
typedef struct {} GMimeFilterYenc;
typedef struct {} GMimeFilterBasic;
typedef struct {} GMimeFilterStrip;
typedef struct {} GMimeFilterCharset;
typedef struct {} GMimeFilterOpenPGP;
typedef struct {} GMimeFilterWindows;
typedef struct {} GMimeFilterChecksum;
typedef struct {} GMimeFilterDos2Unix;
typedef struct {} GMimeFilterUnix2Dos;
typedef struct {} GMimeFilterEnriched;
typedef struct {} GMimeFilterSmtpData;
typedef struct {} GMimeFilterReply;


/* Streams */
typedef struct {} GMimeParser;
typedef struct {} GMimeStream;
typedef struct {} GMimeStreamFs;
typedef struct {} GMimeStreamCat;
typedef struct {} GMimeStreamMem;
typedef struct {} GMimeStreamFile;
typedef struct {} GMimeStreamMmap;
typedef struct {} GMimeStreamNull;
typedef struct {} GMimeStreamPipe;
typedef struct {} GMimeStreamBuffer;
typedef struct {} GMimeStreamFilter;
typedef struct {} GMimeDataWrapper;

/* Encryption */
typedef struct {} GMimeCryptoContext;
typedef struct {} GMimeDecryptResult;
typedef struct {} GMimeAutocryptHeader;
typedef struct {} GMimeAutocryptHeaderList;
typedef struct {} GMimeSignature;
typedef struct {} GMimeSignatureList;
typedef struct {} GMimePkcs7Context;
typedef struct {} GMimeApplicationPkcs7Mime;
typedef struct {} GMimeGpgContext;
typedef struct {} GMimeCertificate;
typedef struct {} GMimeCertificateList;

/* content */
typedef struct {} GMimeHeader;
typedef struct {} GMimeHeaderList;
typedef struct {} InternetAddress;
typedef struct {} InternetAddressGroup;
typedef struct {} InternetAddressMailbox;
typedef struct {} InternetAddressList;
typedef struct {} GMimeContentDisposition;
typedef struct {} GMimeContentType;
typedef struct {} GMimeReferences;

/* Extra */
typedef struct {} GMimeObject;
typedef struct {} GMimeCharset;
typedef struct {} GMimeEncoding;

/* Options */
typedef struct {} GMimeParam;
typedef struct {} GMimeParamList;
typedef struct {} GMimeFormatOptions;
typedef struct {} GMimeParserOptions;

/* To use these, we need to write C code */
typedef struct {} GError;
typedef struct {} GPtrArray;
typedef struct {} GDateTime;
typedef struct {} GBytes;
typedef struct {} GString;
typedef unsigned char guint8;
typedef int gboolean;
typedef int ssize_t;
typedef long time_t;

/* callbacks, these are slow */
typedef GMimeCryptoContext * (* GMimeCryptoContextNewFunc) (void);
typedef gboolean (* GMimePasswordRequestFunc) (GMimeCryptoContext *ctx, const char *user_id, const char *prompt, gboolean reprompt, GMimeStream *response, GError **err);

/* Maybe not */
typedef struct {} FILE;

typedef void* gpointer;

typedef struct {
  char *data;
  unsigned int len;
} GByteArray; 

typedef struct {
	void *data;
	size_t len;
} GMimeStreamIOVector;

typedef int guint;
typedef int guint;
typedef int gchar;
typedef unsigned int guint32;
typedef signed long gint64;
typedef void* *iconv_t;

// old stuff
typedef struct {} GObject;
typedef enum {
	GMIME_WARN_DUPLICATED_HEADER = 1U,
	GMIME_WARN_DUPLICATED_PARAMETER,
	GMIME_WARN_UNENCODED_8BIT_HEADER,
	GMIME_WARN_INVALID_CONTENT_TYPE,
	GMIME_WARN_INVALID_RFC2047_HEADER_VALUE,
	GMIME_WARN_MALFORMED_MULTIPART,
	GMIME_WARN_TRUNCATED_MESSAGE,
	GMIME_WARN_MALFORMED_MESSAGE,
	GMIME_CRIT_INVALID_HEADER_NAME,
	GMIME_CRIT_CONFLICTING_HEADER,
	GMIME_CRIT_CONFLICTING_PARAMETER,
	GMIME_CRIT_MULTIPART_WITHOUT_BOUNDARY,
	GMIME_WARN_INVALID_PARAMETER,
	GMIME_WARN_INVALID_ADDRESS_LIST,
	GMIME_CRIT_NESTING_OVERFLOW,
	GMIME_WARN_PART_WITHOUT_CONTENT,
	GMIME_CRIT_PART_WITHOUT_HEADERS_OR_CONTENT,
} GMimeParserWarning;

typedef enum {
	GMIME_NEWLINE_FORMAT_UNIX,
	GMIME_NEWLINE_FORMAT_DOS
} GMimeNewLineFormat;

typedef enum {
	GMIME_PARAM_ENCODING_METHOD_DEFAULT = 0,
	GMIME_PARAM_ENCODING_METHOD_RFC2231 = 1,
	GMIME_PARAM_ENCODING_METHOD_RFC2047 = 2
} GMimeParamEncodingMethod;

typedef enum {
	GMIME_RFC_COMPLIANCE_LOOSE,
	GMIME_RFC_COMPLIANCE_STRICT
} GMimeRfcComplianceMode;

typedef enum {
	GMIME_TRUST_UNKNOWN   = 0,
	GMIME_TRUST_UNDEFINED = 1,
	GMIME_TRUST_NEVER     = 2,
	GMIME_TRUST_MARGINAL  = 3,
	GMIME_TRUST_FULL      = 4,
	GMIME_TRUST_ULTIMATE  = 5
} GMimeTrust;

typedef enum {
	GMIME_VALIDITY_UNKNOWN   = 0,
	GMIME_VALIDITY_UNDEFINED = 1,
	GMIME_VALIDITY_NEVER     = 2,
	GMIME_VALIDITY_MARGINAL  = 3,
	GMIME_VALIDITY_FULL      = 4,
	GMIME_VALIDITY_ULTIMATE  = 5
} GMimeValidity;

typedef enum {
	GMIME_PUBKEY_ALGO_DEFAULT  = 0,
	GMIME_PUBKEY_ALGO_RSA      = 1,
	GMIME_PUBKEY_ALGO_RSA_E    = 2,
	GMIME_PUBKEY_ALGO_RSA_S    = 3,
	GMIME_PUBKEY_ALGO_ELG_E    = 16,
	GMIME_PUBKEY_ALGO_DSA      = 17,
	GMIME_PUBKEY_ALGO_ECC      = 18,
	GMIME_PUBKEY_ALGO_ELG      = 20,
	GMIME_PUBKEY_ALGO_ECDSA    = 301,
	GMIME_PUBKEY_ALGO_ECDH     = 302,
	GMIME_PUBKEY_ALGO_EDDSA    = 303
} GMimePubKeyAlgo;

typedef enum _GMimeSecureMimeType {
	GMIME_SECURE_MIME_TYPE_COMPRESSED_DATA,
	GMIME_SECURE_MIME_TYPE_ENVELOPED_DATA,
	GMIME_SECURE_MIME_TYPE_SIGNED_DATA,
	GMIME_SECURE_MIME_TYPE_CERTS_ONLY,
	GMIME_SECURE_MIME_TYPE_UNKNOWN,
} GMimeSecureMimeType;

typedef enum {
	GMIME_DIGEST_ALGO_DEFAULT       = 0,
	GMIME_DIGEST_ALGO_MD5           = 1,
	GMIME_DIGEST_ALGO_SHA1          = 2,
	GMIME_DIGEST_ALGO_RIPEMD160     = 3,
	GMIME_DIGEST_ALGO_MD2           = 5,
	GMIME_DIGEST_ALGO_TIGER192      = 6,
	GMIME_DIGEST_ALGO_HAVAL5160     = 7,
	GMIME_DIGEST_ALGO_SHA256        = 8,
	GMIME_DIGEST_ALGO_SHA384        = 9,
	GMIME_DIGEST_ALGO_SHA512        = 10,
	GMIME_DIGEST_ALGO_SHA224        = 11,
	GMIME_DIGEST_ALGO_MD4           = 301,
	GMIME_DIGEST_ALGO_CRC32         = 302,
	GMIME_DIGEST_ALGO_CRC32_RFC1510 = 303,
	GMIME_DIGEST_ALGO_CRC32_RFC2440 = 304
} GMimeDigestAlgo;

typedef enum {
	GMIME_CIPHER_ALGO_DEFAULT     = 0,
	GMIME_CIPHER_ALGO_IDEA        = 1,
	GMIME_CIPHER_ALGO_3DES        = 2,
	GMIME_CIPHER_ALGO_CAST5       = 3,
	GMIME_CIPHER_ALGO_BLOWFISH    = 4,
	GMIME_CIPHER_ALGO_AES         = 7,
	GMIME_CIPHER_ALGO_AES192      = 8,
	GMIME_CIPHER_ALGO_AES256      = 9,
	GMIME_CIPHER_ALGO_TWOFISH     = 10,
	GMIME_CIPHER_ALGO_CAMELLIA128 = 11,
	GMIME_CIPHER_ALGO_CAMELLIA192 = 12,
	GMIME_CIPHER_ALGO_CAMELLIA256 = 13
} GMimeCipherAlgo;

typedef enum {
	GMIME_STREAM_SEEK_SET = 0,
	GMIME_STREAM_SEEK_CUR = 1,
	GMIME_STREAM_SEEK_END = 2
} GMimeSeekWhence;

typedef enum {
	GMIME_STREAM_BUFFER_BLOCK_READ,
	GMIME_STREAM_BUFFER_BLOCK_WRITE
} GMimeStreamBufferMode;

typedef enum {
	GMIME_OPENPGP_DATA_NONE,
	GMIME_OPENPGP_DATA_ENCRYPTED,
	GMIME_OPENPGP_DATA_SIGNED,
	GMIME_OPENPGP_DATA_PUBLIC_KEY,
	GMIME_OPENPGP_DATA_PRIVATE_KEY
} GMimeOpenPGPData;

typedef enum {
  G_CHECKSUM_MD5,
  G_CHECKSUM_SHA1,
  G_CHECKSUM_SHA256,
  G_CHECKSUM_SHA512,
  G_CHECKSUM_SHA384
} GChecksumType;

typedef enum {
	GMIME_FILTER_BEST_CHARSET  = (1 << 0),
	GMIME_FILTER_BEST_ENCODING = (1 << 1)
} GMimeFilterBestFlags;

typedef enum {
	GMIME_FILTER_FROM_MODE_DEFAULT  = 0,
	GMIME_FILTER_FROM_MODE_ESCAPE   = 0,
	GMIME_FILTER_FROM_MODE_ARMOR    = 1
} GMimeFilterFromMode;

typedef enum {
	GMIME_FILTER_GZIP_MODE_ZIP,
	GMIME_FILTER_GZIP_MODE_UNZIP
} GMimeFilterGZipMode;

typedef enum {
	GMIME_AUTOCRYPT_PREFER_ENCRYPT_NONE     = 0,
	GMIME_AUTOCRYPT_PREFER_ENCRYPT_MUTUAL   = 1
} GMimeAutocryptPreferEncrypt;

typedef enum {
	GMIME_ENCRYPT_NONE          = 0,
	GMIME_ENCRYPT_ALWAYS_TRUST  = 1,
	GMIME_ENCRYPT_NO_COMPRESS   = 16,
	GMIME_ENCRYPT_SYMMETRIC     = 32,
	GMIME_ENCRYPT_THROW_KEYIDS  = 64,
} GMimeEncryptFlags;

typedef enum {
	GMIME_FORMAT_MESSAGE,
	GMIME_FORMAT_MBOX,
	GMIME_FORMAT_MMDF
} GMimeFormat;

typedef enum {
	GMIME_DECRYPT_NONE                             = 0,
	GMIME_DECRYPT_EXPORT_SESSION_KEY               = 1 << 0,
	GMIME_DECRYPT_NO_VERIFY                        = 1 << 1,

	GMIME_DECRYPT_ENABLE_KEYSERVER_LOOKUPS         = 1 << 15,
	GMIME_DECRYPT_ENABLE_ONLINE_CERTIFICATE_CHECKS = 1 << 15
} GMimeDecryptFlags;


typedef enum {
	GMIME_VERIFY_NONE                             = 0,
	GMIME_VERIFY_ENABLE_KEYSERVER_LOOKUPS         = 1 << 15,
	GMIME_VERIFY_ENABLE_ONLINE_CERTIFICATE_CHECKS = 1 << 15
} GMimeVerifyFlags;

enum {
	GMIME_MULTIPART_SIGNED_CONTENT,
	GMIME_MULTIPART_SIGNED_SIGNATURE
};

typedef enum GMimeAddressType {
   GMIME_ADDRESS_TYPE_SENDER,
   GMIME_ADDRESS_TYPE_FROM,
   GMIME_ADDRESS_TYPE_REPLY_TO,
   GMIME_ADDRESS_TYPE_TO,
   GMIME_ADDRESS_TYPE_CC,
   GMIME_ADDRESS_TYPE_BCC,
} GMimeAddressType;

typedef enum {
	GMIME_CONTENT_ENCODING_DEFAULT,
	GMIME_CONTENT_ENCODING_7BIT,
	GMIME_CONTENT_ENCODING_8BIT,
	GMIME_CONTENT_ENCODING_BINARY,
	GMIME_CONTENT_ENCODING_BASE64,
	GMIME_CONTENT_ENCODING_QUOTEDPRINTABLE,
	GMIME_CONTENT_ENCODING_UUENCODE
} GMimeContentEncoding;

typedef enum {
	GMIME_ENCODING_CONSTRAINT_7BIT,
	GMIME_ENCODING_CONSTRAINT_8BIT,
	GMIME_ENCODING_CONSTRAINT_BINARY
} GMimeEncodingConstraint;

enum {
	GMIME_ERROR_GENERAL             = -1,
	GMIME_ERROR_NOT_SUPPORTED       = -2,
	GMIME_ERROR_INVALID_OPERATION   = -3,
	GMIME_ERROR_PARSE_ERROR         = -4,
	GMIME_ERROR_PROTOCOL_ERROR      = -5
};

typedef enum {
	GMIME_SIGNATURE_STATUS_VALID         = 0x0001,
	GMIME_SIGNATURE_STATUS_GREEN         = 0x0002,
	GMIME_SIGNATURE_STATUS_RED           = 0x0004,
	GMIME_SIGNATURE_STATUS_KEY_REVOKED   = 0x0010,
	GMIME_SIGNATURE_STATUS_KEY_EXPIRED   = 0x0020,
	GMIME_SIGNATURE_STATUS_SIG_EXPIRED   = 0x0040,
	GMIME_SIGNATURE_STATUS_KEY_MISSING   = 0x0080,
	GMIME_SIGNATURE_STATUS_CRL_MISSING   = 0x0100,
	GMIME_SIGNATURE_STATUS_CRL_TOO_OLD   = 0x0200,
	GMIME_SIGNATURE_STATUS_BAD_POLICY    = 0x0400,
	GMIME_SIGNATURE_STATUS_SYS_ERROR     = 0x0800,
	GMIME_SIGNATURE_STATUS_TOFU_CONFLICT = 0x1000
} GMimeSignatureStatus;

]])

ffi.cdef([[
/* Init */
gboolean g_mime_check_version (guint major, guint minor, guint micro);
void g_mime_init (void);
void g_mime_shutdown (void);

/* Message */
GMimeMessage *g_mime_message_new (gboolean pretty_headers);

InternetAddressList *g_mime_message_get_from (GMimeMessage *message);
InternetAddressList *g_mime_message_get_sender (GMimeMessage *message);
InternetAddressList *g_mime_message_get_reply_to (GMimeMessage *message);
InternetAddressList *g_mime_message_get_to (GMimeMessage *message);
InternetAddressList *g_mime_message_get_cc (GMimeMessage *message);
InternetAddressList *g_mime_message_get_bcc (GMimeMessage *message);

void g_mime_message_add_mailbox (GMimeMessage *message, GMimeAddressType type, const char *name, const char *addr);
InternetAddressList *g_mime_message_get_addresses (GMimeMessage *message, GMimeAddressType type);
InternetAddressList *g_mime_message_get_all_recipients (GMimeMessage *message);

void g_mime_message_set_subject (GMimeMessage *message, const char *subject, const char *charset);
const char *g_mime_message_get_subject (GMimeMessage *message);

void g_mime_message_set_date (GMimeMessage *message, GDateTime *date);
GDateTime *g_mime_message_get_date (GMimeMessage *message);

void g_mime_message_set_message_id (GMimeMessage *message, const char *message_id);
const char *g_mime_message_get_message_id (GMimeMessage *message);

GMimeObject *g_mime_message_get_mime_part (GMimeMessage *message);
void g_mime_message_set_mime_part (GMimeMessage *message, GMimeObject *mime_part);

GMimeAutocryptHeader *g_mime_message_get_autocrypt_header (GMimeMessage *message, GDateTime *now);
GMimeAutocryptHeaderList *g_mime_message_get_autocrypt_gossip_headers (GMimeMessage *message, GDateTime *now, GMimeDecryptFlags flags, const char *session_key, GError **err);
GMimeAutocryptHeaderList *g_mime_message_get_autocrypt_gossip_headers_from_inner_part (GMimeMessage *message, GDateTime *now, GMimeObject *inner_part);


GMimeObject *g_mime_message_get_body (GMimeMessage *message);

void g_mime_part_set_openpgp_data (GMimePart *mime_part, GMimeOpenPGPData data);
GMimeOpenPGPData g_mime_part_get_openpgp_data (GMimePart *mime_part);

GMimePart *g_mime_part_new (void);
GMimePart *g_mime_part_new_with_type (const char *type, const char *subtype);

void g_mime_part_set_content_description (GMimePart *mime_part, const char *description);
const char *g_mime_part_get_content_description (GMimePart *mime_part);

void g_mime_part_set_content_id (GMimePart *mime_part, const char *content_id);
const char *g_mime_part_get_content_id (GMimePart *mime_part);

void g_mime_part_set_content_md5 (GMimePart *mime_part, const char *content_md5);
gboolean g_mime_part_verify_content_md5 (GMimePart *mime_part);
const char *g_mime_part_get_content_md5 (GMimePart *mime_part);

void g_mime_part_set_content_location (GMimePart *mime_part, const char *content_location);
const char *g_mime_part_get_content_location (GMimePart *mime_part);

void g_mime_part_set_content_encoding (GMimePart *mime_part, GMimeContentEncoding encoding);
GMimeContentEncoding g_mime_part_get_content_encoding (GMimePart *mime_part);

GMimeContentEncoding g_mime_part_get_best_content_encoding (GMimePart *mime_part, GMimeEncodingConstraint constraint);

gboolean g_mime_part_is_attachment (GMimePart *mime_part);

void g_mime_part_set_filename (GMimePart *mime_part, const char *filename);
const char *g_mime_part_get_filename (GMimePart *mime_part);

void g_mime_part_set_content (GMimePart *mime_part, GMimeDataWrapper *content);
GMimeDataWrapper *g_mime_part_get_content (GMimePart *mime_part);

gboolean g_mime_part_openpgp_encrypt (GMimePart *mime_part, gboolean sign, const char *userid,
				      GMimeEncryptFlags flags, GPtrArray *recipients, GError **err);
GMimeDecryptResult *g_mime_part_openpgp_decrypt (GMimePart *mime_part, GMimeDecryptFlags flags,
						 const char *session_key, GError **err);

gboolean g_mime_part_openpgp_sign (GMimePart *mime_part, const char *userid, GError **err);
GMimeSignatureList *g_mime_part_openpgp_verify (GMimePart *mime_part, GMimeVerifyFlags flags, GError **err);

GMimeMessagePart *g_mime_message_part_new (const char *subtype);
GMimeMessagePart *g_mime_message_part_new_with_message (const char *subtype, GMimeMessage *message);
void g_mime_message_part_set_message (GMimeMessagePart *part, GMimeMessage *message);
GMimeMessage *g_mime_message_part_get_message (GMimeMessagePart *part);

GMimeMessagePartial *g_mime_message_partial_new (const char *id, int number, int total);
const char *g_mime_message_partial_get_id (GMimeMessagePartial *partial);
int g_mime_message_partial_get_number (GMimeMessagePartial *partial);
int g_mime_message_partial_get_total (GMimeMessagePartial *partial);
GMimeMessage *g_mime_message_partial_reconstruct_message (GMimeMessagePartial **partials, size_t num);
GMimeMessage **g_mime_message_partial_split_message (GMimeMessage *message, size_t max_size, size_t *nparts);

// void g_mime_multipart_foreach (GMimeMultipart *multipart, GMimeObjectForeachFunc callback,
// 			       gpointer user_data);
GMimeMultipart *g_mime_multipart_new (void);

GMimeMultipart *g_mime_multipart_new_with_subtype (const char *subtype);

void g_mime_multipart_set_prologue (GMimeMultipart *multipart, const char *prologue);
const char *g_mime_multipart_get_prologue (GMimeMultipart *multipart);

void g_mime_multipart_set_epilogue (GMimeMultipart *multipart, const char *epilogue);
const char *g_mime_multipart_get_epilogue (GMimeMultipart *multipart);

void g_mime_multipart_clear (GMimeMultipart *multipart);

void g_mime_multipart_add (GMimeMultipart *multipart, GMimeObject *part);
void g_mime_multipart_insert (GMimeMultipart *multipart, int index, GMimeObject *part);
gboolean g_mime_multipart_remove (GMimeMultipart *multipart, GMimeObject *part);
GMimeObject *g_mime_multipart_remove_at (GMimeMultipart *multipart, int index);
GMimeObject *g_mime_multipart_replace (GMimeMultipart *multipart, int index, GMimeObject *replacement);
GMimeObject *g_mime_multipart_get_part (GMimeMultipart *multipart, int index);

gboolean g_mime_multipart_contains (GMimeMultipart *multipart, GMimeObject *part);
int g_mime_multipart_index_of (GMimeMultipart *multipart, GMimeObject *part);

int g_mime_multipart_get_count (GMimeMultipart *multipart);

void g_mime_multipart_set_boundary (GMimeMultipart *multipart, const char *boundary);
const char *g_mime_multipart_get_boundary (GMimeMultipart *multipart);


GMimeObject *g_mime_multipart_get_subpart_from_content_id (GMimeMultipart *multipart,
							   const char *content_id);

GMimeMultipartSigned *g_mime_multipart_signed_new (void);

GMimeMultipartSigned *g_mime_multipart_signed_sign (GMimeCryptoContext *ctx, GMimeObject *entity,
						    const char *userid, GError **err);

GMimeSignatureList *g_mime_multipart_signed_verify (GMimeMultipartSigned *mps, GMimeVerifyFlags flags, GError **err);

GMimeMultipartEncrypted *g_mime_multipart_encrypted_new (void);

GMimeMultipartEncrypted *g_mime_multipart_encrypted_encrypt (GMimeCryptoContext *ctx, GMimeObject *entity,
							     gboolean sign, const char *userid,
							     GMimeEncryptFlags flags, GPtrArray *recipients,
							     GError **err);

GMimeObject *g_mime_multipart_encrypted_decrypt (GMimeMultipartEncrypted *encrypted,
						 GMimeDecryptFlags flags,
						 const char *session_key,
						 GMimeDecryptResult **result,
						 GError **err);

GMimeTextPart *g_mime_text_part_new (void);
GMimeTextPart *g_mime_text_part_new_with_subtype (const char *subtype);

void g_mime_text_part_set_charset (GMimeTextPart *mime_part, const char *charset);
const char *g_mime_text_part_get_charset (GMimeTextPart *mime_part);

void g_mime_text_part_set_text (GMimeTextPart *mime_part, const char *text);
char *g_mime_text_part_get_text (GMimeTextPart *mime_part);

/* Filters */
GMimeFilter *g_mime_filter_copy (GMimeFilter *filter);

void g_mime_filter_filter (GMimeFilter *filter,
			   char *inbuf, size_t inlen, size_t prespace,
			   char **outbuf, size_t *outlen, size_t *outprespace);

void g_mime_filter_complete (GMimeFilter *filter,
			     char *inbuf, size_t inlen, size_t prespace,
			     char **outbuf, size_t *outlen, size_t *outprespace);

void g_mime_filter_reset (GMimeFilter *filter);


void g_mime_filter_backup (GMimeFilter *filter, const char *data, size_t length);

void g_mime_filter_set_size (GMimeFilter *filter, size_t size, gboolean keep);

GMimeFilter *g_mime_filter_best_new (GMimeFilterBestFlags flags);

const char *g_mime_filter_best_charset (GMimeFilterBest *best);

GMimeContentEncoding g_mime_filter_best_encoding (GMimeFilterBest *best, GMimeEncodingConstraint constraint);

GMimeFilter *g_mime_filter_from_new (GMimeFilterFromMode mode);

GMimeFilter *g_mime_filter_gzip_new (GMimeFilterGZipMode mode, int level);

const char *g_mime_filter_gzip_get_filename (GMimeFilterGZip *gzip);
void g_mime_filter_gzip_set_filename (GMimeFilterGZip *gzip, const char *filename);

const char *g_mime_filter_gzip_get_comment (GMimeFilterGZip *gzip);
void g_mime_filter_gzip_set_comment (GMimeFilterGZip *gzip, const char *comment);

GMimeFilter *g_mime_filter_html_new (guint32 flags, guint32 colour);

GMimeFilter *g_mime_filter_yenc_new (gboolean encode);

void g_mime_filter_yenc_set_state (GMimeFilterYenc *yenc, int state);
void g_mime_filter_yenc_set_crc (GMimeFilterYenc *yenc, guint32 crc);

/*int     g_mime_filter_yenc_get_part (GMimeFilterYenc *yenc);*/
guint32 g_mime_filter_yenc_get_pcrc (GMimeFilterYenc *yenc);
guint32 g_mime_filter_yenc_get_crc (GMimeFilterYenc *yenc);

size_t g_mime_ydecode_step  (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf,
			     int *state, guint32 *pcrc, guint32 *crc);
size_t g_mime_yencode_step  (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf,
			     int *state, guint32 *pcrc, guint32 *crc);
size_t g_mime_yencode_close (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf,
			     int *state, guint32 *pcrc, guint32 *crc);

GMimeFilter *g_mime_filter_basic_new (GMimeContentEncoding encoding, gboolean encode);

GMimeFilter *g_mime_filter_strip_new (void);

GMimeFilter *g_mime_filter_charset_new (const char *from_charset, const char *to_charset);

GMimeFilter *g_mime_filter_openpgp_new (void);

GMimeOpenPGPData g_mime_filter_openpgp_get_data_type (GMimeFilterOpenPGP *openpgp);
gint64 g_mime_filter_openpgp_get_begin_offset (GMimeFilterOpenPGP *openpgp);
gint64 g_mime_filter_openpgp_get_end_offset (GMimeFilterOpenPGP *openpgp);

GMimeFilter *g_mime_filter_windows_new (const char *claimed_charset);


gboolean g_mime_filter_windows_is_windows_charset (GMimeFilterWindows *filter);

const char *g_mime_filter_windows_real_charset (GMimeFilterWindows *filter);

GMimeFilter *g_mime_filter_checksum_new (GChecksumType type);

size_t g_mime_filter_checksum_get_digest (GMimeFilterChecksum *checksum, unsigned char *digest, size_t len);

gchar *g_mime_filter_checksum_get_string (GMimeFilterChecksum *checksum);

GMimeFilter *g_mime_filter_dos2unix_new (gboolean ensure_newline);

GMimeFilter *g_mime_filter_unix2dos_new (gboolean ensure_newline);

GMimeFilter *g_mime_filter_enriched_new (guint32 flags);

GMimeFilter *g_mime_filter_smtp_data_new (void);

void g_mime_filter_reply_module_init (void);
GMimeFilter *g_mime_filter_reply_new (gboolean encode);

/* Streams */
typedef void (* GMimeParserHeaderRegexFunc) (GMimeParser *parser, const char *header,
					     const char *value, gint64 offset,
					     gpointer user_data);

GMimeParser *g_mime_parser_new (void);
GMimeParser *g_mime_parser_new_with_stream (GMimeStream *stream);

void g_mime_parser_init_with_stream (GMimeParser *parser, GMimeStream *stream);

gboolean g_mime_parser_get_persist_stream (GMimeParser *parser);
void g_mime_parser_set_persist_stream (GMimeParser *parser, gboolean persist);

GMimeFormat g_mime_parser_get_format (GMimeParser *parser);
void g_mime_parser_set_format (GMimeParser *parser, GMimeFormat format);

gboolean g_mime_parser_get_respect_content_length (GMimeParser *parser);
void g_mime_parser_set_respect_content_length (GMimeParser *parser, gboolean respect_content_length);

void g_mime_parser_set_header_regex (GMimeParser *parser, const char *regex,
				     GMimeParserHeaderRegexFunc header_cb,
				     gpointer user_data);

GMimeObject *g_mime_parser_construct_part (GMimeParser *parser, GMimeParserOptions *options);
GMimeMessage *g_mime_parser_construct_message (GMimeParser *parser, GMimeParserOptions *options);

gint64 g_mime_parser_tell (GMimeParser *parser);

gboolean g_mime_parser_eos (GMimeParser *parser);

char *g_mime_parser_get_mbox_marker (GMimeParser *parser);
gint64 g_mime_parser_get_mbox_marker_offset (GMimeParser *parser);

gint64 g_mime_parser_get_headers_begin (GMimeParser *parser);
gint64 g_mime_parser_get_headers_end (GMimeParser *parser);

void g_mime_stream_construct (GMimeStream *stream, gint64 start, gint64 end);

ssize_t   g_mime_stream_read    (GMimeStream *stream, char *buf, size_t len);
ssize_t   g_mime_stream_write   (GMimeStream *stream, const char *buf, size_t len);
int       g_mime_stream_flush   (GMimeStream *stream);
int       g_mime_stream_close   (GMimeStream *stream);
gboolean  g_mime_stream_eos     (GMimeStream *stream);
int       g_mime_stream_reset   (GMimeStream *stream);
gint64    g_mime_stream_seek    (GMimeStream *stream, gint64 offset, GMimeSeekWhence whence);
gint64    g_mime_stream_tell    (GMimeStream *stream);
gint64    g_mime_stream_length  (GMimeStream *stream);

GMimeStream *g_mime_stream_substream (GMimeStream *stream, gint64 start, gint64 end);

void      g_mime_stream_set_bounds (GMimeStream *stream, gint64 start, gint64 end);

ssize_t   g_mime_stream_write_string (GMimeStream *stream, const char *str);
ssize_t   g_mime_stream_printf       (GMimeStream *stream, const char *fmt, ...);

gint64    g_mime_stream_write_to_stream (GMimeStream *src, GMimeStream *dest);

gint64    g_mime_stream_writev (GMimeStream *stream, GMimeStreamIOVector *vector, size_t count);

GMimeStream *g_mime_stream_fs_new (int fd);
GMimeStream *g_mime_stream_fs_new_with_bounds (int fd, gint64 start, gint64 end);

GMimeStream *g_mime_stream_fs_open (const char *path, int flags, int mode, GError **err);

gboolean g_mime_stream_fs_get_owner (GMimeStreamFs *stream);
void g_mime_stream_fs_set_owner (GMimeStreamFs *stream, gboolean owner);

GMimeStream *g_mime_stream_cat_new (void);

int g_mime_stream_cat_add_source (GMimeStreamCat *cat, GMimeStream *source);

GMimeStream *g_mime_stream_mem_new (void);
GMimeStream *g_mime_stream_mem_new_with_byte_array (GByteArray *array);
GMimeStream *g_mime_stream_mem_new_with_buffer (const char *buffer, size_t len);

GByteArray *g_mime_stream_mem_get_byte_array (GMimeStreamMem *mem);
void g_mime_stream_mem_set_byte_array (GMimeStreamMem *mem, GByteArray *array);

gboolean g_mime_stream_mem_get_owner (GMimeStreamMem *mem);
void g_mime_stream_mem_set_owner (GMimeStreamMem *mem, gboolean owner);

GMimeStream *g_mime_stream_file_new (FILE *fp);
GMimeStream *g_mime_stream_file_new_with_bounds (FILE *fp, gint64 start, gint64 end);

GMimeStream *g_mime_stream_file_open (const char *path, const char *mode, GError **err);

gboolean g_mime_stream_file_get_owner (GMimeStreamFile *stream);
void g_mime_stream_file_set_owner (GMimeStreamFile *stream, gboolean owner);


GMimeStream *g_mime_stream_mmap_new (int fd, int prot, int flags);
GMimeStream *g_mime_stream_mmap_new_with_bounds (int fd, int prot, int flags, gint64 start, gint64 end);

gboolean g_mime_stream_mmap_get_owner (GMimeStreamMmap *stream);
void g_mime_stream_mmap_set_owner (GMimeStreamMmap *stream, gboolean owner);

GMimeStream *g_mime_stream_null_new (void);

void g_mime_stream_null_set_count_newlines (GMimeStreamNull *stream, gboolean count);
gboolean g_mime_stream_null_get_count_newlines (GMimeStreamNull *stream);

GMimeStream *g_mime_stream_pipe_new (int fd);

gboolean g_mime_stream_pipe_get_owner (GMimeStreamPipe *stream);
void g_mime_stream_pipe_set_owner (GMimeStreamPipe *stream, gboolean owner);

GMimeStream *g_mime_stream_buffer_new (GMimeStream *source, GMimeStreamBufferMode mode);

ssize_t g_mime_stream_buffer_gets (GMimeStream *stream, char *buf, size_t max);

void    g_mime_stream_buffer_readln (GMimeStream *stream, GByteArray *buffer);

GMimeStream *g_mime_stream_filter_new (GMimeStream *stream);

int g_mime_stream_filter_add (GMimeStreamFilter *stream, GMimeFilter *filter);
void g_mime_stream_filter_remove (GMimeStreamFilter *stream, int id);

void g_mime_stream_filter_set_owner (GMimeStreamFilter *stream, gboolean owner);
gboolean g_mime_stream_filter_get_owner (GMimeStreamFilter *stream);

GMimeDataWrapper *g_mime_data_wrapper_new (void);
GMimeDataWrapper *g_mime_data_wrapper_new_with_stream (GMimeStream *stream, GMimeContentEncoding encoding);

void g_mime_data_wrapper_set_stream (GMimeDataWrapper *wrapper, GMimeStream *stream);
GMimeStream *g_mime_data_wrapper_get_stream (GMimeDataWrapper *wrapper);

void g_mime_data_wrapper_set_encoding (GMimeDataWrapper *wrapper, GMimeContentEncoding encoding);
GMimeContentEncoding g_mime_data_wrapper_get_encoding (GMimeDataWrapper *wrapper);

ssize_t g_mime_data_wrapper_write_to_stream (GMimeDataWrapper *wrapper, GMimeStream *stream);

/* Encryption */
void g_mime_crypto_context_register (const char *protocol, GMimeCryptoContextNewFunc callback);
void g_mime_crypto_context_set_request_password (GMimeCryptoContext *ctx, GMimePasswordRequestFunc request_passwd);

GMimeCryptoContext *g_mime_crypto_context_new (const char *protocol);

GMimeDigestAlgo g_mime_crypto_context_digest_id (GMimeCryptoContext *ctx, const char *name);
const char *g_mime_crypto_context_digest_name (GMimeCryptoContext *ctx, GMimeDigestAlgo digest);

/* protocol routines */
const char *g_mime_crypto_context_get_signature_protocol (GMimeCryptoContext *ctx);
const char *g_mime_crypto_context_get_encryption_protocol (GMimeCryptoContext *ctx);
const char *g_mime_crypto_context_get_key_exchange_protocol (GMimeCryptoContext *ctx);

/* crypto routines */
int g_mime_crypto_context_sign (GMimeCryptoContext *ctx, gboolean detach, const char *userid,
				GMimeStream *istream, GMimeStream *ostream, GError **err);

GMimeSignatureList *g_mime_crypto_context_verify (GMimeCryptoContext *ctx, GMimeVerifyFlags flags,
						  GMimeStream *istream, GMimeStream *sigstream,
						  GMimeStream *ostream, GError **err);

int g_mime_crypto_context_encrypt (GMimeCryptoContext *ctx, gboolean sign, const char *userid,
				   GMimeEncryptFlags flags, GPtrArray *recipients,
				   GMimeStream *istream, GMimeStream *ostream,
				   GError **err);

GMimeDecryptResult *g_mime_crypto_context_decrypt (GMimeCryptoContext *ctx, GMimeDecryptFlags flags,
						   const char *session_key, GMimeStream *istream,
						   GMimeStream *ostream, GError **err);

/* key/certificate routines */
int g_mime_crypto_context_import_keys (GMimeCryptoContext *ctx, GMimeStream *istream, GError **err);

int g_mime_crypto_context_export_keys (GMimeCryptoContext *ctx, const char *keys[],
				       GMimeStream *ostream, GError **err);


GMimeDecryptResult *g_mime_decrypt_result_new (void);

void g_mime_decrypt_result_set_recipients (GMimeDecryptResult *result, GMimeCertificateList *recipients);
GMimeCertificateList *g_mime_decrypt_result_get_recipients (GMimeDecryptResult *result);

void g_mime_decrypt_result_set_signatures (GMimeDecryptResult *result, GMimeSignatureList *signatures);
GMimeSignatureList *g_mime_decrypt_result_get_signatures (GMimeDecryptResult *result);

void g_mime_decrypt_result_set_cipher (GMimeDecryptResult *result, GMimeCipherAlgo cipher);
GMimeCipherAlgo g_mime_decrypt_result_get_cipher (GMimeDecryptResult *result);

void g_mime_decrypt_result_set_mdc (GMimeDecryptResult *result, GMimeDigestAlgo mdc);
GMimeDigestAlgo g_mime_decrypt_result_get_mdc (GMimeDecryptResult *result);

void g_mime_decrypt_result_set_session_key (GMimeDecryptResult *result, const char *session_key);
const char *g_mime_decrypt_result_get_session_key (GMimeDecryptResult *result);

GMimeAutocryptHeader *g_mime_autocrypt_header_new (void);
GMimeAutocryptHeader *g_mime_autocrypt_header_new_from_string (const char *string);

void g_mime_autocrypt_header_set_address (GMimeAutocryptHeader *ah, InternetAddressMailbox *address);
InternetAddressMailbox *g_mime_autocrypt_header_get_address (GMimeAutocryptHeader *ah);
void g_mime_autocrypt_header_set_address_from_string (GMimeAutocryptHeader *ah, const char *address);
const char *g_mime_autocrypt_header_get_address_as_string (GMimeAutocryptHeader *ah);

void g_mime_autocrypt_header_set_prefer_encrypt (GMimeAutocryptHeader *ah, GMimeAutocryptPreferEncrypt pref);
GMimeAutocryptPreferEncrypt g_mime_autocrypt_header_get_prefer_encrypt (GMimeAutocryptHeader *ah);

void g_mime_autocrypt_header_set_keydata (GMimeAutocryptHeader *ah, GBytes *data);
GBytes *g_mime_autocrypt_header_get_keydata (GMimeAutocryptHeader *ah);

void g_mime_autocrypt_header_set_effective_date (GMimeAutocryptHeader *ah, GDateTime *effective_date);
GDateTime *g_mime_autocrypt_header_get_effective_date (GMimeAutocryptHeader *ah);

char *g_mime_autocrypt_header_to_string (GMimeAutocryptHeader *ah, gboolean gossip);
gboolean g_mime_autocrypt_header_is_complete (GMimeAutocryptHeader *ah);

int g_mime_autocrypt_header_compare (GMimeAutocryptHeader *ah1, GMimeAutocryptHeader *ah2);
void g_mime_autocrypt_header_clone (GMimeAutocryptHeader *dst, GMimeAutocryptHeader *src);

GMimeAutocryptHeaderList *g_mime_autocrypt_header_list_new (void);
guint g_mime_autocrypt_header_list_add_missing_addresses (GMimeAutocryptHeaderList *list, InternetAddressList *addresses);
void g_mime_autocrypt_header_list_add (GMimeAutocryptHeaderList *list, GMimeAutocryptHeader *header);

guint g_mime_autocrypt_header_list_get_count (GMimeAutocryptHeaderList *list);
GMimeAutocryptHeader *g_mime_autocrypt_header_list_get_header_at (GMimeAutocryptHeaderList *list, guint index);
GMimeAutocryptHeader *g_mime_autocrypt_header_list_get_header_for_address (GMimeAutocryptHeaderList *list, InternetAddressMailbox *mailbox);
void g_mime_autocrypt_header_list_remove_incomplete (GMimeAutocryptHeaderList *list);

GMimeSignature *g_mime_signature_new (void);

void g_mime_signature_set_certificate (GMimeSignature *sig, GMimeCertificate *cert);
GMimeCertificate *g_mime_signature_get_certificate (GMimeSignature *sig);

void g_mime_signature_set_status (GMimeSignature *sig, GMimeSignatureStatus status);
GMimeSignatureStatus g_mime_signature_get_status (GMimeSignature *sig);

void g_mime_signature_set_created (GMimeSignature *sig, time_t created);
time_t g_mime_signature_get_created (GMimeSignature *sig);
gint64 g_mime_signature_get_created64 (GMimeSignature *sig);

void g_mime_signature_set_expires (GMimeSignature *sig, time_t expires);
time_t g_mime_signature_get_expires (GMimeSignature *sig);
gint64 g_mime_signature_get_expires64 (GMimeSignature *sig);

GMimeSignatureList *g_mime_signature_list_new (void);

int g_mime_signature_list_length (GMimeSignatureList *list);

void g_mime_signature_list_clear (GMimeSignatureList *list);

int g_mime_signature_list_add (GMimeSignatureList *list, GMimeSignature *sig);
void g_mime_signature_list_insert (GMimeSignatureList *list, int index, GMimeSignature *sig);
gboolean g_mime_signature_list_remove (GMimeSignatureList *list, GMimeSignature *sig);
gboolean g_mime_signature_list_remove_at (GMimeSignatureList *list, int index);

gboolean g_mime_signature_list_contains (GMimeSignatureList *list, GMimeSignature *sig);
int g_mime_signature_list_index_of (GMimeSignatureList *list, GMimeSignature *sig);

GMimeSignature *g_mime_signature_list_get_signature (GMimeSignatureList *list, int index);
void g_mime_signature_list_set_signature (GMimeSignatureList *list, int index, GMimeSignature *sig);

GMimeCryptoContext *g_mime_pkcs7_context_new (void);

GMimeApplicationPkcs7Mime *g_mime_application_pkcs7_mime_new (GMimeSecureMimeType type);

GMimeSecureMimeType g_mime_application_pkcs7_mime_get_smime_type (GMimeApplicationPkcs7Mime *pkcs7_mime);

GMimeApplicationPkcs7Mime *g_mime_application_pkcs7_mime_encrypt (GMimeObject *entity, GMimeEncryptFlags flags,
								  GPtrArray *recipients, GError **err);

GMimeObject *g_mime_application_pkcs7_mime_decrypt (GMimeApplicationPkcs7Mime *pkcs7_mime,
						    GMimeDecryptFlags flags, const char *session_key,
						    GMimeDecryptResult **result, GError **err);

GMimeApplicationPkcs7Mime *g_mime_application_pkcs7_mime_sign (GMimeObject *entity, const char *userid, GError **err);

GMimeSignatureList *g_mime_application_pkcs7_mime_verify (GMimeApplicationPkcs7Mime *pkcs7_mime, GMimeVerifyFlags flags,
							  GMimeObject **entity, GError **err);

GMimeCryptoContext *g_mime_gpg_context_new (void);

GMimeCertificate *g_mime_certificate_new (void);

void g_mime_certificate_set_trust (GMimeCertificate *cert, GMimeTrust trust);
GMimeTrust g_mime_certificate_get_trust (GMimeCertificate *cert);

void g_mime_certificate_set_pubkey_algo (GMimeCertificate *cert, GMimePubKeyAlgo algo);
GMimePubKeyAlgo g_mime_certificate_get_pubkey_algo (GMimeCertificate *cert);

void g_mime_certificate_set_digest_algo (GMimeCertificate *cert, GMimeDigestAlgo algo);
GMimeDigestAlgo g_mime_certificate_get_digest_algo (GMimeCertificate *cert);

void g_mime_certificate_set_issuer_serial (GMimeCertificate *cert, const char *issuer_serial);
const char *g_mime_certificate_get_issuer_serial (GMimeCertificate *cert);

void g_mime_certificate_set_issuer_name (GMimeCertificate *cert, const char *issuer_name);
const char *g_mime_certificate_get_issuer_name (GMimeCertificate *cert);

void g_mime_certificate_set_fingerprint (GMimeCertificate *cert, const char *fingerprint);
const char *g_mime_certificate_get_fingerprint (GMimeCertificate *cert);

void g_mime_certificate_set_key_id (GMimeCertificate *cert, const char *key_id);
const char *g_mime_certificate_get_key_id (GMimeCertificate *cert);

void g_mime_certificate_set_email (GMimeCertificate *cert, const char *email);
const char *g_mime_certificate_get_email (GMimeCertificate *cert);

void g_mime_certificate_set_name (GMimeCertificate *cert, const char *name);
const char *g_mime_certificate_get_name (GMimeCertificate *cert);

void g_mime_certificate_set_user_id (GMimeCertificate *cert, const char *user_id);
const char *g_mime_certificate_get_user_id (GMimeCertificate *cert);

void g_mime_certificate_set_id_validity (GMimeCertificate *cert, GMimeValidity validity);
GMimeValidity g_mime_certificate_get_id_validity (GMimeCertificate *cert);

void g_mime_certificate_set_created (GMimeCertificate *cert, time_t created);
time_t g_mime_certificate_get_created (GMimeCertificate *cert);
gint64 g_mime_certificate_get_created64 (GMimeCertificate *cert);

void g_mime_certificate_set_expires (GMimeCertificate *cert, time_t expires);
time_t g_mime_certificate_get_expires (GMimeCertificate *cert);
gint64 g_mime_certificate_get_expires64 (GMimeCertificate *cert);

GMimeCertificateList *g_mime_certificate_list_new (void);

int g_mime_certificate_list_length (GMimeCertificateList *list);

void g_mime_certificate_list_clear (GMimeCertificateList *list);

int g_mime_certificate_list_add (GMimeCertificateList *list, GMimeCertificate *cert);
void g_mime_certificate_list_insert (GMimeCertificateList *list, int index, GMimeCertificate *cert);
gboolean g_mime_certificate_list_remove (GMimeCertificateList *list, GMimeCertificate *cert);
gboolean g_mime_certificate_list_remove_at (GMimeCertificateList *list, int index);

gboolean g_mime_certificate_list_contains (GMimeCertificateList *list, GMimeCertificate *cert);
int g_mime_certificate_list_index_of (GMimeCertificateList *list, GMimeCertificate *cert);

GMimeCertificate *g_mime_certificate_list_get_certificate (GMimeCertificateList *list, int index);
void g_mime_certificate_list_set_certificate (GMimeCertificateList *list, int index, GMimeCertificate *cert);

/* Content */
typedef char * (* GMimeHeaderRawValueFormatter) (GMimeHeader *header, GMimeFormatOptions *options,
						 const char *value, const char *charset);
char *g_mime_header_format_content_disposition (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
char *g_mime_header_format_content_type (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
char *g_mime_header_format_message_id (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
char *g_mime_header_format_references (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
char *g_mime_header_format_addrlist (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
char *g_mime_header_format_received (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);
char *g_mime_header_format_default (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);

const char *g_mime_header_get_name (GMimeHeader *header);
const char *g_mime_header_get_raw_name (GMimeHeader *header);

const char *g_mime_header_get_value (GMimeHeader *header);
void g_mime_header_set_value (GMimeHeader *header, GMimeFormatOptions *options, const char *value, const char *charset);

const char *g_mime_header_get_raw_value (GMimeHeader *header);
void g_mime_header_set_raw_value (GMimeHeader *header, const char *raw_value);

gint64 g_mime_header_get_offset (GMimeHeader *header);

ssize_t g_mime_header_write_to_stream (GMimeHeader *header, GMimeFormatOptions *options, GMimeStream *stream);

GMimeHeaderList *g_mime_header_list_new (GMimeParserOptions *options);

void g_mime_header_list_clear (GMimeHeaderList *headers);
int g_mime_header_list_get_count (GMimeHeaderList *headers);
gboolean g_mime_header_list_contains (GMimeHeaderList *headers, const char *name);
void g_mime_header_list_prepend (GMimeHeaderList *headers, const char *name, const char *value, const char *charset);
void g_mime_header_list_append (GMimeHeaderList *headers, const char *name, const char *value, const char *charset);
void g_mime_header_list_set (GMimeHeaderList *headers, const char *name, const char *value, const char *charset);
GMimeHeader *g_mime_header_list_get_header (GMimeHeaderList *headers, const char *name);
GMimeHeader *g_mime_header_list_get_header_at (GMimeHeaderList *headers, int index);
gboolean g_mime_header_list_remove (GMimeHeaderList *headers, const char *name);
void g_mime_header_list_remove_at (GMimeHeaderList *headers, int index);

ssize_t g_mime_header_list_write_to_stream (GMimeHeaderList *headers, GMimeFormatOptions *options, GMimeStream *stream);
char *g_mime_header_list_to_string (GMimeHeaderList *headers, GMimeFormatOptions *options);

GDateTime *g_mime_utils_header_decode_date (const char *str);
char *g_mime_utils_header_format_date (GDateTime *date);

char *g_mime_utils_generate_message_id (const char *fqdn);

char *g_mime_utils_decode_message_id (const char *message_id);

char  *g_mime_utils_structured_header_fold (GMimeParserOptions *options, GMimeFormatOptions *format, const char *header);
char  *g_mime_utils_unstructured_header_fold (GMimeParserOptions *options, GMimeFormatOptions *format, const char *header);
char  *g_mime_utils_header_printf (GMimeParserOptions *options, GMimeFormatOptions *format, const char *text, ...);
char  *g_mime_utils_header_unfold (const char *value);

char  *g_mime_utils_quote_string (const char *str);
void   g_mime_utils_unquote_string (char *str);

gboolean g_mime_utils_text_is_8bit (const unsigned char *text, size_t len);
GMimeContentEncoding g_mime_utils_best_encoding (const unsigned char *text, size_t len);

char *g_mime_utils_decode_8bit (GMimeParserOptions *options, const char *text, size_t len);

char *g_mime_utils_header_decode_text (GMimeParserOptions *options, const char *text);
char *g_mime_utils_header_encode_text (GMimeFormatOptions *options, const char *text, const char *charset);

char *g_mime_utils_header_decode_phrase (GMimeParserOptions *options, const char *phrase);
char *g_mime_utils_header_encode_phrase (GMimeFormatOptions *options, const char *phrase, const char *charset);

void internet_address_set_name (InternetAddress *ia, const char *name);
const char *internet_address_get_name (InternetAddress *ia);

void internet_address_set_charset (InternetAddress *ia, const char *charset);
const char *internet_address_get_charset (InternetAddress *ia);

char *internet_address_to_string (InternetAddress *ia, GMimeFormatOptions *options, gboolean encode);

InternetAddress *internet_address_mailbox_new (const char *name, const char *addr);

void internet_address_mailbox_set_addr (InternetAddressMailbox *mailbox, const char *addr);
const char *internet_address_mailbox_get_addr (InternetAddressMailbox *mailbox);
const char *internet_address_mailbox_get_idn_addr (InternetAddressMailbox *mailbox);

InternetAddress *internet_address_group_new (const char *name);

void internet_address_group_set_members (InternetAddressGroup *group, InternetAddressList *members);
InternetAddressList *internet_address_group_get_members (InternetAddressGroup *group);

int internet_address_group_add_member (InternetAddressGroup *group, InternetAddress *member);

InternetAddressList *internet_address_list_new (void);

int internet_address_list_length (InternetAddressList *list);

void internet_address_list_clear (InternetAddressList *list);

int internet_address_list_add (InternetAddressList *list, InternetAddress *ia);
void internet_address_list_prepend (InternetAddressList *list, InternetAddressList *prepend);
void internet_address_list_append (InternetAddressList *list, InternetAddressList *append);
void internet_address_list_insert (InternetAddressList *list, int index, InternetAddress *ia);
gboolean internet_address_list_remove (InternetAddressList *list, InternetAddress *ia);
gboolean internet_address_list_remove_at (InternetAddressList *list, int index);

gboolean internet_address_list_contains (InternetAddressList *list, InternetAddress *ia);
int internet_address_list_index_of (InternetAddressList *list, InternetAddress *ia);

InternetAddress *internet_address_list_get_address (InternetAddressList *list, int index);
void internet_address_list_set_address (InternetAddressList *list, int index, InternetAddress *ia);

char *internet_address_list_to_string (InternetAddressList *list, GMimeFormatOptions *options, gboolean encode);
void internet_address_list_encode (InternetAddressList *list, GMimeFormatOptions *options, GString *str);

InternetAddressList *internet_address_list_parse (GMimeParserOptions *options, const char *str);

GMimeContentDisposition *g_mime_content_disposition_new (void);
GMimeContentDisposition *g_mime_content_disposition_parse (GMimeParserOptions *options, const char *str);

void g_mime_content_disposition_set_disposition (GMimeContentDisposition *disposition, const char *value);
const char *g_mime_content_disposition_get_disposition (GMimeContentDisposition *disposition);

GMimeParamList *g_mime_content_disposition_get_parameters (GMimeContentDisposition *disposition);

void g_mime_content_disposition_set_parameter (GMimeContentDisposition *disposition,
					       const char *name, const char *value);
const char *g_mime_content_disposition_get_parameter (GMimeContentDisposition *disposition,
						      const char *name);

gboolean g_mime_content_disposition_is_attachment (GMimeContentDisposition *disposition);

char *g_mime_content_disposition_encode (GMimeContentDisposition *disposition, GMimeFormatOptions *options);

GMimeContentType *g_mime_content_type_new (const char *type, const char *subtype);
GMimeContentType *g_mime_content_type_parse (GMimeParserOptions *options, const char *str);

char *g_mime_content_type_get_mime_type (GMimeContentType *content_type);

char *g_mime_content_type_encode (GMimeContentType *content_type, GMimeFormatOptions *options);

gboolean g_mime_content_type_is_type (GMimeContentType *content_type, const char *type, const char *subtype);

void g_mime_content_type_set_media_type (GMimeContentType *content_type, const char *type);
const char *g_mime_content_type_get_media_type (GMimeContentType *content_type);

void g_mime_content_type_set_media_subtype (GMimeContentType *content_type, const char *subtype);
const char *g_mime_content_type_get_media_subtype (GMimeContentType *content_type);

GMimeParamList *g_mime_content_type_get_parameters (GMimeContentType *content_type);

void g_mime_content_type_set_parameter (GMimeContentType *content_type, const char *name, const char *value);
const char *g_mime_content_type_get_parameter (GMimeContentType *content_type, const char *name);

GMimeReferences *g_mime_references_new (void);
void g_mime_references_free (GMimeReferences *refs);

GMimeReferences *g_mime_references_parse (GMimeParserOptions *options, const char *text);

GMimeReferences *g_mime_references_copy (GMimeReferences *refs);

int g_mime_references_length (GMimeReferences *refs);

void g_mime_references_append (GMimeReferences *refs, const char *msgid);
void g_mime_references_clear (GMimeReferences *refs);

const char *g_mime_references_get_message_id (GMimeReferences *refs, int index);
void g_mime_references_set_message_id (GMimeReferences *refs, int index, const char *msgid);

/* Options */
typedef void (*GMimeParserWarningFunc) (gint64 offset, GMimeParserWarning errcode, const gchar *item, gpointer user_data);

GMimeParserOptions *g_mime_parser_options_get_default (void);

GMimeParserOptions *g_mime_parser_options_new (void);
void g_mime_parser_options_free (GMimeParserOptions *options);

GMimeParserOptions *g_mime_parser_options_clone (GMimeParserOptions *options);

GMimeRfcComplianceMode g_mime_parser_options_get_address_compliance_mode (GMimeParserOptions *options);
void g_mime_parser_options_set_address_compliance_mode (GMimeParserOptions *options, GMimeRfcComplianceMode mode);

gboolean g_mime_parser_options_get_allow_addresses_without_domain (GMimeParserOptions *options);
void g_mime_parser_options_set_allow_addresses_without_domain (GMimeParserOptions *options, gboolean allow);

GMimeRfcComplianceMode g_mime_parser_options_get_parameter_compliance_mode (GMimeParserOptions *options);
void g_mime_parser_options_set_parameter_compliance_mode (GMimeParserOptions *options, GMimeRfcComplianceMode mode);

GMimeRfcComplianceMode g_mime_parser_options_get_rfc2047_compliance_mode (GMimeParserOptions *options);
void g_mime_parser_options_set_rfc2047_compliance_mode (GMimeParserOptions *options, GMimeRfcComplianceMode mode);

const char **g_mime_parser_options_get_fallback_charsets (GMimeParserOptions *options);
void g_mime_parser_options_set_fallback_charsets (GMimeParserOptions *options, const char **charsets);

GMimeParserWarningFunc g_mime_parser_options_get_warning_callback (GMimeParserOptions *options);
void g_mime_parser_options_set_warning_callback (GMimeParserOptions *options, GMimeParserWarningFunc warning_cb,
						 gpointer user_data);

const char *g_mime_param_get_name (GMimeParam *param);

const char *g_mime_param_get_value (GMimeParam *param);
void g_mime_param_set_value (GMimeParam *param, const char *value);

const char *g_mime_param_get_charset (GMimeParam *param);
void g_mime_param_set_charset (GMimeParam *param, const char *charset);

const char *g_mime_param_get_lang (GMimeParam *param);
void g_mime_param_set_lang (GMimeParam *param, const char *lang);

GMimeParamEncodingMethod g_mime_param_get_encoding_method (GMimeParam *param);
void g_mime_param_set_encoding_method (GMimeParam *param, GMimeParamEncodingMethod method);

GMimeParamList *g_mime_param_list_new (void);
GMimeParamList *g_mime_param_list_parse (GMimeParserOptions *options, const char *str);

int g_mime_param_list_length (GMimeParamList *list);

void g_mime_param_list_clear (GMimeParamList *list);

void g_mime_param_list_set_parameter (GMimeParamList *list, const char *name, const char *value);
GMimeParam *g_mime_param_list_get_parameter (GMimeParamList *list, const char *name);
GMimeParam *g_mime_param_list_get_parameter_at (GMimeParamList *list, int index);

gboolean g_mime_param_list_remove (GMimeParamList *list, const char *name);
gboolean g_mime_param_list_remove_at (GMimeParamList *list, int index);

void g_mime_param_list_encode (GMimeParamList *list, GMimeFormatOptions *options, gboolean fold, GString *str);

GMimeFormatOptions *g_mime_format_options_get_default (void);

GMimeFormatOptions *g_mime_format_options_new (void);
void g_mime_format_options_free (GMimeFormatOptions *options);

GMimeFormatOptions *g_mime_format_options_clone (GMimeFormatOptions *options);

GMimeParamEncodingMethod g_mime_format_options_get_param_encoding_method (GMimeFormatOptions *options);
void g_mime_format_options_set_param_encoding_method (GMimeFormatOptions *options, GMimeParamEncodingMethod method);

GMimeNewLineFormat g_mime_format_options_get_newline_format (GMimeFormatOptions *options);
void g_mime_format_options_set_newline_format (GMimeFormatOptions *options, GMimeNewLineFormat newline);

const char *g_mime_format_options_get_newline (GMimeFormatOptions *options);
GMimeFilter *g_mime_format_options_create_newline_filter (GMimeFormatOptions *options, gboolean ensure_newline);

gboolean g_mime_format_options_is_hidden_header (GMimeFormatOptions *options, const char *header);
void g_mime_format_options_add_hidden_header (GMimeFormatOptions *options, const char *header);
void g_mime_format_options_remove_hidden_header (GMimeFormatOptions *options, const char *header);
void g_mime_format_options_clear_hidden_headers (GMimeFormatOptions *options);

/* Extra */
GMimeContentEncoding g_mime_content_encoding_from_string (const char *str);
const char *g_mime_content_encoding_to_string (GMimeContentEncoding encoding);
void g_mime_encoding_init_encode (GMimeEncoding *state, GMimeContentEncoding encoding);
void g_mime_encoding_init_decode (GMimeEncoding *state, GMimeContentEncoding encoding);
void g_mime_encoding_reset (GMimeEncoding *state);

size_t g_mime_encoding_outlen (GMimeEncoding *state, size_t inlen);

size_t g_mime_encoding_step (GMimeEncoding *state, const char *inbuf, size_t inlen, char *outbuf);
size_t g_mime_encoding_flush (GMimeEncoding *state, const char *inbuf, size_t inlen, char *outbuf);


size_t g_mime_encoding_base64_decode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
size_t g_mime_encoding_base64_encode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
size_t g_mime_encoding_base64_encode_close (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);

size_t g_mime_encoding_uudecode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
size_t g_mime_encoding_uuencode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, unsigned char *uubuf, int *state, guint32 *save);
size_t g_mime_encoding_uuencode_close (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, unsigned char *uubuf, int *state, guint32 *save);

size_t g_mime_encoding_quoted_decode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
size_t g_mime_encoding_quoted_encode_step (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);
size_t g_mime_encoding_quoted_encode_close (const unsigned char *inbuf, size_t inlen, unsigned char *outbuf, int *state, guint32 *save);

iconv_t g_mime_iconv_open (const char *to, const char *from);

int g_mime_iconv_close (iconv_t cd);

void        g_mime_charset_map_init (void);
void        g_mime_charset_map_shutdown (void);

const char *g_mime_locale_charset (void);
const char *g_mime_locale_language (void);

const char *g_mime_charset_language (const char *charset);

const char *g_mime_charset_canon_name (const char *charset);
const char *g_mime_charset_iconv_name (const char *charset);

const char *g_mime_charset_iso_to_windows (const char *isocharset);
void g_mime_charset_init (GMimeCharset *charset);
void g_mime_charset_step (GMimeCharset *charset, const char *inbuf, size_t inlen);
const char *g_mime_charset_best_name (GMimeCharset *charset);

const char *g_mime_charset_best (const char *inbuf, size_t inlen);

gboolean g_mime_charset_can_encode (GMimeCharset *mask, const char *charset,
				    const char *text, size_t len);

// util functions
char *g_mime_iconv_strdup (iconv_t cd, const char *str);
char *g_mime_iconv_strndup (iconv_t cd, const char *str, size_t n);

char *g_mime_iconv_locale_to_utf8 (const char *str);
char *g_mime_iconv_locale_to_utf8_length (const char *str, size_t n);

char *g_mime_iconv_utf8_to_locale (const char *str);
char *g_mime_iconv_utf8_to_locale_length (const char *str, size_t n);

typedef void (* GMimeObjectForeachFunc) (GMimeObject *parent, GMimeObject *part, gpointer user_data);

// void g_mime_object_register_type (const char *type, const char *subtype, GType object_type);

GMimeObject *g_mime_object_new (GMimeParserOptions *options, GMimeContentType *content_type);
GMimeObject *g_mime_object_new_type (GMimeParserOptions *options, const char *type, const char *subtype);

void g_mime_object_set_content_type (GMimeObject *object, GMimeContentType *content_type);
GMimeContentType *g_mime_object_get_content_type (GMimeObject *object);
void g_mime_object_set_content_type_parameter (GMimeObject *object, const char *name, const char *value);
const char *g_mime_object_get_content_type_parameter (GMimeObject *object, const char *name);

void g_mime_object_set_content_disposition (GMimeObject *object, GMimeContentDisposition *disposition);
GMimeContentDisposition *g_mime_object_get_content_disposition (GMimeObject *object);

void g_mime_object_set_disposition (GMimeObject *object, const char *disposition);
const char *g_mime_object_get_disposition (GMimeObject *object);

void g_mime_object_set_content_disposition_parameter (GMimeObject *object, const char *name, const char *value);
const char *g_mime_object_get_content_disposition_parameter (GMimeObject *object, const char *name);

void g_mime_object_set_content_id (GMimeObject *object, const char *content_id);
const char *g_mime_object_get_content_id (GMimeObject *object);

void g_mime_object_prepend_header (GMimeObject *object, const char *header, const char *value, const char *charset);
void g_mime_object_append_header (GMimeObject *object, const char *header, const char *value, const char *charset);
void g_mime_object_set_header (GMimeObject *object, const char *header, const char *value, const char *charset);
const char *g_mime_object_get_header (GMimeObject *object, const char *header);
gboolean g_mime_object_remove_header (GMimeObject *object, const char *header);

GMimeHeaderList *g_mime_object_get_header_list (GMimeObject *object);

char *g_mime_object_get_headers (GMimeObject *object, GMimeFormatOptions *options);

ssize_t g_mime_object_write_to_stream (GMimeObject *object, GMimeFormatOptions *options, GMimeStream *stream);
ssize_t g_mime_object_write_content_to_stream (GMimeObject *object, GMimeFormatOptions *options, GMimeStream *stream);
char *g_mime_object_to_string (GMimeObject *object, GMimeFormatOptions *options);

void g_mime_object_encode (GMimeObject *object, GMimeEncodingConstraint constraint);

/* Helper functions, these are in parts atm */
int gmime_is_message_part(GMimeObject *obj);
int gmime_is_message_partial(GMimeObject *obj);
int gmime_is_multipart(GMimeObject *obj);
int gmime_is_part(GMimeObject *obj);
int gmime_is_multipart_signed(GMimeObject *obj);
int gmime_is_multipart_encrypted(GMimeObject *obj);
int internet_address_is_mailbox(InternetAddress *ia);
int internet_address_is_group(InternetAddress *ia);

GDateTime *         g_date_time_new_from_unix_local     (gint64 t);
GDateTime *         g_date_time_new_from_unix_utc       (gint64 t);
gint64              g_date_time_to_unix                 (GDateTime *datetime);
GPtrArray*          g_ptr_array_sized_new               (guint reserved_size);
void                g_ptr_array_add                     (GPtrArray *array, gpointer data);
gpointer*           g_ptr_array_free                    (GPtrArray *array, gboolean free_seg);
GByteArray*         g_byte_array_new                    (void);
guint8*             g_byte_array_free                   (GByteArray *array, gboolean free_segment);
void                g_date_time_unref                   (GDateTime *datetime);
void                g_ptr_array_unref                   (GPtrArray *array);
void g_object_unref (gpointer object);
gpointer            g_object_ref                        (gpointer object);


// GMimeObject *message_part(GMimeMessage *message);
// guint multipart_len(GMimeMultipart *mp);
// GMimeObject *multipart_child(GMimeMultipart *mp, int i);
]])

return galore
