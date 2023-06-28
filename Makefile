out := _out
libs := gtk4 epoxy x11

CFLAGS := -g -Wall -std=c17 $(shell pkg-config $(libs) --cflags)
LDFLAGS := $(shell pkg-config $(libs) --libs)

deps := $(patsubst %.c, $(out)/%.o, $(wildcard *.c))

$(out)/gtk4_shadertoy: $(deps)
	$(LINK.c) $^ -o $@

$(out)/%.o: %.c
	@mkdir -p $(dir $@)
	$(COMPILE.c) $< -o $@

$(out)/gtkshadertoy.o: gtkshadertoy.h
$(out)/x11.o: x11.h

smoke: $(out)/gtk4_shadertoy
	$< < test/data/afl_ext/very-fast-procedural-ocean.glsl
