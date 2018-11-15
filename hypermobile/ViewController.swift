//
//  ViewController.swift
//  hypermobile
//
//  Created by Evan Williams on 11/14/18.
//  Copyright © 2018 Evan Williams. All rights reserved.
//

import UIKit
import Intents


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        donateInteraction()
    }
    
    func donateInteraction() {
        let intent = GetDailySalesIntent()
        
        intent.suggestedInvocationPhrase = "What were yesterday's sales?"
        
        let interaction = INInteraction(intent: intent, response: nil)
        
        interaction.donate { (error) in
            if error != nil {
                if let error = error as NSError? {
                    print("Interaction donation failed")
                } else {
                    print("Successfully donated interaction")
                }
            }
        }
    }


}

