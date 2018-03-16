//  FileManager.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import UIKit

public extension FileManager {
   
  static var documentDirectoryURL: URL {
    return try! FileManager.default.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: false
    )
  }
  
}
