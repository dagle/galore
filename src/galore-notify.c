#include "galore-notify.h"
#include <gmime/internet-address.h>

GMimeMessage *g_mime_message_make_notification_response(GMimeMessage *message,
	InternetAddressMailbox *mbox) {
	InternetAddressList *addrlist;

	GMimeMessage *notification;

	g_return_val_if_fail(GMIME_IS_MESSAGE(message), NULL);
	g_return_val_if_fail(INTERNET_ADDRESS_IS_MAILBOX(mbox), NULL);
	
	// char *str = internet_address_to_string(INTERNET_ADDRESS(mbox), NULL, FALSE);

	notification = g_mime_message_new(FALSE);


	// g_free(str);

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

	g_mime_object_set_header(GMIME_OBJECT(message), 
			"Original-Recipient", str, NULL);

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

gboolean g_mime_message_is_notification(GMimeMessage *message) {
	g_return_val_if_fail(GMIME_IS_MESSAGE(message), FALSE);
	GMimeObject *root;
	GMimeMultipart *report;
	GMimeContentType *type;

	root = g_mime_message_get_mime_part(message);
	if (!root) {
		return FALSE;
	}

	g_return_if_fail(GMIME_IS_MULTIPART(root), FALSE);
	
	type = g_mime_object_get_content_type (root);
	
	g_return_val_if_fail(type, FALSE);

	if (strcmp(type->type, "multipart") || strcmp(type->subtype, "report")) {
		return FALSE;
	}

	// report-type = disposition-notification

	// try to find one child with the original and a 
	// Content-Type: message/disposition-notification stuff

}

const char *g_mime_message_notification_id(GMimeMessage *message) {

	// the same as the function above but get the Original-Message-ID
	return NULL;
}

gboolean g_mime_message_notification_compare(GMimeMessage *message, GMimeMessage *notification) {
	return FALSE;
}
