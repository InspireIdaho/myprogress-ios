//  IndexPath.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import Foundation

extension IndexPath {
    
    func dotText() -> String {
        return self.reduce("") { result, nextIndex in
            result + String(nextIndex) + "."
        }
    }
}
