//
//  TrackingControlView.swift
//  Sauron
//
//  Created by Wang Jinghan on 21/6/19.
//  Copyright © 2019 Sea Labs. All rights reserved.
//

import UIKit

protocol TrackingControlDelegate: NSObjectProtocol {
    func didUpdate()
}

class TrackingControlView: UIView {
    weak var delegate: TrackingControlDelegate?
    
    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .dark)))
    private let smoothSlider = UISlider()
    private let smoothLabel = UILabel()
    private let responsiveLabel = UILabel()
    private let stackView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configureViews()
        configureConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    private func configureViews() {
        addSubview(backgroundView)
        
        smoothSlider.minimumValue = Float(TrackingService.shared.config.smoothNessMin)
        smoothSlider.maximumValue = Float(TrackingService.shared.config.smoothNessMax)
        smoothSlider.value = Float(TrackingService.shared.config.smoothNess)
        smoothSlider.addTarget(self, action: #selector(didSlideSmoothSlider), for: .valueChanged)
        
        
        responsiveLabel.text = "Responsive"
        responsiveLabel.font = UIFont.boldSystemFont(ofSize: 20)
        stackView.addArrangedSubview(responsiveLabel)
        
        
        stackView.addArrangedSubview(smoothSlider)
        
        smoothLabel.text = "Smooth"
        smoothLabel.font = UIFont.boldSystemFont(ofSize: 20)
        stackView.addArrangedSubview(smoothLabel)
        
        stackView.spacing = 10
        
        vibrancyView.contentView.addSubview(stackView)
        backgroundView.contentView.addSubview(vibrancyView)
        
        backgroundView.clipsToBounds = true
        backgroundView.layer.cornerRadius = 30
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(didPan(gesture:)))
        addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(gesture:)))
        addGestureRecognizer(pinch)
    }
    
    var startVertical: Float?
    var startHorizontal: Float?
    
    @objc
    func didPan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            startVertical = TrackingService.shared.config.vertical
            startHorizontal = TrackingService.shared.config.horizontal
        case .changed:
            let translation = gesture.translation(in: self)
            guard let startV = startVertical, let startH = startHorizontal else { return }
            
            TrackingService.shared.config.vertical = startV + Float(translation.y * 0.001)
            TrackingService.shared.config.horizontal = startH + Float(translation.x * 0.001)
            delegate?.didUpdate()
        default: break
        }
    }
    
    var startRange: Float?
    @objc
    func didPinch(gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            startRange = TrackingService.shared.config.range
        case .changed:
            let diff = Float(1 - gesture.scale)
            var new = TrackingService.shared.config.range + diff * 0.0005
            new = min(new, TrackingService.shared.config.rangeMax)
            new = max(new, TrackingService.shared.config.rangeMin)
            TrackingService.shared.config.range = new
        default: break
        }
    }
    
    @objc
    func didSlideSmoothSlider() {
        TrackingService.shared.config.smoothNess = Int(smoothSlider.value)
    }
     
    private func configureConstraints() {
        vibrancyView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.bottom.equalToSuperview()
        }
        
        backgroundView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview().inset(20)
            make.height.equalTo(60)
        }
    }
}
