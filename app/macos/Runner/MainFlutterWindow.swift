import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    // Mark the window non-opaque before FlutterViewController is created so
    // the Metal layer is initialized in an alpha-capable compositing context.
    self.isOpaque = false
    self.backgroundColor = .clear

    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Impeller's CAMetalLayer defaults to isOpaque=true. Clearing it here
    // tells the compositor to blend transparent Metal pixels against the desktop
    // instead of against a black backing.
    flutterViewController.view.wantsLayer = true
    flutterViewController.view.layer?.isOpaque = false
    flutterViewController.view.layer?.backgroundColor = CGColor.clear

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  // window_manager's setAsFrameless() resets isOpaque=true on the NSWindow.
  // Re-assert both the window and every layer in the Flutter view tree each
  // time we come to front — Impeller may configure its CAMetalLayer after
  // awakeFromNib, so we need to catch it here (post-rendering-surface-init).
  override func makeKeyAndOrderFront(_ sender: Any?) {
    super.makeKeyAndOrderFront(sender)
    self.isOpaque = false
    self.backgroundColor = .clear
    makeLayersTransparent(contentViewController?.view.layer)
    // Impeller may finish Metal layer setup on the next run-loop tick.
    DispatchQueue.main.async { [weak self] in
      self?.makeLayersTransparent(self?.contentViewController?.view.layer)
    }
  }

  private func makeLayersTransparent(_ layer: CALayer?) {
    guard let layer = layer else { return }
    layer.isOpaque = false
    layer.backgroundColor = CGColor.clear
    layer.sublayers?.forEach { makeLayersTransparent($0) }
  }
}
