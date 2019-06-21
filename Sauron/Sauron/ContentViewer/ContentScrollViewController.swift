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
    private let scrollingDuration: Double = 1
    
    private var upCounter = 0
    private var downCounter = 0
    private let counterThreashold = 5
    
    private lazy var maxYOffset = self.webView.scrollView.contentSize.height - self.webView.scrollView.frame.height
    private let minYOffset: CGFloat = 0

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
                let topRect = CGRect(x: 0, y: 0, width: w, height: h * self.threshold)

                if bottomRect.contains(self.previewController.focusCoordinate) {
                    self.downCounter += 1
                    self.upCounter = 0
                    if self.downCounter > self.counterThreashold {
                        self.scroll(in: self.scrollingDuration, isScrollingDown: true)
                    }
                } else if topRect.contains(self.previewController.focusCoordinate) {
                    self.downCounter = 0
                    self.upCounter += 1
                    if self.upCounter > self.counterThreashold {
                        self.scroll(in: self.scrollingDuration, isScrollingDown: false)
                    }
                } else {
                    self.downCounter = 0
                    self.upCounter = 0
                }
            }
        }
    }

    private func configureViews() {
        
    }
    
    private func scroll(in seconds: Double, isScrollingDown: Bool) {
        let contentOffset = self.webView.scrollView.contentOffset
        var newYOffset: CGFloat = 0.0

        if isScrollingDown {
            if contentOffset.y < self.maxYOffset {
                self.isScrolling = true
                newYOffset = min(self.maxYOffset, contentOffset.y + UIScreen.main.bounds.size.height / 3.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    self.isScrolling = false
                }
            }
        } else {
            if contentOffset.y >= self.minYOffset {
                self.isScrolling = true
                newYOffset = max(self.minYOffset, contentOffset.y - UIScreen.main.bounds.size.height / 3.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    self.isScrolling = false
                }
            }
        }
        
        if self.isScrolling {
            UIView.animate(withDuration: seconds) {
                self.webView.scrollView.contentOffset = CGPoint(x: contentOffset.x, y: newYOffset)
            }
        }
    }
}

extension ContentScrollViewController: WKUIDelegate {
    
}
