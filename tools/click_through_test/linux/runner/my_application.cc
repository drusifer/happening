#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif
#ifdef GDK_WINDOWING_WAYLAND
#include <gdk/gdkwayland.h>
#endif

#include "click_through_plugin.h"
#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void first_frame_cb(MyApplication* self, FlView* view) {
  GtkWidget* toplevel = gtk_widget_get_toplevel(GTK_WIDGET(view));
  g_print("[my_application] first_frame_cb — showing window\n");
  gtk_widget_show(toplevel);
}

static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  gtk_window_set_title(window, "Click-Through Test");
  gtk_window_set_default_size(window, 560, 460);

  // ── Log which GDK backend is active ───────────────────────────────────────
  GdkDisplay* display = gdk_display_get_default();
  g_print("[my_application] GDK backend: %s\n",
          display ? G_OBJECT_TYPE_NAME(display) : "null");
  g_print("[my_application] WAYLAND_DISPLAY=%s  DISPLAY=%s\n",
          g_getenv("WAYLAND_DISPLAY") ? g_getenv("WAYLAND_DISPLAY") : "(unset)",
          g_getenv("DISPLAY") ? g_getenv("DISPLAY") : "(unset)");

  // ── Window type: NOTIFICATION ─────────────────────────────────────────────
  // NOTIFICATION-type windows are not given keyboard focus by the WM/compositor
  // and are not included in the taskbar.  Must be set BEFORE the window is
  // realized or shown.
  gtk_window_set_type_hint(window, GDK_WINDOW_TYPE_HINT_NOTIFICATION);
  g_print("[my_application] window type hint → NOTIFICATION\n");

  // Disable focus at the GTK level too.  On X11 this sets WM_HINTS.InputHint=0.
  // On Wayland it has limited effect but doesn't hurt.
  gtk_window_set_accept_focus(window, FALSE);
  gtk_window_set_focus_on_map(window, FALSE);
  g_print("[my_application] accept_focus=FALSE  focus_on_map=FALSE\n");

  // ── ARGB visual (X11 / XWayland only) ────────────────────────────────────
  // On native Wayland this is handled by the compositor automatically.
  GdkScreen* screen = gtk_window_get_screen(window);
  GdkVisual* rgba_visual = gdk_screen_get_rgba_visual(screen);
  if (rgba_visual != nullptr) {
    g_print("[my_application] ARGB visual available\n");
    gtk_widget_set_visual(GTK_WIDGET(window), rgba_visual);
  } else {
    g_print("[my_application] WARNING: no ARGB visual\n");
  }
  gboolean composited = gdk_screen_is_composited(screen);
  g_print("[my_application] screen composited: %d\n", composited);
  gtk_widget_set_app_paintable(GTK_WIDGET(window), TRUE);

  // ── Focus-change logging ──────────────────────────────────────────────────
  g_signal_connect(window, "focus-in-event",
                   G_CALLBACK(click_through_on_focus_in), nullptr);
  g_signal_connect(window, "focus-out-event",
                   G_CALLBACK(click_through_on_focus_out), nullptr);

  // ── Flutter view ──────────────────────────────────────────────────────────
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA bg = {0.0, 0.0, 0.0, 0.0};
  fl_view_set_background_color(view, &bg);

  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));
  gtk_widget_realize(GTK_WIDGET(view));
  g_print("[my_application] view realized\n");

  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  FlPluginRegistrar* ct_registrar = fl_plugin_registry_get_registrar_for_plugin(
      FL_PLUGIN_REGISTRY(view), "ClickThroughPlugin");
  click_through_plugin_register_with_registrar(ct_registrar);
  g_object_unref(ct_registrar);

  gtk_widget_grab_focus(GTK_WIDGET(view));

  // ── Log native window ID ──────────────────────────────────────────────────
#ifdef GDK_WINDOWING_X11
  GdkWindow* gdk_win = gtk_widget_get_window(GTK_WIDGET(window));
  if (gdk_win != nullptr && GDK_IS_X11_WINDOW(gdk_win)) {
    g_print("[my_application] X11 XID: 0x%lx\n",
            (unsigned long)GDK_WINDOW_XID(gdk_win));
  }
#endif
#ifdef GDK_WINDOWING_WAYLAND
  GdkWindow* gdk_win2 = gtk_widget_get_window(GTK_WIDGET(window));
  if (gdk_win2 != nullptr && GDK_IS_WAYLAND_WINDOW(gdk_win2)) {
    g_print("[my_application] Wayland surface: %p\n",
            gdk_wayland_window_get_wl_surface(gdk_win2));
  }
#endif
}

static gboolean my_application_local_command_line(GApplication* application,
                                                   gchar*** arguments,
                                                   int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
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

static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

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
