//
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!

    private let device = MTLCreateSystemDefaultDevice()!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, .showWireframe]
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration)
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { fatalError() }
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        
        // 平面ジオメトリを作成
        let geometry = ARSCNPlaneGeometry(device: device)!
        
        // アンカーが持っているジオメトリ情報でアップデート
        geometry.update(from: planeAnchor.geometry)
        
        // アライメントによって色をわける
        let color: UIColor = planeAnchor.alignment == .horizontal ? UIColor.yellow : UIColor.blue
        
        // 平面ジオメトリを持つノードを作成
        planeAnchor.addPlaneNode(on: node, geometry: geometry, contents: color.withAlphaComponent(0.3))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { fatalError() }
        planeAnchor.updatePlaneGeometryNode(on: node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
        guard let planeAnchor = anchor as? ARPlaneAnchor else { fatalError() }
        planeAnchor.findPlaneGeometryNode(on: node)?.removeFromParentNode()
    }
}
