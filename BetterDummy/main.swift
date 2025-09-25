//
//  BetterDummy
//
//  Created by @waydabber
//

import Cocoa

let prefs = UserDefaults.standard
var app: AppDelegate!

// TODO: Consider adding error handling for app initialization failures
autoreleasepool { () -> Void in
  let app = NSApplication.shared
  let appDelegate = AppDelegate()
  app.delegate = appDelegate
  app.run()
}
