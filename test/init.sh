#!/bin/bash

## setup test data
TEST_ROOT=$(dirname "$0")
TEST_ROOT=$(realpath ${TEST_ROOT})
TMP_DIRECTORY="${TEST_ROOT}/testdir"


if [[ ! -d "$TMP_DIRECTORY" ]]; then
mkdir ${TMP_DIRECTORY}
MAIL_DIR="${TMP_DIRECTORY}/testdata"

if [[ ! -d "$MAIL_DIR" ]]; then
	git clone https://github.com/dagle/galore-test $MAIL_DIR
fi

# setup notmuch
NOTMUCHDIR="${TMP_DIRECTORY}/notmuch/"
mkdir ${NOTMUCHDIR}
export NOTMUCH_CONFIG="${NOTMUCHDIR}/notmuch-config"

cat <<EOF >"${NOTMUCH_CONFIG}"
[database]
path=${MAIL_DIR}/testmail
hook_dir=${NOTMUCHDIR}

[user]
name=Testi McTest
primary_email=testi@testmail.org
other_email=test_suite_other@testmailtwo.org;test_suite@otherdomain.org
EOF

# init
export GNUPGHOME="${TMP_DIRECTORY}/gnupg"
add_gnupg_home () {
    _gnupg_exit () { gpgconf --kill all 2>/dev/null || true; }
    at_exit_function _gnupg_exit
    mkdir -p -m 0700 "$GNUPGHOME"
    gpg --no-tty --import <$MAIL_DIR/testkey.asc >"$GNUPGHOME"/import.log 2>&1

    if (gpg --quick-random --version >/dev/null 2>&1) ; then
	echo quick-random >> "$GNUPGHOME"/gpg.conf
    elif (gpg --debug-quick-random --version >/dev/null 2>&1) ; then
	echo debug-quick-random >> "$GNUPGHOME"/gpg.conf
    fi
    echo no-emit-version >> "$GNUPGHOME"/gpg.conf

    FINGERPRINT="F998009F4AD9084F82096B36140FC9CB9DB2A71B"
    SELF_EMAIL="testi@testmail.org"
    printf '%s:6:\n' "$FINGERPRINT" | gpg --quiet --batch --no-tty --import-ownertrust
	gpgconf --kill all 2>/dev/null || true; 
}

add_gnupg_home

notmuch new

fi
