import Cocoa

protocol Navigator {
  func navigateToUserStoryTaskList(userStory: UserStory)
  func navigateToUserStoryList()
  func disableNavigation()
  func enableNavigation()
}

class AppWindowController: NSWindowController, Navigator {
  @IBOutlet weak var targetView: NSView!
  @IBOutlet weak var navBar: NSView!
  @IBOutlet weak var logoutButton: NSButton!
  @IBOutlet weak var backButton: NSButton!
  @IBOutlet weak var reloadButton: NSButton!
  @IBOutlet weak var navBarTitleTextField: NSTextField!
  var loginViewController = LoginViewController(nibName: "LoginView", bundle: nil)
  var userStoryListViewController = UserStoryListViewController(nibName: "UserStoryListView", bundle: nil)
  var taskListViewController = TaskListViewController(nibName: "TaskListView", bundle: nil)
  var currentViewController: NSViewController?
  var leadingConstraint: NSLayoutConstraint?
  let userStoryListScreenTitle = "My User Stories"

  override func windowDidLoad() {
    super.windowDidLoad()
    
    reloadButton.wantsLayer = true
    
    userStoryListViewController.navigatorOptional = self
    taskListViewController.navigatorOptional = self
    
    navBar.wantsLayer = true
    navBar.layer?.backgroundColor = NSColor.navBarColor().CGColor
    
    backButton.hidden = true
    
    loginViewController.onLogin = {
      self.dismissLoginViewController()
      
      self.presentViewController(self.userStoryListViewController, animated: false)
      
      // TODO: Consolidate this logic.
      self.navBarTitleTextField.stringValue = self.userStoryListScreenTitle
      self.reloadButton.hidden = false
      self.logoutButton.hidden = true
    }
    
//    if isUserLoggedIn() {
      trackScreenView("UserStoryList")
      presentViewController(userStoryListViewController, animated: false)
      
      navBarTitleTextField.stringValue = userStoryListScreenTitle
      reloadButton.hidden = false
      logoutButton.hidden = true
      
//    } else {
//      trackScreenView("Login")
//      presentViewController(loginViewController, animated: false)
//      
//      navBarTitleTextField.stringValue = "Login to JIRA"
//      reloadButton.hidden = true
//      logoutButton.hidden = true
//      
//    }
  }
  
  // MARK: Nav bar UI actions.
  
  @IBAction func logOut(sender: AnyObject) {
    logOutUser()
    dismissUserStoryListViewController()
    presentViewController(loginViewController, animated: false)
    
    navBarTitleTextField.stringValue = "Login to JIRA"
    reloadButton.hidden = true
    logoutButton.hidden = true
  }
  
  @IBAction func reload(sender: AnyObject) {
    if currentViewController == userStoryListViewController {
      userStoryListViewController.reload()
    } else if currentViewController == taskListViewController {
      taskListViewController.reload()
    }
  }
  
  @IBAction func back(sender: NSButton) {
    if currentViewController != taskListViewController { return }
    userStoryListViewController.clearSelection()
    navigateToUserStoryList()
  }
  
  func disableNavigation() {
    backButton.enabled = false
    reloadButton.enabled = false
  }
  
  func enableNavigation() {
    backButton.enabled = true
    reloadButton.enabled = true
  }
  
  
  // MARK: Navigation.
  
  func navigateToUserStoryTaskList(userStory: UserStory) {
    trackScreenView("TaskList")
    taskListViewController.userStoryOptional = userStory
    presentViewController(taskListViewController, animated: true)
    backButton.hidden = false
    logoutButton.hidden = true
    navBarTitleTextField.stringValue = userStory.summary
  }
  
  func navigateToUserStoryList() {
    trackScreenView("UserStoryList")
    backButton.hidden = true
    logoutButton.hidden = true
    navBarTitleTextField.stringValue = userStoryListScreenTitle
    dismissTaskListViewController()
  }
  
  func presentViewController(viewController: NSViewController, animated: Bool) {
    currentViewController = viewController
    let horizontalOffset = CGFloat(animated ? 320.0 : 0.0)
    
    targetView.addSubview(viewController.view)
    viewController.view.translatesAutoresizingMaskIntoConstraints = false
    leadingConstraint = NSLayoutConstraint(
      item: viewController.view,
      attribute: NSLayoutAttribute.Leading,
      relatedBy: NSLayoutRelation.Equal,
      toItem: targetView,
      attribute: NSLayoutAttribute.Leading,
      multiplier: 1.0,
      constant: horizontalOffset)
    let trailingConstraint = NSLayoutConstraint(
      item: viewController.view,
      attribute: NSLayoutAttribute.Trailing,
      relatedBy: NSLayoutRelation.Equal,
      toItem: targetView,
      attribute: NSLayoutAttribute.Trailing,
      multiplier: 1.0,
      constant: 0.0)
    let topConstraint = NSLayoutConstraint(
      item: viewController.view,
      attribute: NSLayoutAttribute.Top,
      relatedBy: NSLayoutRelation.Equal,
      toItem: targetView,
      attribute: NSLayoutAttribute.Top,
      multiplier: 1.0,
      constant: 0.0)
    let bottomConstraint = NSLayoutConstraint(
      item: viewController.view,
      attribute: NSLayoutAttribute.Bottom,
      relatedBy: NSLayoutRelation.Equal,
      toItem: targetView,
      attribute: NSLayoutAttribute.Bottom,
      multiplier: 1.0,
      constant: 0.0)
    targetView.addConstraints([leadingConstraint!, trailingConstraint, topConstraint, bottomConstraint])
    // TODO: Don't call this if on 10.10.
    viewController.viewDidLoad()
    
    if animated {
      var dimmingView = createDimmingView()
      dimmingView.layer?.opacity = 0.0
      targetView.addSubview(dimmingView, positioned: NSWindowOrderingMode.Below, relativeTo: viewController.view)
      
      targetView.layoutSubtreeIfNeeded()
      NSAnimationContext.runAnimationGroup({ animationContext in
        animationContext.allowsImplicitAnimation = true
        animationContext.duration = 0.5
        dimmingView.layer?.opacity = 0.3
        animationContext.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        self.leadingConstraint?.constant = 0.0
        self.targetView.layoutSubtreeIfNeeded()
        }) {
          dimmingView.removeFromSuperview()
        }
    }
  }
  
  func dismissTaskListViewController() {
    if currentViewController != taskListViewController { return }
    targetView.layoutSubtreeIfNeeded()
    
    var dimmingView = createDimmingView()
    dimmingView.layer?.opacity = 0.4
    targetView.addSubview(dimmingView, positioned: NSWindowOrderingMode.Below, relativeTo: taskListViewController.view)
    
    userStoryListViewController.disableList()
    
    
    NSAnimationContext.runAnimationGroup({ animationContext in
      animationContext.allowsImplicitAnimation = true
      animationContext.duration = 0.4
      dimmingView.layer?.opacity = 0.0
      animationContext.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
      self.leadingConstraint?.constant = 320.0
      self.targetView.layoutSubtreeIfNeeded()
      }) {
        self.userStoryListViewController.enableList()
        
        dimmingView.removeFromSuperview()
        if let vc = self.currentViewController {
          if let view = vc.view {
            view.removeFromSuperview()
          }
        }
        self.currentViewController = self.userStoryListViewController
        self.taskListViewController.clearList()
    }
  }
  
  func dismissLoginViewController() {
    if currentViewController != loginViewController { return }
    loginViewController.view.removeFromSuperview()
  }
  
  func dismissUserStoryListViewController() {
    if currentViewController != userStoryListViewController { return }
    userStoryListViewController.view.removeFromSuperview()
  }
  
  func createDimmingView() -> NSView {
    var dimmingView = NSView(frame: targetView.bounds)
    dimmingView.wantsLayer = true
    dimmingView.layer?.backgroundColor = NSColor.blackColor().CGColor
    return dimmingView
  }
}
