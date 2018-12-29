//
//  ViewController.swift
//  ARTapeMeasure
//
//  Created by Shuichi Tsutsumi on 2017/07/17.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSessionDelegate {
    
    private var hitPointNode: SCNNode?
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var resultLabel: UILabel!
    @IBOutlet var resetBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.session.delegate = self
        
        // シーンを生成してARSCNViewにセット
        sceneView.scene = SCNScene()
        
        // セッションのコンフィギュレーションを生成
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        
        // 特徴量を可視化
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

        // セッション開始
        sceneView.session.run(configuration)
    }

    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let pointCloud = frame.rawFeaturePoints else {
            return
        }
        statusLabel.text = "feature points: \(pointCloud.__count)"
        
//        for index in 0..<pointCloud.__count {
//            let identifier = pointCloud.identifiers[index]  // UInt64
//            let point = pointCloud.points[index]            // vector_float3
//            // do something with point
//        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("\(self.classForCoder)/" + #function)
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        print("\(self.classForCoder)/" + #function)
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        print("\(self.classForCoder)/" + #function)
    }
    
    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        statusLabel.text = camera.trackingState.description
    }

    // MARK: - Private

    private func putSphere(at pos: SCNVector3, color: UIColor) -> SCNNode {
        let node = SCNNode.sphereNode(color: color)
        sceneView.scene.rootNode.addChildNode(node)
        node.position = pos
        return node
    }
    
    private func arkitHitTest(_ pos: CGPoint) {

        // 特徴点と平面を対象にヒットテストを実行
        let results = sceneView.hitTest(pos, types: [.featurePoint, .existingPlane])

        // 最も近い（手前にある）結果を取得
        guard let result = results.first else {
            resultLabel.text = "no hit"
            return
        }
        
        // ヒットした位置を計算する
        let pos = result.worldTransform.position()
        
        // ノードを置く
        if let hitPointNode = hitPointNode {
            hitPointNode.removeFromParentNode()
        }
        hitPointNode = SCNNode.sphereNode(color: UIColor.green)
        hitPointNode?.position = pos
        sceneView.scene.rootNode.addChildNode(hitPointNode!)

        // 結果のタイプの判定
        switch result.type {
        case .featurePoint:
            // 特徴点へのヒット
            print(result.anchor as Any)    // 特徴点にはアンカーはないのでnilになる
        case .existingPlane:
            // 検出済み平面へのヒット
            print(result.anchor as Any)    // ヒットした平面のアンカーが得られる
        default:
            break
        }
        resultLabel.text = result.type == .featurePoint ? "Feature Point" : "Plane"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // タップ位置のスクリーン座標を取得
        guard let touch = touches.first else {return}
        let pos = touch.location(in: sceneView)
        
        arkitHitTest(pos)
    }
    
    @IBAction func resetBtnTapped(_ sender: UIButton) {
        hitPointNode?.removeFromParentNode()
    }
}

extension SCNNode {
    
    class func sphereNode(color: UIColor) -> SCNNode {
        let geometry = SCNSphere(radius: 0.01)
        geometry.materials.first?.diffuse.contents = color
        return SCNNode(geometry: geometry)
    }
}
