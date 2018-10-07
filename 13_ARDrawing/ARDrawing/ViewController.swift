//
//  ViewController.swift
//  ARDrawing
//
//  Created by Shuichi Tsutsumi on 2017/07/17.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import ColorSlider

class ViewController: UIViewController, ARSCNViewDelegate {
    
    private var drawingNodes = [DynamicGeometryNode]()

    private var isTouching = false {
        didSet {
            pen.isHidden = !isTouching
        }
    }
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var pen: UILabel!
    @IBOutlet var resetBtn: UIButton!

    @IBOutlet var colorSlider: ColorSlider!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupColorPicker()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // デバッグオプションをセット
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

        // シーンを生成してARSCNViewにセット
        sceneView.scene = SCNScene()
        
        // セッションのコンフィギュレーションを生成
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true

        statusLabel.text = "Wait..."
        pen.isHidden = true
        
        // セッション開始
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Private

    private func setupColorPicker() {
        colorSlider.orientation = .horizontal
        colorSlider.previewEnabled = true
    }
        
    private func reset() {
        for node in drawingNodes {
            node.removeFromParentNode()
        }
        drawingNodes.removeAll()
    }
    
    private func isReadyForDrawing(trackingState: ARCamera.TrackingState) -> Bool {
        switch trackingState {
        case .normal:
            return true
        default:
            return false
        }
    }
    
    // デバイスの現在位置（スクリーンの中心座標）をワールド座標に変換
    private func worldPositionForScreenCenter() -> SCNVector3 {
        // スクリーンの中心座標を取得
        let screenBounds = UIScreen.main.bounds
        let center = CGPoint(x: screenBounds.midX, y: screenBounds.midY)
        
        // 3次元ベクトルにする
        let centerVec3 = SCNVector3Make(Float(center.x), Float(center.y), 0.99)
        
        // unproject（ワールド座標に変換）する
        return sceneView.unprojectPoint(centerVec3)
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard isTouching else {return}
        guard let currentDrawing = drawingNodes.last else {return}
        
        DispatchQueue.main.async(execute: {
            let vertice = self.worldPositionForScreenCenter()
            currentDrawing.addVertice(vertice)
        })
    }

    // MARK: - ARSessionObserver

    func session(_ session: ARSession, didFailWithError error: Error) {
        print("\(self.classForCoder)/\(#function), error: " + error.localizedDescription)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        
        let state = camera.trackingState
        let isReady = isReadyForDrawing(trackingState: state)
        statusLabel.text = isReady ? "Touch the screen to draw." : "Wait. " + state.description
    }
    
    // MARK: - Touch Handlers
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let frame = sceneView.session.currentFrame else {return}
        guard isReadyForDrawing(trackingState: frame.camera.trackingState) else {return}
        
        let drawingNode = DynamicGeometryNode(color: colorSlider.color, lineWidth: 0.004)
        sceneView.scene.rootNode.addChildNode(drawingNode)
        drawingNodes.append(drawingNode)

        statusLabel.text = "Move your device!"

        isTouching = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        statusLabel.text = "Touch the screen to draw."
    }
    
    // MARK: - Actions

    @IBAction func resetBtnTapped(_ sender: UIButton) {
        reset()
    }
}

