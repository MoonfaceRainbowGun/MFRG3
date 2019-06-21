//
//  ContentScrollViewController.swift
//  Sauron
//
//  Created by Huang Bohan on 21/6/19.
//  Copyright © 2019 Sea Labs. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import SnapKit

class ContentScrollViewController: ViewController {
    private let button = UIButton()

    var webView: WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        button.backgroundColor = UIColor.blue
        button.setTitle("Scroll!", for: .normal)
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        view.addSubview(button)
        
        self.configureConstraints()
        
        let myURL = URL(string:"https://www.shopee.sg")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
    
    @objc private func didTapButton() {
        scroll(in: 2)
    }
    
    private func configureConstraints() {
        button.snp.remakeConstraints({ make in
            make.center.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(50)
        })
    }

    private func configureViews() {
        
    }
    
    private func scroll(in seconds: Double) {
        UIView.animate(withDuration: seconds) {
            let contentOffset = self.webView.scrollView.contentOffset
            let newOffset = CGPoint(x: contentOffset.x, y: contentOffset.y + UIScreen.main.bounds.size.height / 3.0)
            self.webView.scrollView.contentOffset = newOffset
        }
    }
}

extension ContentScrollViewController: WKUIDelegate {
    
}
