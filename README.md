![](demo.png)

Run in a window:

    $ gtk4_shadertoy test/data/afl_ext/very-fast-procedural-ocean.glsl

kbd          | desc
------------ | -------------
<kbd>f</kbd> | fullscreen
<kbd>r</kbd> | print the current framerate to stdout
<kbd>q</kbd> | close window

Run fullscreen (-f) and show an FPS overlay (-r):

    $ gtk4_shadertoy -fr < file.glsl

Put the app on the lowest window layer, ignore kbd/mouse input:

    $ gtk4_shadertoy -fr -b file.glsl

To exit the app in such a wallpaper mode, you'll need to kill it
either sending WM_DESTROY, or via the TERM signal.

To make the wallpaper mode work in fvwm3, add to ~/.fvwm/config:

~~~
Style * EWMHUseStackingOrderHints
Style gtk4_shadertoy_below WindowListSkip
~~~

or, by just

~~~
Style gtk4_shadertoy_below StaysOnBottom, Sticky, WindowListSkip
~~~

## Features & limitations

* a tiny gtk4 app;
* no web browser dependency;
* X11 only, no wayland support yet;
* renders only a subset of standalone shaders so far, i.e., if a
  shader depends on a texture specific to shadertoy.com it won't
  work.

## Compilation

~~~
$ sudo dnf install gtk4-devel
$ make
~~~

`_out/gtk4_shadertoy` should be the result.

## License

MIT for `gtk4_shadertoy.c` & `x11.[ch]`.

`gtkshadertoy.[ch]` are ripped from gtk4-demo app and are LGPLv2.1+.

`test/data/*` files are downloaded form shadertoy.com.
