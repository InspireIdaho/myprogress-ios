//  LessonNode.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import Foundation

/**
 Struct to represent a lesson in the Course.
 Lessons, along with CourseUnits, match up with iBook so don't change (unless book revised)
 However, corresponding ProgressNode tracks participant progress.
 */
struct LessonNode : Codable {
    
    /// indexPath provides simple but powerful representation of nested indices
    /// used as the unique key to loosely-couple with corresponding ProgressNode
    let indexPath: IndexPath
    
    /// title matches iBook lesson title
    let title: String
    
    /// indicate if a lesson has a lab component
    var hasLab: Bool = false
    
    /// record how many questions(total) the review/assessment component consists of
    /// in future, the app may also allow tracking of individual scores, and total will be needed
    /// if zero, then no review exists
    var reviewQuestions: Int = 0
}

extension LessonNode: ProgressTrackable {

    /**
     Method to (recursively) create corresponding ProgressNode for Lesson and its 3 components.
     */
    func createProgressNode() -> ProgressNode {
        // progress for this lesson
        let currentNode = ProgressNode(at: indexPath)
        
        // progress for lesson reading
        currentNode.addChild(ProgressNode(at: indexPath.appending(LessonSection.reading.rawValue)))

        // progress for lesson lab
        if hasLab {
            currentNode.addChild(ProgressNode(at: indexPath.appending(LessonSection.lab.rawValue)))
        }
        
        // progress for review assessment
        if reviewQuestions > 0 {
            currentNode.addChild(ProgressNode(at: indexPath.appending(LessonSection.review.rawValue)))
        }
        
        return currentNode
    }
}



extension LessonNode {
    
    static func saveData(units: [CourseUnit]) {
        let dataURL = URL(
            fileURLWithPath: "lessonData",
            relativeTo: FileManager.documentDirectoryURL
        )
        
        print(dataURL.path)
        
        
        let jsonURL = dataURL.appendingPathExtension("json")
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonEncoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try jsonEncoder.encode(units)
            try jsonData.write(to: jsonURL)
        } catch {
            print(error)
        }

    }
    
    static func loadData() -> [CourseUnit] {

        guard let jsonURL = Bundle.main.url(forResource: "lessonData", withExtension: "json")
            else {
                print("uh oh, no data file")
                return []
        }
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        
        do {
            let jsonData = try Data(contentsOf: jsonURL)
            return try jsonDecoder.decode([CourseUnit].self, from: jsonData)
        } catch {
            print(error)
            return []
        }
        
    }

}
