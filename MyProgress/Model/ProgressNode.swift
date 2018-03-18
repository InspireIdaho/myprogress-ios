//  ProgressNode.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import Foundation
import Alamofire

/**
 Define method which Course, Units, Lessons must implement to initialize graph of tree structure for tracking progress.
 */
protocol ProgressTrackable {
    
    /**
     Initialize node/graph of tree structure for tracking progress.
     */
    func createProgressNode() -> ProgressNode
}

/// provide reminder to align with MongoDB type name
typealias ObjectID = String

/**
 Basic unit of tree structure for tracking participant progress.
 Full graph must be created from LessonNodes in order to allow calc of denominators (totalLeafs)
 Upon AppOnly updated nodes need to be saved for user.
 Upon launch, saved nodes are loaded and replace placeholders in registry.
 */
class ProgressNode : Codable {
    
    /// keys required to de/encode swift to json
    enum CodingKeys: String, CodingKey {
        case indexPath = "indexPath"
        case completedOn = "completedOn"
        case dbID = "_id"
    }
    
    // MARK: - Class-level properties

    /// singleton dictionary to store/retrieve ProgressNodes; created at launch
    static var registry = [IndexPath : ProgressNode]()
    
    /// root node reference stored at class-level to facilitate saving to file
    static var progressNodeGraph: ProgressNode?

    // MARK: - Instance properties

    /// used as key to match up with LessonNodes
    let indexPath: IndexPath
    
    /// reference to parent to allow tree traversal; nil means top of tree
    var parent: ProgressNode?
    
    /// maintain reference to child nodes in tree, or if empty then this is a leaf
    var children: [ProgressNode]
    
    /// store date of completion (== completed), if nil then not completed
    var completedOn: Date? {
        didSet {
            isDirty = true
        }
    }
    
    /// track whether in-memory rep has been updated, used to flush changes to server
    var isDirty: Bool = false
    
    /// optional reference to database ID to sync with server representation
    /// required to delete or update objects
    var dbID: ObjectID?
    
    // MARK: - Computed properties
    
    /// helper computed property
    var hasCompleted: Bool {
        return (completedOn != nil)
    }
    
    var debugDescription: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let completedString = hasCompleted ? "\(dateFormatter.string(from: completedOn!))" : "TODO"
        let dirtyString = isDirty ? "Changed" : "UnChanged"
        let dbString = (dbID != nil) ? dbID! : "noID"
        return "ProgressNode-\(indexPath)-\(completedString)-\(dirtyString)-\(dbString)"
    }

    /// recursively walk tree, return total # of edge leafs (yah, I know; leaves)
    var totalLeafs: Int {
        if children.isEmpty {
            return 1
        } else {
            return children.reduce(0) { leafCount, node in
                leafCount + node.totalLeafs
            }
        }
    }
    
    /// recursively walk tree, return # of completed leafs
    var completedLeafs: Int {
        if children.isEmpty {
            return hasCompleted ? 1 : 0
        } else {
            return children.reduce(0) { leafCount, node in
                leafCount + node.completedLeafs
            }
        }
    }
    
    // MARK: - Instance methods

    /**
     Designated initializer for ProgressNode.  **Side Effect:** Newly created ProgressNodes are registered (stored) with `ProgressNode.registry` for later retrieval per LessonNode
     
     - Parameter indexPath: key used to match with the corresponding LessonNode
     - Parameter parent: Optional; parent in tree-graph; Cannot be required at `init()` to allow for tree-graph nodes to be created first then subsequently related to each other
     - Parameter children: Array of child nodes. Leaf nodes, by definition, will have empty array.
        Use `addChild(childNode:)` to automatically form tree relationship.
     - Parameter completedOn: Optional; valid Date means *Completed*; nil means *Not Completed*
     - Returns: the ProgressNode
     */
    required init(at indexPath: IndexPath,
                  parent: ProgressNode? = nil,
                  children: [ProgressNode] = [],
                  completedOn: Date? = nil) {
        self.indexPath = indexPath
        self.parent = parent
        self.children = children
        self.completedOn = completedOn
        self.isDirty = false
        ProgressNode.registry[indexPath] = self
    }
    
    
    /**
     Adds given node to child array.  Ensures its parent property is set to `this`.
     
     - Parameter childNode: Node to add.
     */
    func addChild(_ childNode: ProgressNode) {
        childNode.parent = self
        children.append(childNode)
    }
    
    // flatten graph into array, of only nodes that are complete
    func completedNodes() -> [ProgressNode] {
        var completed = [ProgressNode]()
        if hasCompleted {
            completed.append(self)
        } else {
            for child in children {
                completed.append(contentsOf: child.completedNodes())
            }
        }
        return completed
    }
    
    
    // MARK: - De/Coding methods

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        indexPath = try values.decode(IndexPath.self, forKey: .indexPath)
        completedOn = try values.decode(Date.self, forKey: .completedOn)
        dbID = try? values.decode(ObjectID.self, forKey: .dbID)
        children = []
        parent = nil
        
        // lookup existing node match, update its state
        let blank = ProgressNode.registry[indexPath]
        blank?.completedOn = completedOn
        blank?.dbID = dbID
        // reset flag, only counts if initiated by user
        blank?.isDirty = false
    }
    
    func encode(to encoder: Encoder) throws {
        // we only need to save nodes (actually only leafs) that have been completed
        // all internal nodes in graph will calc
        if (hasCompleted) {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(indexPath, forKey: .indexPath)
            try container.encode(completedOn, forKey: .completedOn)
            try container.encode(dbID, forKey: .dbID)
        }
    }
    
    
    // MARK: - Class-level methods

    /**
     Creates a tree-graph of empty (un-completed) ProgressNodes correspondind with the course structure:  Course, Units, Lessons, LessonComponents
     
     - Parameter course: Course struct to map.
     - Returns: single ProgressNode as root(top) of tree
     */
    static func createProgressGraph(course: Course) -> ProgressNode {
        return course.createProgressNode()
    }
    

    
}

