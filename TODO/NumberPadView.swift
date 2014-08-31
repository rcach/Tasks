import Cocoa

class NumberPadView: NSView {
  @IBOutlet weak var one: NSButton!
  @IBOutlet weak var two: NSButton!
  @IBOutlet weak var three: NSButton!
  @IBOutlet weak var four: NSButton!
  @IBOutlet weak var five: NSButton!
  @IBOutlet weak var six: NSButton!
  @IBOutlet weak var seven: NSButton!
  @IBOutlet weak var eight: NSButton!
  
  var onNumberPress: ((Int)->())?
  
  @IBAction func numberPressed(sender: NSButton) {
    var number = 0
    switch sender {
    case one:
      number = 1
    case two:
      number = 2
    case three:
      number = 3
    case four:
      number = 4
    case five:
      number = 5
    case six:
      number = 6
    case seven:
      number = 7
    case eight:
      number = 8
    default:
      number = 0
    }
    onNumberPress?(number)
  }
  
}
