import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // Forward custom-scheme URLs (works.gs.happening://oauth?code=...) to
  // app_links so the OAuth redirect handler receives them.
  override func application(_ application: NSApplication, open urls: [URL]) {
    super.application(application, open: urls)
  }
}
