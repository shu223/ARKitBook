//
//  ViewController.swift
//  ARDebug
//
//  Created by Shuichi Tsutsumi on 2017/07/17.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    private var virtualObjectNode: SCNNode!
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var trackingStateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 仮想オブジェクトのノードを作成
        virtualObjectNode = loadModel()

        sceneView.delegate = self
        
        // シーンを生成してARSCNViewにセット
        sceneView.scene = SCNScene()
        
        // セッションのコンフィギュレーションを生成
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true

        // デバッグオプション
//        sceneView.debugOptions = [.showBoundingBoxes]
//        sceneView.debugOptions = [.showWireframe]
        sceneView.debugOptions = [.renderAsWireframe]

        // セッション開始
        sceneView.session.run(configuration)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    private func loadModel() -> SCNNode {
        guard let scene = SCNScene(named: "duck.scn", inDirectory: "models.scnassets/duck") else {fatalError()}
        
        let modelNode = SCNNode()
        for child in scene.rootNode.childNodes {
            modelNode.addChildNode(child)
        }
        
        return modelNode
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        // 平面アンカーを可視化
        planeAnchor.addPlaneNode(on: node, contents: UIColor.yellow)
        
        DispatchQueue.main.async(execute: {
            // 仮想オブジェクトを乗せる
            node.addChildNode(self.virtualObjectNode)
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        DispatchQueue.main.async(execute: {
            planeAnchor.updatePlaneNode(on: node)
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }

    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        trackingStateLabel.text = camera.trackingState.description
    }
}

