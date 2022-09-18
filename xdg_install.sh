#!/bin/sh
BASEDIR=$(dirname $0)
install -d ${XDG_DATA_HOME}/icons/scalable/apps/ ${XDG_DATA_HOME}/applications/
install ${BASEDIR}/galore.desktop ${XDG_DATA_HOME}/applications/
install ${BASEDIR}/res/galore.svg ${XDG_DATA_HOME}/icons/scalable/apps/
update-desktop-database ${XDG_DATA_HOME}/applications
