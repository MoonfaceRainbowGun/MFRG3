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
//    private lazy var nodeEye = createDogEyeLightBeam()
    
    private let nodeEyeTargetLeft = SCNNode()
    private let nodeEyeTargetRight = SCNNode()
    
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
        
        nodeEyeLeft.addChildNode(nodeEyeTargetLeft)
        nodeEyeRight.addChildNode(nodeEyeTargetRight)
        
        
        nodeRoot.addChildNode(nodeVirtualPad)
        
        nodeEyeTargetLeft.position.z = 2
        nodeEyeTargetRight.position.z = 2
        
        view.addSubview(sceneView)
    }
    
    private func configureConstraints() {
        sceneView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    private func createDogEyeLightBeam() -> SCNNode {
        let height: CGFloat = 0.2
        let geometry = SCNCone(topRadius: 0.001, bottomRadius: 0.001, height: height)
        
        geometry.radialSegmentCount = 10
        geometry.firstMaterial?.diffuse.contents = UIColor.yellow
        
        let eyeNode = SCNNode()
        eyeNode.geometry = geometry
        eyeNode.eulerAngles.x = -.pi / 2
        
        
        let child = SCNNode()
        let geo = SCNCone(topRadius: 0.001, bottomRadius: 0.001, height: height)
        child.geometry = geo
        child.localTranslate(by: SCNVector3Make(0, -0.2, 0))
        geo.firstMaterial?.diffuse.contents = UIColor.red
        eyeNode.addChildNode(child)
        
        eyeNode.position.z = 0.1
        let parentNode = SCNNode()
        parentNode.addChildNode(eyeNode)
        
        return parentNode
    }
}

// MARK: Update
extension TrackingPreviewViewController {
    private func update(faceAnchor: ARFaceAnchor) {
        nodeEyeLeft.simdTransform = faceAnchor.leftEyeTransform
        nodeEyeRight.simdTransform = faceAnchor.rightEyeTransform
        
        var hittingPointLeft = CGPoint()
        var hittingPointRight = CGPoint()
        
        let padScreenSize = CGSize(width: 0.0774, height: 0.1575)
        let padScreenPointSize = view.window?.bounds ?? .zero
        
        guard let resultLeft = nodeVirtualPad
            .hitTestWithSegment(
                from: nodeEyeTargetLeft.worldPosition,
                to: nodeEyeLeft.worldPosition,
                options: nil
            )
            .first else { return }
        
        guard let resultRight = nodeVirtualPad
            .hitTestWithSegment(
                from: nodeEyeTargetRight.worldPosition,
                to: nodeEyeRight.worldPosition,
                options: nil
            )
            .first else { return }
        
        hittingPointLeft.x = CGFloat(resultLeft.localCoordinates.x) / (padScreenSize.width / 2) * padScreenPointSize.width
        hittingPointLeft.y = CGFloat(resultLeft.localCoordinates.y) / (padScreenSize.height / 2) * padScreenPointSize.height
        
        hittingPointRight.x = CGFloat(resultRight.localCoordinates.x) / (padScreenSize.width / 2) * padScreenPointSize.width
        hittingPointRight.y = CGFloat(resultRight.localCoordinates.y) / (padScreenSize.height / 2) * padScreenPointSize.height
        
        updateTargetPosition(left: hittingPointLeft, right: hittingPointRight)
    }
    
    private func updateTargetPosition(left: CGPoint, right: CGPoint) {
    
    }
    
    private func update(node: SCNNode, anchor: ARAnchor) {
        DispatchQueue.main.async {
            self.nodeFace.transform = node.transform
            guard let faceAnchor = anchor as? ARFaceAnchor else { return }
            self.update(faceAnchor: faceAnchor)
        }
    }
}

// MARK: ARSCNViewDelegate
extension TrackingPreviewViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        update(node: node, anchor: anchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            guard let sceneTransformInfo = self.sceneView.pointOfView?.transform else { return }
            self.nodeVirtualPad.transform = sceneTransformInfo
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        update(node: node, anchor: anchor)
    }
}

// MARK: ARSessionDelegate
extension TrackingPreviewViewController: ARSessionDelegate {
    
}
