#include "galore-notify.h"
#include "gmime/gmime-message.h"
#include "gmime/gmime-object.h"
#include <gmime/internet-address.h>
#include <gmime/gmime-multipart.h>
#include <gmime/gmime-utils.h>
#include <gmime/gmime-part.h>
#include <gmime/gmime-message-part.h>

GMimeMessage *g_mime_message_make_notification_response(GMimeMessage *message,
	InternetAddressMailbox *from, InternetAddressMailbox *to, const char *ua) {
	GMimeMessage *notification;
	GMimeMultipart *mp;
	char *prologe;
	GMimePart *part;
	GMimeMessagePart *msg_part;

	g_return_val_if_fail(GMIME_IS_MESSAGE(message), NULL);
	g_return_val_if_fail(INTERNET_ADDRESS_IS_MAILBOX(to), NULL);

	notification = g_mime_message_new(TRUE);

	g_mime_message_add_mailbox(notification, GMIME_ADDRESS_TYPE_FROM,
			INTERNET_ADDRESS(from)->name, to->addr);
	g_mime_message_add_mailbox(notification, GMIME_ADDRESS_TYPE_TO,
			INTERNET_ADDRESS(to)->name, to->addr);

	char *from_str = internet_address_to_string(INTERNET_ADDRESS(from), NULL, 0);
	// TODO: free date?
	GDateTime *date = g_mime_message_get_date(message);
	char *date_str = g_mime_utils_header_format_date(date);

	// TODO: generate mid
	// prologe = g_string_new("");

	prologe = g_strdup_printf(
			"The message sent on %s to %s with subject"
			"\"%s\" has been displayed."
			"This is no guarantee that the message has been read or understood.",
			date_str, from_str, g_mime_message_get_subject(message));
	
	g_free(from_str);
	g_free(date_str);

	mp = g_mime_multipart_new_with_subtype("report");

	g_mime_object_set_content_type_parameter(GMIME_OBJECT(mp),
			"report-type", "disposition-notification");

	g_mime_multipart_set_prologue(mp, prologe);
	g_free(prologe);

	part = g_mime_part_new_with_type ("message", "disposition-notification");
	g_mime_object_set_header(GMIME_OBJECT(part), "Reporting-UA",
			ua, NULL);

	char *recipient;
	recipient = g_strdup_printf ("rfc822;%s", from->addr);
	g_mime_object_set_header(GMIME_OBJECT(part), "Original-Recipient",
			recipient, NULL);
	g_mime_object_set_header(GMIME_OBJECT(part), "Final-Recipient",
			recipient, NULL);
	g_free(recipient);

	char *msgid;
	msgid = g_strdup_printf ("<%s>", g_mime_message_get_message_id(message));
	g_mime_object_set_header(GMIME_OBJECT(part), "Original-Message-ID",
			msgid, NULL);
	g_free(msgid);

	g_mime_object_set_header(GMIME_OBJECT(part), "Disposition",
			"manual-action/MDN-sent-manually; displayed", NULL);

	// Reporting-UA: joes-pc.cs.example.com; Foomail 97.1
	// Original-Recipient: rfc822;Joe_Recipient@example.com
	// Final-Recipient: rfc822;Joe_Recipient@example.com
	// Original-Message-ID: <199509192301.23456@example.org>
	// Disposition: manual-action/MDN-sent-manually; displayed
	g_mime_multipart_add(mp, GMIME_OBJECT(part));
	g_object_unref(part);

	msg_part = g_mime_message_part_new_with_message("rfc822", message);
	g_mime_multipart_add(mp, GMIME_OBJECT(msg_part));



	return notification;
}

void g_mime_message_request_notification(GMimeMessage *message,
		InternetAddressMailbox *mbox) {

	g_return_if_fail(GMIME_IS_MESSAGE(message));

	char *str = internet_address_to_string(INTERNET_ADDRESS(mbox), NULL, FALSE);

	g_mime_object_set_header(GMIME_OBJECT(message), 
			"Disposition-Notification-To", str, NULL);

	g_mime_object_set_header(GMIME_OBJECT(message), 
			"Return-Path", str, NULL);

	g_free(str);
}

gboolean g_mime_message_has_request_notification(GMimeMessage *message) {
	const char *dnt; 
	const char *rp; 

	g_return_val_if_fail(GMIME_IS_MESSAGE(message), FALSE);

	dnt = g_mime_object_get_header(GMIME_OBJECT(message), "Disposition-Notification-To");
	rp = g_mime_object_get_header(GMIME_OBJECT(message), "Return-Path");

	if (dnt == NULL || rp == NULL) {
		return FALSE;
	}

	// TODO: compare case-sensitive (local) and case-insensitive (domain)
	// check for number of addresses == 1
	if (strcmp(dnt, rp)) {
		return FALSE;
	}

	return TRUE;
}

GMimeObject *g_mime_message_notification_object(GMimeMessage *message) {
	g_return_val_if_fail(GMIME_IS_MESSAGE(message), FALSE);

	GMimeObject *root, *part;
	GMimeMultipart *report;
	GMimeContentType *ct;
	const char *report_type;

	root = g_mime_message_get_mime_part(message);
	g_return_val_if_fail(GMIME_IS_MULTIPART(root), NULL);

	report = GMIME_MULTIPART(root);

	ct = g_mime_object_get_content_type (root);
	g_return_val_if_fail(ct, NULL);

	if (strcmp(ct->type, "multipart") || strcmp(ct->subtype, "report")) {
		return FALSE;
	}

	report_type = g_mime_object_get_content_type_parameter(root, "report-type");
	g_return_val_if_fail(report_type, NULL);

	if (strcmp(report_type, "disposition-notification")) {
		return FALSE;
	}

	part = g_mime_multipart_get_part(report, 1);
	g_return_val_if_fail(part, NULL);

	ct = g_mime_object_get_content_type (part);
	g_return_val_if_fail(ct, NULL);

	if (strcmp(ct->type, "message") || strcmp(ct->subtype, "disposition-notification")) {
		return NULL;
	}
	return part;
}

gboolean g_mime_message_notification_compare(GMimeMessage *message, GMimeMessage *notification) {
	return FALSE;
}
