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
    @IBOutlet weak var worldMappingStateLabel: UILabel!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var loadBtn: UIButton!
    
    lazy var mapSaveURL: URL = {
        return try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("map.arexperience")
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadBtn.isHidden = mapDataFromFile == nil

        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        saveBtn.isEnabled = false
        
        runSession()
    }
    
    private func runSession(initialWorldMap: ARWorldMap? = nil) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        if let worldMap = initialWorldMap {
            configuration.initialWorldMap = worldMap
        }
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func saveCurrentWorldMap() {
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let worldMap = worldMap else { fatalError("WorldMap取得失敗: \(error!.localizedDescription)") }
            
            let data = try! NSKeyedArchiver.archivedData(withRootObject: worldMap,
                                                         requiringSecureCoding: true)
            try! data.write(to: self.mapSaveURL, options: [.atomic])
            DispatchQueue.main.async {
                self.loadBtn.isHidden = false
                self.loadBtn.isEnabled = true
            }
        }
    }
    
    // Called opportunistically to verify that map data can be loaded from filesystem.
    private var mapDataFromFile: Data? {
        return try? Data(contentsOf: mapSaveURL)
    }

    private func loadSavedWorldMap() {
        guard let data = mapDataFromFile else { return }
        let worldMap = try! NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self,
                                                               from: data)
        runSession(initialWorldMap: worldMap)
    }
    
    // MARK: - Actions
    
    @IBAction func saveBtnTapped(_ sender: UIButton) {
        saveCurrentWorldMap()
    }

    @IBAction func loadBtnTapped(_ sender: UIButton) {
        loadSavedWorldMap()
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = sceneView.session.currentFrame else { return }
        
        DispatchQueue.main.async {
            // ワールドマッピングステータスがmappedのときだけ保存ボタンを有効にする
            self.saveBtn.isEnabled = frame.worldMappingStatus == .mapped
            
            self.worldMappingStateLabel.text = frame.worldMappingStatus.description
        }
        
        sceneView.updateLightingEnvironment(for: frame)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        trackingStateLabel.text = camera.trackingState.description
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        guard let planeGeoemtry = ARSCNPlaneGeometry(device: sceneView.device!) else { fatalError() }
        planeAnchor.addPlaneNode(on: node, geometry: planeGeoemtry, contents: UIColor.blue.withAlphaComponent(0.3))

        let virtualNode = VirtualObjectNode()
        DispatchQueue.main.async(execute: {
            node.addChildNode(virtualNode)
        })
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        planeAnchor.updatePlaneGeometryNode(on: node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        planeAnchor.findPlaneGeometryNode(on: node)?.removeFromParentNode()
    }
}
