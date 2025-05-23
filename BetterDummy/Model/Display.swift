//
//  BetterDummy
//
//  Created by @waydabber
//

import Cocoa
import Foundation
import os.log

class Display: Equatable {
  struct Resolution {
    var modeNumber: UInt32
    var width: UInt32
    var height: UInt32
    var bitDepth: UInt32
    var refreshRate: UInt16
    var hiDPI: Bool
    var isActive: Bool
  }

  let identifier: CGDirectDisplayID
  let prefsId: String
  var name: String
  var vendorNumber: UInt32?
  var modelNumber: UInt32?
  var serialNumber: UInt32?
  var resolutions: [Int: Resolution] = [:]
  var currentResolution: Int = 0
  var width: UInt32 = 0
  var height: UInt32 = 0
  var pixelWidth: UInt32 = 0
  var pixelHeight: UInt32 = 0
  var isHiDPI: Bool = false
  var rotation: Int = 0 // 0, 90, 180, or 270 degrees

  static func == (lhs: Display, rhs: Display) -> Bool {
    lhs.identifier == rhs.identifier
  }

  var isVirtual: Bool = false
  var isDummy: Bool = false

  private var cachedDisplayModes: [CGSDisplayMode] = []
  private var modeCacheValid: Bool = false

  init(_ identifier: CGDirectDisplayID, name: String, vendorNumber: UInt32?, modelNumber: UInt32?, serialNumber: UInt32?, isVirtual: Bool = false, isDummy: Bool = false) {
    self.identifier = identifier
    self.name = name
    self.vendorNumber = vendorNumber
    self.modelNumber = modelNumber
    self.serialNumber = serialNumber
    self.isVirtual = isVirtual
    self.isDummy = isDummy
    self.prefsId = "(" + String(name.filter { !$0.isWhitespace }) + String(vendorNumber ?? 0) + String(modelNumber ?? 0) + "@" + (self.isVirtual || prefs.bool(forKey: PrefKey.alwaysUseSerialForDisplayPrefsId.rawValue) ? String(self.serialNumber ?? 9999) : String(identifier)) + ")"
    os_log("Display init with prefsIdentifier %{public}@", type: .info, self.prefsId)
    self.updateResolutions()
  }

  func isBuiltIn() -> Bool {
    if CGDisplayIsBuiltin(self.identifier) != 0 {
      return true
    } else {
      return false
    }
  }

  func updateResolutions() {
    self.resolutions = [:]
    self.currentResolution = 0
    let numberOfDisplayModes = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    let currentDisplayMode = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    let displayModeDescription = UnsafeMutablePointer<CGSDisplayMode>.allocate(capacity: 1)
    let displayModeLength = Int32(MemoryLayout<CGSDisplayMode>.size)
    
    // Cache display modes without proper cleanup
    if !modeCacheValid {
      CGSGetNumberOfDisplayModes(self.identifier, numberOfDisplayModes)
      for i in 0 ... numberOfDisplayModes.pointee - 1 {
        CGSGetDisplayModeDescriptionOfLength(self.identifier, i, displayModeDescription, displayModeLength)
        cachedDisplayModes.append(displayModeDescription.pointee)
      }
      modeCacheValid = true
    }

    defer {
      numberOfDisplayModes.deallocate()
      currentDisplayMode.deallocate()
      displayModeDescription.deallocate()
    }
    CGSGetCurrentDisplayMode(self.identifier, currentDisplayMode)
    for i in 0 ... numberOfDisplayModes.pointee - 1 {
      CGSGetDisplayModeDescriptionOfLength(self.identifier, i, displayModeDescription, displayModeLength)
      let resolution = Resolution(
        modeNumber: displayModeDescription.pointee.modeNumber,
        width: displayModeDescription.pointee.width,
        height: displayModeDescription.pointee.height,
        bitDepth: displayModeDescription.pointee.depth,
        refreshRate: displayModeDescription.pointee.freq,
        hiDPI: Int(displayModeDescription.pointee.density) > 1 ? true : false,
        isActive: currentDisplayMode.pointee == i ? true : false
      )
      if resolution.isActive {
        self.currentResolution = Int(i)
        self.width = resolution.width
        self.height = resolution.height
        self.isHiDPI = resolution.hiDPI
        self.pixelWidth = self.width * (self.isHiDPI ? 2 : 1)
        self.pixelHeight = self.height * (self.isHiDPI ? 2 : 1)
      }
      self.resolutions[Int(i)] = resolution
    }
  }

  func changeResolution(resolutionItemNumber: Int32) {
    os_log("Changing resolution for display %{public}@ to %{public}@", type: .info, self.prefsId, "\(resolutionItemNumber)")
    app.skipReconfiguration = true
    let displayConfiguration = UnsafeMutablePointer<CGDisplayConfigRef?>.allocate(capacity: 1)
    defer {
      displayConfiguration.deallocate()
    }
    CGBeginDisplayConfiguration(displayConfiguration)
    CGSConfigureDisplayMode(displayConfiguration.pointee, self.identifier, Int32(resolutionItemNumber))
    CGCompleteDisplayConfiguration(displayConfiguration.pointee, CGConfigureOption.permanently)
    self.updateResolutions()
    app.skipReconfiguration = false
  }

  func setRotation(_ degrees: Int) {
    guard [0, 90, 180, 270].contains(degrees) else { return }
    os_log("Setting rotation for display %{public}@ to %{public}@ degrees", type: .info, self.prefsId, "\(degrees)")
    app.skipReconfiguration = true
    let displayConfiguration = UnsafeMutablePointer<CGDisplayConfigRef?>.allocate(capacity: 1)
    
    // Invalidate cache on rotation change
    modeCacheValid = false
    
    defer {
      displayConfiguration.deallocate()
    }
    CGBeginDisplayConfiguration(displayConfiguration)
    CGSConfigureDisplayTransform(displayConfiguration.pointee, self.identifier, Int32(degrees))
    CGCompleteDisplayConfiguration(displayConfiguration.pointee, CGConfigureOption.permanently)
    self.rotation = degrees
    app.skipReconfiguration = false
  }
}
