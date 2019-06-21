//
//  TrackingService.swift
//  Sauron
//
//  Created by Wang Jinghan on 21/6/19.
//  Copyright © 2019 Sea Labs. All rights reserved.
//

import UIKit

class TrackingService {
    static let shared = TrackingService()
    
    let config = Config()
   
    
    private init() {}
    
    
}

extension TrackingService {
    class Config {
        var range: Float = 0.1
        var rangeMin: Float = 0.05
        var rangeMax: Float = 0.15
        
        var horizontal: Float = 0
        var horizontalMin: Float = -0.5
        var horizontalMax: Float = 0.5
        
        var vertical: Float = 1.6
        var verticalMin: Float = .pi / 2 - 0.5
        var verticalMax: Float = .pi / 2 + 0.5
        
        var sightConeLength: CGFloat = 0.4
        var blinkOpenThreshold: CGFloat = 0.2
        var blinkCloseThreshold: CGFloat = 0.8
        
        var dogEyeDismissDuration: Double = 0.2
        var smoothNess: Int = 20
        var smoothNessMin: Int = 1
        var smoothNessMax: Int = 30
    }
}
