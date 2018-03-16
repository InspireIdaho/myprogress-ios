//  Course.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import Foundation

struct Course : Codable, ProgressTrackable {
    
    // MARK: - Instance properties

    let title: String
    let version: Int
    let units: [CourseUnit]
    
    func createProgressNode() -> ProgressNode {
        
        let currentNode = ProgressNode(at: IndexPath(indexes: [0]))
        
        for unit in units {
            // ask each unit to create progress
            currentNode.addChild(unit.createProgressNode())
        }
        return currentNode
    }

}

struct CourseUnit : Codable, ProgressTrackable {
    let indexPath: IndexPath
    let title: String
    let lessons: [LessonNode]
    
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

extension Course {
    
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
