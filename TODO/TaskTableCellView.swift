import Cocoa


func dec(left:Float, right: Int) -> String {
  let nf = NSNumberFormatter()
  nf.maximumSignificantDigits = Int(right)
  return nf.stringFromNumber(NSNumber(float: left))
}


var activeTimers = [String: Timer]()

enum TaskCellState {
  case Todo
  case TodoMutationActivityInProgress
  case DoingTimerOff
  case DoingTimerOffMutationActivityInProgress
  case DoingTimerOn
  case DoingTimerOnMutationActivityInProgress
  case DoingEditHours
  case DoingSetHoursRemaining
  case DoneSetHours
  case Done
  case DoneMutationActivityInProgress
  case Empty
}

// TODO: Method indicateActivityStateForCurrentState

enum ControlButtonImage: String {
  case CheckOutlineBlue = "CheckOutlineBlue"
  case CheckOutlineOrange = "CheckOutlineOrange"
  case CheckFilledGreen = "CheckFilledGreen"
  
  case ClockOutlineBlue = "ClockOutlineBlue"
  case OnOutlineOrange = "OnOutlineOrange"
  case CircleFilledOrange = "CircleFilledOrange"
  
  case CircleOutlineOrange = "CircleOutlineOrange"
  case CircleOutlineGreen = "CircleOutlineGreen"
}

enum MiddleButtonLabelText: String {
  case Doing = "DOING"
  case StartTimer = "START"
  case StopTimer = "STOP"
}

func imageForControlButton(controlButtonImage: ControlButtonImage) -> NSImage {
  return NSImage(named: controlButtonImage.toRaw())
}

// TODO: Don't attempt to mark as doing when start timer button is on screen.


class TaskTableCellView: NSTableCellView {
  @IBOutlet var numberPad: NumberPadView!
  @IBOutlet weak var leadingButton: NSButton!
  @IBOutlet weak var leadingButtonLabel: NSTextField!
  
  @IBOutlet weak var middleButton: NSButton!
  @IBOutlet weak var middleButtonLabel: NSTextField!
  
  @IBOutlet weak var trailingButton: NSButton!
  @IBOutlet weak var trailingButtonLabel: NSTextField!
  
  @IBOutlet weak var timeSpentLabel: NSTextField!
  
  var handler: TaskUIHandler?
  var rowHeightsOrNil: TableViewRowHeights?
  var state: TaskCellState?
  
  var indexOrNil: Int?

  @IBAction func done(sender: NSButton) {
    // TODO: Think about this, should this if branch be based on the status of the task or the current UI state?
    if state == .Done {
      transitionToState(.DoneMutationActivityInProgress)
      handler?.markTaskDoing() {
        [weak self] (errorOrNil: NSError?) -> () in
        if self == nil { return }
        if errorOrNil == nil {
          if let task = self?.handler?.task {
            self?.updateWithTask(task)
          } else {
            self?.transitionToState(.DoingTimerOff)
          }
        } else {
          self?.transitionToState(.Done)
          println("Error marking task as doing (from done): \(errorOrNil!)")
        }
      }
      return
    }
    
    if state == .Todo {
      transitionToState(.TodoMutationActivityInProgress)
    } else if state == .DoingTimerOff {
      transitionToState(.DoingTimerOffMutationActivityInProgress)
    } else {
      return
    }
    handler?.markTaskDone() {
      [weak self] (error: NSError?) -> () in
      if self == nil { return }
      if error == nil {
        if let task = self?.handler?.task {
          self?.updateWithTask(task)
        } else {
          self?.transitionToState(.Done)
        }
      } else {
        if let task = self?.handler?.task {
          self?.updateWithTask(task)
        } else {
          self?.transitionToState(.DoingTimerOff)
        }
        
        println("Error marking task as done: \(error!)")
      }
    }
  }
  
  @IBAction func doing(sender: NSButton) {
    if state == .Todo {
      transitionToState(.TodoMutationActivityInProgress)
      handler?.markTaskDoing() {
        [weak self] (error: NSError?) -> () in
        if self == nil { return }
        if error == nil {
          if let task = self?.handler?.task {
            self?.updateWithTask(task)
          } else {
            self?.transitionToState(.DoingTimerOff)
          }
        } else {
          println("Error marking task as doing: \(error!)")
        }
      }
      return
    }
    if state == .DoingTimerOff {
      if let realHandler = self.handler {
        activeTimers[realHandler.task.identifier] = Timer(task: realHandler.task)
        transitionToState(.DoingTimerOn)
      }
      return
    }
    if state == .DoingTimerOn {
      transitionToState(.DoingSetHoursRemaining)
    }
  }
  
  func updateWithTask(task: Task) {
    timeSpentLabel.stringValue = "\(Float(task.timeSpentSeconds)/(60.0 * 60.0))"
    switch task.status() {
    case .InDefinition:
      transitionToState(.Todo)
    case .Development, .Testing:
      if let timer = activeTimers[task.identifier] {
        transitionToState(.DoingTimerOn)
      } else {
        transitionToState(.DoingTimerOff)
      }
    case .Done:
      transitionToState(.Done)
    default:
      println()
    }
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    handler = nil
    indexOrNil = nil
  }
  
  func transitionToState(state: TaskCellState) {
    loadNumberPadViewIfNeeded()
    switch state {
    case TaskCellState.Todo:
      leadingButton.image = imageForControlButton(.CheckOutlineBlue)
      leadingButtonLabel.textColor = NSColor.todoColor()
      leadingButton.enabled = true
      leadingButton.hidden = false
      leadingButtonLabel.hidden = false
      
      middleButton.image = imageForControlButton(.ClockOutlineBlue)
      middleButtonLabel.textColor = NSColor.todoColor()
      middleButtonLabel.stringValue = MiddleButtonLabelText.Doing.toRaw()
      middleButton.hidden = false
      middleButtonLabel.hidden = false
      
      trailingButton.hidden = true
      trailingButtonLabel.hidden = true
      timeSpentLabel.hidden = true
      
      middleButton.enabled = true
      trailingButton.enabled = true
      
      numberPad.hidden = true
      updateRowHeightUseCustomHeight(false)
    
    case TaskCellState.TodoMutationActivityInProgress:
      leadingButton.image = imageForControlButton(.CheckOutlineBlue)
      leadingButtonLabel.textColor = NSColor.todoColor()
      leadingButton.enabled = false
      leadingButton.hidden = false
      leadingButtonLabel.hidden = false
      
      middleButton.image = imageForControlButton(.ClockOutlineBlue)
      middleButtonLabel.textColor = NSColor.todoColor()
      middleButtonLabel.stringValue = MiddleButtonLabelText.Doing.toRaw()
      middleButton.hidden = false
      middleButtonLabel.hidden = false
      
      trailingButton.hidden = true
      trailingButtonLabel.hidden = true
      timeSpentLabel.hidden = true
      
      middleButton.enabled = false
      trailingButton.enabled = false
      
      numberPad.hidden = true
      updateRowHeightUseCustomHeight(false)
      
      
    case TaskCellState.DoingTimerOn:
      leadingButton.image = imageForControlButton(.CheckOutlineOrange)
      leadingButtonLabel.textColor = NSColor.doingColor()
      leadingButton.enabled = false
      leadingButton.hidden = false
      leadingButtonLabel.hidden = false
      
      middleButton.image = imageForControlButton(.CircleFilledOrange)
      middleButtonLabel.textColor = NSColor.doingColor()
      middleButtonLabel.stringValue = MiddleButtonLabelText.StopTimer.toRaw()
      middleButton.hidden = false
      middleButtonLabel.hidden = false
      
      trailingButton.hidden = true
      trailingButtonLabel.hidden = true
      timeSpentLabel.hidden = true
      
      middleButton.enabled = true
      trailingButton.enabled = false
      
      numberPad.hidden = true
      updateRowHeightUseCustomHeight(false)
      
    case TaskCellState.DoingTimerOnMutationActivityInProgress:
      leadingButton.image = imageForControlButton(.CheckOutlineOrange)
      leadingButtonLabel.textColor = NSColor.doingColor()
      leadingButton.enabled = false
      leadingButton.hidden = false
      leadingButtonLabel.hidden = false
      
      middleButton.image = imageForControlButton(.CircleFilledOrange)
      middleButtonLabel.textColor = NSColor.doingColor()
      middleButtonLabel.stringValue = MiddleButtonLabelText.StopTimer.toRaw()
      middleButton.hidden = false
      middleButtonLabel.hidden = false
      
      trailingButton.hidden = true
      trailingButtonLabel.hidden = true
      timeSpentLabel.hidden = true
      
      middleButton.enabled = false
      trailingButton.enabled = false
      
      numberPad.hidden = true
      updateRowHeightUseCustomHeight(false)
      
    case TaskCellState.DoingTimerOff:
      leadingButton.image = imageForControlButton(.CheckOutlineOrange)
      leadingButtonLabel.textColor = NSColor.doingColor()
      leadingButton.enabled = true
      leadingButton.hidden = false
      leadingButtonLabel.hidden = false
      
      middleButton.image = imageForControlButton(.OnOutlineOrange)
      middleButtonLabel.textColor = NSColor.doingColor()
      middleButtonLabel.stringValue = MiddleButtonLabelText.StartTimer.toRaw()
      middleButton.hidden = false
      middleButtonLabel.hidden = false
      
      trailingButton.image = imageForControlButton(.CircleOutlineOrange)
      trailingButtonLabel.textColor = NSColor.doingColor()
      trailingButton.hidden = true
      trailingButtonLabel.hidden = false
      timeSpentLabel.hidden = false
      timeSpentLabel.textColor = NSColor.doingColor()
      
      middleButton.enabled = true
      trailingButton.enabled = true
      
      numberPad.hidden = true
      updateRowHeightUseCustomHeight(false)
      
    case TaskCellState.DoingTimerOffMutationActivityInProgress:
      leadingButton.image = imageForControlButton(.CheckOutlineOrange)
      leadingButtonLabel.textColor = NSColor.doingColor()
      leadingButton.enabled = false
      leadingButton.hidden = false
      leadingButtonLabel.hidden = false
      
      middleButton.image = imageForControlButton(.OnOutlineOrange)
      middleButtonLabel.textColor = NSColor.doingColor()
      middleButtonLabel.stringValue = MiddleButtonLabelText.StartTimer.toRaw()
      middleButton.hidden = false
      middleButtonLabel.hidden = false
      
      trailingButton.image = imageForControlButton(.CircleOutlineOrange)
      trailingButtonLabel.textColor = NSColor.doingColor()
      trailingButton.hidden = true
      trailingButtonLabel.hidden = false
      timeSpentLabel.hidden = false
      timeSpentLabel.textColor = NSColor.doingColor()
      
      middleButton.enabled = false
      trailingButton.enabled = false
      
      numberPad.hidden = true
      updateRowHeightUseCustomHeight(false)
      
      
    case TaskCellState.DoingEditHours:
      leadingButton.image = imageForControlButton(.CheckOutlineOrange)
      leadingButtonLabel.textColor = NSColor.doingColor()
      leadingButton.enabled = true
      leadingButton.hidden = false
      leadingButtonLabel.hidden = false
      
      middleButton.image = imageForControlButton(.OnOutlineOrange)
      middleButtonLabel.textColor = NSColor.doingColor()
      middleButtonLabel.stringValue = ""
      middleButton.hidden = false
      middleButtonLabel.hidden = false
      
      trailingButton.image = imageForControlButton(.CircleOutlineOrange)
      trailingButtonLabel.textColor = NSColor.doingColor()
      trailingButton.hidden = true
      trailingButtonLabel.hidden = false
      timeSpentLabel.hidden = false
      timeSpentLabel.textColor = NSColor.doingColor()
      
      middleButton.enabled = false
      trailingButton.enabled = true
      
      numberPad.hidden = true
      updateRowHeightUseCustomHeight(false)
      
    case TaskCellState.DoingSetHoursRemaining:
      leadingButton.hidden = true
      leadingButtonLabel.hidden = true
      
      middleButton.hidden = true
      middleButtonLabel.hidden = true
      
      trailingButton.hidden = true
      trailingButtonLabel.hidden = true
      timeSpentLabel.hidden = true
      
      numberPad.hidden = false
      updateRowHeightUseCustomHeight(true)

      self.numberPad.onNumberPress = { hoursRemaining in
        if let realHandler = self.handler {
          if let timer = activeTimers[realHandler.task.identifier] {
            var seconds = timer.secondsSinceStart()
            self.handler?.logTime(seconds, numberOfHoursRemaining: hoursRemaining) {
              [weak self] (errorOrNil: NSError?) -> () in
              if self == nil { return }
              self!.transitionToState(TaskCellState.DoingTimerOff)
              if let error = errorOrNil { println("Error logging time: \(error)") }
            }
            self.transitionToState(.DoingTimerOnMutationActivityInProgress)
            activeTimers[realHandler.task.identifier] = nil
            return
          }
        }
        self.transitionToState(.DoingTimerOff) // TODO: Place in an error state.
      }

    case TaskCellState.DoneSetHours:
      leadingButton.image = imageForControlButton(.CheckOutlineOrange)
      leadingButtonLabel.textColor = NSColor.doingColor()
      leadingButton.enabled = true
      leadingButton.hidden = false
      leadingButtonLabel.hidden = false
      
      middleButton.image = imageForControlButton(.OnOutlineOrange)
      middleButtonLabel.textColor = NSColor.doingColor()
      middleButtonLabel.stringValue = ""
      middleButton.hidden = false
      middleButtonLabel.hidden = false
      
      trailingButton.image = imageForControlButton(.CircleOutlineOrange)
      trailingButtonLabel.textColor = NSColor.doingColor()
      trailingButton.hidden = true
      trailingButtonLabel.hidden = false
      timeSpentLabel.hidden = false
      timeSpentLabel.textColor = NSColor.doingColor()
      
      middleButton.enabled = false
      trailingButton.enabled = true
      
      numberPad.hidden = true
      updateRowHeightUseCustomHeight(false)
      
    case TaskCellState.Done:
      leadingButton.image = imageForControlButton(.CheckFilledGreen)
      leadingButtonLabel.textColor = NSColor.doneColor()
      leadingButton.enabled = true
      leadingButton.hidden = false
      leadingButtonLabel.hidden = false
      
      middleButton.hidden = true
      middleButtonLabel.hidden = true
      
      trailingButton.image = imageForControlButton(.CircleOutlineGreen)
      trailingButtonLabel.textColor = NSColor.doneColor()
      trailingButton.hidden = true
      trailingButtonLabel.hidden = false
      timeSpentLabel.hidden = false
      timeSpentLabel.textColor = NSColor.doneColor()
      
      middleButton.enabled = false
      trailingButton.enabled = true
      
      numberPad.hidden = true
      updateRowHeightUseCustomHeight(false)
      
    case TaskCellState.DoneMutationActivityInProgress:
      leadingButton.image = imageForControlButton(.CheckFilledGreen)
      leadingButtonLabel.textColor = NSColor.doneColor()
      leadingButton.enabled = false
      leadingButton.hidden = false
      leadingButtonLabel.hidden = false
      
      middleButton.hidden = true
      middleButtonLabel.hidden = true
      
      trailingButton.image = imageForControlButton(.CircleOutlineGreen)
      trailingButtonLabel.textColor = NSColor.doneColor()
      trailingButton.hidden = true
      trailingButtonLabel.hidden = false
      timeSpentLabel.hidden = false
      timeSpentLabel.textColor = NSColor.doneColor()
      
      middleButton.enabled = false
      trailingButton.enabled = false
      
      numberPad.hidden = true
      updateRowHeightUseCustomHeight(false)
      
    case TaskCellState.Empty:
      leadingButton.image = imageForControlButton(.CheckFilledGreen)
      leadingButtonLabel.textColor = NSColor.doneColor()
      leadingButton.enabled = false
      leadingButton.hidden = true
      leadingButtonLabel.hidden = true
      
      middleButton.hidden = true
      middleButtonLabel.hidden = true
      
      trailingButton.image = imageForControlButton(.CircleOutlineGreen)
      trailingButtonLabel.textColor = NSColor.doneColor()
      trailingButton.hidden = true
      trailingButtonLabel.hidden = true
      timeSpentLabel.hidden = true
      timeSpentLabel.textColor = NSColor.doneColor()
      
      middleButton.enabled = false
      trailingButton.enabled = true
      
      numberPad.hidden = true
      updateRowHeightUseCustomHeight(false)
      
    }
    self.state = state
    self.window?.recalculateKeyViewLoop()
  }
  
  func loadNumberPadViewIfNeeded() {
    if numberPad == nil {
      loadNumberPadView()
      // TODO: Use auto layout.
      numberPad.frame = NSRect(x: 0, y: -80, width: 320, height: 162)
      addSubview(numberPad)
    }
  }
  
  func loadNumberPadView() {
    NSBundle.mainBundle().loadNibNamed("NumberPadView", owner: self, topLevelObjects: nil)
  }
  
  // TODO: Use 'expanded' instead of 'custom.'
  func updateRowHeightUseCustomHeight(useCustomHeight: Bool) {
    if let rowHeights = self.rowHeightsOrNil {
      if let index = self.indexOrNil {
        if useCustomHeight {
          rowHeights.cellNeedsCustomHeight(230, atIndex: index)
        } else {
          rowHeights.cellNeedsDefaultHeightAtIndex(index)
        }
      }
    }
  }
  
}
