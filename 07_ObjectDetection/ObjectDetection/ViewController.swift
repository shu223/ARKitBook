//
//  ViewController.swift
//  ObjectDetection
//
//  Created by Shuichi Tsutsumi on 2018/08/26.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var trackingStateLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, .showWireframe]
        
        let objects = ARReferenceObject.referenceObjects(inGroupNamed: "AR Resources",
                                                         bundle: nil)!        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionObjects = objects
        sceneView.session.run(configuration)
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        trackingStateLabel.text = camera.trackingState.description
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
        guard let objectAnchor = anchor as? ARObjectAnchor else { return }
        objectAnchor.addBoxNode(on: node, color: UIColor.blue.withAlphaComponent(0.5))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let objectAnchor = anchor as? ARObjectAnchor else { return }
        objectAnchor.updateBoxNode(on: node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
        guard let objectAnchor = anchor as? ARObjectAnchor else { return }
        objectAnchor.removeBoxNode(on: node)
    }
}

extension ARObjectAnchor {
    
    func addBoxNode(on node: SCNNode, color: UIColor) {
        // 直方体ジオメトリを作成
        let extent = referenceObject.extent
        let geometry = SCNBox(width: CGFloat(extent.x), height: CGFloat(extent.y), length: CGFloat(extent.z), chamferRadius: 0.01)
        if let material = geometry.firstMaterial {
            material.diffuse.contents = color
            material.lightingModel = .physicallyBased
        }

        // 直方体ジオメトリを持つノードを作成
        let boxNode = SCNNode(geometry: geometry)
        boxNode.position = SCNVector3(referenceObject.center)
        DispatchQueue.main.async(execute: {
            node.addChildNode(boxNode)
        })
    }

    func findBoxNode(on node: SCNNode) -> SCNNode? {
        for childNode in node.childNodes {
            if childNode.geometry as? SCNBox != nil {
                return childNode
            }
        }
        return nil
    }

    func updateBoxNode(on node: SCNNode) {
        DispatchQueue.main.async(execute: {
            // 中心座標を更新
            guard let boxNode = self.findBoxNode(on: node) else { return }
            boxNode.position = SCNVector3(self.referenceObject.center)

            // サイズを更新
            guard let box = boxNode.geometry as? SCNBox else { fatalError() }
            let extent = self.referenceObject.extent
            box.width = CGFloat(extent.x)
            box.height = CGFloat(extent.y)
            box.length = CGFloat(extent.z)
        })
    }
    
    func removeBoxNode(on node: SCNNode) {
        DispatchQueue.main.async(execute: {
            guard let boxNode = self.findBoxNode(on: node) else { return }
            boxNode.removeFromParentNode()
        })
    }
}
