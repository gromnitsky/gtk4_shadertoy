#include <fcntl.h>
#include <wordexp.h>
#include "gtkshadertoy.h"

#ifdef GDK_WINDOWING_X11
#include "x11.h"
#else
#error "Unsupported GDK backend"
#endif

typedef struct {
  gchar *shader_src;
  GtkWidget* shader;
  GtkWidget *fps_label;
  int shader_fps_tick;
  gboolean shader_playing;

  /* command line */
  gchar *shader_path;
  gboolean fullscreen;
  gboolean fps;
  gboolean below;
  gint port;
} Opt;

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

GtkWidget* shader_new(gchar *shader_src) {
  GtkWidget *toy = gtk_shadertoy_new();
  gtk_shadertoy_set_image_shader(GTK_SHADERTOY(toy), shader_src);
  return toy;
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

void shader_pause(Opt *opt) {
  if (opt->shader_playing) {
    gtk_shadertoy_pause(opt->shader);
    if (opt->fps)
      gtk_widget_remove_tick_callback(opt->shader, opt->shader_fps_tick);

  } else {
    gtk_shadertoy_resume(opt->shader);
    if (opt->fps)
      opt->shader_fps_tick = gtk_widget_add_tick_callback(opt->shader, on_toy_tick, opt->fps_label, NULL);
  }

  opt->shader_playing = !opt->shader_playing;
}

char** shellexpand(const char *s) {
  if (!s) return NULL;
  wordexp_t r;
  int status;
  if (0 != (status = wordexp(s, &r, WRDE_SHOWERR|WRDE_NOCMD))) {
    if (status == WRDE_NOSPACE) wordfree(&r);
    return NULL;
  }
  return r.we_wordv;
}

gboolean on_socket_msg(GThreadedSocketService *service,
                       GSocketConnection *conn,
                       GSocketListener *listener, Opt* opt) {
  GOutputStream *out = g_io_stream_get_output_stream(G_IO_STREAM(conn));
  GInputStream *in = g_io_stream_get_input_stream (G_IO_STREAM(conn));
  char buf[BUFSIZ];
  gssize size;

  char *hello = "Available commands: pause, load file.glsl, quit\n";
  g_output_stream_write_all(out, hello, strlen(hello), NULL, NULL, NULL);

  GtkWindow *toplevel = GTK_WINDOW(gtk_widget_get_root(opt->shader));

  while (0 < (size = g_input_stream_read(in, buf, sizeof buf, NULL, NULL))) {
    char *res = "400 invalid command\n";
    static GMutex mutex;
    buf[size] = '\0';
    char *req = g_strstrip(buf);

    g_mutex_lock(&mutex);
    char **cmd = shellexpand(req);

    if (!cmd) {
      res = "400 syntax error\n";
    } else if (1 == g_strv_length(cmd)) {
      if (0 == strcmp(req, "pause")) {
        res = "200 pause\n";
        shader_pause(opt);
      }
      if (0 == strcmp(req, "quit")) gtk_window_close(toplevel);

    } else if (2 == g_strv_length(cmd)) {
      if (0 == strcmp(cmd[0], "load")) {
        char *src = input(cmd[1]);
        if (src) {
          res = "200 load\n";
          char *title = g_path_get_basename(cmd[1]);
          gtk_window_set_title(toplevel, title);
          gtk_shadertoy_set_image_shader(GTK_SHADERTOY(opt->shader), src);
          if (!opt->shader_playing) shader_pause(opt);
          g_free(src);
          g_free(title);
        } else {
          res = "400 load: reading failed\n";
        }
      }
    }

    g_strfreev(cmd);
    g_mutex_unlock(&mutex);

    g_output_stream_write(out, res, strlen(res), NULL, NULL);
  }

  return TRUE;
}

gboolean socket_listen(Opt *opt) {
  GError *error = NULL;
  GSocketService *service = g_threaded_socket_service_new(10);
  GInetAddress *inet_addr = g_inet_address_new_from_string("127.0.0.1");
  GSocketAddress *addr = g_inet_socket_address_new(inet_addr, opt->port);
  gboolean ok = g_socket_listener_add_address(G_SOCKET_LISTENER(service),
                                              addr, G_SOCKET_TYPE_STREAM,
                                              G_SOCKET_PROTOCOL_TCP,
                                              NULL, NULL, &error);
  g_object_unref(inet_addr);
  g_object_unref(addr);
  if (!ok) {
    g_log(NULL, G_LOG_LEVEL_CRITICAL, "%s", error->message);
    return FALSE;
  }
  g_message("Listening on localhost:%d", opt->port);
  g_signal_connect(service, "run", G_CALLBACK(on_socket_msg), opt);
  return TRUE;
}

void fullscreen_toggle(GtkWidget *win) {
  void (*fn)(GtkWindow*) = gtk_window_is_fullscreen(GTK_WINDOW(win)) ? gtk_window_unfullscreen : gtk_window_fullscreen;
  fn(GTK_WINDOW(win));
}

gboolean on_keypress(GtkWidget *win, guint keyval, guint keycode,
                     GdkModifierType state, GtkEventControllerKey *evt_ctrl) {
  if (GDK_KEY_f == keyval) fullscreen_toggle(win);
  if (GDK_KEY_q == keyval) gtk_window_close(GTK_WINDOW(win));

  Opt *opt = g_object_get_data(G_OBJECT(win), "opt");
  if (GDK_KEY_r == keyval) printf("%f\n", fps(opt->shader));
  if (GDK_KEY_space == keyval) shader_pause(opt);

  return TRUE;
}

gboolean on_close(GtkWidget *w, Opt *opt) {
  if (opt->below) gdk_display_beep(gtk_widget_get_display(w));
  return opt->below;
}

void app_activate(GApplication *app, Opt *opt) {
  if (opt->port && !socket_listen(opt)) {
    // how do I provide status for g_application_quit()?
    exit(1);
  }

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

  opt->shader = shader_new(opt->shader_src);

  if (opt->fps) {
    GtkWidget *fps_overlay = gtk_overlay_new();
    gtk_overlay_set_child(GTK_OVERLAY(fps_overlay), opt->shader);

    GtkWidget *fps_frame = gtk_frame_new(NULL);
    gtk_widget_set_halign(fps_frame, GTK_ALIGN_START);
    gtk_widget_set_valign(fps_frame, GTK_ALIGN_START);
    gtk_widget_add_css_class(fps_frame, "app-notification");

    opt->fps_label = gtk_label_new("-1");
    gtk_widget_set_halign(opt->fps_label, GTK_ALIGN_START);
    gtk_frame_set_child(GTK_FRAME(fps_frame), opt->fps_label);
    gtk_overlay_add_overlay(GTK_OVERLAY(fps_overlay), fps_frame);

    gtk_aspect_frame_set_child(GTK_ASPECT_FRAME(aspect), fps_overlay);

    opt->shader_fps_tick = gtk_widget_add_tick_callback(opt->shader, on_toy_tick, opt->fps_label, NULL);
  } else {
    gtk_aspect_frame_set_child(GTK_ASPECT_FRAME(aspect), opt->shader);
  }

  g_free(opt->shader_path);
  g_free(opt->shader_src);

  g_object_set_data(G_OBJECT(win), "opt", opt); // for on_keypress()
  gtk_window_present(GTK_WINDOW(win));

  if (opt->fullscreen) gtk_window_fullscreen(GTK_WINDOW(win));

  if (opt->below) {
    gtk_widget_set_can_target(opt->shader, FALSE); // ignore mouse events
    move_close_to_root(win);
  } else {
    GtkEventController *ctrl = gtk_event_controller_key_new();
    g_signal_connect_object(ctrl, "key-pressed",
                            G_CALLBACK(on_keypress), win, G_CONNECT_SWAPPED);
    gtk_widget_add_controller(win, ctrl);
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
  Opt opt = { .shader_playing = TRUE };
  GOptionEntry params[] = {
    { "fullscreen", 'f', 0,G_OPTION_ARG_NONE,&opt.fullscreen,NULL,NULL },
    { "below", 'b', 0,G_OPTION_ARG_NONE, &opt.below,"fake x11 root window",NULL},
    { "fps", 'r', 0,G_OPTION_ARG_NONE,&opt.fps,"show an FPS overlay", NULL },
    { "port", 'p', 0,G_OPTION_ARG_INT,&opt.port,"start a server", "integer" },
    { NULL }
  };
  g_application_add_main_option_entries(G_APPLICATION(app), params);

  g_signal_connect(app, "activate", G_CALLBACK(app_activate), &opt);
  g_signal_connect(app, "open", G_CALLBACK(app_open), &opt);

  int status = g_application_run(G_APPLICATION(app), argc, argv);
  g_object_unref(app);
  return status;
}
