#include "galore-address-convert.h"
#include <string.h>

static gint galore_utf8_strncmp(const char *str1, gssize len1, const char *str2, gssize len2) {
	gchar *fold1;
	gchar *fold2;
	gint ret;

	fold1 = g_utf8_casefold(str1, len1);
	fold2 = g_utf8_casefold(str2, len2);

	ret = g_utf8_collate(fold1, fold2);
	g_free(fold1);
	g_free(fold2);

	return ret;
}

static gint galore_utf8_strcmp(char *str1, char *str2) {
	gssize len1 = strlen(str1);
	gssize len2 = strlen(str2);

	return galore_utf8_strncmp(str1, len1, str2, len2);
}

static gint galore_strn_cmp(const char *str1, gssize len1, const char *str2, gssize len2) {
	int i = 0;
	for (; i < len1 && i < len2; i++) {
		if (str1[i] != str2[i]) {
			return str1[i] - str2[i];
		}
	}

	if (len1 == len2) {
		return 0;
	}

	i++;
	if (i > (len1 - 1)) {
		return -str2[i];
	} 

	return str1[i];
}

static char *strnchr(const char *s, gssize len, int c) {
	for (int i = 0; i < len; i++) {
		if (*s == c) {
			return (char *)s;
		}
		s++;
	}
	return NULL;
}

static char *strnchrs(const char *s, gssize len, const char *cs) {
	for (int i = 0; i < len; i++) {
		for (const char *c = cs; c; c++) {
			if (*s == *c) {
				return (char *)s;
			}
		}
		s++;
	}
	return NULL;
}

static gboolean is_sub_address(InternetAddressMailbox *mb) {
	int i = 0;
	for (char *str = mb->addr + mb->at + 1; *str; str++) {
		if (*str == '.') {
			i++;
		}
	}
	return i > 1;
}

/**
 * galore_address_sub_to_plus:
 * @mb: email we want to base the new address on
 * 
 * Converts a mailbox of the format local@sub.domain to local+sub@domain
 * This function should only be called for addresss you know that sub
 * is part of the local address. Typically addresses you own and is of
 * this format. The reason for doing this is that it makes comparisons easier.
 *
 * Returns: (transfer full): a new InternetAddress
 */
InternetAddress *galore_address_sub_to_plus(InternetAddressMailbox *mb) {
	g_return_val_if_fail(INTERNET_ADDRESS_IS_MAILBOX(mb), NULL);

	GString *str = NULL;
	const char *domain, *sub, *prefix;
	int sublen;

	if (!is_sub_address(mb)) {
		return NULL;
	}

	sub = mb->addr + mb->at + 1;
	domain = strchr(sub, '.');

	if (!domain) {
		return NULL;
	}

	sublen = domain - sub;

	prefix = mb->addr;

	str = g_string_new_len(NULL, strlen(mb->addr));

	g_string_printf(str, "%.*s+%.*s@%s", sublen, prefix, mb->at-1, sub, domain);

	InternetAddress *plus = internet_address_mailbox_new(
			INTERNET_ADDRESS(mb)->name, str->str);

	g_string_free(str, TRUE);

	return plus;
}

/**
 * galore_address_plus_to_sub:
 * @mb: email we want to base the new address on
 * 
 * Converts a mailbox of the format local+sub@domain to local@sub.domain
 * This function should only be called for addresss you know that sub
 * from the local is part of the domain. Typically addresses you own and is of
 * this format. The reason for doing this is that it makes comparisons easier.
 *
 * Returns: (transfer full): a new InternetAddress
 */
InternetAddress *galore_address_plus_to_sub(InternetAddressMailbox *mb) {
	g_return_val_if_fail(INTERNET_ADDRESS_IS_MAILBOX(mb), NULL);

	GString *str = NULL;
	const char *domain, *sub, *prefix;
	int sublen;
	int prefixlen;

	char *s1 = strnchrs(mb->addr, mb->at, "+");

	if (!s1) {
		return NULL;
	}

	prefixlen = s1 - mb->addr;
	sublen = mb->at - prefixlen;
	prefix = mb->addr;

	g_string_printf(str, "%.*s@%.*s.%s", prefixlen, prefix, sublen, sub, domain);

	InternetAddress *plus = internet_address_mailbox_new(
			INTERNET_ADDRESS(mb)->name, str->str);

	g_string_free(str, TRUE);

	return plus;
}

static gint galore_address_plus_len(const char *address, int len, const char *cs) {
	g_return_val_if_fail(address, 0);
	g_return_val_if_fail(cs, len);
	
	char *s1 = strnchrs(address, len, cs);
	if (s1) {
		return address-s1;
	}

	return len;
}

/**
 * galore_address_compare_local:
 * @mb1: First address to compare
 * @mb2: Second address to compare
 * @seperators: (nullable): Characters that seperates an email address
 * @mode: how we want to compare the local part of the email address
 *
 * Compares the local parts of 2 email addresses. The seperators is used to be 
 * able to compare addresses with plus addressing, local+sub@domain being equal
 * to local@domain
 * 
 * Returns: %TRUE if we concider the addresses to be equal
 */
gboolean galore_address_compare_local(InternetAddressMailbox *mb1, 
	InternetAddressMailbox *mb2, const char *seperators, GaloreCompareLocal mode) {
	gssize len1;
	gssize len2;

	g_return_val_if_fail(mb1, FALSE);
	g_return_val_if_fail(mb1, FALSE);

	len1 = galore_address_plus_len(mb1->addr, mb1->at, seperators);
	len2 = galore_address_plus_len(mb2->addr, mb2->at, seperators);

	if (mode & GALORE_COMPARE_INSENSITIVE_LOCAL) {
		return galore_utf8_strncmp(mb1->addr, len1, mb2->addr, len2);
	} else {
		return galore_strn_cmp(mb1->addr, len1, mb2->addr, len2);
	}
}

/**
 * galore_address_compare_domain:
 * @mb1: First address to compare
 * @mb2: Second address to compare
 * @mode: how we want to compare the domain of the email address
 *
 * Compares the domain of 2 email addresses.
 * 
 * Returns: %TRUE if we concider the addresses to be equal
 */
gboolean galore_address_compare_domain(InternetAddressMailbox *mb1, 
		InternetAddressMailbox *mb2, GaloreCompareDomain mode) {

	g_return_val_if_fail(mb1, FALSE);
	g_return_val_if_fail(mb1, FALSE);

	const char *d1;
	const char *d2;

	if (mode & GALORE_COMPARE_DOMAIN_IDN) {
		d1 = internet_address_mailbox_get_idn_addr(mb1) + mb1->at + 1;
		d2 = internet_address_mailbox_get_idn_addr(mb2) + mb2->at + 1;
	} else {
		d1 = mb1->addr + mb1->at + 1;
		d2 = mb2->addr + mb2->at + 1;
	}

	gssize len1 = strlen(d1);
	gssize len2 = strlen(d2);

	if (mode & GALORE_COMPARE_INSENSITIVE_DOMAIN) {
		return galore_utf8_strncmp(d1, len1, d2, len2);
	} else {
		return galore_strn_cmp(d1, len1, d2, len2);
	}
}
