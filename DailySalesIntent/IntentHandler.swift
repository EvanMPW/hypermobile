//
//  IntentHandler.swift
//  DailySalesIntent
//
//  Created by Evan Williams on 11/14/18.
//  Copyright © 2018 Evan Williams. All rights reserved.
//

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
       
        guard intent is GetDailySalesIntent else {
            fatalError("Unhandled intent type: \(intent)")
        }
        
        return GetDailySalesIntentHandler()

    }
    
}
