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

#include <stdbool.h>

#include "galore-filter-reply.h"
// #include "notmuch-client.h"

/**
 * SECTION: gmime-filter-reply
 * @title: GaloreFilterReply
 * @short_description: Add/remove reply markers
 *
 * A #GMimeFilter for adding or removing reply markers
 **/
#define unused(x) x ## _unused __attribute__ ((unused))

static void galore_filter_reply_class_init (GaloreFilterReplyClass *klass, void *class_data);
static void galore_filter_reply_init (GaloreFilterReply *filter, GaloreFilterReplyClass *klass);
static void galore_filter_reply_finalize (GObject *object);

static GMimeFilter *filter_copy (GMimeFilter *filter);
static void filter_filter (GMimeFilter *filter, char *in, size_t len, size_t prespace,
			   char **out, size_t *outlen, size_t *outprespace);
static void filter_complete (GMimeFilter *filter, char *in, size_t len, size_t prespace,
			     char **out, size_t *outlen, size_t *outprespace);
static void filter_reset (GMimeFilter *filter);


static GMimeFilterClass *parent_class = NULL;

GType
galore_filter_reply_get_type (void)
{
	static GType type = 0;
	if (!type) {
		static const GTypeInfo info = {
			.class_size = sizeof (GaloreFilterReplyClass),
			.base_init = NULL,
			.base_finalize = NULL,
			.class_init = (GClassInitFunc) galore_filter_reply_class_init,
			.class_finalize = NULL,
			.class_data = NULL,
			.instance_size = sizeof (GaloreFilterReply),
			.n_preallocs = 0,
			.instance_init = (GInstanceInitFunc) galore_filter_reply_init,
			.value_table = NULL,
		};
		type = g_type_register_static (GMIME_TYPE_FILTER, "GaloreFilterReply", &info, 0);
	}
    return type;
}

static void
galore_filter_reply_class_init (GaloreFilterReplyClass *klass, unused (void *class_data))
{
    GObjectClass *object_class = G_OBJECT_CLASS (klass);
    GMimeFilterClass *filter_class = GMIME_FILTER_CLASS (klass);

	parent_class = g_type_class_ref (GMIME_TYPE_FILTER);
    object_class->finalize = galore_filter_reply_finalize;

    filter_class->copy = filter_copy;
    filter_class->filter = filter_filter;
    filter_class->complete = filter_complete;
    filter_class->reset = filter_reset;
}

static void
galore_filter_reply_init (GaloreFilterReply *filter, GaloreFilterReplyClass *klass)
{
    (void) klass;
    filter->saw_nl = true;
    filter->saw_angle = false;
}

static void
galore_filter_reply_finalize (GObject *object)
{
    G_OBJECT_CLASS (parent_class)->finalize (object);
}


static GMimeFilter *
filter_copy (GMimeFilter *filter)
{
    GaloreFilterReply *reply = (GaloreFilterReply *) filter;

    return galore_filter_reply_new (reply->encode);
}

static void
filter_filter (GMimeFilter *filter, char *inbuf, size_t inlen, size_t prespace,
	       char **outbuf, size_t *outlen, size_t *outprespace)
{
    GaloreFilterReply *reply = (GaloreFilterReply *) filter;
    const char *inptr = inbuf;
    const char *inend = inbuf + inlen;
    char *outptr;

    (void) prespace;
    if (reply->encode) {
		g_mime_filter_set_size (filter, 3 * inlen, false);

		outptr = filter->outbuf;
		while (inptr < inend) {
			if (reply->saw_nl) {
				*outptr++ = '>';
				// only add the space if there isn't a qoute 
				if (*inptr != '>') {
					*outptr++ = ' ';
				}
				reply->saw_nl = false;
			}
			if (*inptr == '\n')
				reply->saw_nl = true;
			else
				reply->saw_nl = false;
			if (*inptr != '\r')
				*outptr++ = *inptr;
			inptr++;
		}
    } else {
		g_mime_filter_set_size (filter, inlen + 1, false);

		outptr = filter->outbuf;
		while (inptr < inend) {
			if (reply->saw_nl) {
				if (*inptr == '>')
					reply->saw_angle = true;
				else
					*outptr++ = *inptr;
				reply->saw_nl = false;
			} else if (reply->saw_angle) {
				if (*inptr == ' ')
					;
				else
					*outptr++ = *inptr;
				reply->saw_angle = false;
			} else if (*inptr != '\r') {
				if (*inptr == '\n')
					reply->saw_nl = true;
				*outptr++ = *inptr;
			}

			inptr++;
		}
    }

    *outlen = outptr - filter->outbuf;
    *outprespace = filter->outpre;
    *outbuf = filter->outbuf;
}

static void
filter_complete (GMimeFilter *filter, char *inbuf, size_t inlen, size_t prespace,
		 char **outbuf, size_t *outlen, size_t *outprespace)
{
    if (inbuf && inlen)
	filter_filter (filter, inbuf, inlen, prespace, outbuf, outlen, outprespace);
}

static void
filter_reset (GMimeFilter *filter)
{
    GaloreFilterReply *reply = (GaloreFilterReply *) filter;

    reply->saw_nl = true;
    reply->saw_angle = false;
}


/**
 * galore_filter_reply_new:
 * @encode: %true if the filter should encode or %false otherwise
 *
 * If @encode is %true, then all lines will be prefixed by "> ",
 * otherwise any lines starting with "> " will have that removed
 *
 * Returns: a new reply filter with @encode.
 **/
GMimeFilter *
galore_filter_reply_new (gboolean encode)
{
    GaloreFilterReply *new_reply;

    new_reply = (GaloreFilterReply *) g_object_new (GALORE_TYPE_FILTER_REPLY, NULL);
    new_reply->encode = encode;

    return (GMimeFilter *) new_reply;
}
