//
//  ViewController.swift
//  FaceTracking
//
//  Created by Shuichi Tsutsumi on 2018/08/08.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var trackingStateLabel: UILabel!
    @IBOutlet weak var wireframeSwitch: UISwitch!
    @IBOutlet weak var fillMeshSwitch: UISwitch!

    private var faceGeometry: ARSCNFaceGeometry!
    private let faceNode = SCNNode()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard ARFaceTrackingConfiguration.isSupported else { fatalError("Not supported") }

        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        sceneView.scene = SCNScene()
        
        updateFaceGeometry()

        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
    }

    private func updateFaceGeometry() {
        let device = sceneView.device!
        faceGeometry = ARSCNFaceGeometry(device: device, fillMesh: fillMeshSwitch.isOn)
        if let material = faceGeometry.firstMaterial {
            material.diffuse.contents = UIColor.green
            material.lightingModel = .physicallyBased
        }
        faceNode.geometry = faceGeometry
    }
    
    @IBAction func wireframeSwitched(_ sender: UISwitch) {
        sceneView.debugOptions = wireframeSwitch.isOn ? [.renderAsWireframe] : []
    }

    @IBAction func fillMeshSwitched(_ sender: UISwitch) {
        updateFaceGeometry()
    }
}

extension ViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        trackingStateLabel.text = camera.trackingState.description
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        faceGeometry.update(from: faceAnchor.geometry)
        
        node.addChildNode(faceNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        faceGeometry.update(from: faceAnchor.geometry)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }
}
