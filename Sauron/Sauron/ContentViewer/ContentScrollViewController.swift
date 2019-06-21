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
    
    private let closeBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let closeVibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
    private let closeButton = UIButton(type: .system)
    
    private let segmentBackgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let segmentVibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
    
    private let previewButton = UIButton(type: .system)
    private let normalButton = UIButton(type: .system)
    private let settingButton = UIButton(type: .system)
    
    private let stackView = UIStackView()
    
    
    private let previewController = TrackingPreviewViewController()
    private let threshold: CGFloat = 0.3
    private let magic: CGFloat = 300
    private var isScrolling: Bool = false
    private let scrollingDuration: Double = 1
    
    private var upCounter = 0
    private var downCounter = 0
    private let counterThreashold = 5
    
    private lazy var maxYOffset = self.webView.scrollView.contentSize.height - self.webView.scrollView.frame.height
    private let minYOffset: CGFloat = 0

    private let url: URL
    private let webView: WKWebView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    
    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        webView.uiDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.loadFileURL(url, allowingReadAccessTo: url)
        
        let previewView = previewController.view
        view.addSubview(previewView!)
        addChild(previewController)
        
        previewView?.snp.remakeConstraints({ make in
            make.center.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalToSuperview()
        })
        
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(didTapDimiss), for: .touchUpInside)
        closeBackgroundView.layer.cornerRadius = 30
        closeBackgroundView.clipsToBounds = true
        closeButton.setImage(UIImage(named: "round_cancel_black_48pt"), for: .normal)
        closeBackgroundView.contentView.addSubview(closeVibrancyView)
        closeVibrancyView.contentView.addSubview(closeButton)
        view.addSubview(closeBackgroundView)
        closeBackgroundView.snp.makeConstraints { (make) in
            make.top.trailing.equalTo(view.safeAreaLayoutGuide).inset(30)
            make.width.height.equalTo(60)
        }
        
        closeVibrancyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(segmentBackgroundView)
        
        stackView.distribution = .fillEqually
        stackView.spacing = 5
        stackView.axis = .vertical
        
        previewButton.setImage(UIImage(named: "round_sentiment_satisfied_alt_black_48pt"), for: .normal)
        previewButton.addTarget(self, action: #selector(didTapPreview), for: .touchUpInside)
        stackView.addArrangedSubview(previewButton)
        
        normalButton.setImage(UIImage(named: "round_stars_black_48pt"), for: .normal)
        normalButton.addTarget(self, action: #selector(didTapNormal), for: .touchUpInside)
        stackView.addArrangedSubview(normalButton)
        
        settingButton.setImage(UIImage(named: "round_adjust_black_48pt"), for: .normal)
        settingButton.addTarget(self, action: #selector(didTapSetting), for: .touchUpInside)
        stackView.addArrangedSubview(settingButton)
        
        segmentVibrancyView.contentView.addSubview(stackView)
        segmentBackgroundView.layer.cornerRadius = 30
        segmentBackgroundView.clipsToBounds = true
        segmentBackgroundView.contentView.addSubview(segmentVibrancyView)
        
        segmentBackgroundView.snp.makeConstraints { (make) in
            make.width.equalTo(60)
            make.height.equalTo(165)
            make.trailing.equalTo(closeBackgroundView)
            make.top.equalTo(closeBackgroundView.snp.bottom).offset(20)
        }
        
        segmentVibrancyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(6)
        }
        
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !self.isScrolling {
                
                let w = self.view.frame.width
                let h = self.view.frame.height
                let bottomRect = CGRect(x: 0, y: h * (1 - self.threshold), width: w, height: h * self.threshold + self.magic)
                let topRect = CGRect(x: 0, y: -self.magic, width: w, height: h * self.threshold + self.magic)

                if bottomRect.contains(self.previewController.focusCoordinate) {
                    self.downCounter += 1
                    self.upCounter = 0
                    if self.downCounter > self.counterThreashold {
                        self.scroll(in: self.scrollingDuration, isScrollingDown: true)
                        self.downCounter = 0
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
    
    @objc func didTapPreview() {
        if previewController.mode != .preview {
            previewController.mode = .preview
        }
    }
    
    @objc func didTapNormal() {
        if previewController.mode != .hidden {
            previewController.mode = .hidden
        }
    }
    
    @objc func didTapSetting() {
        if previewController.mode != .setting {
            previewController.mode = .setting
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
