//
//  ViewController.swift
//  ARMetal1
//
//  Created by Shuichi Tsutsumi on 2017/07/17.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
        
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var resetBtn: UIButton!

    private lazy var startTime = Date()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.scene = SCNScene()
        
        label.text = "Wait..."
        
        // セッション開始
        startRunning()
    }
    
    private func startRunning() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func updateTime(_ time: TimeInterval, for material: SCNMaterial) {
        // 時刻を取得
        var floatTime = Float(time)
        
        // バイナリデータにする
        let timeData = Data(bytes: &floatTime, count: MemoryLayout<Float>.size)
        
        // シェーダの引数に対応するキーの値としてセット
        material.setValue(timeData, forKey: "time")
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let currentFrame = sceneView.session.currentFrame else {return}
        for anchor in currentFrame.anchors {
            // 平面ノード取得
            guard let planeAnchor = anchor as? ARPlaneAnchor else {continue}
            guard let node = sceneView.node(for: planeAnchor) else {continue}
            let planeNode = planeAnchor.findPlaneNode(on: node)

            // 時間を更新
            guard let material = planeNode?.geometry?.firstMaterial else {return}
            updateTime(time, for: material)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        
        // SCNProgram作成
        let program = SCNProgram()
        program.vertexFunctionName = "vertexShader"
        program.fragmentFunctionName = "fragmentShader"
        
        planeAnchor.addPlaneNode(on: node, contents: program)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.updatePlaneNode(on: node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }
    
    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        label.text = camera.trackingState.description
    }

    // MARK: - Actions

    @IBAction func resetBtnTapped(_ sender: UIButton) {
        // restart
        startRunning()
    }
}
