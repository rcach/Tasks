import Foundation

let appName = "Tasks"
let appVersion = "0.1.4" // TODO: Get this from the bundle.
let appID = "com.mm.tasks"

func trackEvent(eventCategory: String, eventAction: String, eventLabel: String, eventValue: String) {
  return // Comment out if want to use analytics.
  
  // TODO: Build user agent string.
  let trackingID = "UA-XXXXXXXX-1"
  let url = NSURL(string: "https://ssl.google-analytics.com/collect")
  let anonymousClientID = installID()
  let hitType = "event"
  
  var bodyString = "v=1&tid=\(trackingID)&cid=\(anonymousClientID)&t=\(hitType)&ec=\(eventCategory)&ea=\(eventAction)&el=\(eventLabel)&ev=\(eventValue)&an=\(appName)&av=\(appVersion)&aid=\(appID)"
  
  var urlRequest = NSMutableURLRequest(URL: url)
  urlRequest.HTTPMethod = "POST"
  urlRequest.HTTPBody = bodyString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
//  urlRequest.setValue("Mozilla/5.0 (iPad; CPU OS 7_0 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) CriOS/30.0.1599.12 Mobile/11A465 Safari/8536.25 (3B92C18B-D9DE-4CB7-A02A-22FD2AF17C8F)", forHTTPHeaderField: "User-Agent")
  
  let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) { dataOrNil, responseOrNil, errorOrNil in
    if let error = errorOrNil {
      println("Error attempting to post event to Google Analytics. Error: \(error)")
      return
    }
    
    if let httpResponse = responseOrNil as? NSHTTPURLResponse {
      if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300  {
        return
      }
      println("Error attempting to post event to Google Analytics. HTTP status code: \(httpResponse.statusCode)")
    }
  }
  dataTask.resume()
}

func trackScreenView(screenName: String) {
  return // Comment out if want to use analytics.
  
  // TODO: Build user agent string.
  let trackingID = "UA-XXXXXXXX-1"
  let url = NSURL(string: "https://ssl.google-analytics.com/collect")
  let anonymousClientID = installID()
  let hitType = "screenview"
  
  var bodyString = "v=1&tid=\(trackingID)&cid=\(anonymousClientID)&t=\(hitType)&an=\(appName)&av=\(appVersion)&aid=\(appID)&cd=\(screenName)"
  
  var urlRequest = NSMutableURLRequest(URL: url)
  urlRequest.HTTPMethod = "POST"
  urlRequest.HTTPBody = bodyString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
//  urlRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 6_1_4 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10B350 Safari/8536.25", forHTTPHeaderField: "User-Agent")
  
  let dataTask = NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) { dataOrNil, responseOrNil, errorOrNil in
    if let error = errorOrNil {
      println("Error attempting to post event to Google Analytics. Error: \(error)")
      return
    }
    
    if let httpResponse = responseOrNil as? NSHTTPURLResponse {
      if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300  {
        return
      }
      println("Error attempting to post event to Google Analytics. HTTP status code: \(httpResponse.statusCode)")
    }
  }
  dataTask.resume()
}