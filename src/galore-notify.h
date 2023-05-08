#include <gmime/gmime-message.h>

GMimeMessage *g_mime_message_make_notification(GMimeMessage *message);
gboolean g_mime_message_is_notification(GMimeMessage *message);

const char *g_mime_message_notification_id(GMimeMessage *message);
gboolean g_mime_message_notification_compare(GMimeMessage *message, GMimeMessage *notification);
