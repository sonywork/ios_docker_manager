//
//  ControllerAPI.swift
//  docker Manager
//
//  Created by Developer on 23/03/2017.
//  Copyright © 2017 Ingesup. All rights reserved.
//

import Foundation

class APIController {
    var url = ""
    var jsonDataArray : [[String:Any]] = []
    var jsonData: [String:Any] = [:]
    let VALID_CODES = [200, 201, 204]
    
    init(url:String = "") {
        self.url = url
    }
    
    func getContainerAll () -> [Container] {
        let tmp_url = self.url + "/containers/json?all=1"
        var containers : [Container] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        doCall(urlPath: tmp_url){ code in
            for item in self.jsonDataArray {
                
                let container = Container(id: (item["Id"] as? String)!, names: (item["Names"] as? [String])!, image_name: (item["Image"] as? String)!, image_id: (item["ImageID"] as? String)!, command: (item["Command"] as? String)!, created: (item["Created"] as? Int)!, state: (item["State"] as? String)!, status: (item["Status"] as? String)!, ports: (item["Ports"] as? [[String:Any]])!, volumes: (item["Mounts"] as? [[String:Any]])!)
                
                
                
                containers.append(container)
            }
            semaphore.signal()
        }
        semaphore.wait()
        return containers
    }
    
    func doCall (urlPath:String, completion: @escaping (Int) -> ()) {
        var request = URLRequest(url: URL(string: urlPath)!)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                completion(0)
                return
            }
            guard let data = data else {
                completion(0)
                return
            }
            
            
            do {
                let httpStatus = response as? HTTPURLResponse
                let httpStatusCode:Int = (httpStatus?.statusCode)!
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]]
                
                if(json == nil) {
                    let test = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
                    self.jsonData = test!
                } else {
                    
                    self.jsonDataArray = json!
                }
                
                completion(httpStatusCode)
            } catch {
            }
            
        }
        
        task.resume()
    }
    
    func resetJsonData() {
        self.jsonData = [:]
    }
    
    func resetJsonDataArray() {
        self.jsonDataArray = []
    }
    /*
    static func getUrl() -> String {
        let ip_server = ProcessInfo.processInfo.environment["IP_SERVER"]
        
        if(ip_server != nil)
        {
            return "http://\(ip_server!)"
        }
        
        return "http://91.121.184.50:31337"
    }*/
    
    func startContainer(id: String) -> (status: Bool, response: String){
        let semaphore = DispatchSemaphore(value: 0)
        var status:Bool = false
        var responseString = ""
        
        var request = URLRequest(url: URL(string: "\(self.url)/containers/\(id)/start")!)
        request.httpMethod = "POST"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            let httpStatus = response as? HTTPURLResponse
            let statusCode = (httpStatus?.statusCode)!
            
            if APIController().VALID_CODES.index(of: statusCode) != nil {
                status = true
            }
            
            responseString = String(data: data, encoding: .utf8)!
            
            semaphore.signal()
        }
        task.resume()
        
        semaphore.wait()

        return (status, responseString)

    }
    func stopContainer(id: String) -> (status: Bool, response: String){
        let semaphore = DispatchSemaphore(value: 0)
        var status:Bool = false
        var responseString = ""
        
        var request = URLRequest(url: URL(string: "\(self.url)/containers/\(id)/stop")!)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            let httpStatus = response as? HTTPURLResponse
            let statusCode = (httpStatus?.statusCode)!
            
            if APIController().VALID_CODES.index(of: statusCode) != nil {
                status = true
            }
            
            
            responseString = String(data: data, encoding: .utf8)!
           

            switch statusCode {
            case 304:
                responseString = "Le container est déjà arrêté"
                break;
            case 404:
                responseString = "Aucun container ne correspond à votre demande"
                break;
            case 500:
                responseString = "Mauvais paramètre !"
                break;
            default:
                break;
            }
            
            semaphore.signal()
        }
        task.resume()
        
        semaphore.wait()
        
        return (status, responseString)
        
    }
    
    func removeContainer(id: String) -> (status: Bool, response: String){
        let semaphore = DispatchSemaphore(value: 0)
        var status:Bool = false
        var responseString = ""
        
        var request = URLRequest(url: URL(string: "\(self.url)/containers/\(id)")!)
        request.httpMethod = "DELETE"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            let httpStatus = response as? HTTPURLResponse
            let statusCode = (httpStatus?.statusCode)!
            
            
            if APIController().VALID_CODES.index(of: statusCode) != nil {
                status = true
            }
            
            
            responseString = String(data: data, encoding: .utf8)!
            
            
            switch statusCode {
            case 409:
                responseString = "Conflit"
                break;
            case 404:
                responseString = "Aucun container ne correspond à votre demande"
                break;
            case 400,500:
                responseString = "Mauvais paramètre !"
                break;
            default:
                break;
            }
            
            
            semaphore.signal()
        }
        task.resume()
        
        semaphore.wait()
        
        return (status, responseString)
    }
    
    
    // get specific container
    func getContainer (uuid : String) -> Container {
        let tmp_url = "\(self.url)/containers/\(uuid)/json"
        var containers : [Container] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        doCall(urlPath: tmp_url){ code in
            let item = self.jsonData
            
            var names : [String] = []
            names.append((item["Name"] as? String)!)
            
            let config = item["Config"] as? [String:Any]
            let image_name = config?["Image"]
            let cmdArray = config?["Cmd"] as? [String]
            let cmd = cmdArray?[0]
            
            
            let state = item["State"] as? [String:Any]
            let status = state?["Status"]
            let finishedAt = state?["FinishedAt"]
            
            let container = Container(id: (item["Id"] as? String)!, names: names, image_name: (image_name as? String)!, command: (cmd )!, state: (status as? String)!, status: (status as? String)!, finishedAt: (finishedAt as? String)!, volumes: (item["Mounts"] as? [[String:Any]])!)
            
            containers.append(container)
            semaphore.signal()
        }
        semaphore.wait()
        return containers[0]
    }
    
    
    // Get logs
    func getLogs (uuid: String) -> String {
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var responseString = ""
        
        let request = URLRequest(url: URL(string: "\(self.url)/containers/\(uuid)/logs?stdout=true&stderr=true")!)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                                 print("error=\(error)")
                return
            }
            
            let formattedData = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            
            if formattedData != nil {
                responseString = formattedData! as String

            }
            semaphore.signal()
        }
        task.resume()
        
        semaphore.wait()
        
        
        return responseString
    }
    
    //Creation container
    func createContainer (nameContainer: String, nameImage: String, cmd: String) -> String{
        var toReturn : String = ""
        let semaphore = DispatchSemaphore(value: 0)
        let parameters = ["image": nameImage, "cmd": cmd] as Dictionary<String, Any>
        
        let tmp_url = self.url + "/containers/create?name=\(nameContainer)"
        let session = URLSession.shared
        
        var request = URLRequest(url: URL(string: tmp_url)!)
        request.httpMethod = "POST"
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            
        } catch {
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                return
            }
            
            guard data != nil else {
                return
            }
            
            do {
                
                let httpStatus = response as? HTTPURLResponse
                let httpStatusCode:Int = (httpStatus?.statusCode)!
                
                switch httpStatusCode {
                case 201:
                    toReturn = "Conteneur créé !"
                    break;
                case 404:
                    toReturn = "Aucune image ne correspond à votre demande !"
                    break;
                case 400:
                    toReturn = "Mauvais paramètre !"
                    break;
                default:
                    toReturn = ""
                    break;
                    
                }
                
                semaphore.signal()
                
            }
        })
        task.resume()
        semaphore.wait()
        return toReturn
    }

    
    
    // Ping
    func isAccessible () -> Bool {
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var res = false
        
        let request = URLRequest(url: URL(string: "\(self.url)/_ping")!)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            let httpStatus = response as? HTTPURLResponse
            let statusCode = (httpStatus?.statusCode)!
            
            
            if APIController().VALID_CODES.index(of: statusCode) != nil {
                res = true
            }
            semaphore.signal()
        }
        task.resume()
        
        semaphore.wait()
        
        
        return res
    }
    
    
    // get info
    func getInfo () -> System {
        let tmp_url = "\(self.url)/info"
        var system : System = System()
        let semaphore = DispatchSemaphore(value: 0)
        
        doCall(urlPath: tmp_url){ code in
            let item = self.jsonData
            
            system = System(containersCount: (item["Containers"] as? Int)!, runningContainersCount: (item["ContainersRunning"] as? Int)!, stoppedContainersCount: (item["ContainersStopped"] as? Int)!,imagesCount: (item["Images"] as? Int)!, name: (item["Name"] as? String)!,os: (item["OperatingSystem"] as? String)!, architecture: (item["Architecture"] as? String)!)
                        semaphore.signal()
        }
        semaphore.wait()
        return system
    }
    
    ////////////////////IMAGES ///////////////////////
    // Get all image
    func getAllImage () -> [Image] {
        let tmp_url = self.url + "/images/json?all=1"
        var images : [Image] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        doCall(urlPath: tmp_url){ code in
            for item in self.jsonDataArray {
                let image = Image(id: (item["Id"] as? String)!, parentId: (item["ParentId"] as? String)!, repoTags: (item["RepoTags"] as? [String])!, repoDigests: (item["RepoDigests"] as? [String])!, created: (item["Created"] as? Int)!, size: (item["Size"] as? Int)!, virtualSize: (item["VirtualSize"] as? Int)!, sharedSize: (item["SharedSize"] as? Int)!, number_containers: (item["Containers"] as? Int)!)
                
                images.append(image)
            }
            semaphore.signal()
        }
        semaphore.wait()
        resetJsonDataArray()
        return images
    }
    /////////////////////////////////////////////////
}
