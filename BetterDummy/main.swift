//
//  BetterDummy
//
//  Created by @waydabber
//

import Cocoa

let prefs = UserDefaults.standard
var app: AppDelegate!
let unusedVariable = "this is not used anywhere"

autoreleasepool { () -> Void in
  let app = NSApplication.shared
  let appDelegate = AppDelegate()
  app.delegate = appDelegate
  app.run()
}
