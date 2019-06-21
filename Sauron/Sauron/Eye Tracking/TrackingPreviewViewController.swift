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
    
    var didDetectDoubleBlink: () -> () = {}

    private let sceneView = ARSCNView()
    private lazy var focusView = UIView()
    private let imageView = UIImageView()
    private let controlView = TrackingControlView()
    
    private let nodeVirtualPad = SCNNode()
    private let nodeFace = SCNNode()
    private lazy var nodeEyeLeft = createDogEyeLightBeam(isLeft: true)
    private lazy var nodeEyeRight = createDogEyeLightBeam(isLeft: false)
    private var nodeEyeTargetLeft: SCNNode?
    private var nodeEyeTargetRight: SCNNode?
    private var nodeEyeBeamLeft: SCNNode?
    private var nodeEyeBeamRight: SCNNode?
    private lazy var nodeFocus = createFocusPoint()
    
    private var pastPositions: [simd_float3] = []
    private var blinkLeftInProgress = false
    private var blinkRightInProgress = false
    private var prevBlinkDate = Date()
    private let doubleBlinkTimeInterval = TimeInterval(1)
    
    private var config: TrackingService.Config {
        return TrackingService.shared.config
    }

    private var dogEyeTimer: Timer?
    var mode: Mode = .setting {
        didSet {
            view.isUserInteractionEnabled = mode.viewInteractionEnabled
            sceneView.alpha = mode.viewAlpha
            controlView.isHidden = !mode.showNodes
            nodeFace.isHidden = controlView.isHidden
            nodeFocus.isHidden = nodeFace.isHidden
        }
    }

    var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.green
        let vsNode = SCNNode()
        vsNode.geometry = screenGeometry
        return vsNode
    }()
    
    public var focusCoordinate: CGPoint {
        return focusView.center
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
        configureConstraints()
        
        mode = .preview
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError()
        }
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        focusView.center = view.center
        
        updateTransform()
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
        
        imageView.image = UIImage(named: "")
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0.8
        view.addSubview(imageView)
        
        focusView.backgroundColor = UIColor(red: 225/255.0, green: 110/255.0, blue: 56/255.0, alpha: 0.2)
        focusView.layer.cornerRadius = 30
        focusView.frame.size = CGSize(width: 60, height: 60)
        view.addSubview(focusView)
        
        controlView.delegate = self
        view.addSubview(controlView)
    }
    
    private func updateTransform() {
        [nodeEyeTargetLeft, nodeEyeTargetRight].forEach { (node) in
            var transform = SCNMatrix4Identity
            transform = SCNMatrix4Translate(transform, 0, 2, 0)
            transform = SCNMatrix4Rotate(transform, config.vertical, 1, 0, 0)
            transform = SCNMatrix4Rotate(transform, config.horizontal, 0, 1, 0)
            node?.transform = transform
        }
        
        [nodeEyeBeamLeft, nodeEyeBeamRight].forEach { (node) in
            var transform = SCNMatrix4Identity
            transform = SCNMatrix4Rotate(transform, config.vertical, 1, 0, 0)
            transform = SCNMatrix4Rotate(transform, config.horizontal, 0, 1, 0)
            node?.transform = transform
        }
    }
    
    private func configureConstraints() {
        sceneView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        controlView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    private func configureTimer() {
        configureOpacity(opacity: 1.0)
        dogEyeTimer?.invalidate()
        dogEyeTimer = Timer.scheduledTimer(withTimeInterval: config.dogEyeDismissDuration, repeats: false) { (t) in
            DispatchQueue.main.async {
                self.configureOpacity(opacity: 0.0)
            }
        }
    }
    
    private func configureOpacity(opacity: CGFloat) {
        [self.nodeEyeBeamLeft, self.nodeEyeBeamRight, self.nodeFocus].forEach { (node) in
            node?.opacity = opacity
        }
    }
    
    private func createDogEyeLightBeam(isLeft: Bool) -> SCNNode {
        let parentNode = SCNNode()
        
        do {
            let geometry = SCNCone(topRadius: 0.001, bottomRadius: 0.001, height: config.sightConeLength)

            geometry.radialSegmentCount = 10
            geometry.firstMaterial?.diffuse.contents = UIColor.yellow.withAlphaComponent(0)
            let node = SCNNode()
            node.geometry = geometry
            
            let beam = SCNParticleSystem(named: "beam.scnp", inDirectory: nil)!
            node.addParticleSystem(beam)

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
        geometry.firstMaterial?.diffuse.contents = UIColor(white: 0.8, alpha: 0.7)
        node.geometry = geometry
        return node
    }
}

// MARK: Update
extension TrackingPreviewViewController {
    private func update(faceAnchor: ARFaceAnchor) {
        self.configureTimer()

        var blinkLeft = false
        var blinkRight = false
        
        if let value = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue {
            if !blinkLeftInProgress && CGFloat(value) > config.blinkCloseThreshold {
                blinkLeftInProgress = true
            } else if blinkLeftInProgress && CGFloat(value) < config.blinkOpenThreshold {
                blinkLeftInProgress = false
                blinkLeft = true
            }
        }
        
        if let value = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue {
            if !blinkRightInProgress && CGFloat(value) > config.blinkCloseThreshold {
                blinkRightInProgress = true
            } else if blinkRightInProgress && CGFloat(value) < config.blinkOpenThreshold {
                blinkRightInProgress = false
                blinkRight = true
            }
        }
        
        if blinkLeft && blinkRight {
            let date = Date()
            
            if date.timeIntervalSince(prevBlinkDate) < doubleBlinkTimeInterval {
                didDetectDoubleBlink()
            }
            
            prevBlinkDate = date
        }

        nodeEyeLeft.simdTransform = faceAnchor.leftEyeTransform
        nodeEyeRight.simdTransform = faceAnchor.rightEyeTransform
        
        let eyeX = (nodeEyeLeft.worldPosition.x + nodeEyeRight.worldPosition.x) / 2
        let eyeY = (nodeEyeLeft.worldPosition.y + nodeEyeRight.worldPosition.y) / 2
        let eyeZ = (nodeEyeLeft.worldPosition.z + nodeEyeRight.worldPosition.z) / 2
        
        let targetX = (nodeEyeTargetLeft!.worldPosition.x + nodeEyeTargetRight!.worldPosition.x) / 2
        let targetY = (nodeEyeTargetLeft!.worldPosition.y + nodeEyeTargetRight!.worldPosition.y) / 2
        let targetZ = (nodeEyeTargetLeft!.worldPosition.z + nodeEyeTargetRight!.worldPosition.z) / 2
        
        let cc = Float(-config.range)
        let aa = ((eyeX * targetZ - targetX * eyeZ + (targetX - eyeX) * cc) / (targetZ - eyeZ))
        let bb = ((eyeY * targetZ - targetY * eyeZ + (targetY - eyeY) * cc) / (targetZ - eyeZ))
        
        
        updateTargetPosition(position: simd_float3(x: aa, y: bb, z: cc))
    }
    
    private func updateTargetPosition(position: simd_float3) {
        pastPositions.append(position)
        let lastTen = pastPositions.suffix(TrackingService.shared.config.smoothNess)
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
        
        if pastPositions.count > 1000 {
            pastPositions = Array(lastTen)
        }
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

extension TrackingPreviewViewController: TrackingControlDelegate {
    func didUpdate() {
        updateTransform()
    }
}

extension TrackingPreviewViewController {
    enum Mode {
        case preview
        case hidden
        case setting
        
        var viewInteractionEnabled: Bool {
            return self == .setting
        }
        
        var viewAlpha: CGFloat {
            switch self {
            case .setting:
                return 1
            case .preview:
                return 0.2
            case .hidden:
                return 0
            }
        }
        
        var showNodes: Bool {
            return self == .setting
        }
    }
}
