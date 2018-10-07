//
//  ARSampleCommon.swift
//
//  Created by Shuichi Tsutsumi on 2017/09/04.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import ARKit
import SceneKit.ModelIO

class VirtualObjectNode: SCNNode {
    
    enum VirtualObjectType {
        case duck
        case cupandsaucer
        case wheelbarrow
        case teapot
    }

    init(type: VirtualObjectType = .duck) {
        super.init()

        var scale = 1.0
        switch type {
        case .duck:
            loadScn(name: "duck", inDirectory: "models.scnassets/duck")
        case .cupandsaucer:
            loadUsdz(name: "cupandsaucer")
            scale = 0.005
        case .wheelbarrow:
            loadUsdz(name: "wheelbarrow")
            scale = 0.005
        case .teapot:
            loadUsdz(name: "teapot")
            scale = 0.005
        }
        self.scale = SCNVector3(scale, scale, scale)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func react() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        SCNTransaction.completionBlock = {
            SCNTransaction.animationDuration = 0.15
            self.opacity = 1.0
        }
        self.opacity = 0.5
        SCNTransaction.commit()
    }
}

extension SCNNode {
    
    func loadScn(name: String, inDirectory directory: String) {
        guard let scene = SCNScene(named: "\(name).scn", inDirectory: directory) else { fatalError() }
        for child in scene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            addChildNode(child)
        }
    }

    func loadUsdz(name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "usdz") else { fatalError() }
        let mdlAsset = MDLAsset(url: url)
        let scene = SCNScene(mdlAsset: mdlAsset)
        for child in scene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            addChildNode(child)
        }
    }
}

extension SCNView {
    
    private func enableEnvironmentMap(intensity: CGFloat) {
        if scene?.lightingEnvironment.contents == nil {
            if let environmentMap = UIImage(named: "models.scnassets/sharedImages/environment_blur.exr") {
                scene?.lightingEnvironment.contents = environmentMap
            }
        }
        scene?.lightingEnvironment.intensity = intensity
    }
    
    private func enableSceneBackground() {
        if scene?.background.contents == nil {
            if let environment = UIImage(named: "models.scnassets/sharedImages/environment.jpg") {
                scene?.background.contents = environment
            }
        }
    }
    
    func updateLightingEnvironment(for frame: ARFrame) {
        // If light estimation is enabled, update the intensity of the model's lights and the environment map
        let intensity: CGFloat
        if let lightEstimate = frame.lightEstimate {
            intensity = lightEstimate.ambientIntensity / 400
        } else {
            intensity = 2
        }
        DispatchQueue.main.async(execute: {
            self.enableEnvironmentMap(intensity: intensity)
        })
    }

    func updateSceneBackground(for frame: ARFrame) {
        DispatchQueue.main.async(execute: {
            self.enableSceneBackground()
        })
    }
}

