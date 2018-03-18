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
                    //return container.progress.count
                    completion()
                } catch {
                    print("Get All: error during JSON decode")
                }
            }
        }
    }
    
    static func postProgressNode(_ node: ProgressNode) {
        let jsonEncoder = JSONEncoder()

        if let data = try? jsonEncoder.encode(node) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any] {
                makeAPIcall(method: .post, json: json) { response in
                    if let json = response.result.value {
                        let jsonDecoder = JSONDecoder()
                        do {
                            let _ = try jsonDecoder.decode(ProgressNode.self, from: json)
                            //print(savedNode)
                        } catch {
                            print("Post Node: error during JSON decode")
                        }
                    }
                }
            }
        }

    }
    
    static func deleteProgressNode(_ node: ProgressNode) {
        
    }
    
    
    static func makeAPIcall(method: HTTPMethod, json: Parameters? = nil, handler: @escaping (DataResponse<Data>) -> Void) {
        
        let url = URL(string: "progress", relativeTo: dataServerURL)
        
        let xauth = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI1YWFkYTE2OTY2MTQwOWUyNGI0OGI5YjEiLCJhY2Nlc3MiOiJhdXRoIiwiaWF0IjoxNTIxMzI4NDg5fQ.3gaYVci-H84C_SVdditp64NT60Mv9hFZsaZqvJn6dLg"
        
        let headers: HTTPHeaders = ["x-auth" : xauth]
        
        Alamofire.request(url!, method: method,  parameters: json, encoding: JSONEncoding.default ,headers: headers).responseData(completionHandler: handler)
        
    }
    
    static func saveNode(node: ProgressNode) {
        // at this point, node was dirty, so needs to be saved
        // upon success, clear dirty flag
        
        
        if node.hasCompleted {
            if let dbId = node.dbID {
                // if dbID exists, must update on server
                print("update node not implemented")
            } else {
                //if no dbID, then create new on server, get ID back, save in mem
                postProgressNode(node)
            }
        } else {
            // but if not compl, && has dbID, then will need to delete from server
            if let dbId = node.dbID {
                // if dbID exists, must delete from server
                print("delete node not implemented")

            } else {
                //if no dbID, no need to do anything,
                print("no need to do anything")

            }

        }
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
