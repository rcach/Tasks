import Cocoa

let installIDUserDefaultsKey = "Tasks.Prefs.InstallID"

class AppDelegate: NSObject, NSApplicationDelegate, BITHockeyManagerDelegate, SUUpdaterDelegate {
  var appWindowController = AppWindowController(windowNibName: "AppWindow")
  
  func applicationWillFinishLaunching(notification: NSNotification!) {
//    setUpSparkle()
  }
  
  func applicationDidFinishLaunching(aNotification: NSNotification?) {
    registerLocalDataURLProtocol()
    generateInstallIDIfNeeded()
//    setUpHockey()
    trackEvent("AppLifecycle", "Launch", "FinishLaunching", "1")
    
    (appWindowController.window.contentView as NSView).wantsLayer = true
    appWindowController.showWindow(self)
    let x = NSWindow.makeFirstResponder(appWindowController.window)
  }

  func applicationWillTerminate(aNotification: NSNotification?) {
    // Insert code here to tear down your application
  }
  
  func registerLocalDataURLProtocol() {
    NSURLProtocol.registerClass(JiraLocalDataURLProtocol.self)
  }
  
  func setUpHockey() {
    // TODO: Integrate feedback UI.
    BITHockeyManager.sharedHockeyManager().configureWithIdentifier("<YourHockeyIDGoesHere>")
    BITHockeyManager.sharedHockeyManager().crashManager.autoSubmitCrashReport = true
    BITHockeyManager.sharedHockeyManager().debugLogEnabled = false
    BITHockeyManager.sharedHockeyManager().delegate = self
    BITHockeyManager.sharedHockeyManager().startManager()
  }
  
  func setUpSparkle() {
    SUUpdater.sharedUpdater().delegate = self
    SUUpdater.sharedUpdater().feedURL = NSURL(string: "https://rink.hockeyapp.net/api/2/apps/<YourHockeyIDGoesHere>")
    SUUpdater.sharedUpdater().sendsSystemProfile = true
    SUUpdater.sharedUpdater().automaticallyChecksForUpdates = true
    SUUpdater.sharedUpdater().automaticallyDownloadsUpdates = true
    SUUpdater.sharedUpdater().checkForUpdatesInBackground()
    
    let systemProfile = BITSystemProfile.sharedSystemProfile()
    NSNotificationCenter.defaultCenter().addObserver(systemProfile, selector: "startUsage", name: NSApplicationDidBecomeActiveNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(systemProfile, selector: "stopUsage", name: NSApplicationWillTerminateNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(systemProfile, selector: "stopUsage", name: NSApplicationWillResignActiveNotification, object: nil)
  }
  
  func userIDForHockeyManager(hockeyManager: BITHockeyManager!, componentManager: BITHockeyBaseManager!) -> String! {
    if let username = userJiraUsername() {
      return username
    }
    return "<Uknown JIRA username>"
  }
  
  func feedParametersForUpdater(updater: SUUpdater!, sendingSystemProfile sendingProfile: Bool) -> [AnyObject]! {
    return BITSystemProfile.sharedSystemProfile().systemUsageData()
  }
  
  @IBAction func showFeedbackWindow(sender: AnyObject) {
    BITHockeyManager.sharedHockeyManager().feedbackManager.showFeedbackWindow()
  }
  
  func generateInstallIDIfNeeded() {
    if let installID = installIDOrNil() {
      return
    }
    generateNewInstallID()
  }
  
  func generateNewInstallID() {
    NSUserDefaults.standardUserDefaults().setObject(NSUUID().UUIDString, forKey: installIDUserDefaultsKey)
    NSUserDefaults.standardUserDefaults().synchronize()
  }
  
}

func installIDOrNil() -> String? {
  return NSUserDefaults.standardUserDefaults().stringForKey(installIDUserDefaultsKey)
}

func installID() -> String {
  if let installID = installIDOrNil() {
    return installID
  }
  return "0"
}

