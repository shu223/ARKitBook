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

class ViewController: UIViewController, ARSCNViewDelegate {
    
    private var startNode: SCNNode?
    private var endNode: SCNNode?
    private var lineNode: SCNNode?

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var trackingStateLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var resetBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // デバッグオプションをセット
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

        // シーンを生成してARSCNViewにセット
        sceneView.scene = SCNScene()
        
        reset()
        
        // セッション開始
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Private
    
    private func reset() {
        startNode?.removeFromParentNode()
        startNode = nil
        endNode?.removeFromParentNode()
        endNode = nil
        statusLabel.isHidden = true
    }
    
    private func putSphere(at pos: SCNVector3, color: UIColor) -> SCNNode {
        let node = SCNNode.sphereNode(color: color)
        sceneView.scene.rootNode.addChildNode(node)
        node.position = pos
        return node
    }
    
    private func drawLine(from: SCNNode, to: SCNNode, length: Float) -> SCNNode {
        let lineNode = SCNNode.lineNode(length: CGFloat(length), color: UIColor.red)
        from.addChildNode(lineNode)
        lineNode.position = SCNVector3Make(0, 0, -length / 2)
        from.look(at: to.position)
        return lineNode
    }
    
    private func hitTest(_ pos: CGPoint) {

        // 平面を対象にヒットテストを実行
        let results = sceneView.hitTest(pos, types: [.existingPlane])

        // 平面もしくは特徴点を対象にヒットテストを実行
//        let results = sceneView.hitTest(pos, types: [.existingPlane, .featurePoint])

        // 最も近い（手前にある）結果を取得
        guard let result = results.first else {return}
        
        // ヒットした位置を計算する
        let hitPos = result.worldTransform.position()
        
        // 始点はもう決まっているか？
        if let startNode = startNode {
            // 終点を決定する（終点ノードを追加）
            endNode = putSphere(at: hitPos, color: UIColor.green)
            guard let endNode = endNode else {fatalError()}
            
            // 始点と終点の距離を計算する
            let distance = (endNode.position - startNode.position).length()
            print("distance: \(distance) [m]")
            
            // 始点と終点を結ぶ線を描画する
            lineNode = drawLine(from: startNode, to: endNode, length: distance)
            
            // ラベルに表示
            statusLabel.text = String(format: "Distance: %.2f [m]", distance)
        } else {
            // 始点を決定する（始点ノードを追加）
            startNode = putSphere(at: hitPos, color: UIColor.blue)
            statusLabel.text = "終点をタップしてください"
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = sceneView.session.currentFrame else {return}
        DispatchQueue.main.async(execute: {
            self.statusLabel.isHidden = !(frame.anchors.count > 0)
            if self.startNode == nil {
                self.statusLabel.text = "始点をタップしてください"
            }
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        planeAnchor.addPlaneNode(on: node, contents: UIColor.yellow.withAlphaComponent(0.1))
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
        trackingStateLabel.text = camera.trackingState.description
    }

    // MARK: - Touch Handlers
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // タップ位置のスクリーン座標を取得
        guard let touch = touches.first else {return}
        let pos = touch.location(in: sceneView)
        
        // 終点が既に決まっている場合は終点を置き換える処理とする
        if let endNode = endNode {
            endNode.removeFromParentNode()
            lineNode?.removeFromParentNode()
        }
        
        hitTest(pos)
    }

    // MARK: - Actions

    @IBAction func resetBtnTapped(_ sender: UIButton) {
        reset()
    }
}

extension SCNNode {
    
    class func sphereNode(color: UIColor) -> SCNNode {
        let geometry = SCNSphere(radius: 0.01)
        geometry.materials.first?.diffuse.contents = color
        return SCNNode(geometry: geometry)
    }
    
    class func lineNode(length: CGFloat, color: UIColor) -> SCNNode {
        
        // 線としてのカプセル型ジオメトリを持つノード
        let geometry = SCNCapsule(capRadius: 0.004, height: length) // 半径4cm
        geometry.materials.first?.diffuse.contents = color
        let line = SCNNode(geometry: geometry)
        
        // lineをz軸に対して90°回転させるためのコンテナノード
        let node = SCNNode()
        node.eulerAngles = SCNVector3Make(Float.pi/2, 0, 0)
        node.addChildNode(line)
        
        return node
    }
}
