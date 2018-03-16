//  LessonNode.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import Foundation


struct LessonUnit : Codable {
    let indexPath: IndexPath
    let title: String
    let lessons: [LessonNode]
    
    func createProgressNode() -> ProgressNode {
        // progress for this unit
        let currentNode = ProgressNode(at: indexPath)

        for lesson in lessons {
            // ask each lesson to create progress
            currentNode.addChild(childNode: lesson.createProgressNode())
        }
        
        return currentNode
    }
}

struct LessonNode : Codable {
    let indexPath: IndexPath
    let title: String
    var hasLab: Bool = false
    var reviewQuestions: Int = 0
    
    func createProgressNode() -> ProgressNode {
        // progress for this lesson
        let currentNode = ProgressNode(at: indexPath)
        
        // progress for lesson reading
        currentNode.addChild(childNode: ProgressNode(at: indexPath.appending(LessonSection.reading.rawValue)))

        // progress for lesson lab
        if hasLab {
            currentNode.addChild(childNode: ProgressNode(at: indexPath.appending(LessonSection.lab.rawValue)))
        }
        
        // progress for review assessment
        if reviewQuestions > 0 {
            currentNode.addChild(childNode: ProgressNode(at: indexPath.appending(LessonSection.review.rawValue)))
        }
        
        return currentNode
    }
}

extension LessonNode {
    static func testData() -> [LessonUnit] {
        return
            [LessonUnit(indexPath: IndexPath(indexes: [1]),
                        title: "Unit 1: Getting Started", lessons:
                [
                    LessonNode(
                        indexPath: IndexPath(indexes: [1,1]),
                        title: "Intro to Swift and Playgrounds",
                        hasLab: true, reviewQuestions: 4),
                    LessonNode(
                        indexPath: IndexPath(indexes: [1,2]),
                        title: "Constants, Vars, and Data Types",
                        hasLab: true, reviewQuestions: 7),
                    LessonNode(
                        indexPath: IndexPath(indexes: [1,3]),
                        title: "Operators",
                        hasLab: true, reviewQuestions: 6),
                    LessonNode(
                        indexPath: IndexPath(indexes: [1,4]),
                        title: "Control Flow",
                        hasLab: true, reviewQuestions: 10),
                    LessonNode(
                        indexPath: IndexPath(indexes: [1,5]),
                        title: "Xcode",
                        hasLab: false, reviewQuestions: 6),
                    LessonNode(
                        indexPath: IndexPath(indexes: [1,6]),
                        title: "Building, Running, Debugging",
                        hasLab: false, reviewQuestions: 6),
                    LessonNode(
                        indexPath: IndexPath(indexes: [1,7]),
                        title: "Documentation",
                        hasLab: false, reviewQuestions: 6),
                    LessonNode(
                        indexPath: IndexPath(indexes: [1,8]),
                        title: "Interface Builder Basics",
                        hasLab: false, reviewQuestions: 6),
                    LessonNode(
                        indexPath: IndexPath(indexes: [1,9]),
                        title: "Guided Project - Light",
                        hasLab: false, reviewQuestions: 0),
                    ]
                )
        ]
    }
    
    static func saveData(units: [LessonUnit]) {
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
    
    static func loadData() -> [LessonUnit] {

        guard let jsonURL = Bundle.main.url(forResource: "lessonData", withExtension: "json")
            else {
                print("uh oh, no data file")
                return []
        }
        
        //let jsonURL = dataURL.appendingPathExtension("json")
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        
        do {
            let jsonData = try Data(contentsOf: jsonURL)
            return try jsonDecoder.decode([LessonUnit].self, from: jsonData)
        } catch {
            print(error)
            return []
        }
        
    }

}
