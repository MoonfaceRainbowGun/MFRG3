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
    private let previewController = TrackingPreviewViewController()
    private let threshold: CGFloat = 0.2

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
        
        let myURL = URL(string:"http://uygnim.com/xwlb.pdf")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
        
        let previewView = previewController.view
        view.addSubview(previewView!)
        
//        previewView?.alpha = 0.4
        previewView?.snp.remakeConstraints({ make in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        })
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            let w = self.view.frame.width
            let h = self.view.frame.height
            let bottomRect = CGRect(x: 0, y: h * (1 - self.threshold), width: w, height: h * self.threshold)
            let topRect = CGRect(x: 0, y: h * self.threshold, width: w, height: h * self.threshold)

            if bottomRect.contains(self.previewController.focusCoordinate) {
                self.scroll(in: 1, isScrollingDown: true)
            } else if topRect.contains(self.previewController.focusCoordinate) {
                self.scroll(in: 1, isScrollingDown: false)
            }
        }
    }
    
    @objc private func didTapButton() {
        scroll(in: 1, isScrollingDown: true)
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
    
    private func scroll(in seconds: Double, isScrollingDown: Bool) {
        UIView.animate(withDuration: seconds) {
            let contentOffset = self.webView.scrollView.contentOffset
            var yOffset: CGFloat
            if isScrollingDown {
                yOffset = min(self.webView.scrollView.contentSize.height, contentOffset.y + UIScreen.main.bounds.size.height / 3.0)
            } else {
                yOffset = max(0, contentOffset.y - UIScreen.main.bounds.size.height / 3.0)
            }
            self.webView.scrollView.contentOffset = CGPoint(x: contentOffset.x, y: yOffset)
        }
    }
}

extension ContentScrollViewController: WKUIDelegate {
    
}
