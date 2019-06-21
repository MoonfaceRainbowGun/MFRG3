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
    private let previewController = TrackingPreviewViewController()
    private let threshold: CGFloat = 0.2
    private var isScrolling: Bool = false

    var webView: WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myURL = URL(string:"http://uygnim.com/xwlb.pdf")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
        
        let previewView = previewController.view
        view.addSubview(previewView!)
        
        previewView?.snp.remakeConstraints({ make in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        })
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !self.isScrolling {
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
    }

    private func configureViews() {
        
    }
    
    private func scroll(in seconds: Double, isScrollingDown: Bool) {
        self.isScrolling = true
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
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.isScrolling = false
        }
    }
}

extension ContentScrollViewController: WKUIDelegate {
    
}
