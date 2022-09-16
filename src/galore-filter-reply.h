/*
 * Copyright © 2009 Keith Packard <keithp@keithp.com>
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

#ifndef _GALORE_FILTER_REPLY_H_
#define _GALORE_FILTER_REPLY_H_

#include <gmime/gmime-filter.h>

void galore_filter_reply_module_init (void);

G_BEGIN_DECLS

#define GALORE_TYPE_FILTER_REPLY            (galore_filter_reply_get_type ())
#define GALORE_FILTER_REPLY(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
									GALORE_TYPE_FILTER_REPLY, \
									GaloreFilterReply))
#define GALORE_FILTER_REPLY_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass), GALORE_TYPE_FILTER_REPLY, \
								     GaloreFilterReplyClass))
#define GALORE_IS_FILTER_REPLY(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
									GALORE_TYPE_FILTER_REPLY))
#define GALORE_IS_FILTER_REPLY_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), \
								     GALORE_TYPE_FILTER_REPLY))
#define GALORE_FILTER_REPLY_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj), GALORE_TYPE_FILTER_REPLY, \
								       GaloreFilterReplyClass))

typedef struct _GaloreFilterReply GaloreFilterReply;
typedef struct _GaloreFilterReplyClass GaloreFilterReplyClass;

/**
 * GaloreFilterReply:
 * @parent_object: parent #GMimeFilter
 * @encode: encoding vs decoding reply markers
 * @saw_nl: previous char was a \n
 * @saw_angle: previous char was a >
 *
 * A filter to insert/remove reply markers (lines beginning with >)
 **/
struct _GaloreFilterReply {
    GMimeFilter parent_object;

    gboolean encode;
    gboolean saw_nl;
    gboolean saw_angle;
};

struct _GaloreFilterReplyClass {
    GMimeFilterClass parent_class;

};


GType galore_filter_reply_get_type (void);

GMimeFilter *galore_filter_reply_new (gboolean encode);

G_END_DECLS


#endif /* _GALORE_FILTER_REPLY_H_ */
