//
//  ViewController.swift
//  VirtualObject
//
//  Created by Shuichi Tsutsumi on 2017/07/17.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // シーンを生成してARSCNViewにセット
        sceneView.scene = SCNScene()
        
        // セッションのコンフィギュレーションを生成
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // セッション開始
        sceneView.session.run(configuration)
    }
    
    private func loadModel() -> SCNNode {
        guard let scene = SCNScene(named: "duck.scn", inDirectory: "models.scnassets/duck") else {fatalError()}
        
        let modelNode = SCNNode()
        
        for child in scene.rootNode.childNodes {
            modelNode.addChildNode(child)
        }
        
        // .dae等のフォーマットからモデルを読み込む場合
//        let url = Bundle.main.url(forResource: "filename", withExtension: "dae")!
//        let sceneSource = SCNSceneSource(url: url, options: nil)!
//        guard let modelNode = sceneSource.entryWithIdentifier("modelId", withClass: SCNNode.self) else {fatalError()}

        return modelNode
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        planeAnchor.addPlaneNode(on: node, contents: UIColor.yellow.withAlphaComponent(0.5))
        
        // 仮想オブジェクトのノードを作成
        let virtualObjectNode = loadModel()
        
        DispatchQueue.main.async(execute: {
            // 仮想オブジェクトを乗せる
            node.addChildNode(virtualObjectNode)
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.updatePlaneNode(on: node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }
}

