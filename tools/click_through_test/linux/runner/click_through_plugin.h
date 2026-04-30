#ifndef CLICK_THROUGH_PLUGIN_H_
#define CLICK_THROUGH_PLUGIN_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

void click_through_plugin_register_with_registrar(FlPluginRegistrar* registrar);

// Focus-event signal handlers — wire into the GtkWindow in my_application.cc
// so focus changes appear in the terminal alongside plugin debug output.
gboolean click_through_on_focus_in(GtkWidget* widget, GdkEvent* event,
                                    gpointer user_data);
gboolean click_through_on_focus_out(GtkWidget* widget, GdkEvent* event,
                                     gpointer user_data);

#endif  // CLICK_THROUGH_PLUGIN_H_
