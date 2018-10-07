//
//  ViewController.swift
//  ARInteraction
//
//  Created by Shuichi Tsutsumi on 2017/07/17.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

fileprivate let duration1: CFTimeInterval = 0.5
fileprivate let duration2: CFTimeInterval = 0.2

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var trackingStateLabel: UILabel!
    @IBOutlet var lookAtSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // シーンを生成してARSCNViewにセット
        sceneView.scene = SCNScene()
        
        // セッションのコンフィギュレーションを生成
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        
        // セッション開始
        sceneView.session.run(configuration)
    }
    
    // MARK: - Private
    
    private func loadModel(for node: SCNNode) {
        guard let scene = SCNScene(named: "duck.scn", inDirectory: "models.scnassets/duck") else {fatalError()}
        for child in scene.rootNode.childNodes {
            node.addChildNode(child)
        }
    }

    private func planeHitTest(_ pos: CGPoint) {
        
        // 平面を対象にヒットテストを実行
        let results = sceneView.hitTest(pos, types: .existingPlaneUsingExtent)

        // ヒット結果のうち、もっともカメラに近いものを取り出す
        
        if let result = results.first {
            // ヒットした平面のアンカーを取り出す
            guard let anchor = result.anchor else {return}
            
            // 対応するノードを取得
            guard let node = sceneView.node(for: anchor) else {return}
            
            // 平面ジオメトリを持つ子ノードを探す
            for child in node.childNodes {
                guard let plane = child.geometry as? SCNPlane else {continue}

                // 半透明にして戻す
                SCNTransaction.begin()
                SCNTransaction.animationDuration = duration1
                SCNTransaction.completionBlock = {
                    SCNTransaction.animationDuration = duration2
                    plane.firstMaterial?.diffuse.contents = UIColor.yellow
                }
                plane.firstMaterial?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.5)
                SCNTransaction.commit()
                
                break
            }
        }
    }
    
    private func virtualNodeHitTest(_ pos: CGPoint) -> Bool {
        // ヒットテストのオプション設定
        let hitTestOptions = [SCNHitTestOption: Any]()
        
        // ヒットテスト実行
        let results: [SCNHitTestResult] = sceneView.hitTest(pos, options: hitTestOptions)
        
        // ヒットしたノードに合致する仮想オブジェクトはあるか、再帰的に探す
        for child in sceneView.scene.rootNode.childNodes {
            guard let virtualNode = child as? VirtualObjectNode else {continue}
            for result in results {
                for virtualChild in virtualNode.childNodes {
                    guard virtualChild == result.node else {continue}
                    // 該当するノードにリアクションさせる
                    virtualNode.react()
                    return true
                }
            }
        }
        return false
    }

    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}

        // 可視化用の平面ノードを追加
        planeAnchor.addPlaneNode(on: node, contents: UIColor.yellow)
        
        // 仮想オブジェクトのノードを作成
        let virtualNode = VirtualObjectNode(anchorId: anchor.identifier)
        loadModel(for: virtualNode)
        
        DispatchQueue.main.async(execute: {
            // 仮想オブジェクトは**平面アンカーの向きの更新を受けないよう**、ルートに載せる
            self.sceneView.scene.rootNode.addChildNode(virtualNode)
            // 位置だけをアンカーに対応するノードに合わせる
            virtualNode.position = node.position
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.updatePlaneNode(on: node)
        // 更新されたアンカーに対応する仮想オブジェクトを探索
        for child in sceneView.scene.rootNode.childNodes {
            guard let virtualNode = child as? VirtualObjectNode else {continue}
            guard anchor.identifier == virtualNode.anchorId else {continue}
            DispatchQueue.main.async(execute: {
                // 仮想オブジェクトの位置を更新
                virtualNode.position = node.position
            })
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
        // 削除されたアンカーに対応する仮想オブジェクトを探索
        for child in sceneView.scene.rootNode.childNodes {
            guard let virtualNode = child as? VirtualObjectNode else {continue}
            guard anchor.identifier == virtualNode.anchorId else {continue}
            DispatchQueue.main.async(execute: {
                // 仮想オブジェクトを削除
                virtualNode.removeFromParentNode()
            })
        }
    }

    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        trackingStateLabel.text = camera.trackingState.description
    }
    
    // MARK: - ARSessionDelegate
    
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        DispatchQueue.main.async(execute: {
//            if !self.lookAtSwitch.isOn {
//                return
//            }
//            for child in self.sceneView.scene.rootNode.childNodes {
//                guard let virtualNode = child as? VirtualObjectNode else {continue}
//
//                // カメラの位置を計算
//                let mat = SCNMatrix4(frame.camera.transform)
//                let cameraPos = SCNVector3(mat.m41, mat.m42, mat.m43)
//
//                // 仮想オブジェクトとカメラの成すベクトルの、x-z平面における角度を計算
//                let vec = virtualNode.position - cameraPos
//                let angle = atan2f(vec.x, vec.z)
//
//                // 仮想オブジェクトのrotationに反映
//                SCNTransaction.begin()
//                SCNTransaction.animationDuration = 0.1
//                virtualNode.rotation = SCNVector4Make(0, 1, 0, angle + Float.pi)
//                SCNTransaction.commit()
//            }
//        })
//    }
    
    // MARK: - Touch Handlers
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // タップ位置のスクリーン座標を取得
        guard let touch = touches.first else {return}
        let pos = touch.location(in: sceneView)

        // 仮想オブジェクトへのヒットテスト
        let isHit = virtualNodeHitTest(pos)

        if !isHit {
            // 検出済み平面へのヒットテスト
            planeHitTest(pos)
        }
        
    }

    // MARK: - Actions
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        for child in self.sceneView.scene.rootNode.childNodes {
            guard let virtualNode = child as? VirtualObjectNode else {continue}

            if sender.isOn {
                // ビルボード制約を追加
                let billboardConstraint = SCNBillboardConstraint()
                billboardConstraint.freeAxes = SCNBillboardAxis.Y
                virtualNode.constraints = [billboardConstraint]
            } else {
                virtualNode.constraints = []
            }
        }
    }
}

extension SCNNode {
    
    func react() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = duration1
        SCNTransaction.completionBlock = {
            SCNTransaction.animationDuration = duration2
            self.opacity = 1.0
        }
        self.opacity = 0.5
        SCNTransaction.commit()
    }
}

