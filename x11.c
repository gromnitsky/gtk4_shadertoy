#include <gdk/x11/gdkx.h>
#include "x11.h"

typedef struct DisplayAndWindow {
  Display *dpy;
  Window id;
} DisplayAndWindow;

DisplayAndWindow display_and_window(GtkWidget *win) {
  DisplayAndWindow r;
  r.dpy = GDK_SURFACE_XDISPLAY(GDK_SURFACE(gtk_native_get_surface(GTK_NATIVE(win))));
  r.id = GDK_SURFACE_XID(GDK_SURFACE(gtk_native_get_surface(GTK_NATIVE(win))));
  return r;
}

void net_wm_state_set_prop(GtkWidget *win, char *prop, int state) {
  DisplayAndWindow daw = display_and_window(win);

  XClientMessageEvent msg = {
    .type = ClientMessage,
    .display = daw.dpy,
    .window = daw.id,
    .message_type = XInternAtom(daw.dpy, "_NET_WM_STATE", False),
    .format = 32,
    .data = {
      .l = {
        state,
        XInternAtom(daw.dpy, prop, False),
        None,
        1,
        0
      }
    }
  };

  if (!XSendEvent(daw.dpy, XRootWindow(daw.dpy, XDefaultScreen(daw.dpy)), False,
                  SubstructureRedirectMask|SubstructureNotifyMask,
                  (XEvent*)&msg))
    g_warning("net_wm_state_set_prop %s=%d failed", prop, state);
}

void wm_class_set(GtkWidget *win, char *name, char *klass) {
  DisplayAndWindow daw = display_and_window(win);
  XClassHint *ch = XAllocClassHint();
  ch->res_name = name;
  ch->res_class = klass;
  XSetClassHint(daw.dpy, daw.id, ch);
  XFree(ch);
}

void move_close_to_root(GtkWidget *win) {
  wm_class_set(win, "gtk4_shadertoy_below", "GTK4_Shadertoy_Below");

  net_wm_state_set_prop(win, "_NET_WM_STATE_BELOW", 1);
  net_wm_state_set_prop(win, "_NET_WM_STATE_STICKY", 1);
  net_wm_state_set_prop(win, "_NET_WM_STATE_SKIP_PAGER", 1);
  net_wm_state_set_prop(win, "_NET_WM_STATE_SKIP_TASKBAR", 1);
}
