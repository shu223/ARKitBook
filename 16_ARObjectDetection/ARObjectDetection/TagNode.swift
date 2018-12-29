//
//  TagAnchor.swift
//  ARObjectDetection
//
//  Created by Shuichi Tsutsumi on 2017/09/07.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import SceneKit
import Vision

class TagNode: SCNNode {

    var classificationObservation: VNClassificationObservation? {
        didSet {
            addTextNode()
        }
    }
    
    private func addTextNode() {
        guard let text = classificationObservation?.identifier else {return}
        let shorten = text.components(separatedBy: ", ").first!
        let textNode = SCNNode.textNode(text: shorten)
        DispatchQueue.main.async(execute: {
            self.addChildNode(textNode)
        })
        addSphereNode(color: UIColor.green)
    }
    
    private func addSphereNode(color: UIColor) {
        DispatchQueue.main.async(execute: {
            let sphereNode = SCNNode.sphereNode(color: color)
            self.addChildNode(sphereNode)
        })
    }    
}

extension SCNNode {
    
    class func sphereNode(color: UIColor) -> SCNNode {
        let geometry = SCNSphere(radius: 0.01)
        geometry.materials.first?.diffuse.contents = color
        return SCNNode(geometry: geometry)
    }
    
    class func textNode(text: String) -> SCNNode {
        let geometry = SCNText(string: text, extrusionDepth: 0.01)
        geometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        if let material = geometry.firstMaterial {
            material.diffuse.contents = UIColor.white
            material.isDoubleSided = true
        }
        let textNode = SCNNode(geometry: geometry)
        
        // フォントサイズ小さくしすぎると荒くなるので、scaleで調整
        geometry.font = UIFont.systemFont(ofSize: 1)
        textNode.scale = SCNVector3Make(0.02, 0.02, 0.02)
        
        // テキストが見えるようにtranslationを計算してpivotにセット
        let (min, max) = geometry.boundingBox
        textNode.pivot = SCNMatrix4MakeTranslation((max.x - min.x)/2, min.y - 0.5, 0)
        
        // Y軸を自由にしてカメラの方を向くように（親ノードに）制約をつける
        let node = SCNNode()
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        node.constraints = [billboardConstraint]
        
        node.addChildNode(textNode)
        
        return node
    }
}
