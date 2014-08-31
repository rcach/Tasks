import Cocoa


func isStoryRequest(request: NSURLRequest!) -> Bool {
  let body = NSURLProtocol.propertyForKey("HTTPBody", inRequest: request) as? NSData
  let bodyString = NSString(data: body!, encoding: NSUTF8StringEncoding)
  let storyQueryRange = bodyString.rangeOfString("issuetype = Story")
  if storyQueryRange.location != NSNotFound {
    return true
  } else {
    return false
  }
}

func isTaskRequest(request: NSURLRequest!) -> Bool {
  let body = NSURLProtocol.propertyForKey("HTTPBody", inRequest: request) as? NSData
  let bodyString = NSString(data: body!, encoding: NSUTF8StringEncoding)
  let taskQueryRange = bodyString.rangeOfString("issuetype = \'Technical Task\'")
  if taskQueryRange.location != NSNotFound {
    return true
  } else {
    return false
  }
}


func isTransitionRequest(request: NSURLRequest!) -> Bool {
  let pathRange = request.URL.absoluteString!.rangeOfString("/transitions")
  if pathRange != nil && request.HTTPMethod == "POST" {
    return true
  } else {
    return false
  }
}

func isTimeLogRequest(request: NSURLRequest!) -> Bool {
  let pathRange = request.URL.absoluteString!.rangeOfString("/worklog")
  if pathRange != nil && request.HTTPMethod == "POST" {
    return true
  } else {
    return false
  }
}

func isJQLRequest(request: NSURLRequest!) -> Bool {
  let URL = request.URL
  let pathRange = URL.absoluteString!.rangeOfString("/rest/api/2/search")
  let body = NSURLProtocol.propertyForKey("HTTPBody", inRequest: request) as? NSData
  if pathRange != nil && request.HTTPMethod == "POST" && body != nil {
    return true
  } else {
    return false
  }
}

class JiraLocalDataURLProtocol: NSURLProtocol {
  override class func canInitWithRequest(request: NSURLRequest!) -> Bool {
    if isTimeLogRequest(request) { return true }
    if isTransitionRequest(request) { return true }
    if !isJQLRequest(request) { return false }
    if isStoryRequest(request) { return true }
    if isTaskRequest(request) { return true }
    
    return false
  }
  
  override class func canonicalRequestForRequest(request: NSURLRequest!) -> NSURLRequest! {
    return request
  }
  
  override class func requestIsCacheEquivalent(a: NSURLRequest!, toRequest b: NSURLRequest!) -> Bool {
    return super.requestIsCacheEquivalent(a, toRequest: b)
  }
  
  override func startLoading() {
    if isTimeLogRequest(request) {
      startLoadingTimeLog()
    } else if isTransitionRequest(request) {
      startLoadingTransition()
    } else if isStoryRequest(request) {
      startLoadingStories()
    } else if isTaskRequest(request) {
      startLoadingTasks()
    }
  }
  
  func startLoadingStories() {
    dispatch_after_delay(0.5, dispatch_get_main_queue()) {
      let responseAndData = self.responseAndDataForStories(self.request.URL)
      self.client.URLProtocol(self, didReceiveResponse: responseAndData.response, cacheStoragePolicy: .NotAllowed)
      self.client.URLProtocol(self, didLoadData: responseAndData.data)
      self.client.URLProtocolDidFinishLoading(self)
    }
  }
  
  func startLoadingTasks() {
    dispatch_after_delay(0.5, dispatch_get_main_queue()) {
      let responseAndData = self.responseAndDataForTasks(self.request.URL)
      self.client.URLProtocol(self, didReceiveResponse: responseAndData.response, cacheStoragePolicy: .NotAllowed)
      self.client.URLProtocol(self, didLoadData: responseAndData.data)
      self.client.URLProtocolDidFinishLoading(self)
    }
  }
  
  func startLoadingTransition() {
    dispatch_after_delay(0.5, dispatch_get_main_queue()) {
      let response = self.responseForTransition(self.request.URL)
      self.client.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
      self.client.URLProtocolDidFinishLoading(self)
    }
  }
  
  func startLoadingTimeLog() {
    dispatch_after_delay(0.5, dispatch_get_main_queue()) {
      let response = self.responseForTimeLog(self.request.URL)
      self.client.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
      self.client.URLProtocolDidFinishLoading(self)
    }
  }
  
  override func stopLoading() {
    // Do nothing.
  }
  
  func responseAndDataForStories(url: NSURL) -> (response: NSURLResponse, data: NSData) {
    var dataString = "{\"expand\":\"schema,names\",\"startAt\":0,\"maxResults\":15,\"total\":3,\"issues\":[{\"expand\":\"editmeta,renderedFields,transitions,changelog,operations\",\"id\":\"456315\",\"self\":\"https://jira.myDomain.com/rest/api/2/issue/456315\",\"key\":\"PRJ-0001\",\"fields\":{\"summary\":\"Build Login\"}},{\"expand\":\"editmeta,renderedFields,transitions,changelog,operations\",\"id\":\"446937\",\"self\":\"https://jira.myDomain.com/rest/api/2/issue/446937\",\"key\":\"PRJ-0002\",\"fields\":{\"summary\":\"Build Logout\"}},{\"expand\":\"editmeta,renderedFields,transitions,changelog,operations\",\"id\":\"297445\",\"self\":\"https://jira.myDomain.com/rest/api/2/issue/297445\",\"key\":\"PRJ-003\",\"fields\":{\"summary\":\"Build Intro Screen\"}}]}"
    var data = dataString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    
    return (NSURLResponse(URL: url, MIMEType: "application/json", expectedContentLength: data.length, textEncodingName: "utf-8"), data)
  }
  
  func responseAndDataForTasks(url: NSURL) -> (response: NSURLResponse, data: NSData) {
    var dataString = "{\"expand\":\"schema,names\",\"startAt\":0,\"maxResults\":15,\"total\":2,\"issues\":[{\"expand\":\"editmeta,renderedFields,transitions,changelog,operations\",\"id\":\"456317\",\"self\":\"https://jira.myDomain.com/rest/api/2/issue/456317\",\"key\":\"PRJ-0010\",\"fields\":{\"summary\":\"Build View\",\"timetracking\":{\"originalEstimate\":\"2d\",\"remainingEstimate\":\"0d\",\"timeSpent\":\"0h\",\"originalEstimateSeconds\":57600,\"remainingEstimateSeconds\":0,\"timeSpentSeconds\":0},\"status\":{\"self\":\"https://jira.myDomain.com/rest/api/2/status/10005\",\"description\":\"\",\"iconUrl\":\"https://jira.myDomain.com/images/icons/statuses/open.png\",\"name\":\"In Definition\",\"id\":\"10005\",\"statusCategory\":{\"self\":\"https://jira.myDomain.com/rest/api/2/statuscategory/1\",\"id\":1,\"key\":\"todo\",\"colorName\":\"blue\",\"name\":\"Todo\"}}}},{\"expand\":\"editmeta,renderedFields,transitions,changelog,operations\",\"id\":\"456317\",\"self\":\"https://jira.myDomain.com/rest/api/2/issue/456317\",\"key\":\"PRJ-0011\",\"fields\":{\"summary\":\"Build Model\",\"timetracking\":{\"originalEstimate\":\"2d\",\"remainingEstimate\":\"0d\",\"timeSpent\":\"0.6h\",\"originalEstimateSeconds\":57600,\"remainingEstimateSeconds\":0,\"timeSpentSeconds\":2160},\"status\":{\"self\":\"https://jira.myDomain.com/rest/api/2/status/10005\",\"description\":\"\",\"iconUrl\":\"https://jira.myDomain.com/images/icons/statuses/open.png\",\"name\":\"In Definition\",\"id\":\"10005\",\"statusCategory\":{\"self\":\"https://jira.myDomain.com/rest/api/2/statuscategory/1\",\"id\":1,\"key\":\"todo\",\"colorName\":\"blue\",\"name\":\"Todo\"}}}}]}"
    var data = dataString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    
    return (NSURLResponse(URL: url, MIMEType: "application/json", expectedContentLength: data.length, textEncodingName: "utf-8"), data)
  }
  
  func responseForTransition(url: NSURL) -> NSURLResponse {
    return NSHTTPURLResponse(URL: url, statusCode: 204, HTTPVersion: "HTTP/1.1", headerFields: Dictionary<NSString,NSString>())
  }
  
  func responseForTimeLog(url: NSURL) -> NSURLResponse {
    return NSHTTPURLResponse(URL: url, statusCode: 201, HTTPVersion: "HTTP/1.1", headerFields: Dictionary<NSString,NSString>())
  }
}
