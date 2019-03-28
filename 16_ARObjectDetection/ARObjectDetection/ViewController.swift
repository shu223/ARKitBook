//
//  ViewController.swift
//  ARInteraction
//
//  Created by Shuichi Tsutsumi on 2017/07/17.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//
//  Thanks: https://github.com/hanleyweng/CoreML-in-ARKit

import UIKit
import SceneKit
import ARKit
import CoreML
import Vision

class ViewController: UIViewController, ARSCNViewDelegate {

    private var model: VNCoreMLModel!
    private var screenCenter: CGPoint?

    private let serialQueue = DispatchQueue(label: "com.shu223.arkit.objectdetection")
    private var isPerformingCoreML = false

    private var latestResult: VNClassificationObservation?
    private var tags: [TagNode] = []
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var trackingStateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Core MLモデルの準備
        model = try! VNCoreMLModel(for: Inceptionv3().model)
        
        // Set the view's delegate
        sceneView.delegate = self
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
    }
    
    // MARK: - Private
    
    private func coreMLRequest() -> VNCoreMLRequest {
        let request = VNCoreMLRequest(model: model, completionHandler: { (request, error) in
            guard let best = request.results?.first as? VNClassificationObservation  else {
                self.isPerformingCoreML = false
                return
            }
//            print("best: \(best.identifier)")
            
            // 信頼度が低い結果は採用しない
            if best.confidence < 0.5 {
                self.isPerformingCoreML = false
                return
            }

            // 初めて出る認識結果か？（連続してタグ付けされることを防ぐため）
            if self.isFirstOrBestResult(result: best) {
                self.latestResult = best
                self.hitTest()
            }
            
            self.isPerformingCoreML = false
        })
        request.preferBackgroundProcessing = true

        // 画面の中心でクロップした画像を利用する
        request.imageCropAndScaleOption = .centerCrop
        
        return request
    }
    
    private func performCoreML() {

        serialQueue.async {
            guard !self.isPerformingCoreML else {return}
            guard let imageBuffer = self.sceneView.session.currentFrame?.capturedImage else {return}
            self.isPerformingCoreML = true
            
            let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer)
            let request = self.coreMLRequest()
            do {
                try handler.perform([request])
            } catch {
                print(error)
                self.isPerformingCoreML = false
            }
        }
    }
    
    // 初めて出る結果か、前回より良い結果か
    private func isFirstOrBestResult(result: VNClassificationObservation) -> Bool {
        for tag in tags {
            guard let prevRes = tag.classificationObservation else {continue}
            if prevRes.identifier == result.identifier {
                // 前回より良い場合は、前回のを削除
                if prevRes.confidence < result.confidence {
                    if let index = tags.firstIndex(of: tag) {
                        tags.remove(at: index)
                    }
                    tag.removeFromParentNode()
                    return true
                }
                // 重複するノードが既にあり、前回分の方が信頼度が高い
                return false
            }
        }
        return true
    }
    
    private func hitTest() {
        guard let frame = sceneView.session.currentFrame else {return}
        let state = frame.camera.trackingState
        switch state {
        case .normal:
            guard let pos = screenCenter else {return}
            DispatchQueue.main.async(execute: {
                self.hitTest(pos)
            })
        default:
            break
        }
    }
    
    private func hitTest(_ pos: CGPoint) {
        // 平面を対象にヒットテストを実行
        let results1 = sceneView.hitTest(pos, types: [.existingPlaneUsingExtent, .estimatedHorizontalPlane])
        if let result = results1.first {
            addTag(for: result)
            return
        }
        
        // 特徴点を対象にヒットテストを実行
        let results2 = sceneView.hitTest(pos, types: .featurePoint)
        if let result = results2.first {
            addTag(for: result)
        }
    }

    private func addTag(for hitTestResult: ARHitTestResult) {
        let tagNode = TagNode()
        tagNode.transform = SCNMatrix4(hitTestResult.worldTransform)
        tags.append(tagNode)
        tagNode.classificationObservation = latestResult
        sceneView.scene.rootNode.addChildNode(tagNode)
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Core MLによる物体認識を実行
        performCoreML()
    }

    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        trackingStateLabel.text = camera.trackingState.description
    }
}

