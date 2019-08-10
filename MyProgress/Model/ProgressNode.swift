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

/// provide alignment with MongoDB type name
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
        case dbID = "id"
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
            hasChanges = true
        }
    }
    
    /// track whether in-memory rep has been updated, used to flush changes to server
    var hasChanges: Bool = false
    
    /// optional reference to database ID to sync with server representation
    /// required to delete or update objects
    //var dbID: ObjectID?  // if using Mongo
    var dbID: Int?          // MySQL id

    // MARK: - Computed properties
    
    /// helper computed property
    var hasCompleted: Bool {
        return (completedOn != nil)
    }
    
    var hasDBRep: Bool {
        return (dbID != nil)
    }
    
    /// simple aid for debugging
    var debugDescription: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let completedString = hasCompleted ? "\(dateFormatter.string(from: completedOn!))" : "TODO"
        let dirtyString = hasChanges ? "Changed" : "UnChanged"
        let dbString = (dbID != nil) ? "id(\(dbID!))" : "noID"
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
        self.hasChanges = false
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
    
    // MARK: - Save/Sync state to Server methods

    func syncToServer() {
        // at this point, node was dirty, so needs to be saved
        // upon success, clear dirty flag
        guard hasChanges else { return }
        
        if hasCompleted {
            if hasDBRep {
                // if dbID exists, must update on server
                ServerProxy.updateProgressNode(self)
            } else {
                //if no dbID, then create new on server, get ID back, save in mem
                ServerProxy.createProgressNode(self)
            }
        } else {
            // but if not compl, && has dbID, then will need to delete from server
            if hasDBRep {
                // if dbID exists, must delete from server
                ServerProxy.deleteProgressNode(self)
                self.dbID = nil     // don't delete from registry, as it contains course tree
            } else {
                //if no dbID, no need to do anything,
                print("no need to do anything for: \(self)")
            }
        }
    }

    
    // MARK: - De/Coding methods

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let path: String = try values.decode(String.self, forKey: .indexPath)
        let path2 = path.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        let path3 = path2.filter { $0 != " " }
        let elems = path3.split(separator: ",").map { Int($0)! }
        indexPath = IndexPath(indexes: elems)
        completedOn = try values.decode(Date.self, forKey: .completedOn)
        dbID = try? values.decode(Int.self, forKey: .dbID)
        children = []
        parent = nil
        
        // lookup existing node match, update its state
        let blank = ProgressNode.registry[indexPath]
        blank?.completedOn = completedOn
        blank?.dbID = dbID
        // reset flag, only counts if initiated by user
        blank?.hasChanges = false
    }
    
    func encode(to encoder: Encoder) throws {
        // we only need to save nodes (actually only leafs) that have been completed
        // all internal nodes in graph will calc
        if (hasCompleted) {
            var container = encoder.container(keyedBy: CodingKeys.self)
            let foo = indexPath.description
            try container.encode(foo, forKey: .indexPath)
            try container.encode(completedOn, forKey: .completedOn)
            try container.encode(dbID, forKey: .dbID)
        }
    }
    
    
    // MARK: - Class-level methods

    /**
     Creates a tree-graph of empty (un-completed) ProgressNodes corresponding with the course structure:  Course, Units, Lessons, LessonComponents. Stores reference
     
     - Parameter course: Course struct to map.
     */
    static func createProgressGraph(course: Course) {
        
        if progressNodeGraph == nil {
            progressNodeGraph = course.createProgressNode()
            print("Finished initializing _empty_ ProgressNodes for course")
        }
    }
    
    static func clearRegistry() {
        registry.removeAll()
        progressNodeGraph = nil
    }

    
}

