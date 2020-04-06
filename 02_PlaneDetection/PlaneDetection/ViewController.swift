//
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self

        // シーンを生成してARSCNViewにセット
        sceneView.scene = SCNScene()
        
        // セッションのコンフィギュレーションを生成
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]

        // セッション開始
        sceneView.session.run(configuration)
    }
}

extension ViewController: ARSCNViewDelegate {
    
    // 新しいアンカーに対応するノードがシーンに追加された
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        guard let planeAnchor = anchor as? ARPlaneAnchor else { fatalError() }
        // アライメントによって色をわける
        let color: UIColor = planeAnchor.alignment == .horizontal ? UIColor.yellow : UIColor.blue
        
        // 平面ジオメトリを持つノードを作成し、
        // 検出したアンカーに対応するノードに子ノードとして持たせる
        planeAnchor.addPlaneNode(on: node, contents: color.withAlphaComponent(0.5))
    }
    
    // 対応するアンカーの現在の状態に合うようにノードが更新された
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.updatePlaneNode(on: node)
    }
    
    // 削除されたアンカーに対応するノードがシーンから削除された
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
        guard let planeAnchor = anchor as? ARPlaneAnchor else {fatalError()}
        planeAnchor.findPlaneNode(on: node)?.removeFromParentNode()
    }
}
