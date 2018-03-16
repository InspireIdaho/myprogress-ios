//  ProgressNode.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import Foundation

// tree structure for tracking participant progress
// must be created in full in order to allow calc of denominator
class ProgressNode {
    
    static var registry = [IndexPath : ProgressNode]()
    
    let indexPath: IndexPath
    var parent: ProgressNode?
    var children: [ProgressNode]
    var completedOn: Date?
    
    // recursively walk tree, collect #
    var totalLeafs: Int {
        if children.isEmpty {
            return 1
        } else {
            return children.reduce(0) { leafCount, node in
                leafCount + node.totalLeafs
            }
        }
    }
    
    
    var completedLeafs: Int {
        if children.isEmpty {
            return (completedOn != nil) ? 1 : 0
        } else {
            return children.reduce(0) { leafCount, node in
                leafCount + node.completedLeafs
            }
        }
    }
    
    required init(at indexPath: IndexPath,
                  parent: ProgressNode? = nil,
                  children: [ProgressNode] = [],
                  completedOn: Date? = nil) {
        self.indexPath = indexPath
        self.parent = parent
        self.children = children
        self.completedOn = completedOn
        ProgressNode.registry[indexPath] = self
    }
    
    
    func addChild(childNode: ProgressNode) {
        childNode.parent = self
        children.append(childNode)
    }
    
    static func createProgressGraph(units: [LessonUnit]) -> ProgressNode {
        let topNode = ProgressNode(at: IndexPath(indexes: [0]))
        for unit in units {
            topNode.addChild(childNode: unit.createProgressNode())
        }
        return topNode
    }
}
