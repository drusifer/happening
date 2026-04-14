#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <unistd.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#include <X11/Xatom.h>
#endif
#ifdef HAS_GTK_LAYER_SHELL
#include <gtk-layer-shell/gtk-layer-shell.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Reads fontSize from ~/.config/happening/settings.json.
// Returns the pixel size: 13 (small), 15 (medium, default), 17 (large).
static int get_reserved_height(void) {
  const gchar* config_dir = g_get_user_config_dir();
  g_autofree gchar* path =
      g_build_filename(config_dir, "happening", "settings.json", NULL);
  
  const int og_height = 35;
  int height = (og_height + 15) * 1.1 + 1; //default medium

  g_autofree gchar* contents = NULL;
  if (!g_file_get_contents(path, &contents, NULL, NULL)) {
    return height;  // file absent or unreadable — use medium default
  }

  if (strstr(contents, "\"fontSize\":\"small\"") ||
      strstr(contents, "\"fontSize\": \"small\"")) {
    height = (og_height + 13) * 1.1 + 1; //default medium
  }
  if (strstr(contents, "\"fontSize\":\"large\"") ||
      strstr(contents, "\"fontSize\": \"large\"")) {
    height = (og_height + 17) * 1.1 + 1; //default large
  }
  return height;  
}

// Sets _NET_WM_STRUT_PARTIAL so the WM reserves 30px at the top of the
// screen and won't tile or maximise other windows behind the strip.
static void set_x11_strut(GtkWindow* window) {
#ifdef GDK_WINDOWING_X11
  GdkDisplay* display = gdk_display_get_default();
  if (!GDK_IS_X11_DISPLAY(display)) return;

  GdkWindow* gdk_window = gtk_widget_get_window(GTK_WIDGET(window));
  if (!gdk_window) return;

  Display* xdisplay = GDK_DISPLAY_XDISPLAY(display);
  Window xwindow = GDK_WINDOW_XID(gdk_window);

  GdkMonitor* monitor = gdk_display_get_primary_monitor(display);
  GdkRectangle geo;
  gdk_monitor_get_geometry(monitor, &geo);

  // _NET_WM_STRUT_PARTIAL: left, right, top, bottom,
  //   left_y0, left_y1, right_y0, right_y1,
  //   top_x0,  top_x1,  bottom_x0, bottom_x1
  const int height = get_reserved_height();
  long strut[12] = {
      0, 0, height, 0,
      0, 0, 0,      0,
      geo.x, geo.x + geo.width - 1, 0, 0};

  Atom strut_atom = XInternAtom(xdisplay, "_NET_WM_STRUT_PARTIAL", False);
  XChangeProperty(xdisplay, xwindow, strut_atom, XA_CARDINAL, 32,
                  PropModeReplace, (unsigned char*)strut, 12);

  // Tell the WM this window IS the panel — place it at y=0, not below the strut.
  Atom wm_type = XInternAtom(xdisplay, "_NET_WM_WINDOW_TYPE", False);
  Atom wm_type_dock = XInternAtom(xdisplay, "_NET_WM_WINDOW_TYPE_DOCK", False);
  XChangeProperty(xdisplay, xwindow, wm_type, XA_ATOM, 32,
                  PropModeReplace, (unsigned char*)&wm_type_dock, 1);
#endif
}

// Configures the window as a Wayland layer-shell panel anchored to the top of
// the screen, reserving exclusive space equal to the strip height.
// No-op if gtk-layer-shell was not available at build time.
static void set_wayland_layer(GtkWindow* window) {
#ifdef HAS_GTK_LAYER_SHELL
  GdkDisplay* display = gdk_display_get_default();
  // Only activate on Wayland; X11 path uses set_x11_strut instead.
  if (GDK_IS_X11_DISPLAY(display)) return;

  gtk_layer_init_for_window(window);
  gtk_layer_set_layer(window, GTK_LAYER_SHELL_LAYER_TOP);
  gtk_layer_set_anchor(window, GTK_LAYER_SHELL_EDGE_TOP, TRUE);
  gtk_layer_set_anchor(window, GTK_LAYER_SHELL_EDGE_LEFT, TRUE);
  gtk_layer_set_anchor(window, GTK_LAYER_SHELL_EDGE_RIGHT, TRUE);
  gtk_layer_set_exclusive_zone(window, get_reserved_height());
#endif
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  GtkWidget* toplevel = gtk_widget_get_toplevel(GTK_WIDGET(view));
  // Set X11 DOCK type + strut BEFORE showing so the WM never positions the
  // window as a normal window first (avoids race where it appears too low).
  set_x11_strut(GTK_WINDOW(toplevel));
  gtk_widget_show(toplevel);
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = FALSE;
  
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "happening");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "happening");
  }

  gtk_window_set_default_size(window, 1280, 1);

  // Load the window icon from the bundled PNG (data/app_icon.png, adjacent to
  // the executable in the release bundle).
  {
    char exe_path[4096];
    ssize_t len = readlink("/proc/self/exe", exe_path, sizeof(exe_path) - 1);
    if (len > 0) {
      exe_path[len] = '\0';
      g_autofree gchar* exe_dir = g_path_get_dirname(exe_path);
      g_autofree gchar* icon_path =
          g_build_filename(exe_dir, "data", "app_icon.png", NULL);
      GError* icon_err = NULL;
      gtk_window_set_icon_from_file(window, icon_path, &icon_err);
      if (icon_err) g_clear_error(&icon_err);
    }
  }

  set_wayland_layer(window);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#00000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
