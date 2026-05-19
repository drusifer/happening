#include "linux_dock_window_manager_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gdk/gdkx.h>
#include <gtk/gtk.h>
#include <X11/Xatom.h>
#include <X11/Xlib.h>

#define CHANNEL_NAME "linux_dock_window_manager"

struct _LinuxDockWindowManagerPlugin {
  GObject parent_instance;
  FlMethodChannel* channel;
  GtkWindow* window;
};

typedef struct _LinuxDockWindowManagerPlugin LinuxDockWindowManagerPlugin;
typedef struct {
  GObjectClass parent_class;
} LinuxDockWindowManagerPluginClass;

G_DEFINE_TYPE(LinuxDockWindowManagerPlugin,
              linux_dock_window_manager_plugin,
              G_TYPE_OBJECT)

static void linux_dock_window_manager_plugin_dispose(GObject* object) {
  LinuxDockWindowManagerPlugin* self =
      (LinuxDockWindowManagerPlugin*)object;
  g_clear_object(&self->channel);
  G_OBJECT_CLASS(linux_dock_window_manager_plugin_parent_class)
      ->dispose(object);
}

static void linux_dock_window_manager_plugin_class_init(
    LinuxDockWindowManagerPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = linux_dock_window_manager_plugin_dispose;
}

static void linux_dock_window_manager_plugin_init(
    LinuxDockWindowManagerPlugin* self) {}

// Sets _NET_WM_STRUT_PARTIAL and _NET_WM_STRUT for a full-width top strip.
static void set_strut(Display* display, Window xid, int height) {
  int screen_width = DisplayWidth(display, DefaultScreen(display));

  // _NET_WM_STRUT_PARTIAL: left, right, top, bottom,
  //   left_start, left_end, right_start, right_end,
  //   top_start, top_end, bottom_start, bottom_end
  long strut12[12] = {
      0, 0, height, 0,
      0, 0, 0,      0,
      0, screen_width - 1, 0, 0};
  Atom partial = XInternAtom(display, "_NET_WM_STRUT_PARTIAL", False);
  XChangeProperty(display, xid, partial, XA_CARDINAL, 32, PropModeReplace,
                  (unsigned char*)strut12, 12);

  // Legacy _NET_WM_STRUT for older window managers.
  long strut4[4] = {0, 0, height, 0};
  Atom strut_atom = XInternAtom(display, "_NET_WM_STRUT", False);
  XChangeProperty(display, xid, strut_atom, XA_CARDINAL, 32, PropModeReplace,
                  (unsigned char*)strut4, 4);

  XFlush(display);
}

// Removes _NET_WM_STRUT_PARTIAL and _NET_WM_STRUT.
static void clear_strut(Display* display, Window xid) {
  Atom partial = XInternAtom(display, "_NET_WM_STRUT_PARTIAL", False);
  XDeleteProperty(display, xid, partial);

  Atom strut_atom = XInternAtom(display, "_NET_WM_STRUT", False);
  XDeleteProperty(display, xid, strut_atom);

  XFlush(display);
}

static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data) {
  LinuxDockWindowManagerPlugin* self =
      (LinuxDockWindowManagerPlugin*)user_data;
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "isDockable") == 0) {
    Display* display = gdk_x11_get_default_xdisplay();
    g_autoptr(FlValue) result = fl_value_new_bool(display != nullptr);
    fl_method_call_respond_success(method_call, result, nullptr);
    return;
  }

  if (strcmp(method, "dock") == 0) {
    Display* display = gdk_x11_get_default_xdisplay();
    if (display == nullptr) {
      // Wayland — no-op.
      fl_method_call_respond_success(method_call, nullptr, nullptr);
      return;
    }

    FlValue* args = fl_method_call_get_args(method_call);
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
      fl_method_call_respond_error(method_call, "INVALID_ARGS",
                                   "Expected map", nullptr, nullptr);
      return;
    }
    FlValue* height_val = fl_value_lookup_string(args, "height");
    if (height_val == nullptr ||
        fl_value_get_type(height_val) != FL_VALUE_TYPE_INT) {
      fl_method_call_respond_error(method_call, "INVALID_ARGS",
                                   "Missing height", nullptr, nullptr);
      return;
    }
    int height = (int)fl_value_get_int(height_val);

    GdkWindow* gdk_window =
        gtk_widget_get_window(GTK_WIDGET(self->window));
    if (gdk_window == nullptr) {
      fl_method_call_respond_success(method_call, nullptr, nullptr);
      return;
    }

    Window xid = gdk_x11_window_get_xid(gdk_window);
    set_strut(display, xid, height);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
    return;
  }

  if (strcmp(method, "undock") == 0) {
    Display* display = gdk_x11_get_default_xdisplay();
    if (display == nullptr) {
      // Wayland — no-op.
      fl_method_call_respond_success(method_call, nullptr, nullptr);
      return;
    }

    GdkWindow* gdk_window =
        gtk_widget_get_window(GTK_WIDGET(self->window));
    if (gdk_window == nullptr) {
      fl_method_call_respond_success(method_call, nullptr, nullptr);
      return;
    }

    Window xid = gdk_x11_window_get_xid(gdk_window);
    clear_strut(display, xid);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
    return;
  }

  fl_method_call_respond_not_implemented(method_call, nullptr);
}

void linux_dock_window_manager_plugin_register_with_registrar(
    FlPluginRegistrar* registrar, GtkWindow* window) {
  LinuxDockWindowManagerPlugin* plugin =
      (LinuxDockWindowManagerPlugin*)g_object_new(
          linux_dock_window_manager_plugin_get_type(), nullptr);
  plugin->window = window;

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar), CHANNEL_NAME,
      FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      plugin->channel, method_call_cb, g_object_ref(plugin), g_object_unref);

  g_object_unref(plugin);
}
