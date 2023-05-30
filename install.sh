#!/bin/bash
# If we want to install it globally, you don't want to run this file

NAME=$(dirname "$0")
BASEDIR=$(realpath "${NAME}")

if [ -d "${BASEDIR}/build" ]; then
	rm -r "${BASEDIR}"/build
fi
meson setup --prefix="${BASEDIR}/lib" "${BASEDIR}"/build
meson install -C "${BASEDIR}"/build
