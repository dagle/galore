/*
 * Copyright © 2023 Per Odlund <per.odlund@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
 */

#ifndef _GALORE_ADDRESS_NOTIFY_H_
#define _GALORE_ADDRESS_NOTIFY_H_

#include <gmime/gmime-message.h>

typedef enum {
	GALORE_NOTIFICATION_REQUIRED,
	GALORE_NOTIFICATION_OPTIONAL
} GaloreNotificationParameter;

GMimeMessage *g_mime_message_make_notification(GMimeMessage *message);
gboolean g_mime_message_is_notification(GMimeMessage *message);

const char *g_mime_message_notification_id(GMimeMessage *message);
gboolean g_mime_message_notification_compare(GMimeMessage *message, GMimeMessage *notification);

#endif /* _GALORE_ADDRESS_NOTIFY_H_ */
