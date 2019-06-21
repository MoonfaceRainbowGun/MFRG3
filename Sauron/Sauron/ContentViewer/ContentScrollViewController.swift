//
//  ContentScrollViewController.swift
//  Sauron
//
//  Created by Huang Bohan on 21/6/19.
//  Copyright © 2019 Sea Labs. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class ContentScrollViewController: ViewController {
    private var numberOfViews = 8
    private var contentViews = [UIView]()
    private let scrollView = UIScrollView()
    
    private let button = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.isPagingEnabled = false
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.decelerationRate = .fast
        scrollView.scrollsToTop = false
        view.addSubview(scrollView)
        
        button.setTitle("Scroll!", for: .normal)
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        view.addSubview(button)
        
        self.configureConstraints()
        self.configureViews()
    }
    
    @objc private func didTapButton() {
        scroll(in: 2)
    }
    
    private func configureConstraints() {
        scrollView.snp.remakeConstraints({ make in
            make.edges.equalToSuperview()
        })
        
        button.snp.remakeConstraints({ make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(50)
        })
    }

    private func configureViews() {
        while contentViews.count < numberOfViews {
            contentViews.append(ContentView(counter: contentViews.count))
        }
        
        for (index, view) in contentViews.enumerated() {
            scrollView.addSubview(view)
            view.frame = CGRect(x: 0, y: CGFloat(index) * viewHeight, width: viewWidth, height: viewHeight)
        }
        
        scrollView.contentSize = CGSize(width: viewWidth, height: CGFloat(contentViews.count) * viewHeight)
    }
    
    private func scroll(in seconds: Double) {
        UIView.animate(withDuration: seconds) {
            let contentOffset = self.scrollView.contentOffset
            let newOffset = CGPoint(x: contentOffset.x, y: contentOffset.y + self.viewHeight / 3.0)
            self.scrollView.contentOffset = newOffset
        }
    }
    
    private var viewSize: CGSize {
        return UIScreen.main.bounds.size
    }
    
    private var viewWidth: CGFloat {
        return viewSize.width
    }
    
    private var viewHeight: CGFloat {
        return viewSize.height
    }
}

extension ContentScrollViewController: UIScrollViewDelegate {
    
}
