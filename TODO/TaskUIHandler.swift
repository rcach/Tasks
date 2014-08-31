import Foundation

class TaskUIHandler {
  var task: Task
  
  init(task: Task) {
    self.task = task
  }
  
  func markTaskDoing(onComplete: (error: NSError?) -> ()) {
    trackEvent("UserActions", "Task", "MarkDoing", "1")
    markTaskAsDoing(task) { errorOrNil in
      if errorOrNil == nil {
        // TODO: This isn't exactly right, task may be 'Testing'.
        self.task = Task(task: self.task, status: Status.Development)
      }
      onComplete(error: errorOrNil) // TODO: On error perhaps re-fetch task from network.
    }
  }
  
  func markTaskDone(onComplete: (error: NSError?) -> ()) {
    trackEvent("UserActions", "Task", "MarkDone", "1")
    markTaskAsDone(task) { errorOrNil in
      if errorOrNil == nil {
        self.task = Task(task: self.task, status: Status.Done)
      }
      onComplete(error: errorOrNil)
    }
  }
  
  func logTime(numberOfSeconds: Int, numberOfHoursRemaining: Int, onComplete: (error: NSError?) -> ()) {
    trackEvent("UserActions", "Task", "LogTime", "1")
    logTimeInSeconds(numberOfSeconds, hoursRemaining: numberOfHoursRemaining, toTask: task, onComplete)
  }
  
}