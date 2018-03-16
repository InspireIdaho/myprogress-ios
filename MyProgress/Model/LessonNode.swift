//  LessonNode.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import Foundation




struct LessonNode : Codable {
    let indexPath: IndexPath
    let title: String
    var hasLab: Bool = false
    var reviewQuestions: Int = 0
    
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
