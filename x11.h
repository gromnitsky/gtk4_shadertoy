#ifndef X11_H_E72ECBF5_9CA1_4115_A6EF_B5CE6CBDF9BB
#define X11_H_E72ECBF5_9CA1_4115_A6EF_B5CE6CBDF9BB

#include <stdbool.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <gtk/gtk.h>

void net_wm_state_set_prop(GtkWidget *win, char *prop, int state);

#endif // X11_H_E72ECBF5_9CA1_4115_A6EF_B5CE6CBDF9BB
