//  Course.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.
//
//  Define both Course and CourseUnit

import Foundation

/**
 Struct to represent iBook Course & structure.
 Note version prop; one could forsee revisions to iBook that affect course structure, but it is unused at present.
 */
struct Course : Codable, ProgressTrackable {
    
    /// title matches iBook title
    let title: String
    
    /// version may be need to be used if iBook revised
    let version: Int
    
    /// array of top-level units within iBook
    let units: [CourseUnit]
    
    /**
     Method to (recursively) create corresponding ProgressNode for Course its CourseUnits.
     */
    func createProgressNode() -> ProgressNode {
        
        let currentNode = ProgressNode(at: IndexPath(indexes: [0]))
        
        for unit in units {
            // ask each unit to create progress
            currentNode.addChild(unit.createProgressNode())
        }
        return currentNode
    }

}

/**
 Struct to represent iBook CourseUnit/Lessons.
 */
struct CourseUnit : Codable, ProgressTrackable {
    
    /// indexPath provides simple but powerful representation of nested indices
    /// used as the unique key to loosely-couple with corresponding ProgressNode
    let indexPath: IndexPath
    
    /// title matches iBook unit title
    let title: String
    
    /// array of lessons within unit
    let lessons: [LessonNode]
    
    /**
     Method to (recursively) create corresponding ProgressNode for CourseUnits and its Lessons.
     */
    func createProgressNode() -> ProgressNode {
        // progress for this unit
        let currentNode = ProgressNode(at: indexPath)
        
        for lesson in lessons {
            // ask each lesson to create progress
            currentNode.addChild(lesson.createProgressNode())
        }
        
        return currentNode
    }
}

// MARK: - Class-level methods

extension Course {

    /**
     Supports loading Course data from a json file distributed in app bundle.
     In future, may make sense to host data file on web service, if frequent changes expected.
     (or if other courses/iBooks need to be supported)
     */
    static func loadData() -> Course? {
        
        guard let jsonURL = Bundle.main.url(forResource: "courseData", withExtension: "json")
            else {
                print("uh oh, no data file")
                return nil
        }
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        
        do {
            let jsonData = try Data(contentsOf: jsonURL)
            return try jsonDecoder.decode(Course.self, from: jsonData)
        } catch {
            print(error)
            return nil
        }
        
    }

}
