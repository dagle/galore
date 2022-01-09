INC =`pkg-config --cflags gmime-3.0`
LD = `pkg-config --libs gmime-3.0`

CFLAGS = -Wall -Werror -fpic -std=gnu99
# CFLAGS = -Wall -Werror -fpic -std=gnu99 -Og -ggdb3
COVERAGE ?=

MKD = mkdir -p
RM = rm -rf
TARGET := libgalore.so
SRC = src/galore.c src/filter-reply.c
OBJ = build/galore.o build/filter-reply.o

all: mkbuild build/$(TARGET)

build/$(TARGET): $(OBJ)
	${CC} -shared $(LD) $^ -o build/$(TARGET)

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
