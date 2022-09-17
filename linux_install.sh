#!/bin/sh
install -d ${XDG_DATA_HOME}/icons/scalable/apps/ ${XDG_DATA_HOME}/applications/
install galore.desktop ${XDG_DATA_HOME}/applications/
install res/galore.svg ${XDG_DATA_HOME}/icons/scalable/apps/
update-desktop-database ${XDG_DATA_HOME}/applications
