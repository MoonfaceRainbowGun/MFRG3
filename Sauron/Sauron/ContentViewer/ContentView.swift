//
//  ContentView.swift
//  Sauron
//
//  Created by Huang Bohan on 21/6/19.
//  Copyright © 2019 Sea Labs. All rights reserved.
//

import UIKit

class ContentView: InfiniteScrollViewElement {
    private let textLabel = UILabel()
    
    init(counter: Int) {
        super.init(frame: .zero)
        
        backgroundColor = UIColor.orange
        
        layer.borderColor = UIColor.blue.cgColor
        layer.borderWidth = CGFloat(3)
        
        textLabel.text = String(counter)
        textLabel.textColor = UIColor.black
        addSubview(textLabel)
        
        textLabel.snp.remakeConstraints({ make in
            make.center.equalToSuperview()
        })
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
