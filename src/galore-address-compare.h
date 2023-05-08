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

#ifndef _GALORE_ADDRESS_CONVERTION_H
#define _GALORE_ADDRESS_CONVERTION_H

#include <gmime/internet-address.h>

G_BEGIN_DECLS

typedef enum {
	// GOLARE_COMPARE_PLUS_ADDRESSING_LOCAL,
	GALORE_COMPARE_INSENSITIVE_LOCAL,
} GaloreCompareLocal;

typedef enum {
	// GALORE_COMPARE_SUB_DOMAIN,
	GALORE_COMPARE_INSENSITIVE_DOMAIN,
	GALORE_COMPARE_DOMAIN_IDN,
} GaloreCompareDomain;

InternetAddress *galore_address_sub_to_plus(InternetAddressMailbox *mb);
InternetAddress *galore_address_plus_to_sub(InternetAddressMailbox *mb);

gboolean galore_address_compare_domain(InternetAddressMailbox *mb1, 
		InternetAddressMailbox *mb2, GaloreCompareDomain mode);

gboolean galore_address_compare_local(InternetAddressMailbox *mb1, 
	InternetAddressMailbox *mb2, const char *seperators, GaloreCompareLocal mode);

G_END_DECLS


#endif /* _GALORE_FILTER_REPLY_H_ */
