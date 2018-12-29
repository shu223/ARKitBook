//
//  ViewController.swift
//  ImageDetectionAndTracking
//
//  Created by Shuichi Tsutsumi on 2018/08/25.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var trackingStateLabel: UILabel!
    @IBOutlet weak var segmentedCtl: UISegmentedControl!

    private let device = MTLCreateSystemDefaultDevice()!
    private var referenceImage: ARReferenceImage!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        let image = UIImage(named: "namecard")!
        referenceImage = ARReferenceImage(image.cgImage!, orientation: .up, physicalWidth: 0.051)
        
        runSession()
    }
    
    private func runSession() {
        let configuration: ARConfiguration
        switch segmentedCtl.selectedSegmentIndex {
        case 0:
            let worldTrackingConfiguration = ARWorldTrackingConfiguration()
            worldTrackingConfiguration.detectionImages = [referenceImage]
//            worldTrackingConfiguration.maximumNumberOfTrackedImages = 1
            configuration = worldTrackingConfiguration
        case 1:
            let imageTrackingConfiguration = ARImageTrackingConfiguration()
            imageTrackingConfiguration.trackingImages = [referenceImage]
            configuration = imageTrackingConfiguration
        default:
            fatalError()
        }
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    @IBAction func configurationSwitched(_ sender: UISegmentedControl) {
        runSession()
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        trackingStateLabel.text = camera.trackingState.description
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = sceneView.session.currentFrame else { return }
        sceneView.updateLightingEnvironment(for: frame)
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        // 検出した画像アンカーを平面ジオメトリで可視化
        imageAnchor.addPlaneNode(on: node, color: UIColor.blue.withAlphaComponent(0.5))
        print("is tracked: \(imageAnchor.isTracked)")

        // 仮想コンテンツを設置
        let virtualNode = VirtualObjectNode()
        virtualNode.scale = SCNVector3(0.4, 0.4, 0.4)
        DispatchQueue.main.async(execute: {
            node.addChildNode(virtualNode)
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
//        print("is tracked: \(imageAnchor.isTracked)")
        imageAnchor.updatePlaneNode(on: node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        imageAnchor.removePlaneNode(on: node)
    }
}

extension ARImageAnchor {
    // 画像アンカーと同じサイズの平面ジオメトリを持つノードを追加する
    func addPlaneNode(on node: SCNNode, color: UIColor) {
        // 物理サイズを取得
        let size = referenceImage.physicalSize

        // 同じサイズの平面ジオメトリを作成
        let geometry = SCNPlane(width: size.width, height: size.height)
        geometry.materials.first?.diffuse.contents = color
        
        // 平面ジオメトリを持つノードを作成
        let planeNode = SCNNode(geometry: geometry)
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)

        DispatchQueue.main.async(execute: {
            node.addChildNode(planeNode)
        })
    }

    func findPlaneNode(on node: SCNNode) -> SCNNode? {
        for childNode in node.childNodes {
            if childNode.geometry as? SCNPlane != nil {
                return childNode
            }
        }
        return nil
    }

    func updatePlaneNode(on node: SCNNode) {
        let size = referenceImage.physicalSize
        DispatchQueue.main.async(execute: {
            guard let planeNode = self.findPlaneNode(on: node) else { return }
            guard let plane = planeNode.geometry as? SCNPlane else { fatalError() }
            // 平面ジオメトリのサイズを更新
            plane.width = size.width
            plane.height = size.height
        })
    }
    
    func removePlaneNode(on node: SCNNode) {
        DispatchQueue.main.async(execute: {
            guard let planeNode = self.findPlaneNode(on: node) else { return }
            planeNode.removeFromParentNode()
        })
    }
}
