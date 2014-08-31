import Foundation

struct UserStory {
  let identifier: String
  let key: String
  let summary: String
}

struct Task {
  let identifier: String
  let key: String
  let summary: String
  let statusIdentifier: String
  let timeSpentSeconds: Int
  
  init(task: Task, status: Status) {
    self.identifier = task.identifier
    self.key = task.key
    self.summary = task.summary
    self.statusIdentifier = status.toRaw()
    self.timeSpentSeconds = task.timeSpentSeconds
  }
  
  init(identifier: String, key: String, summary: String, statusIdentifier: String, timeSpentSeconds: Int) {
    self.identifier = identifier
    self.key = key
    self.summary = summary
    self.statusIdentifier = statusIdentifier
    self.timeSpentSeconds = timeSpentSeconds
  }
  
  func status() -> Status {
    if let status = Status.fromRaw(statusIdentifier) {
      return status
    }
    return .Unknown
  }
}

enum Status: String {
  case InDefinition = "10005"
  case Development = "10055"
  case Testing = "10054"
  case Done = "10011"
  case Unknown = "" // TODO: Use optionals.
}

enum Transition: String {
  case forwardToDevelopment = "231"
  case forwardToTesting = "251"
  case forwardToDone = "161"
  case backToTesting = "281"
  case backToDevelopment = "141"
  case backToInDefinition = "71"
}

struct Timer {
  let task: Task
  let startTime: NSDate
  
  init(task: Task) {
    self.task = task
    startTime = NSDate() // TODO: Revisit auto starting timer.
  }
  
  func secondsSinceStart() -> Int {
    return max(Int(NSDate().timeIntervalSinceDate(startTime)), 60)
  }
  
}

struct JiraUser {
  let username: String
}