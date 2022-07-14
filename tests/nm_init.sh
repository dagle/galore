#!/bin/sh

if [ "$#" -ne 1 ]; then
	echo "Wrong number of arguments"
	exit 1
fi

## setup test data
TEST_ROOT=$(dirname "$0")
TMP_DIRECTORY="${TEST_ROOT}/$1"
TEST_DATA="${TEST_ROOT}/testdata"
TEST_MAIL="${TEST_DATA}/testmail"

if [[ ! -d "$TEST_DATA" ]]; then
	git clone https://github.com/dagle/galore-testdata testdata
fi

if [[ -d "${TMP_DIRECTORY}" ]]; then
	rm -r ${TMP_DIRECTORY}
fi

mkdir ${TMP_DIRECTORY}
cp -r ${TEST_MAIL} "${TMP_DIRECTORY}/mail"
MAIL_DIR=$(realpath "${TMP_DIRECTORY}/mail")

# setup notmuch
NOTMUCHDIR="${TMP_DIRECTORY}/notmuch/"
mkdir ${NOTMUCHDIR}
export NOTMUCH_CONFIG="${NOTMUCHDIR}/notmuch-config"

cat <<EOF >"${NOTMUCH_CONFIG}"
[database]
path=${MAIL_DIR}
hook_dir=${NOTMUCHDIR}

[user]
name=Testi McTest
primary_email=testi@daglemail.org
other_email=test_suite_other@daglemail.org;test_suite@otherdomain.org
EOF

# setup gpg
export GNUPGHOME="${TMP_DIRECTORY}/gnupg"
add_gnupg_home () {
    [ -e "${GNUPGHOME}/gpg.conf" ] && return
    # _gnupg_exit () { gpgconf --kill all 2>/dev/null || true; }
    # at_exit_function _gnupg_exit
    mkdir -p -m 0700 "$GNUPGHOME"
    gpg --no-tty --import <$TEST_DATA/testkey.asc >"$GNUPGHOME"/import.log 2>&1
    # test_debug "cat $GNUPGHOME/import.log"

    if (gpg --quick-random --version >/dev/null 2>&1) ; then
	echo quick-random >> "$GNUPGHOME"/gpg.conf
    elif (gpg --debug-quick-random --version >/dev/null 2>&1) ; then
	echo debug-quick-random >> "$GNUPGHOME"/gpg.conf
    fi
    echo no-emit-version >> "$GNUPGHOME"/gpg.conf

    # Change this if we ship a new test key
    FINGERPRINT="945C289BEC95362D88C9BD5DC7BEF55C3396773C"
    # SELF_USERID="Notmuch Test Suite <test_suite@notmuchmail.org> (INSECURE!)"
    SELF_EMAIL="testi@daglemail.org"
    printf '%s:6:\n' "$FINGERPRINT" | gpg --quiet --batch --no-tty --import-ownertrust
	gpgconf --kill all 2>/dev/null || true; 
}

add_gnupg_home
cp -r tests/ "${TMP_DIRECTORY}"

# init
notmuch new
export GALOREPATH="${TMP_DIRECTORY}/galore"

# nvim --headless -c "PlenaryBustedDirectory ${TMP_DIRECTORY}/tests {sequential = true}"
