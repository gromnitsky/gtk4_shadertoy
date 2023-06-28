#include <fcntl.h>
#include "gtkshadertoy.h"

#ifdef GDK_WINDOWING_X11
#include "x11.h"
#else
#error "Unsupported GDK backend"
#endif

typedef struct {
  gchar *shader_path;
  gchar *shader_src;
  gboolean fullscreen;
  gboolean fps;
  gboolean below;
} Opt;

void fullscreen_toggle(GtkWidget *win) {
  void (*fn)(GtkWindow*) = gtk_window_is_fullscreen(GTK_WINDOW(win)) ? gtk_window_unfullscreen : gtk_window_fullscreen;
  fn(GTK_WINDOW(win));
}

double fps(GtkWidget *w) {
  GdkFrameClock *frame_clock = gtk_widget_get_frame_clock(w);
  if (frame_clock == NULL) return 0.0;
  return gdk_frame_clock_get_fps(frame_clock);
}

gboolean on_toy_tick(GtkWidget* toy, GdkFrameClock* frame_clock,
                     gpointer fps_label) {
  char s[10];
  snprintf(s, sizeof(s), "%.2f", fps(toy));
  gtk_label_set_text(GTK_LABEL(fps_label), s);
  return TRUE;
}

gboolean on_keypress(GtkWidget *win, guint keyval, guint keycode,
                     GdkModifierType state, GtkEventControllerKey *evt_ctrl) {
  if (GDK_KEY_f == keyval) fullscreen_toggle(win);
  if (GDK_KEY_q == keyval) gtk_window_close(GTK_WINDOW(win));
  if (GDK_KEY_r == keyval) printf("%f\n", fps(win));
  return TRUE;
}

GtkWidget* new_shadertoy(gchar *shader_src) {
  GtkWidget *toy = gtk_shadertoy_new();
  gtk_shadertoy_set_image_shader(GTK_SHADERTOY(toy), shader_src);
  return toy;
}

gboolean on_close(GtkWidget *w, Opt *opt) {
  if (opt->below) gdk_display_beep(gtk_widget_get_display(w));
  return opt->below;
}

gchar* input(char *file) {
  int fd = file ? open(file, O_RDONLY) : fileno(stdin);
  GIOChannel* cn = g_io_channel_unix_new(fd);
  gchar* buf;
  gsize len;

  if (G_IO_STATUS_NORMAL != g_io_channel_read_to_end(cn, &buf, &len, NULL))
    buf = NULL;
  g_io_channel_unref(cn);
  if (file) close(fd);
  return buf;
}

void app_activate(GApplication *app, Opt *opt) {
  if (!opt->shader_src) opt->shader_src = input(NULL); // try to read stdin
  if (opt->below) g_set_prgname("gtk4_shadertoy_below");

  GtkWidget *win = gtk_window_new();
  gtk_window_set_application(GTK_WINDOW(win), GTK_APPLICATION(app));
  gtk_window_set_default_size(GTK_WINDOW(win), 854, 480); // 480p, 16:9
  gtk_window_set_title(GTK_WINDOW(win),
                       opt->shader_path ? opt->shader_path : "[stdin]");

  g_signal_connect(win, "close-request", G_CALLBACK(on_close), opt);

  GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, FALSE);
  gtk_window_set_child(GTK_WINDOW(win), box);

  GtkWidget *aspect = gtk_aspect_frame_new(0.5, 0.5, 1.77777, FALSE);
  gtk_widget_set_hexpand(aspect, TRUE);
  gtk_widget_set_vexpand(aspect, TRUE);
  gtk_box_append(GTK_BOX(box), aspect);

  GtkWidget *toy = new_shadertoy(opt->shader_src);

  if (opt->fps) {
    GtkWidget *fps_overlay = gtk_overlay_new();
    gtk_overlay_set_child(GTK_OVERLAY(fps_overlay), toy);

    GtkWidget *fps_frame = gtk_frame_new(NULL);
    gtk_widget_set_halign(fps_frame, GTK_ALIGN_START);
    gtk_widget_set_valign(fps_frame, GTK_ALIGN_START);
    gtk_widget_add_css_class(fps_frame, "app-notification");

    GtkWidget *fps_label = gtk_label_new("-1");
    gtk_widget_set_halign(fps_label, GTK_ALIGN_START);
    gtk_frame_set_child(GTK_FRAME(fps_frame), fps_label);
    gtk_overlay_add_overlay(GTK_OVERLAY(fps_overlay), fps_frame);

    gtk_aspect_frame_set_child(GTK_ASPECT_FRAME(aspect), fps_overlay);

    gtk_widget_add_tick_callback(toy, on_toy_tick, fps_label, NULL);
  } else {
    gtk_aspect_frame_set_child(GTK_ASPECT_FRAME(aspect), toy);
  }

  g_free(opt->shader_path);
  g_free(opt->shader_src);

  gtk_window_present(GTK_WINDOW(win));

  if (opt->fullscreen) gtk_window_fullscreen(GTK_WINDOW(win));

  if (opt->below) {
    gtk_widget_set_can_target(toy, FALSE); // ignore mouse events
    move_close_to_root(win);
  } else {
    GtkEventController *ctrl = gtk_event_controller_key_new();
    g_signal_connect_object(ctrl, "key-pressed",
                            G_CALLBACK(on_keypress), win, G_CONNECT_SWAPPED);
    gtk_widget_add_controller(GTK_WIDGET(win), ctrl);
  }
}

void app_open(GApplication *app, GFile **files, gint n_files,
              gchar* hint, Opt *opt) {
  char *path = g_file_get_path(files[0]);
  opt->shader_src = input(path);
  if (opt->shader_src) opt->shader_path = g_file_get_basename(files[0]);
  g_free(path);
  g_application_activate(app);
}

int main(int argc, char **argv) {
  GtkApplication *app = gtk_application_new(NULL, G_APPLICATION_NON_UNIQUE|G_APPLICATION_HANDLES_OPEN);
  Opt opt = {};
  GOptionEntry params[] = {
    { "fullscreen", 'f', 0,G_OPTION_ARG_NONE,&opt.fullscreen,NULL,NULL },
    { "below", 'b', 0,G_OPTION_ARG_NONE, &opt.below,"fake x11 root window",NULL},
    { "fps", 'r', 0,G_OPTION_ARG_NONE,&opt.fps,"show an FPS overlay", NULL },
    { NULL }
  };
  g_application_add_main_option_entries(G_APPLICATION(app), params);

  g_signal_connect(app, "activate", G_CALLBACK(app_activate), &opt);
  g_signal_connect(app, "open", G_CALLBACK(app_open), &opt);

  int status = g_application_run(G_APPLICATION(app), argc, argv);
  g_object_unref(app);
  return status;
}
