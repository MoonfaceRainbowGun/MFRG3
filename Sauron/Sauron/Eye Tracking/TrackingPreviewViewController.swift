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
    
    private let nodeVirtualPad = SCNNode()
    private let nodeFace = SCNNode()
    private lazy var nodeEyeLeft = createDogEyeLightBeam()
    private lazy var nodeEyeRight = createDogEyeLightBeam()
    private lazy var nodeFocus = createFocusPoint()
    
    var virtualScreenNode: SCNNode = {
        let screenGeometry = SCNPlane(width: 1, height: 1)
        screenGeometry.firstMaterial?.isDoubleSided = true
        screenGeometry.firstMaterial?.diffuse.contents = UIColor.green
        let vsNode = SCNNode()
        vsNode.geometry = screenGeometry
        return vsNode
    }()
    
    private var nodeEyeTargetLeft: SCNNode?
    private var nodeEyeTargetRight: SCNNode?
    
    
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
    }
    
    private func configureConstraints() {
        sceneView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    private func createDogEyeLightBeam() -> SCNNode {
        let height: CGFloat = 0.4
        let parentNode = SCNNode()
        
        do {
            let geometry = SCNCone(topRadius: 0.001, bottomRadius: 0.001, height: height)
            
            geometry.radialSegmentCount = 10
            geometry.firstMaterial?.diffuse.contents = UIColor.yellow
            
            let eyeNode = SCNNode()
            eyeNode.geometry = geometry
            
            var transform = SCNMatrix4Identity
            transform = SCNMatrix4Translate(transform, 0, Float(height) / 2, 0)
            transform = SCNMatrix4Rotate(transform, 1.5, 1, 0, 0)
            eyeNode.transform = transform
            
            parentNode.addChildNode(eyeNode)
        }
        
        
        do {
            let target = SCNNode()
            
            let geometry = SCNSphere(radius: 0.005)
            geometry.firstMaterial?.diffuse.contents = UIColor.red
            target.geometry = geometry
            
            var transform = SCNMatrix4Identity
            transform = SCNMatrix4Translate(transform, 0, 2, 0)
            transform = SCNMatrix4Rotate(transform, 1.5, 1, 0, 0)
            target.transform = transform
            
            parentNode.addChildNode(target)
            
            if nodeEyeTargetLeft == nil {
                nodeEyeTargetLeft = target
            } else {
                nodeEyeTargetRight = target
            }
        }
        
        return parentNode
    }
    
    private func createFocusPoint() -> SCNNode {
        let node = SCNNode()
        let geometry = SCNSphere(radius: 0.005)
        geometry.firstMaterial?.diffuse.contents = UIColor.red
        node.geometry = geometry
        return node
    }
}

// MARK: Update
extension TrackingPreviewViewController {
    private func update(faceAnchor: ARFaceAnchor) {
        nodeEyeLeft.simdTransform = faceAnchor.leftEyeTransform
        nodeEyeRight.simdTransform = faceAnchor.rightEyeTransform
        
        let eyeX = (nodeEyeLeft.worldPosition.x + nodeEyeRight.worldPosition.x) / 2
        let eyeY = (nodeEyeLeft.worldPosition.y + nodeEyeRight.worldPosition.y) / 2
        let eyeZ = (nodeEyeLeft.worldPosition.z + nodeEyeRight.worldPosition.z) / 2
        
        let targetX = (nodeEyeTargetLeft!.worldPosition.x + nodeEyeTargetRight!.worldPosition.x) / 2
        let targetY = (nodeEyeTargetLeft!.worldPosition.y + nodeEyeTargetRight!.worldPosition.y) / 2
        let targetZ = (nodeEyeTargetLeft!.worldPosition.z + nodeEyeTargetRight!.worldPosition.z) / 2
        
        let cc = Float(-0.1)
        let aa = ((eyeX * targetZ - targetX * eyeZ + (targetX - eyeX) * cc) / (targetZ - eyeZ))
        let bb = ((eyeY * targetZ - targetY * eyeZ + (targetX - eyeX) * cc) / (targetZ - eyeZ)) + 0.07
        
        
        nodeFocus.worldPosition = SCNVector3Make(aa, bb, cc)
    }
    
    private func updateTargetPosition(left: CGPoint, right: CGPoint) {
        
    }
    
    private func update(node: SCNNode, anchor: ARAnchor) {
        nodeFace.transform = node.transform
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        update(faceAnchor: faceAnchor)
    }
}

// MARK: ARSCNViewDelegate
extension TrackingPreviewViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            self.update(node: node, anchor: anchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            guard let sceneTransformInfo = self.sceneView.pointOfView?.transform else { return }
            self.nodeVirtualPad.transform = sceneTransformInfo
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            self.update(node: node, anchor: anchor)
        }
    }
}

// MARK: ARSessionDelegate
extension TrackingPreviewViewController: ARSessionDelegate {
    
}
