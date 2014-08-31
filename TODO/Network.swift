import Foundation

// TODO: Handle and display errors!

typealias JSON = AnyObject
typealias JSONDictionary = Dictionary<String, JSON>
typealias JSONArray = Array<JSON>

// TODO: Use generic for value type once Swift compiler bug is fixed.
enum NetworkJSONResult {
  case Error(NSError)
  case Value([UserStory])
}

enum NetworkJSONResultTasks {
  case Error(NSError)
  case Value([Task])
}

func JSONInt(object: JSON?) -> Int? {
  return object as? Int
}

func JSONString(object: JSON?) -> String? {
  return object as? String
}

func JSONObjects(object: JSON?) -> JSONArray? {
  return object as? JSONArray
}

func JSONObject(object: JSON?) -> JSONDictionary? {
  return object as? JSONDictionary
}


func getJiraAuthenticatedUser(username: String, password: String, onComplete: (user: JiraUser?, error: NSError?) -> ()) {
  let rawCredentialData = "\(username):\(password)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
  let authValue = "Basic \(rawCredentialData.base64EncodedStringWithOptions(nil))"
  
  var urlRequest = NSMutableURLRequest(URL: NSURL(string: "https://jira.myDomain.com/rest/api/2/myself"))
  urlRequest.HTTPMethod = "GET"
  urlRequest.setValue(authValue, forHTTPHeaderField: "Authorization")
  
  var dataTask = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) { data, response, errorOrNil in
    dispatch_async(dispatch_get_main_queue()) {
      if let error = errorOrNil {
        onComplete(user:nil, error: error)
        return
      }
      if let httpResponse = response as? NSHTTPURLResponse {
        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300  {
          // TODO: Parse the user.
          onComplete(user: JiraUser(username: "ThisIsNotARealUsername"), error: nil)
          return
        }
      }
      // TODO: Use meaningful error codes.
      onComplete(user: nil, error: NSError(domain: "com.mm.tasks", code: 10, userInfo: nil))
    }
  }
  dataTask.resume()
}

// TODO: Move out to another file.
func sharedDateFormatter() -> NSDateFormatter {
  var threadDictionary = NSThread.currentThread().threadDictionary
  var dateFormatterOptional = threadDictionary["com.mm.tasks.dateformatter"] as? NSDateFormatter
  if let dateFormatter = dateFormatterOptional {
    return dateFormatter
  } else {
    var dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    let startedTimestamp = dateFormatter.stringFromDate(NSDate())
    NSThread.currentThread().threadDictionary["com.mm.tasks.dateformatter"] = dateFormatter
    return dateFormatter
  }
}

func logTimeInSeconds(numberOfSeconds: Int, hoursRemaining numberOfHoursRemaining:Int, toTask task:Task, onComplete: (error: NSError?) -> ()){
  let startedTimestamp = sharedDateFormatter().stringFromDate(NSDate())
  let authValue = HTTPAuthHeaderValue()
  
  var urlRequest = NSMutableURLRequest(URL: NSURL(string: "https://jira.myDomain.com/rest/api/2/issue/\(task.identifier)/worklog?adjustEstimate=new&newEstimate=\(numberOfHoursRemaining)h"))
  urlRequest.HTTPMethod = "POST"
  urlRequest.setValue(authValue, forHTTPHeaderField: "Authorization")
  urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
  urlRequest.HTTPBody = "{\"started\":\"\(startedTimestamp)\",\"timeSpentSeconds\":\(numberOfSeconds)}".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
  
  var dataTask = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) { data, response, errorOrNil in
    dispatch_async(dispatch_get_main_queue()) {
      if let error = errorOrNil {
        onComplete(error: error)
        return
      }
      if let httpResponse = response as? NSHTTPURLResponse {
        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300  {
          // TODO: Parse for new total time spent so the UI can update.
          onComplete(error: nil)
          return
        }
      }
      // TODO: Use meaningful error codes.
      onComplete(error: NSError(domain: "com.mm.tasks", code: 10, userInfo: nil))
    }
  }
  dataTask.resume()
}

func markTaskAsDoing(task: Task, onComplete: (error: NSError?) -> ()) {
  if task.status() == Status.InDefinition {
    transitionTask(task.identifier, transition:Transition.forwardToDevelopment) { transtion, errorOrNil in onComplete(error: errorOrNil) }
    return
  }
  if task.status() == Status.Development || task.status() == Status.Testing {
    dispatch_async(dispatch_get_main_queue()) {
      // TODO: Use meaningful error codes.
      onComplete(error: NSError(domain: "com.mm.tasks", code: 10, userInfo: nil))
    }
    return
  }
  if task.status() == Status.Done {
    transitionTask(task.identifier, transition:Transition.backToTesting) { transtion, errorOrNilFirst in
      if let error = errorOrNilFirst {
        onComplete(error: error)
      }
      transitionTask(task.identifier, transition: Transition.backToDevelopment) { transtion, errorOrNilSecond in onComplete(error: errorOrNilSecond) }
    }
    return
  }
}

// TODO: Handle case when task has been updated in JIRA outside of the app, handle errors and reload UI.
// TODO: This function / logic needs clean up.
func markTaskAsDone(task: Task, onComplete: (error: NSError?) -> ()) {
  var firstTransition = Transition.forwardToTesting
  if task.status() == Status.Testing {
    firstTransition = Transition.forwardToDone
  } else if task.status() == Status.InDefinition {
    firstTransition = Transition.forwardToDevelopment
  }
  
  transitionTask(task.identifier, transition:firstTransition) { transitionFinishedOne, errorOrNil in
    if let error = errorOrNil {
      onComplete(error: error)
      return
    }
    
    var secondTransition = Transition.forwardToDone
    if transitionFinishedOne == Transition.forwardToDevelopment {
      secondTransition = Transition.forwardToTesting
    } else if transitionFinishedOne == Transition.forwardToTesting {
      secondTransition = Transition.forwardToDone
    } else {
      onComplete(error: nil)
      return
    }

    transitionTask(task.identifier, transition:secondTransition) { transitionFinishedTwo, errorOrNil in
      if let error = errorOrNil {
        onComplete(error: error)
        return
      }
      if transitionFinishedTwo == Transition.forwardToTesting {
        transitionTask(task.identifier, transition:Transition.forwardToDone) { transitionFinishedThree, errorOrNil in onComplete(error: errorOrNil) }
      } else {
        onComplete(error: nil)
      }
    }
  }
}

func transitionTask(taskIdentifier: String, #transition: Transition, onComplete: (transition: Transition, error: NSError?) -> ()) {
  let authValue = HTTPAuthHeaderValue()
  
  var urlRequest = NSMutableURLRequest(URL: NSURL(string: "https://jira.myDomain.com/rest/api/2/issue/\(taskIdentifier)/transitions"))
  urlRequest.HTTPMethod = "POST"
  urlRequest.setValue(authValue, forHTTPHeaderField: "Authorization")
  urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
  urlRequest.HTTPBody = "{ \"transition\": { \"id\": \"\(transition.toRaw())\" } }".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
  
  var dataTask = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) { data, response, errorOrNil in
    dispatch_async(dispatch_get_main_queue()) {
      if let error = errorOrNil {
        onComplete(transition:transition, error: error)
        return
      }
      
      if let httpResponse = response as? NSHTTPURLResponse {
        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300  {
          onComplete(transition:transition, error: nil)
          return
        }
      }
      
      // TODO: Use meaningful error codes.
      onComplete(transition:transition, error: NSError(domain: "com.mm.tasks", code: 10, userInfo: nil))
    }
  }
  dataTask.resume()
}

func getUserStories(onComplete: (NetworkJSONResult) -> ()) {
  var username = ""
  if let jiraUsername = userJiraUsername() {
    username = jiraUsername
  }

  var JQL = "{\"jql\": \"project = PRJ AND issuetype = Story AND assignee = \(username)\",\"startAt\": 0,\"maxResults\": 15,\"fields\": [\"summary\"]}"
  var urlRequest = URLRequestForJQL(JQL)
  NSURLProtocol.setProperty(urlRequest.HTTPBody, forKey: "HTTPBody", inRequest: urlRequest)
  var dataTask = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) { data, response, errorOrNil in
    dispatch_async(dispatch_get_main_queue()) {
      // Network error.
      if let error = errorOrNil {
        onComplete(.Error(error))
        return
      }
      
      // TODO: Handle HTTP error status code.
      //      if let httpResponse = response as? NSHTTPURLResponse {
      //        let statusCode = httpResponse.statusCode
      //      }
      
      // Deserialize data.
      var jsonErrorOptional: NSError?
      let jsonOptional: JSON! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
      if let jsonError = jsonErrorOptional {
        onComplete(.Error(jsonError))
        return
      }
      
      // Parse data.
      var userStories = [UserStory]()
      if let json = JSONObject(jsonOptional) {
        if let issues = JSONObjects(json["issues"]) {
          for issue in issues as [JSONDictionary] {
            if let identifier = JSONString(issue["id"]) {
              if let key = JSONString(issue["key"]) {
                if let fields = JSONObject(issue["fields"]) {
                  if let summary = JSONString(fields["summary"]) {
                    let userStory = UserStory(identifier: identifier, key: key, summary: summary)
                    userStories.append(userStory)
                  }
                }
              }
            }
          }
        }
      }
      
      // Done, return stories.
      onComplete(.Value(userStories))
    }
  }
  
  dataTask.resume()
}

func getUserStoryTasks(story: UserStory, onComplete: (NetworkJSONResultTasks) -> ()) {
  var username = ""
  if let jiraUsername = userJiraUsername() {
    username = jiraUsername
  }
  
  var JQL = "{\"jql\": \"project = PRJ AND issuetype = \'Technical Task\' AND assignee = \(username) AND parent = \(story.key)\",\"startAt\": 0,\"maxResults\": 15,\"fields\": [\"summary\",\"status\",\"timetracking\"]}"
  var urlRequest = URLRequestForJQL(JQL)
  NSURLProtocol.setProperty(urlRequest.HTTPBody, forKey: "HTTPBody", inRequest: urlRequest)
  var dataTask = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) { data, response, errorOrNil in
    dispatch_async(dispatch_get_main_queue()) {
      // Network error.
      if let error = errorOrNil {
        onComplete(.Error(error))
        return
      }
      
      // TODO: Handle HTTP error status code.
      //      if let httpResponse = response as? NSHTTPURLResponse {
      //        let statusCode = httpResponse.statusCode
      //      }
      
      // Deserialize data.
      var jsonErrorOptional: NSError?
      let jsonOptional: JSON! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &jsonErrorOptional)
      if let jsonError = jsonErrorOptional {
        onComplete(.Error(jsonError))
        return
      }
      
      // Parse data.
      var tasks = [Task]()
      if let json = JSONObject(jsonOptional) {
        if let issues = JSONObjects(json["issues"]) {
          for issue in issues as [JSONDictionary] {
            var timeSpent: Int = 0
            if let identifier = JSONString(issue["id"]) {
              if let key = JSONString(issue["key"]) {
                if let fields = JSONObject(issue["fields"]) {
                  if let summary = JSONString(fields["summary"]) {
                    if let status = JSONObject(fields["status"]) {
                      if let statusIdentifier = JSONString(status["id"]) {
                        if let timetracking = JSONObject(fields["timetracking"]) {
                          if let timeSpentSeconds = JSONInt(timetracking["timeSpentSeconds"]) {
                            timeSpent = timeSpentSeconds
                          }
                        }
                        let task = Task(identifier: identifier, key: key, summary: summary, statusIdentifier: statusIdentifier, timeSpentSeconds: timeSpent)
                        tasks.append(task)
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      // Done, return stories.
      onComplete(.Value(tasks))
    }
  }
  
  dataTask.resume()
}

func URLRequestForJQL(JQL: String) -> NSMutableURLRequest {
  let authValue = HTTPAuthHeaderValue()
  
  var urlRequest = NSMutableURLRequest(URL: NSURL(string: "https://jira.myDomain.com/rest/api/2/search"))
  urlRequest.HTTPMethod = "POST"
  urlRequest.setValue(authValue, forHTTPHeaderField: "Authorization")
  urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
  urlRequest.HTTPBody = JQL.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
  
  return urlRequest
}

func HTTPAuthHeaderValue() -> String {
  if let creds = userJiraCredentials() {
    let rawCredentialData = "\(creds.0):\(creds.1)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    return "Basic \(rawCredentialData.base64EncodedStringWithOptions(nil))"
  }
  // TODO: Assert or throw excpetion.
  return ""
}
