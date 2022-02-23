#!/bin/sh

if [ "$#" -ne 1 ]; then
	echo "Wrong number of arguments"
	exit 1
fi

TEST_ROOT=$(dirname "$0")
TMP_DIRECTORY="${TEST_ROOT}/$1"

if [[ -d "${TMP_DIRECTORY}" ]]; then
	rm -r ${TMP_DIRECTORY}
fi

mkdir ${TMP_DIRECTORY}
TEST_MAIL="${TEST_ROOT}/corpora"
cp -r ${TEST_MAIL} "${TMP_DIRECTORY}/mail"
MAIL_DIR=$(realpath "${TMP_DIRECTORY}/mail")
export NOTMUCH_CONFIG="${TMP_DIRECTORY}/notmuch-config"

cat <<EOF >"${NOTMUCH_CONFIG}"
[database]
path=${MAIL_DIR}

[user]
name=Notmuch Test Suite
primary_email=test_suite@notmuchmail.org
other_email=test_suite_other@notmuchmail.org;test_suite@otherdomain.org
EOF
notmuch new
