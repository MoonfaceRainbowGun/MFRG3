//
//  ViewController.swift
//  Mordor
//
//  Created by Huang Bohan on 22/6/19.
//  Copyright © 2019 Huang Bohan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .cancel, target: self, action: #selector(didTapDimiss))
    }
    
    @objc func didTapDimiss() {
        dismiss(animated: true, completion: nil)
    }
}
