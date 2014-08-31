import Cocoa

class Window: NSWindow {
  override var canBecomeKeyWindow: Bool { return true }
  override var canBecomeMainWindow: Bool { return true }
}
