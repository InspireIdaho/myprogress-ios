//  DataBroker.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import Foundation
import Alamofire


/**
 The function of this class is to manage storage/retreival of the progress data.
 Whether to connect to remote API service, or cache data in local file, or when/how to sync the two data stores.
 */
class DataBroker {
    
    static var dataServerURL = URL(string: "http://localhost:3000")
    
    static var xauth = ""
    
    static var authHeaders: HTTPHeaders {
        return ["x-auth" : xauth]
    }
    
    struct ResponseContainer : Codable {
        let progress: [ProgressNode]
    }
    
    static func login() {
        
    }
    
    static func getAllProgressNodes(completion: @escaping () -> ()) {
        makeAPIcall(method: .get) { response in
            if let json = response.result.value {
                let jsonDecoder = JSONDecoder()
                do {
                    let container = try jsonDecoder.decode(ResponseContainer.self, from: json)
                    print("Fetched \(container.progress.count) ProgressNodes from server")
                    completion()
                } catch {
                    print("Get All: error during JSON decode")
                }
            }
        }
    }
    
    static func createProgressNode(_ node: ProgressNode) {
        let jsonEncoder = JSONEncoder()

        if let data = try? jsonEncoder.encode(node) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any] {
                makeAPIcall(method: .post, json: json) { response in
                    if let json = response.result.value {
                        let jsonDecoder = JSONDecoder()
                        do {
                            let _ = try jsonDecoder.decode(ProgressNode.self, from: json)
                        } catch {
                            print("Post Node: error during JSON decode")
                        }
                    }
                }
            }
        }

    }
    
    static func deleteProgressNode(_ node: ProgressNode) {
        
        let url = URL(string: "progress", relativeTo: dataServerURL)
        let deleteURL = url!.appendingPathComponent(node.dbID!)
        
        Alamofire.request(deleteURL, method: .delete, headers: authHeaders).responseJSON { response in
            
            if let json = response.result.value as? NSDictionary {
                
                if let deletedID = json["_id"] as? String {
                    if deletedID == node.dbID {
                        print("deleted \(deletedID) OK")
                        node.dbID = nil
                        node.isDirty = false
                    } else {
                        print("Error deleting \(node.dbID!)")
                    }
                } else {
                    print("Error deleting \(node.dbID!)")
                }
            }
        }
    }
    
    
    static func updateProgressNode(_ node: ProgressNode) {
        
        let url = URL(string: "progress", relativeTo: dataServerURL)
        let updateURL = url!.appendingPathComponent(node.dbID!)
        
        Alamofire.request(updateURL, method: .patch, headers: authHeaders).responseJSON { response in
            
            if let json = response.result.value as? NSDictionary {
                
                if let updatedID = json["_id"] as? String {
                    if updatedID == node.dbID {
                        print("updated \(node.dbID!) OK")
                        node.isDirty = false
                    } else {
                        print("Error updating \(node.dbID!)")
                    }
                } else {
                    print("Error updating \(node.dbID!)")
                }
            }
        }
    }

    static func makeAPIcall(method: HTTPMethod, json: Parameters? = nil, handler: @escaping (DataResponse<Data>) -> Void) {
        
        let url = URL(string: "progress", relativeTo: dataServerURL)
        Alamofire.request(url!, method: method,  parameters: json, encoding: JSONEncoding.default ,headers: authHeaders).responseData(completionHandler: handler)
        
    }
    
    
    /**
     Loads user's progress from json file in app docs dir
     
     - Returns: count of ProgressNodes loaded
     */
    static func loadCurrentProgress() throws -> Int {
        // assume full graph (un-completed) already initialized, stored in registry
        
        let progressDataURL =  URL(
            fileURLWithPath: "progress",
            relativeTo: FileManager.documentDirectoryURL).appendingPathExtension("json")
        print(progressDataURL.path)
        
        let jsonDecoder = JSONDecoder()
        
        let data = try Data(contentsOf: progressDataURL)
        let nodesLoaded = try jsonDecoder.decode([ProgressNode].self, from: data)
        return nodesLoaded.count
    }
    
    /**
     Saves user's progress to json file in app docs dir
     
     - Returns: count of ProgressNodes saved
     */
    static func saveCurrentProgress() throws -> Int {
        let progressDataURL =  URL(
            fileURLWithPath: "progress",
            relativeTo: FileManager.documentDirectoryURL).appendingPathExtension("json")
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        
        if let nodesToSave = ProgressNode.progressNodeGraph?.completedNodes() {
            let data = try jsonEncoder.encode(nodesToSave)
            try data.write(to: progressDataURL)
            return nodesToSave.count
        }
        return 0
    }

}
