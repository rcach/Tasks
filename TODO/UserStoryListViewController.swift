import Cocoa

class UserStoryListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
  @IBOutlet weak var tableView: NSTableView!
  // TODO: Make this an unowned reference once you can specify memory management on Swift protocol object references.
  var navigatorOptional: Navigator?
  var userStories = [UserStory]()

  override func viewDidLoad() {
    reload()
  }
  
  func reload() {
    clearSelection()
    userStories.removeAll(keepCapacity: true)
    tableView.reloadData()
    loadDataFromJIRA()
  }
  
  func clearSelection() {
    tableView.deselectAll(self)
  }
  
  func disableList() {
    tableView.enabled = false
  }
  
  func enableList() {
    tableView.enabled = true
  }
  
  func loadDataFromJIRA() {
    navigatorOptional?.disableNavigation()
    disableList()
    getUserStories() { result in
      // TODO: Handle this better.
      if self.view.superview == nil { return }
      
      self.navigatorOptional?.enableNavigation()
      self.enableList()
      switch result {
      case let .Error(error):
        // TODO: Indicate error to user.
        println(error)
        
      case let .Value(userStories):
        self.userStories = userStories
        self.tableView.reloadData()
      }
    }
  }
}

extension UserStoryListViewController {
  // MARK: NSTableViewDataSource
  
  func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
    return userStories.count
  }
  
  // MARK: NSTableViewDelegate
  
  func tableView(tableView: NSTableView!, viewForTableColumn tableColumn: NSTableColumn!, row: Int) -> NSView! {
    if let reusableCellView = tableView.makeViewWithIdentifier(tableColumn.identifier, owner: self) as? NSTableCellView {
      var titleTextField = reusableCellView.textField
      titleTextField.stringValue = userStories[row].summary
      return reusableCellView
    }
    return nil
  }
  
  func tableView(tableView: NSTableView!, selectionIndexesForProposedSelection proposedSelectionIndexes: NSIndexSet!) -> NSIndexSet! {
    if let navigator = navigatorOptional {
      if proposedSelectionIndexes.count > 0 {
        navigator.navigateToUserStoryTaskList(userStories[proposedSelectionIndexes.firstIndex])
      }
    }
    return proposedSelectionIndexes
  }
}
