THIS_DIR := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))

install:
	# do xdg etc
	install -d ${HOME}/.local/share/icons/scalable/apps/ ${HOME}/.local/share/applications/
	install galore.desktop ${HOME}/.local/share/applications/
	install res/galore.svg ${HOME}/.local/share/icons/scalable/apps/
	update-desktop-database ~/.local/share/applications
#	xdg-mime default galore.desktop x-scheme-handler/mailto

lint:
	luacheck lua
	# add linting to src/ for C

stylua:
	stylua lua/

format:
	clang-format --style=file --dry-run -Werror src/.c src/.h

# TODO finnish this
# gdi: 
# 	gir-to-vimdoc

test/testdir:
	test/init.sh

# this will kinda ruin your install if you run ready-pod
# Fix this later
test: test/testdir
	./install_local.sh
	LUA_PATH="/usr/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?.lua" nvim --headless --clean \
	-u test/minimal.vim \
	-c "PlenaryBustedDirectory test/test {minimal_init = 'test/minimal.vim'}"

pod-build:
	podman build . -t galore
	# podman build --no-cache . -t galore

ready-pod:
	podman run -v $(shell pwd):/code/galore -t galore

clean:
	$(RM) -r build
	$(RM) -r test/testdir

.PHONY: lint format stylua clean test debug 
