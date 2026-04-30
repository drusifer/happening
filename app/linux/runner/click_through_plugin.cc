// click_through_plugin.cc
//
// Implements setIgnoreMouseEvents via GDK input-shape on Linux.
//
// Methods exposed on channel "com.happeningapp/click_through":
//
//   setIgnoreMouseEvents({ignore: bool})
//     Enable:  gdk_window_input_shape_combine_region(empty) +
//              gtk/gdk_window_set_accept_focus(FALSE)
//     Disable: gdk_window_input_shape_combine_region(NULL) +
//              gtk/gdk_window_set_accept_focus(TRUE)
//
//   getDisplayServer() → "x11" | "xwayland" | "wayland" | "unknown"
//
//   isLayerShellAvailable() → bool (compile-time; true only when
//     gtk-layer-shell-0 was found by CMake and LAYER_SHELL_AVAILABLE is defined)

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

// Detect display backend by GDK display type name + WAYLAND_DISPLAY env.
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
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGS", "Expected {ignore: bool}", nullptr));
  }
  bool ignore = fl_value_get_bool(ignore_val);

  GtkWindow* gtk_win = get_gtk_window(self);
  GdkWindow* gdk_win = get_gdk_window(self);

  if (gtk_win == nullptr || gdk_win == nullptr) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "NOT_READY", "GDK window not yet realized", nullptr));
  }

  if (ignore) {
    cairo_region_t* empty = cairo_region_create();
    gdk_window_input_shape_combine_region(gdk_win, empty, 0, 0);
    cairo_region_destroy(empty);

    gtk_window_set_accept_focus(gtk_win, FALSE);
    gtk_window_set_focus_on_map(gtk_win, FALSE);
    gdk_window_set_accept_focus(gdk_win, FALSE);
    gdk_window_set_focus_on_map(gdk_win, FALSE);
  } else {
    gdk_window_input_shape_combine_region(gdk_win, nullptr, 0, 0);

    gtk_window_set_accept_focus(gtk_win, TRUE);
    gtk_window_set_focus_on_map(gtk_win, TRUE);
    gdk_window_set_accept_focus(gdk_win, TRUE);
    gdk_window_set_focus_on_map(gdk_win, TRUE);
  }

  // Flush changes to the server/compositor immediately.
  gdk_display_flush(gdk_display_get_default());
  gdk_window_invalidate_rect(gdk_win, nullptr, FALSE);

  g_autoptr(FlValue) result = fl_value_new_bool(true);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

// ── getDisplayServer ─────────────────────────────────────────────────────────

static FlMethodResponse* get_display_server(ClickThroughPlugin* self) {
  const gchar* backend = detect_backend();
  g_autoptr(FlValue) result = fl_value_new_string(backend);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

// ── isLayerShellAvailable ────────────────────────────────────────────────────

static FlMethodResponse* is_layer_shell_available(ClickThroughPlugin* self) {
#ifdef LAYER_SHELL_AVAILABLE
  g_autoptr(FlValue) result = fl_value_new_bool(true);
#else
  g_autoptr(FlValue) result = fl_value_new_bool(false);
#endif
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
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
  } else if (g_strcmp0(method, "isLayerShellAvailable") == 0) {
    response = is_layer_shell_available(self);
  } else {
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

// ── GObject lifecycle ────────────────────────────────────────────────────────

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

void click_through_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  ClickThroughPlugin* plugin = CLICK_THROUGH_PLUGIN(
      g_object_new(click_through_plugin_get_type(), nullptr));

  plugin->registrar = FL_PLUGIN_REGISTRAR(g_object_ref(registrar));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "com.happeningapp/click_through", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      plugin->channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
