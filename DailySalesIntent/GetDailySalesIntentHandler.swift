//
//  GetDailySalesIntentHandler.swift
//  hypermobile
//
//  Created by Evan Williams on 11/14/18.
//  Copyright © 2018 Evan Williams. All rights reserved.
//

import Foundation

class GetDailySalesIntentHandler: NSObject, GetDailySalesIntentHandling {

    func handle(intent: GetDailySalesIntent, completion: @escaping (GetDailySalesIntentResponse) -> Void) {
        
        let username = "ewilliams"
        let password = "password"
        let loginMode = 1
        let baseRestURL = "https://env-112079.customer.cloud.microstrategy.com/MicroStrategyLibrary/api/" //path to MSTR library API
        let datasetType = "reports" //choose reports or cubes
        let datasetID = "12EC4CA611E8E89A570C0080EFC5B0B1" //cube or report id
        let projectID = "9FBA360E11E8488E24FF0080EF253654" //project id
        
        //set full URLs for logging in and publishing dataset instance
        let loginURL = URL(string: baseRestURL + "auth/login")
        let datasetPublishURL = URL(string: baseRestURL + datasetType + "/" + datasetID + "/instances")
        
        //create structure to hold body of login API call
        struct loginStruct: Codable {
            let username: String
            let password: String
            let loginMode: Int
        }
        
        //encode login data to JSON for API call
        let loginData = loginStruct(username: username, password:password, loginMode: loginMode)
        let encoder = JSONEncoder()
        let loginJSON = try? encoder.encode(loginData)
        
        //create login request
        var loginRequest = URLRequest(url: loginURL!)
        loginRequest.httpMethod = "POST"
        loginRequest.httpBody = loginJSON
        loginRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //create task to execute login request
        let getDailySalesTask = URLSession.shared.dataTask(with: loginRequest) {(loginRequestdata, loginRequestResponse, loginRequesterror) in
            
            //get auth token from login request
            let httpResponse = loginRequestResponse as! HTTPURLResponse
            let authToken = httpResponse.allHeaderFields["x-mstr-authtoken"] as! String
            
            //create request to publish instance of dataset
            var datasetPublishRequest = URLRequest(url: datasetPublishURL!)
            datasetPublishRequest.httpMethod = "POST"
            datasetPublishRequest.addValue(authToken, forHTTPHeaderField: "X-MSTR-AuthToken")
            datasetPublishRequest.addValue(projectID, forHTTPHeaderField: "X-MSTR-ProjectID")
            
            //create task to publish instance of dataset
            let datasetPublishTask = URLSession.shared.dataTask(with: datasetPublishRequest) {(datasetPublishData, datasetPublishResponse, datasetPublishError) in
                
                //parse response from dataset publish request to retrieve ID of published dataset instance
                let datasetInstanceJSON = try? JSONSerialization.jsonObject(with: datasetPublishData as! Data, options: [])
                let datasetInstanceString = datasetInstanceJSON as! [String: Any]
                let datasetInstanceID = datasetInstanceString["instanceId"] as! String
                
                //set full URL for retrieving data from published dataset instance
                let datasetDataURL = URL(string: baseRestURL + datasetType + "/" + datasetID + "/instances/" + datasetInstanceID)
                
                //create request to retrieve data from published dataset instance
                var datasetDataRequest = URLRequest(url: datasetDataURL!)
                datasetDataRequest.httpMethod = "GET"
                datasetDataRequest.addValue(authToken, forHTTPHeaderField: "X-MSTR-AuthToken")
                datasetDataRequest.addValue(projectID, forHTTPHeaderField: "X-MSTR-ProjectID")
                
                //create task to retrieve data from published dataset instance
                let datasetDataTask = URLSession.shared.dataTask(with: datasetDataRequest) {(datasetData, datasetDataResponse, datasetDataError) in
                    
                    //parse response from data retrieval request to get value of metric
                    let datasetDataJSON = try? JSONSerialization.jsonObject(with: datasetData as! Data, options: [])
                    let datasetDataString = datasetDataJSON as! [String: Any]
                    let datasetDataResult = datasetDataString["result"] as! [String: Any]
                    let datasetDataDefinition = datasetDataResult["definition"] as! [String: Any]
                    let datasetDataMetrics = datasetDataDefinition["metrics"] as! [[String: Any]]
                    let datasetMetricResult = datasetDataMetrics[0] as [String: Any]
                    let datasetMetricValue = datasetMetricResult["max"] as! Double
                    
                    //format metric value as currency
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.maximumFractionDigits = 0
                    let datasetMetricCurrency = formatter.string(from: NSNumber(value: datasetMetricValue))!
                    
                    //save formatted metric value to app group user defaults for shared use
                    let defaults = UserDefaults(suiteName: "group.com.evanwilliams.hypermobile")!
                    defaults.set(datasetMetricCurrency, forKey: "sales_value")
                
                    //pass formatted metric value back to GetDailySales intent for siri reply
                    completion(GetDailySalesIntentResponse.success(salesAmount: datasetMetricCurrency))
                
                }
                
                datasetDataTask.resume()
    
            }
            
            datasetPublishTask.resume()
            
        }
        
        getDailySalesTask.resume()
        
    }
    
}
