out := _out
libs := gtk4 epoxy

CFLAGS := -g -Wall -Werror -std=c17 $(shell pkg-config $(libs) --cflags)
LDFLAGS := $(shell pkg-config $(libs) --libs)

deps := $(patsubst %.c, $(out)/%.o, $(wildcard *.c))

$(out)/gtk4-shadertoy: $(deps)
	$(CC) $(LDFLAGS) $(deps) -o $@

$(out)/%.o: %.c
	@mkdir -p $(dir $@)
	$(COMPILE.c) $< -o $@

$(out)/gtkshadertoy.o: gtkshadertoy.h

smoke: $(out)/gtk4-shadertoy
	$< < very-fast-procedural-ocean.glsl
