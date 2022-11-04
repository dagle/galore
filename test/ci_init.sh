#!/bin/sh

# TEST_ROOT=$(dirname "$0")
# git clone https://github.com/dagle/galore-test testdata

MAIL_DIR="./testdata/testmail"
mkdir -p ${HOME}/.config/notmuch/default

cat <<EOF >${HOME}/.config/notmuch/default/config
[database]
path=${MAIL_DIR}

[user]
name=Testi McTest
primary_email=testi@testmail.org
other_email=test_suite_other@testmailtwo.org;test_suite@otherdomain.org
EOF

# init
notmuch new

# run tests

# fi
