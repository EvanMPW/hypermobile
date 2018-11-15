//
//  GetDailySalesIntentHandler.swift
//  hypermobile
//
//  Created by Evan Williams on 11/14/18.
//  Copyright © 2018 Evan Williams. All rights reserved.
//

import Foundation
import CoreData

class GetDailySalesIntentHandler: NSObject, GetDailySalesIntentHandling {

    func handle(intent: GetDailySalesIntent, completion: @escaping (GetDailySalesIntentResponse) -> Void) {
        
        let username = "ewilliams"
        let password = "password"
       
        
        struct loginStruct: Codable {
            let username: String
            let password: String
            let loginMode: Int
        }
        
        
        let loginData = loginStruct(username: username, password:password, loginMode: 1)
        let loginURL = URL(string: "https://env-112079.customer.cloud.microstrategy.com/MicroStrategyLibrary/api/auth/login")
        let encoder = JSONEncoder()
        let loginJSON = try? encoder.encode(loginData)
        
        var loginRequest = URLRequest(url: loginURL!)
        loginRequest.httpMethod = "POST"
        loginRequest.httpBody = loginJSON
        loginRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let getDailySalesTask = URLSession.shared.dataTask(with: loginRequest) {(loginRequestdata, loginRequestResponse, loginRequesterror) in
            
            let httpResponse = loginRequestResponse as! HTTPURLResponse
            let authToken = httpResponse.allHeaderFields["x-mstr-authtoken"] as! String
            
            
            let cubePublishURL = URL(string: "https://env-112079.customer.cloud.microstrategy.com/MicroStrategyLibrary/api/cubes/5BF9E98011E8E7DCCEB40080EF1533B7/instances")
            var cubePublishRequest = URLRequest(url: cubePublishURL!)
            cubePublishRequest.httpMethod = "POST"
            cubePublishRequest.addValue(authToken, forHTTPHeaderField: "X-MSTR-AuthToken")
            cubePublishRequest.addValue("F5BC563811E6E1DB2E0A0080EFA589EE", forHTTPHeaderField: "X-MSTR-ProjectID")
            
            let cubePublishTask = URLSession.shared.dataTask(with: cubePublishRequest) {(cubePublishData, cubePublishResponse, cubePublishError) in
                
                let cubeInstanceJSON = try? JSONSerialization.jsonObject(with: cubePublishData as! Data, options: [])
                let cubeInstanceString = cubeInstanceJSON as! [String: Any]
                
                let cubeInstanceID = cubeInstanceString["instanceId"] as! String
                
                
                let cubeDataURL = URL(string: "https://env-112079.customer.cloud.microstrategy.com/MicroStrategyLibrary/api/cubes/5BF9E98011E8E7DCCEB40080EF1533B7/instances/" + cubeInstanceID)
                var cubeDataRequest = URLRequest(url: cubeDataURL!)
                cubeDataRequest.httpMethod = "GET"
                cubeDataRequest.addValue(authToken, forHTTPHeaderField: "X-MSTR-AuthToken")
                cubeDataRequest.addValue("F5BC563811E6E1DB2E0A0080EFA589EE", forHTTPHeaderField: "X-MSTR-ProjectID")
                
                let cubeDataTask = URLSession.shared.dataTask(with: cubeDataRequest) {(cubeData, cubeDataResponse, cubeDataError) in
                    let cubeDataJSON = try? JSONSerialization.jsonObject(with: cubeData as! Data, options: [])
                    let cubeDataString = cubeDataJSON as! [String: Any]
                    let cubeDataResult = cubeDataString["result"] as! [String: Any]
                    let cubeDataDefinition = cubeDataResult["definition"] as! [String: Any]
                    let cubeDataMetrics = cubeDataDefinition["metrics"] as! [[String: Any]]
                    
                    let cySales = cubeDataMetrics[0] as! [String: Any]
                    let lySales = cubeDataMetrics[1] as! [String: Any]
                    
                    let cySalesValue = cySales["max"] as! Double
                    let lySalesValue = lySales["max"] as! Double
                    let salesDeltaDollars = cySalesValue - lySalesValue
                    let salesDeltaPercent = salesDeltaDollars / lySalesValue
                    
                    var formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.maximumFractionDigits = 0
                    
                    let cySalesString = formatter.string(from: NSNumber(value: cySalesValue))
                    
                    let defaults = UserDefaults(suiteName: "group.com.evanwilliams.hypermobile")!
                    defaults.set(cySalesString, forKey: "sales_value")
                    let testAmount = defaults.string(forKey: "sales_value")!
                    
                   
        
                completion(GetDailySalesIntentResponse.success(salesAmount: testAmount))
                    
                    
                    
                }
                
                cubeDataTask.resume()
                
            }
            
            cubePublishTask.resume()
            
        }
        
        getDailySalesTask.resume()
        
        
        
        
    }
}
