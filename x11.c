#include <gdk/x11/gdkx.h>
#include "x11.h"

void net_wm_state_set_prop(GtkWidget *win, char *prop, int state) {
  Display *dpy = GDK_SURFACE_XDISPLAY(GDK_SURFACE(gtk_native_get_surface(GTK_NATIVE(win))));
  Window id = GDK_SURFACE_XID(GDK_SURFACE(gtk_native_get_surface(GTK_NATIVE(win))));

  XClientMessageEvent msg = {
    .type = ClientMessage,
    .display = dpy,
    .window = id,
    .message_type = XInternAtom(dpy, "_NET_WM_STATE", False),
    .format = 32,
    .data = {
      .l = {
        state,
        XInternAtom(dpy, prop, False),
        None,
        1,
        0
      }
    }
  };

  if (!XSendEvent(dpy, XRootWindow(dpy, XDefaultScreen(dpy)), False,
                  SubstructureRedirectMask|SubstructureNotifyMask,
                  (XEvent*)&msg))
    g_warning("net_wm_state_set_prop %s=%d failed", prop, state);
}
