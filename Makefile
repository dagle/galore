INC =`pkg-config --cflags gmime-3.0`
LD =-lgmime-3.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lgpgme

CFLAGS = -Wall -Werror -fpic -std=gnu99
COVERAGE ?=

MKD = mkdir -p
RM = rm -rf
TARGET := libgalore.so
SRC = src/galore.c src/filter-reply.c src/autocrypt.c
OBJ = build/galore.o build/filter-reply.o #build/autocrypt.o

all: mkbuild build/$(TARGET) install

build/$(TARGET): $(OBJ)
	${CC} -shared $(LD) $^ -o build/$(TARGET)

install:
	# do xdg etc
	install -d ${HOME}/.local/share/icons/scalable/apps/ ${HOME}/.local/share/applications/
	install galore.desktop ${HOME}/.local/share/applications/
	install res/galore.svg ${HOME}/.local/share/icons/scalable/apps/
	update-desktop-database ~/.local/share/applications

build/%.o: src/%.c
	${CC} -c ${CFLAGS} $(INC) $< -o $@

mkbuild:
	$(MKD) build

lint:
	luacheck lua

format:
	clang-format --style=file --dry-run -Werror src/.c src/.h

debug:
	$(MKD) build
	$(CC) -Og -ggdb3 $(CFLAGS) $(COVERAGE) -shared src/libgalore.c -o build/$(TARGET)

test:
	@LD_LIBRARY_PATH=${PWD}/build:${LD_LIBRARY_PATH} luajit test/test.lua

clangdhappy:
	compiledb make

clean:
	$(RM) build

.PHONY: lint format clangdhappy clean test debug 
