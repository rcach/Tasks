import Foundation

let jiraUsernameUserDefaultsKey = "Tasks.Prefs.JiraUsername"

func isUserLoggedIn() -> Bool {
  if let credentials = userJiraCredentials() {
    return true
  }
  return false
}

func userJiraCredentials() -> (String, String, Unmanaged<SecKeychainItemRef>)? {
  if let username = userJiraUsername() {
    // TODO: Determine if its possible to get the saved password from Safari here and also if
    //  can populate it so that users who log in to the app will have their creds in Safari automatically.
    var passwordLength: UInt32 = 0
    var passwordPtr = UnsafeMutablePointer<Void>()
    var keychainItem: Unmanaged<SecKeychainItemRef>? // TODO: Manage this unmanaged reference.
    let findStatus = SecKeychainFindGenericPassword(nil, 13, "AtlassianJira", UInt32(strlen(username)), username, &passwordLength, &passwordPtr, &keychainItem)
    if findStatus == noErr {
      let password: NSString = NSString(bytesNoCopy: passwordPtr, length: Int(passwordLength), encoding: NSUTF8StringEncoding, freeWhenDone: true)
      return (username, password, keychainItem!)
    }
    return nil
  }
  return nil
}

func logInUsingCredentials(username: String, password: String, onComplete: (didLogIn: Bool) -> ()) {
  getJiraAuthenticatedUser(username, password) { userOrNil, errorOrNil in
    if errorOrNil == nil {
      // TODO: Check that the save was good.
      saveLoginCredentials(username, password)
      onComplete(didLogIn: true)
      return
    }
    onComplete(didLogIn: false)
  }
}

func logOutUser() {
  clearLogInCredentials()
  var url = NSURL(string: "https://jira.myDomain.com")
  let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookiesForURL(url)
  for cookie in cookies {
    NSHTTPCookieStorage.sharedHTTPCookieStorage().deleteCookie(cookie as NSHTTPCookie)
  }
}

func saveLoginCredentials(username: String, password: String) -> Bool {
  // Add New Password to Keychain
  let addStatus = SecKeychainAddGenericPassword(nil, 13, "AtlassianJira", UInt32(strlen(username)), username, UInt32(strlen(password)),password, nil)
  if addStatus == noErr {
    saveUserJiraUsername(username)
    return true
  }
  return false
}

func clearLogInCredentials() {
  if let credentials = userJiraCredentials() {
    let deleteStatus = SecKeychainItemDelete(credentials.2.takeRetainedValue())
    if deleteStatus == noErr { clearUserJiraUsername() }
  }
}

func userJiraUsername() -> String? {
//  return NSUserDefaults.standardUserDefaults().stringForKey(jiraUsernameUserDefaultsKey)
  return "USERNAME"
}

func saveUserJiraUsername(username: String) {
  NSUserDefaults.standardUserDefaults().setObject(username, forKey: jiraUsernameUserDefaultsKey)
  NSUserDefaults.standardUserDefaults().synchronize()
}

func clearUserJiraUsername() {
  NSUserDefaults.standardUserDefaults().removeObjectForKey(jiraUsernameUserDefaultsKey)
}
