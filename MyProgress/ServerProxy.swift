//  ServerProxy.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import Foundation
import Alamofire

/// convenient trick to enable out-of-box use of Codable for JSON web response/body
private struct ResponseContainer : Codable {
    let progress: [ProgressNode]
}

private struct UpdateContainer : Codable {
    let completedOn: Date
}


/**
 The function of this class is to manage storage/retreival of the progress data.
 Currently to connect to remote API service, (in future, may cache data in local file for offline use,
 but then issue arises of when/how to sync the two data stores).
 
 All properties and methods are currently defined at class-level.
 
 Class needs to be re-factored to eliminate cut-n-paste duplication; next exercise!
 */
class ServerProxy {
    
    
    /// location of remote web service
    static var dataServerURL = URL(string: Config.env.serverUrl)
    
    /// compute headers in one place so not sprinkled everywhere
    static var authHeaders: HTTPHeaders {
        if let token = User.principle?.token {
            return ["x-auth" : token]
        } else {
            return [:]
        }
    }
    
    // MARK: - ProgressNode manipulation Methods

    /**
     Request list of ProgressNodes (for user) from api server.
     Does not need to return the list, as the nodes are cached in ProgressNode registry
     as they are initialized from decoder.
     
     - Parameter completion: handler to be called once done
     */
    static func getAllProgressNodes(completion: @escaping () -> ()) {
        makeAPIcall(method: .get) { response in
            if let json = response.data {
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
            if let json = ((try? JSONSerialization.jsonObject(with: data) as? [String:Any]) as [String : Any]??) {
                makeAPIcall(method: .post, json: json) { response in
                    if let json = response.data {
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
        
        AF.request(deleteURL, method: .delete, headers: authHeaders).responseJSON { response in
            
            if let possData = response.data {
                if let json = ((try? JSONSerialization.jsonObject(with: possData, options: .allowFragments) as? Dictionary<String, Any>) as Dictionary<String, Any>??) {
                
                    if let deletedID = json?["_id"] as? String {
                    if deletedID == node.dbID {
                        print("deleted \(deletedID) OK")
                        node.dbID = nil
                        node.hasChanges = false
                    } else {
                        print("Error deleting \(node.dbID!)")
                    }
                } else {
                    print("Error deleting \(node.dbID!)")
                }
                }
                
            }
        }
    }
    
    
    static func updateProgressNode(_ node: ProgressNode) {
        
        let url = URL(string: "progress", relativeTo: dataServerURL)
        let updateURL = url!.appendingPathComponent(node.dbID!)
        
        guard let changedDate = node.completedOn else {
            print("cannot update progress without date completedOn")
            return
            
        }
        
        let updateObj = UpdateContainer(completedOn: changedDate)
        let jsonEncoder = JSONEncoder()
        
        if let data = try? jsonEncoder.encode(updateObj) {
            if let json = ((try? JSONSerialization.jsonObject(with: data) as? [String:Any]) as [String : Any]??) {

                AF.request(updateURL, method: .patch,  parameters: json, encoding: JSONEncoding.default ,headers: authHeaders).responseJSON { response in
                    
                    //let foo = response.response?.description
                    //print(foo)
                    
                    if let possData = response.data {
                        
                        if let json = ((try? JSONSerialization.jsonObject(with: possData, options: .allowFragments) as? Dictionary<String, Any>) as Dictionary<String, Any>??) {
                            
                            if let updatedID = json?["_id"] as? String {
                                if updatedID == node.dbID {
                                    print("updated \(node.dbID!) OK")
                                    node.hasChanges = false
                                } else {
                                    print("Error updating \(node.dbID!)")
                                }
                            } else {
                                print("Error updating \(node.dbID!)")
                            }
                        }
                    }
                }
            }
        }
    }

    static func makeAPIcall(method: HTTPMethod, json: Parameters? = nil, handler: @escaping (DataResponse<Data>) -> Void) {
        
        let url = URL(string: "progress", relativeTo: dataServerURL)
        AF.request(url!, method: method,  parameters: json, encoding: JSONEncoding.default ,headers: authHeaders).responseData(completionHandler: handler)
    }
    
    // MARK: - User-related Methods

    static func makeUsersAPIcall(method: HTTPMethod, json: Parameters? = nil, handler: @escaping (DataResponse<Data>) -> Void) {
        
        let url = URL(string: "users", relativeTo: dataServerURL)
        AF.request(url!, method: method,  parameters: json, encoding: JSONEncoding.default ,headers: authHeaders).responseData(completionHandler: handler)
    }
    
    static func makeUsersLoginCall(method: HTTPMethod, json: Parameters? = nil, handler: @escaping (DataResponse<Data>) -> Void) {
        
        let url = URL(string: "users", relativeTo: dataServerURL)?.appendingPathComponent("login")
        AF.request(url!, method: method,  parameters: json, encoding: JSONEncoding.default ,headers: authHeaders).responseData(completionHandler: handler)
    }


    static func isAuthenticated(success: @escaping () -> (), failure: @escaping () -> ()) {
        
        let url = URL(string: "users/me", relativeTo: dataServerURL)
        AF.request(url!, method: .get,headers: authHeaders).responseJSON { response in
            if let possData = response.data {
                
                if let json = ((try? JSONSerialization.jsonObject(with: possData, options: .allowFragments) as? Dictionary<String, Any>) as Dictionary<String, Any>??) {
                if let _ = json?["email"] as? String {
                    // TODO: change success closure to accept email
                    // TODO: change to single closure with bool params for success/fail?
                    success()
                } else {
                    failure()
                }
                
                //expected response
//                {
//                    "_id" = 5aada169661409e24b48b9b1;
//                    email = "sean@bonnerventure.com";
//                }
            }
            }
        }

    }
    
    // MARK: - Local File Storage
    
    // these methods were used during initial bootstrap testing
    // no longer active, since progress now persisted at remote server
    // left in place as possible future exercise in caching data locally, in case network unavailable
    
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
