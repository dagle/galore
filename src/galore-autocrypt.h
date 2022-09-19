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


#ifndef __GALORE_AU_CONTEXT_H__
#define __GALORE_AU_CONTEXT_H__

#include <gmime/gmime-crypto-context.h>

G_BEGIN_DECLS

#define GALORE_TYPE_AU_CONTEXT            (galore_au_context_get_type ())
#define GALORE_AU_CONTEXT(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), GALORE_TYPE_AU_CONTEXT, GMimeGpgContext))
#define GALORE_AU_CONTEXT_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass), GALORE_TYPE_AU_CONTEXT, GMimeGpgContextClass))
#define GALORE_IS_AU_CONTEXT(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GALORE_TYPE_AU_CONTEXT))
#define GALORE_IS_AU_CONTEXT_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), GALORE_TYPE_AU_CONTEXT))
#define GALORE_AU_CONTEXT_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj), GALORE_TYPE_AU_CONTEXT, GMimeGpgContextClass))

typedef struct _GaloreAutoCryptContext GaloreAutoCryptContext;
typedef struct _GaloreAutoCryptContextClass GaloreAutoCryptContextClass;

GType galore_au_context_get_type (void);

GMimeCryptoContext *galore_au_context_new (void);

G_END_DECLS

#endif /* __GALORE_AU_CONTEXT_H__ */
