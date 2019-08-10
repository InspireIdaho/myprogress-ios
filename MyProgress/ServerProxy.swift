//  ServerProxy.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import Foundation
import Alamofire

// trick is no longer needed, and doesn't work because the json decode expects key/value pair
// not a raw array
//private struct ResponseContainer : Codable {
//    let progress: [ProgressNode]
//}

/// convenient trick to enable out-of-box use of Codable for JSON web response/body
private struct NodeUpdateContainer : Codable {
    let indexPath: String
    let completedOn: Date
}

/// convenient trick to enable out-of-box use of Codable for JSON web response/body
/// AND by conforming to Error, an instance can be thrown (in do/try) as-is... bonus!
 struct ErrorResponse : Codable, Error {
    let error: Bool
    let reason: String
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
        var headers: HTTPHeaders = [:]
        if let token = User.principle?.token {
            let bearer = HTTPHeader.authorization(bearerToken: token)
            headers.add(bearer)
        }
        return headers
    }
    
    // MARK: - ProgressNode manipulation Methods

    /**
     Request list of ProgressNodes (for user) from api server.
     Does not need to return the list, as the nodes are cached in ProgressNode registry
     as they are initialized from decoder.
     
     - Parameter completion: handler to be called once done
     */
    // TODO: perhaps change func signature to use success & failure completion blocks
    // like  isUserAuthenticated(success: () -> (), failure: () -> ())
    static func getAllProgressNodes(completion: @escaping () -> ()) {
        let url = URL(string: "user", relativeTo: dataServerURL)?
            .appendingPathComponent("progress")

        AF.request(url!, method: .get,
                   parameters: nil, encoding: JSONEncoding.default,
                   headers: authHeaders).responseData { response in
            if let json = response.data {
                let jsonDecoder = JSONDecoder()
                do {
                    // check status, decode different JSON depending on result
                    let status = response.response?.statusCode ?? 0
                    // TODO: perhaps change all locations handling response data
                    // to same form
                    if (status == 200) {
                        let container = try jsonDecoder.decode(Array<ProgressNode>.self, from: json)
                        
                        print("Fetched \(container.count) ProgressNodes from server")
                    } else if (status >= 400) {
                        let localError = try jsonDecoder.decode(ErrorResponse.self, from: json)
                        throw localError
                    }
                    completion()
                } catch let error {
                    print("Get All: error during JSON decode: \(error)")
                }
            }
        }
    }
    
    static func createProgressNode(_ node: ProgressNode) {
        let jsonEncoder = JSONEncoder()

        if let data = try? jsonEncoder.encode(node) {
            if let json = ((try? JSONSerialization.jsonObject(with: data) as? [String:Any]) as [String : Any]??) {
                
                let url = URL(string: "progress", relativeTo: dataServerURL)
                AF.request(url!, method: .post,
                           parameters: json, encoding: JSONEncoding.default,
                           headers: authHeaders).responseData { response in
                    if let json = response.data {
                        let jsonDecoder = JSONDecoder()
                        do {
                            _ = try jsonDecoder.decode(ProgressNode.self, from: json)
                        } catch let error {
                            print("Post Node: error during JSON decode: \(error)")
                        }
                    }
                }
            }
        }

    }
    
    static func deleteProgressNode(_ node: ProgressNode) {
        
        let url = URL(string: "progress", relativeTo: dataServerURL)
        let deleteURL = url!.appendingPathComponent("\(node.dbID!)")
        
        AF.request(deleteURL, method: .delete, headers: authHeaders).responseJSON { response in
            
            if let possData = response.data {
                if let json = ((try? JSONSerialization.jsonObject(with: possData, options: .allowFragments) as? Dictionary<String, Any>) as Dictionary<String, Any>??) {
                
                    if let deletedID = json?["id"] as? Int {
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
        let updateURL = url!.appendingPathComponent("\(node.dbID!)")
        
        guard let changedDate = node.completedOn else {
            print("cannot update progress without date completedOn")
            return
            
        }
        
        let updateObj = NodeUpdateContainer(indexPath: node.indexPath.description, completedOn: changedDate)
        let jsonEncoder = JSONEncoder()
        
        if let data = try? jsonEncoder.encode(updateObj) {
            if let json = ((try? JSONSerialization.jsonObject(with: data) as? [String:Any]) as [String : Any]??) {

                AF.request(updateURL, method: .patch,  parameters: json, encoding: JSONEncoding.default ,headers: authHeaders).responseJSON { response in
                    
                    if let possData = response.data {
                        
                        if let json = ((try? JSONSerialization.jsonObject(with: possData, options: .allowFragments) as? Dictionary<String, Any>) as Dictionary<String, Any>??) {
                            
                            if let updatedID = json?["id"] as? Int {
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

    
    // MARK: - User-related Methods

    
    static func loginUser(method: HTTPMethod, cred: UserLogin, json: Parameters? = nil, handler: @escaping (DataResponse<Data>) -> Void) {
        
        var localHeaders: HTTPHeaders = [:]
        let basic = HTTPHeader.authorization(username: cred.email, password: cred.password)
        localHeaders.add(basic)
        
        let url = URL(string: "user", relativeTo: dataServerURL)?.appendingPathComponent("login")
        AF.request(url!, method: method,  parameters: json, encoding: JSONEncoding.default, headers: localHeaders)
            .responseData(completionHandler: handler)
    }


    static func isUserAuthenticated(success: @escaping () -> (), failure: @escaping () -> ()) {
        
        let url = URL(string: "user", relativeTo: dataServerURL)?
            .appendingPathComponent("me")

        AF.request(url!, method: .get, headers: authHeaders).responseJSON { response in
            if let possData = response.data {
                
                if let json = ((try? JSONSerialization.jsonObject(with: possData, options: .allowFragments) as? Dictionary<String, Any>) as Dictionary<String, Any>??) {
                if let _ = json?["email"] as? String {
                    // TODO: change success closure to accept email
                    // TODO: change to single closure with bool params for success/fail?
                    success()
                } else {
                    failure()
                }
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
