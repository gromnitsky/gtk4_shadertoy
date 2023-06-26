#include <epoxy/gl.h>
#include "gtkshadertoy.h"

static gchar *my_shader;

GtkWidget* new_shadertoy() {
  GtkWidget *toy = gtk_shadertoy_new();
  gtk_shadertoy_set_image_shader(GTK_SHADERTOY(toy), my_shader);
  return toy;
}

void app_activate(GApplication *app, gpointer *user_data) {
  GtkWidget *win = gtk_window_new();
  gtk_window_set_application(GTK_WINDOW(win), GTK_APPLICATION(app));
  gtk_window_set_default_size(GTK_WINDOW(win), 854, 480); // 480p, 16:9

  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, FALSE);
  gtk_window_set_child(GTK_WINDOW(win), box);

  GtkWidget *aspect = gtk_aspect_frame_new(0.5, 0.5, 1.77777, FALSE);
  gtk_widget_set_hexpand(aspect, TRUE);
  gtk_widget_set_vexpand(aspect, TRUE);
  gtk_box_append(GTK_BOX(box), aspect);

  GtkWidget *shadertoy = new_shadertoy();
  gtk_aspect_frame_set_child(GTK_ASPECT_FRAME(aspect), shadertoy);

  gtk_window_present(GTK_WINDOW(win));
}

gchar* stdin_read() {
    GIOChannel* cn = g_io_channel_unix_new(fileno(stdin));
    gchar* buf;
    gsize len;

    if (G_IO_STATUS_NORMAL != g_io_channel_read_to_end(cn, &buf, &len, NULL))
      buf = NULL;
    g_io_channel_unref(cn);
    return buf;
}

int main(int argc, char **argv) {
  my_shader = stdin_read();

  GtkApplication *app = gtk_application_new("org.sigwait.gtk4-shadertoy",
                                            G_APPLICATION_DEFAULT_FLAGS);
  g_signal_connect(app, "activate", G_CALLBACK(app_activate), NULL);
  int stat = g_application_run(G_APPLICATION(app), argc, argv);
  g_object_unref(app);
  return stat;
}
