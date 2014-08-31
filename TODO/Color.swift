import Cocoa

extension NSColor {
  class func todoColor() -> NSColor {
    return colorWithRGB(0x00AFFF)
  }
  
  class func doingColor() -> NSColor {
    return colorWithRGB(0xFF8E00)
  }
  
  class func doneColor() -> NSColor {
    return colorWithRGB(0x00CC00)
  }
  
  class func navBarColor() -> NSColor {
    return colorWithRGB(0x62B1FF)
  }
}

func colorWithRGB(rgb: UInt) -> NSColor {
  return colorWithRGB(rgb, 1)
}

func colorWithRGB(rgb: UInt, alpha: CGFloat) -> NSColor {
  let r = CGFloat((rgb / 0x10000) % 0x100) / 0xFF
  let g = CGFloat((rgb / 0x100) % 0x100) / 0xFF
  let b = CGFloat(rgb % 0x100) / 0xFF
  return NSColor(red: r, green: g, blue: b, alpha: alpha)
}
