//
// click_through_plugin.cc  — debug build
//
// Implements setIgnoreMouseEvents via GDK input-shape on Linux.
// All operations emit g_print debug lines visible in the terminal so we can
// diagnose whether GDK calls are actually taking effect.
//
// Methods exposed on channel "com.example.click_through_test/click_through":
//
//   setIgnoreMouseEvents({ignore: bool})
//     Enable:  gdk_window_input_shape_combine_region(empty) +
//              gtk_window_set_accept_focus(FALSE)
//     Disable: gdk_window_input_shape_combine_region(NULL) +
//              gtk_window_set_accept_focus(TRUE)
//
//   getDisplayServer()  → "x11" | "xwayland" | "wayland" | "unknown"
//
//   getWindowInfo()     → map of diagnostic fields (for Dart log panel)
//

#include "click_through_plugin.h"

#include <cairo/cairo.h>
#include <flutter_linux/flutter_linux.h>
#include <gdk/gdk.h>
#include <gtk/gtk.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif
#ifdef GDK_WINDOWING_WAYLAND
#include <gdk/gdkwayland.h>
#endif

// ── GObject boilerplate ──────────────────────────────────────────────────────

typedef struct _ClickThroughPlugin ClickThroughPlugin;
typedef struct _ClickThroughPluginClass ClickThroughPluginClass;

#define CLICK_THROUGH_PLUGIN(obj)                                      \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), click_through_plugin_get_type(), \
                              ClickThroughPlugin))

struct _ClickThroughPlugin {
  GObject parent_instance;
  FlPluginRegistrar* registrar;
  FlMethodChannel* channel;
};

struct _ClickThroughPluginClass {
  GObjectClass parent_class;
};

G_DEFINE_TYPE(ClickThroughPlugin, click_through_plugin, G_TYPE_OBJECT)

// ── helpers ──────────────────────────────────────────────────────────────────

static GtkWindow* get_gtk_window(ClickThroughPlugin* self) {
  FlView* view = fl_plugin_registrar_get_view(self->registrar);
  if (view == nullptr) return nullptr;
  return GTK_WINDOW(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

static GdkWindow* get_gdk_window(ClickThroughPlugin* self) {
  GtkWindow* win = get_gtk_window(self);
  if (win == nullptr) return nullptr;
  return gtk_widget_get_window(GTK_WIDGET(win));
}

// Detect display backend by GDK display type name + env.
static const gchar* detect_backend() {
  GdkDisplay* display = gdk_display_get_default();
  if (display == nullptr) return "unknown";
  const gchar* t = G_OBJECT_TYPE_NAME(display);
  if (g_strstr_len(t, -1, "X11") != nullptr) {
    const gchar* wd = g_getenv("WAYLAND_DISPLAY");
    return (wd != nullptr && wd[0] != '\0') ? "xwayland" : "x11";
  }
  if (g_strstr_len(t, -1, "Wayland") != nullptr) return "wayland";
  return "unknown";
}

// ── setIgnoreMouseEvents ─────────────────────────────────────────────────────

static FlMethodResponse* set_ignore_mouse_events(ClickThroughPlugin* self,
                                                  FlValue* args) {
  FlValue* ignore_val = fl_value_lookup_string(args, "ignore");
  if (ignore_val == nullptr ||
      fl_value_get_type(ignore_val) != FL_VALUE_TYPE_BOOL) {
    g_print("[click_through] ERROR: missing/invalid 'ignore' arg\n");
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGS", "Expected {ignore: bool}", nullptr));
  }
  bool ignore = fl_value_get_bool(ignore_val);

  g_print("[click_through] setIgnoreMouseEvents(%s) called\n",
          ignore ? "true" : "false");

  GtkWindow* gtk_win = get_gtk_window(self);
  GdkWindow* gdk_win = get_gdk_window(self);

  if (gtk_win == nullptr || gdk_win == nullptr) {
    g_print("[click_through] ERROR: window not realized (gtk=%p gdk=%p)\n",
            (void*)gtk_win, (void*)gdk_win);
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "NOT_READY", "GDK window not yet realized", nullptr));
  }

  // Log window state before the change.
  gboolean is_realized = gtk_widget_get_realized(GTK_WIDGET(gtk_win));
  gboolean is_visible  = gtk_widget_is_visible(GTK_WIDGET(gtk_win));
  gboolean accepts_focus = gtk_window_get_focus_on_map(gtk_win);
  g_print("[click_through]   gtk_win=%p  realized=%d  visible=%d  focus_on_map=%d\n",
          (void*)gtk_win, is_realized, is_visible, accepts_focus);

#ifdef GDK_WINDOWING_X11
  if (GDK_IS_X11_WINDOW(gdk_win)) {
    guint32 xid = (guint32)GDK_WINDOW_XID(gdk_win);
    g_print("[click_through]   backend=X11  xid=0x%x\n", xid);
  }
#endif

  // Log GDK backend of the actual GdkWindow (may differ from display type on
  // multi-backend systems).
  const gchar* win_backend = "unknown";
#ifdef GDK_WINDOWING_X11
  if (GDK_IS_X11_WINDOW(gdk_win)) win_backend = "x11";
#endif
#ifdef GDK_WINDOWING_WAYLAND
  if (GDK_IS_WAYLAND_WINDOW(gdk_win)) win_backend = "wayland";
#endif
  g_print("[click_through]   window backend: %s\n", win_backend);

  if (ignore) {
    // ── ENABLE click-through ────────────────────────────────────────────────
    g_print("[click_through]   applying empty input-shape region\n");
    cairo_region_t* empty = cairo_region_create();
    gdk_window_input_shape_combine_region(gdk_win, empty, 0, 0);
    cairo_region_destroy(empty);

    // GTK-level focus prevention (sets WM_HINTS on X11).
    g_print("[click_through]   gtk: set_accept_focus(FALSE)  set_focus_on_map(FALSE)\n");
    gtk_window_set_accept_focus(gtk_win, FALSE);
    gtk_window_set_focus_on_map(gtk_win, FALSE);

    // GDK-level focus prevention (more direct than GTK wrapper on some backends).
    g_print("[click_through]   gdk: gdk_window_set_accept_focus(FALSE)\n");
    gdk_window_set_accept_focus(gdk_win, FALSE);
    gdk_window_set_focus_on_map(gdk_win, FALSE);

    // Force changes to reach the server/compositor immediately.
    // On X11: flushes the XShape + WM_HINTS changes.
    // On Wayland: gdk_window_invalidate_rect triggers a surface commit so
    //   wl_surface.set_input_region takes effect before the next click.
    gdk_display_flush(gdk_display_get_default());
    gdk_window_invalidate_rect(gdk_win, nullptr, FALSE);
    g_print("[click_through]   flush + invalidate done\n");

  } else {
    // ── DISABLE click-through ───────────────────────────────────────────────
    g_print("[click_through]   restoring full input-shape region (NULL)\n");
    gdk_window_input_shape_combine_region(gdk_win, nullptr, 0, 0);

    g_print("[click_through]   gtk+gdk: restoring accept_focus / focus_on_map\n");
    gtk_window_set_accept_focus(gtk_win, TRUE);
    gtk_window_set_focus_on_map(gtk_win, TRUE);
    gdk_window_set_accept_focus(gdk_win, TRUE);
    gdk_window_set_focus_on_map(gdk_win, TRUE);

    gdk_display_flush(gdk_display_get_default());
    gdk_window_invalidate_rect(gdk_win, nullptr, FALSE);
    g_print("[click_through]   flush + invalidate done\n");
  }

  g_print("[click_through]   setIgnoreMouseEvents done\n");
  g_autoptr(FlValue) result = fl_value_new_bool(true);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

// ── getDisplayServer ─────────────────────────────────────────────────────────

static FlMethodResponse* get_display_server(ClickThroughPlugin* self) {
  GdkDisplay* display = gdk_display_get_default();
  const gchar* type_name =
      (display != nullptr) ? G_OBJECT_TYPE_NAME(display) : "null";
  const gchar* backend = detect_backend();
  g_print("[click_through] getDisplayServer → %s  (GdkDisplay type: %s)\n",
          backend, type_name);
  g_autoptr(FlValue) result = fl_value_new_string(backend);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

// ── getWindowInfo (diagnostic dump) ─────────────────────────────────────────

static FlMethodResponse* get_window_info(ClickThroughPlugin* self) {
  g_autoptr(FlValue) map = fl_value_new_map();

  const gchar* backend = detect_backend();
  fl_value_set_string_take(map, "backend", fl_value_new_string(backend));

  GdkDisplay* display = gdk_display_get_default();
  const gchar* disp_type =
      (display != nullptr) ? G_OBJECT_TYPE_NAME(display) : "null";
  fl_value_set_string_take(map, "gdkDisplayType",
                           fl_value_new_string(disp_type));

  GtkWindow* gtk_win = get_gtk_window(self);
  GdkWindow* gdk_win = get_gdk_window(self);

  if (gtk_win != nullptr) {
    gboolean realized  = gtk_widget_get_realized(GTK_WIDGET(gtk_win));
    gboolean visible   = gtk_widget_is_visible(GTK_WIDGET(gtk_win));
    gboolean accept_f  = gtk_window_get_accept_focus(gtk_win);
    gboolean focus_map = gtk_window_get_focus_on_map(gtk_win);
    gboolean keep_above = FALSE;
    g_object_get(gtk_win, "is-active", &keep_above, NULL);  // reuse var for active
    fl_value_set_string_take(map, "realized", fl_value_new_bool(realized));
    fl_value_set_string_take(map, "visible",  fl_value_new_bool(visible));
    fl_value_set_string_take(map, "acceptFocus",  fl_value_new_bool(accept_f));
    fl_value_set_string_take(map, "focusOnMap",   fl_value_new_bool(focus_map));
    fl_value_set_string_take(map, "isActive",     fl_value_new_bool(keep_above));
  } else {
    fl_value_set_string_take(map, "error",
                             fl_value_new_string("gtk_win is null"));
  }

#ifdef GDK_WINDOWING_X11
  if (gdk_win != nullptr && GDK_IS_X11_WINDOW(gdk_win)) {
    guint32 xid = (guint32)GDK_WINDOW_XID(gdk_win);
    gchar xid_str[32];
    g_snprintf(xid_str, sizeof(xid_str), "0x%x", xid);
    fl_value_set_string_take(map, "xid", fl_value_new_string(xid_str));
  }
#endif

  const gchar* wayland_display = g_getenv("WAYLAND_DISPLAY");
  fl_value_set_string_take(map, "WAYLAND_DISPLAY",
                           fl_value_new_string(
                               wayland_display ? wayland_display : "(unset)"));
  const gchar* display_env = g_getenv("DISPLAY");
  fl_value_set_string_take(map, "DISPLAY",
                           fl_value_new_string(display_env ? display_env
                                                           : "(unset)"));

  return FL_METHOD_RESPONSE(fl_method_success_response_new(map));
}

// ── dispatch ─────────────────────────────────────────────────────────────────

static void click_through_plugin_handle_method_call(ClickThroughPlugin* self,
                                                     FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (g_strcmp0(method, "setIgnoreMouseEvents") == 0) {
    response = set_ignore_mouse_events(self, args);
  } else if (g_strcmp0(method, "getDisplayServer") == 0) {
    response = get_display_server(self);
  } else if (g_strcmp0(method, "getWindowInfo") == 0) {
    response = get_window_info(self);
  } else {
    g_print("[click_through] unknown method: %s\n", method);
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  click_through_plugin_handle_method_call(CLICK_THROUGH_PLUGIN(user_data),
                                          method_call);
}

// ── GObject lifecycle ─────────────────────────────────────────────────────────

static void click_through_plugin_dispose(GObject* object) {
  ClickThroughPlugin* self = CLICK_THROUGH_PLUGIN(object);
  g_clear_object(&self->channel);
  g_clear_object(&self->registrar);
  G_OBJECT_CLASS(click_through_plugin_parent_class)->dispose(object);
}

static void click_through_plugin_class_init(ClickThroughPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = click_through_plugin_dispose;
}

static void click_through_plugin_init(ClickThroughPlugin* self) {}

// ── registration ─────────────────────────────────────────────────────────────

// Focus-change log handlers registered in my_application.cc via this signal.
// Defined here so they can use the [click_through] prefix.
gboolean click_through_on_focus_in(GtkWidget* widget, GdkEvent* event,
                                    gpointer user_data) {
  g_print("[click_through] FOCUS-IN  (window gained focus)\n");
  return FALSE;
}

gboolean click_through_on_focus_out(GtkWidget* widget, GdkEvent* event,
                                     gpointer user_data) {
  g_print("[click_through] FOCUS-OUT (window lost focus)\n");
  return FALSE;
}

void click_through_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  ClickThroughPlugin* plugin = CLICK_THROUGH_PLUGIN(
      g_object_new(click_through_plugin_get_type(), nullptr));

  plugin->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.example.click_through_test/click_through", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      plugin->channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_print("[click_through] plugin registered on channel "
          "com.example.click_through_test/click_through\n");

  g_object_unref(plugin);
}
