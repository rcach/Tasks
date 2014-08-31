import Cocoa

class TableViewRowHeights {
  let tableView: NSTableView
  let defaultHeight: CGFloat
  var customHeights = [Int:Int]()
  
  init(tableView: NSTableView, defaultHeight: CGFloat) {
    self.tableView = tableView
    self.defaultHeight = defaultHeight
  }
  
  func cellNeedsCustomHeight(height: Int, atIndex index:Int) {
    customHeights[index] = height
    tableView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(index: index))
  }
  
  func cellNeedsDefaultHeightAtIndex(index: Int) {
    customHeights.removeValueForKey(index)
    tableView.noteHeightOfRowsWithIndexesChanged(NSIndexSet(index: index))
  }
  
  func clearAllCustomRowHeights() {
    customHeights.removeAll(keepCapacity: true)
  }
  
  func heightForCellAtIndex(index: Int) -> CGFloat {
    if let customHeight = customHeights[index] {
      return CGFloat(customHeight)
    } else {
      return defaultHeight
    }
  }
}