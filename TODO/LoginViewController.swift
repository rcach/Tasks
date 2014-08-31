import Cocoa
import Security

enum LoginScreenState {
  case UserInput
  case LoggingIn
  case LogInError
}

class LoginViewController: NSViewController, NSTextFieldDelegate {
  @IBOutlet weak var usernameTextField: NSTextField!
  @IBOutlet weak var passwordTextField: NSSecureTextField!
  @IBOutlet weak var loginButton: NSButton!
  @IBOutlet weak var activityIndicator: NSProgressIndicator!
  @IBOutlet weak var errorLabel: NSTextField!
  var onLogin: (()->())?

  override func viewDidLoad() {
    transitionToState(.UserInput)
    dispatch_async(dispatch_get_main_queue()) {
      self.usernameTextField.window?.makeFirstResponder(self.usernameTextField)
      return
    }
  }
    
  @IBAction func userDidTypeUsername(sender: NSTextField) {
    passwordTextField.becomeFirstResponder()
  }
  
  @IBAction func logIn(sender: AnyObject) {
    logInUsingCredentials(usernameTextField.stringValue, passwordTextField.stringValue) { didLogIn in
      dispatch_async(dispatch_get_main_queue()) {
        if didLogIn {
          self.onLogin?()
          self.passwordTextField.stringValue = ""
        }
        else { self.transitionToState(.LogInError) }
      }
    }
    transitionToState(.LoggingIn)
  }
  
  func transitionToState(state: LoginScreenState) {
    switch state {
    case .UserInput:
      activityIndicator.stopAnimation(self)
      usernameTextField.enabled = true
      passwordTextField.enabled = true
      loginButton.title = "Login"
      errorLabel.hidden = true
    case .LoggingIn:
      activityIndicator.startAnimation(self)
      usernameTextField.enabled = false
      passwordTextField.enabled = false
      loginButton.title = ""
      errorLabel.hidden = true
    case .LogInError:
      activityIndicator.stopAnimation(self)
      activityIndicator.stopAnimation(self)
      usernameTextField.enabled = true
      passwordTextField.enabled = true
      loginButton.title = "Login"
      errorLabel.hidden = false
    }
  }
  
  func control(control: NSControl!, textView: NSTextView!, doCommandBySelector commandSelector: Selector) -> Bool {
    switch commandSelector {
    case "insertNewline:":
      logIn(self)
    case "insertTab:":
      usernameTextField.becomeFirstResponder()
    default:
      return true
    }
    return true
  }
  
}
