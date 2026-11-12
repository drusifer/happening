#include <stdlib.h>

#include "my_application.h"

int main(int argc, char** argv) {
  // Force the X11 GDK backend (via XWayland on Wayland sessions) so that
  // _NET_WM_WINDOW_TYPE_DOCK, _NET_WM_STRUT_PARTIAL, and window positioning
  // work consistently whether launched via `make run-linux`, `flutter run`,
  // or the standalone binary.
  setenv("GDK_BACKEND", "x11", 0);

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
