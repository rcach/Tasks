import Cocoa

class TaskListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
  @IBOutlet weak var tableView: NSTableView!
  // TODO: Make this an unowned reference once you can specify memory management on Swift protocol object references.
  var navigatorOptional: Navigator?
  var userStoryOptional: UserStory?
  var tasks = [Task]()
  var isDisplayingData = false
  var rowHeightsOptional: TableViewRowHeights?
  let defaultRowHeight: CGFloat = 145

  override func viewDidLoad() {
    self.rowHeightsOptional = TableViewRowHeights(tableView: tableView, defaultHeight: defaultRowHeight)
    reload()
  }
  
  func reload() {
    clearList()
    loadDataFromJIRA()
  }
  
  func clearList() {
    isDisplayingData = false
    tasks.removeAll(keepCapacity: true)
    rowHeightsOptional?.clearAllCustomRowHeights()
    tableView.reloadData()
  }
  
  func loadDataFromJIRA() {
    navigatorOptional?.disableNavigation()
    if let userStory = userStoryOptional {
      getUserStoryTasks(userStory) { result in
        dispatch_async(dispatch_get_main_queue()) {
          // TODO: Handle this better.
          if self.view.superview == nil { return }
          
          self.navigatorOptional?.enableNavigation()
          switch result {
          case let .Error(error):
            println(error)
            
          case let .Value(tasks):
            self.tasks = tasks
            self.isDisplayingData = true
            self.tableView.reloadData()
          }
        }
      }
    }
  }
  
}

extension TaskListViewController {
  // MARK: NSTableViewDataSource
  
  func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
    if !isDisplayingData {
      return 8
    }
    return tasks.count
  }
  
  
  // MARK: NSTableViewDelegate
  
  func tableView(tableView: NSTableView!, viewForTableColumn tableColumn: NSTableColumn!, row: Int) -> NSView! {
    if let reusableCellView = tableView.makeViewWithIdentifier(tableColumn.identifier, owner: self) as? TaskTableCellView {
      reusableCellView.rowHeightsOrNil = rowHeightsOptional
      reusableCellView.indexOrNil = row
      var titleTextField = reusableCellView.textField
      if isDisplayingData {
        titleTextField.stringValue = tasks[row].summary
        reusableCellView.handler = TaskUIHandler(task: tasks[row])
        reusableCellView.updateWithTask(tasks[row])
      } else {
        titleTextField.stringValue = ""
        reusableCellView.transitionToState(TaskCellState.Empty)
      }
      
      return reusableCellView
    }
    return nil
  }
  
  func tableView(tableView: NSTableView!, selectionIndexesForProposedSelection proposedSelectionIndexes: NSIndexSet!) -> NSIndexSet! {
    return nil
  }
  
  func tableView(tableView: NSTableView!, heightOfRow row: Int) -> CGFloat {
    // TODO: Use autolayout to figure out row height.
    if let heights = rowHeightsOptional {
      return heights.heightForCellAtIndex(row)
    }
    return defaultRowHeight
  }

}
