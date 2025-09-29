//
//  BetterDummy
//
//  Created by @waydabber
//

import Cocoa

// BUG: Global mutable state - can be modified from anywhere, potential security risk
let prefs = UserDefaults.standard
var app: AppDelegate!

autoreleasepool { () -> Void in
  let app = NSApplication.shared
  let appDelegate = AppDelegate()
  app.delegate = appDelegate
  app.run()
}
