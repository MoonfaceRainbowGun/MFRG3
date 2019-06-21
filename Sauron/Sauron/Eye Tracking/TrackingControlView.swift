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
    
    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect.init(style: .dark))
    private let pitchSlider = UISlider()
    private let rangeSlider = UISlider()
    private let rollSlider = UISlider()
    
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
        
        pitchSlider.minimumValue = TrackingService.shared.config.verticalMin
        pitchSlider.maximumValue = TrackingService.shared.config.verticalMax
        pitchSlider.value = TrackingService.shared.config.vertical
        pitchSlider.addTarget(self, action: #selector(didSlidePitchSlider), for: .valueChanged)
        addSubview(pitchSlider)
        
        rangeSlider.minimumValue = TrackingService.shared.config.rangeMin
        rangeSlider.maximumValue = TrackingService.shared.config.rangeMax
        rangeSlider.value = TrackingService.shared.config.range
        rangeSlider.addTarget(self, action: #selector(didSlideRangeSlider), for: .valueChanged)
        addSubview(rangeSlider)
        
        rollSlider.minimumValue = TrackingService.shared.config.horizontalMin
        rollSlider.maximumValue = TrackingService.shared.config.horizontalMax
        rollSlider.value = TrackingService.shared.config.horizontal
        rollSlider.addTarget(self, action: #selector(didSliderRollSlider), for: .valueChanged)
        addSubview(rollSlider)
        
        
        clipsToBounds = true
        layer.cornerRadius = 20
    }
    
    @objc
    func didSlidePitchSlider() {
        TrackingService.shared.config.vertical = pitchSlider.value
        delegate?.didUpdate()
    }
    
    @objc
    func didSlideRangeSlider() {
        TrackingService.shared.config.range = rangeSlider.value
        delegate?.didUpdate()
    }
    
    @objc
    func didSliderRollSlider() {
        TrackingService.shared.config.horizontal = rollSlider.value
        delegate?.didUpdate()
    }
    
    private func configureConstraints() {
        rollSlider.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(20)
            make.leading.trailing.equalTo(rangeSlider)
            make.bottom.equalTo(rangeSlider.snp.top).offset(-20)
        }
        
        rangeSlider.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(pitchSlider)
            make.bottom.equalTo(pitchSlider.snp.top).offset(-20)
        }
        
        pitchSlider.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalTo(safeAreaLayoutGuide).inset(20)
        }
        
        backgroundView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}
