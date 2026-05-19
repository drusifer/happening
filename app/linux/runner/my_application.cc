#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <unistd.h>

#include "flutter/generated_plugin_registrant.h"
#include "linux_dock_window_manager_plugin.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
// This callback exists to defer the window show until Flutter has content,
// avoiding a brief black flash during the loading state.
static void first_frame_cb(MyApplication* self, FlView* view) {
  GtkWidget* toplevel = gtk_widget_get_toplevel(GTK_WIDGET(view));
  gtk_widget_show(toplevel);
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Enable RGBA visual so the compositor can composite the window with alpha.
  // This is required for visual (see-through) transparency on Wayland and
  // composited X11. gtk_widget_set_app_paintable prevents GTK from painting
  // its own opaque theme background behind Flutter's content.
  // Safe unconditionally: gdk_screen_get_rgba_visual returns nullptr when no
  // compositor is present (e.g. bare X11), making this block a no-op.
  {
    GdkScreen* screen = gtk_widget_get_screen(GTK_WIDGET(window));
    GdkVisual* rgba_visual = gdk_screen_get_rgba_visual(screen);
    if (rgba_visual != nullptr) {
      gtk_widget_set_visual(GTK_WIDGET(window), rgba_visual);
      gtk_widget_set_app_paintable(GTK_WIDGET(window), TRUE);
    }
  }

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  // Declare this window as a dock/panel before it is mapped so the WM
  // classifies it correctly from the first map event.  Setting
  // _NET_WM_WINDOW_TYPE_DOCK after mapping causes Mutter to re-composite
  // the window (black-screen bug).  Setting it here — before gtk_widget_show
  // fires via first_frame_cb — is safe and tells the WM to keep the window
  // at the edge it declares via _NET_WM_STRUT_PARTIAL without repositioning it.
  gtk_window_set_type_hint(window, GDK_WINDOW_TYPE_HINT_DOCK);
  // Dock windows default to accept_focus=FALSE, which blocks keyboard input.
  // Explicitly re-enable so TextFields (e.g. city search) work.
  gtk_window_set_accept_focus(window, TRUE);

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
  gtk_widget_realize(GTK_WIDGET(view));

  // Show window after Flutter renders first frame so the user never sees an
  // empty (black) window.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));
  linux_dock_window_manager_plugin_register_with_registrar(
      fl_plugin_registry_get_registrar_for_plugin(FL_PLUGIN_REGISTRY(view),
                                                   "LinuxDockWindowManagerPlugin"),
      window);

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
