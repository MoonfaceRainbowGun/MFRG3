//
//  TrackingPreviewViewController.swift
//  Sauron
//
//  Created by Wang Jinghan on 21/6/19.
//  Copyright © 2019 Sea Labs. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import SnapKit

class TrackingPreviewViewController: ViewController {

    private let sceneView = ARSCNView()
    private lazy var focusView = UIView()
    private let pitchSlider = UISlider()
    private let rangeSlider = UISlider()
    private let rollSlider = UISlider()
    private let imageView = UIImageView()
    
    private let nodeVirtualPad = SCNNode()
    private let nodeFace = SCNNode()
    private lazy var nodeEyeLeft = createDogEyeLightBeam(isLeft: true)
    private lazy var nodeEyeRight = createDogEyeLightBeam(isLeft: false)
    private var nodeEyeTargetLeft: SCNNode?
    private var nodeEyeTargetRight: SCNNode?
    private var nodeEyeBeamLeft: SCNNode?
    private var nodeEyeBeamRight: SCNNode?
    private lazy var nodeFocus = createFocusPoint()
    
    private let height: CGFloat = 0.4
    private var padDistance: Float = 0.08
    
    private var pastPositions: [simd_float3] = []
    
    private var blinkOpenThreshold: CGFloat = 0.2
    private var blinkCloseThreshold: CGFloat = 0.8
    private var blinkLeftInProgress = false
    private var blinkRightInProgress = false

    var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.green
        let vsNode = SCNNode()
        vsNode.geometry = screenGeometry
        return vsNode
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureViews()
        self.configureConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError()
        }
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}

// MARK: View Configurators
extension TrackingPreviewViewController {
    private func configureViews() {
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        let nodeRoot = sceneView.scene.rootNode
        nodeRoot.addChildNode(nodeFace)
        nodeFace.addChildNode(nodeEyeLeft)
        nodeFace.addChildNode(nodeEyeRight)
        
        nodeVirtualPad.addChildNode(virtualScreenNode)
        nodeRoot.addChildNode(nodeVirtualPad)
        
        nodeRoot.addChildNode(nodeFocus)
        
        view.addSubview(sceneView)
        focusView.frame.size = CGSize(width: 30, height: 30)
        focusView.backgroundColor = .blue
        
        imageView.image = UIImage(named: "")
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0.8
        view.addSubview(imageView)
        
        view.addSubview(focusView)
        
        pitchSlider.minimumValue = .pi / 2 - 0.5
        pitchSlider.maximumValue = .pi / 2 + 0.5
        pitchSlider.value = 1.6
        pitchSlider.addTarget(self, action: #selector(didSlidePitchSlider), for: .valueChanged)
        view.addSubview(pitchSlider)
        
        rangeSlider.minimumValue = 0.03
        rangeSlider.maximumValue = 0.13
        rangeSlider.value = padDistance
        rangeSlider.addTarget(self, action: #selector(didSlideRangeSlider), for: .valueChanged)
        view.addSubview(rangeSlider)
        
        rollSlider.minimumValue = -0.5
        rollSlider.maximumValue = 0.5
        rollSlider.value = 0
        rollSlider.addTarget(self, action: #selector(didSliderRollSlider), for: .valueChanged)
        view.addSubview(rollSlider)
    }
    
    @objc func didSlidePitchSlider() {
        updateTransform()
    }
    
    @objc
    func didSlideRangeSlider() {
        padDistance = rangeSlider.value
    }
    
    @objc
    func didSliderRollSlider() {
        updateTransform()
    }
    
    private func updateTransform() {
        [nodeEyeTargetLeft, nodeEyeTargetRight].forEach { (node) in
            var transform = SCNMatrix4Identity
            transform = SCNMatrix4Translate(transform, 0, 2, 0)
            transform = SCNMatrix4Rotate(transform, pitchSlider.value, 1, 0, 0)
            transform = SCNMatrix4Rotate(transform, rollSlider.value, 0, 1, 0)
            node?.transform = transform
        }
        
        [nodeEyeBeamLeft, nodeEyeBeamRight].forEach { (node) in
            var transform = SCNMatrix4Identity
            transform = SCNMatrix4Translate(transform, 0, Float(height) / 2, 0)
            transform = SCNMatrix4Rotate(transform, pitchSlider.value, 1, 0, 0)
            transform = SCNMatrix4Rotate(transform, rollSlider.value, 0, 1, 0)
            node?.transform = transform
        }
    }
    
    private func configureConstraints() {
        sceneView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        pitchSlider.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
        
        rangeSlider.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(pitchSlider)
            make.bottom.equalTo(pitchSlider.snp.top).offset(-20)
        }
        
        rollSlider.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(rangeSlider)
            make.bottom.equalTo(rangeSlider.snp.top).offset(-20)
        }
    }
    
    private func createDogEyeLightBeam(isLeft: Bool) -> SCNNode {
        let parentNode = SCNNode()
        
        do {
            let geometry = SCNCone(topRadius: 0.001, bottomRadius: 0.001, height: height)
            
            geometry.radialSegmentCount = 10
            geometry.firstMaterial?.diffuse.contents = UIColor.yellow
            
            let node = SCNNode()
            node.geometry = geometry
            
            var transform = SCNMatrix4Identity
            transform = SCNMatrix4Translate(transform, 0, Float(height) / 2, 0)
            transform = SCNMatrix4Rotate(transform, 1.6, 1, 0, 0)
            node.transform = transform
            
            if isLeft {
                nodeEyeBeamLeft = node
            } else {
                nodeEyeBeamRight = node
            }
            
            parentNode.addChildNode(node)
        }
        
        
        do {
            let target = SCNNode()
            
            let geometry = SCNSphere(radius: 0.005)
            geometry.firstMaterial?.diffuse.contents = UIColor.red
            target.geometry = geometry
            
            var transform = SCNMatrix4Identity
            transform = SCNMatrix4Translate(transform, 0, 2, 0)
            transform = SCNMatrix4Rotate(transform, 1.6, 1, 0, 0)
            target.transform = transform
            
            parentNode.addChildNode(target)
            
            if isLeft {
                nodeEyeTargetLeft = target
            } else {
                nodeEyeTargetRight = target
            }
        }
        
        return parentNode
    }
    
    private func createFocusPoint() -> SCNNode {
        let node = SCNNode()
        let geometry = SCNSphere(radius: 0.002)
        geometry.firstMaterial?.diffuse.contents = UIColor.red
        node.geometry = geometry
        return node
    }
}

// MARK: Update
extension TrackingPreviewViewController {
    private func update(faceAnchor: ARFaceAnchor) {
        if let value = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue {
            if !blinkLeftInProgress && CGFloat(value) > blinkCloseThreshold {
                blinkLeftInProgress = true
            } else if blinkLeftInProgress && CGFloat(value) < blinkOpenThreshold {
                blinkLeftInProgress = false
                print(" Blink my right eye!")
            }
        }
        
        if let value = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue {
            if !blinkRightInProgress && CGFloat(value) > blinkCloseThreshold {
                blinkRightInProgress = true
            } else if blinkRightInProgress && CGFloat(value) < blinkOpenThreshold {
                blinkRightInProgress = false
                print(" Blink my left eye!")
            }
        }

        nodeEyeLeft.simdTransform = faceAnchor.leftEyeTransform
        nodeEyeRight.simdTransform = faceAnchor.rightEyeTransform
        
        let eyeX = (nodeEyeLeft.worldPosition.x + nodeEyeRight.worldPosition.x) / 2
        let eyeY = (nodeEyeLeft.worldPosition.y + nodeEyeRight.worldPosition.y) / 2
        let eyeZ = (nodeEyeLeft.worldPosition.z + nodeEyeRight.worldPosition.z) / 2
        
        let targetX = (nodeEyeTargetLeft!.worldPosition.x + nodeEyeTargetRight!.worldPosition.x) / 2
        let targetY = (nodeEyeTargetLeft!.worldPosition.y + nodeEyeTargetRight!.worldPosition.y) / 2
        let targetZ = (nodeEyeTargetLeft!.worldPosition.z + nodeEyeTargetRight!.worldPosition.z) / 2
        
        let cc = Float(-padDistance)
        let aa = ((eyeX * targetZ - targetX * eyeZ + (targetX - eyeX) * cc) / (targetZ - eyeZ))
        let bb = ((eyeY * targetZ - targetY * eyeZ + (targetY - eyeY) * cc) / (targetZ - eyeZ))
        
        
        updateTargetPosition(position: simd_float3(x: aa, y: bb, z: cc))
    }
    
    private func updateTargetPosition(position: simd_float3) {
        pastPositions.append(position)
        let lastTen = pastPositions.suffix(10)
        var sumX: Float = 0.0
        var sumY: Float = 0.0
        var sumZ: Float = 0.0
        for item in lastTen {
            sumX += item.x
            sumY += item.y
            sumZ += item.z
        }
        sumX /= Float(lastTen.count)
        sumY /= Float(lastTen.count)
        sumZ /= Float(lastTen.count)
        nodeFocus.worldPosition = SCNVector3(x: sumX, y: sumY, z: sumZ)
    }
    
    private func update(node: SCNNode, anchor: ARAnchor) {
        nodeFace.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        update(faceAnchor: faceAnchor)
    }
    
    private func notifyUpdate(renderer: SCNSceneRenderer) {
        let node = nodeFocus
        let positionOnScreen = renderer.projectPoint(node.position)
        let point = CGPoint(
            x: CGFloat(positionOnScreen.x),
            y: CGFloat(positionOnScreen.y)
        )
        focusView.center = point
    }
}

// MARK: ARSCNViewDelegate
extension TrackingPreviewViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            self.update(node: node, anchor: anchor)
            self.notifyUpdate(renderer: renderer)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            guard let sceneTransformInfo = self.sceneView.pointOfView?.transform else { return }
            self.nodeVirtualPad.transform = sceneTransformInfo
            self.notifyUpdate(renderer: renderer)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            self.update(node: node, anchor: anchor)
            self.notifyUpdate(renderer: renderer)
        }
    }
}

// MARK: ARSessionDelegate
extension TrackingPreviewViewController: ARSessionDelegate {
    
}
