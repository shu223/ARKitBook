//
//  ARPlaneAnchor+Visualize.swift
//
//  Created by Shuichi Tsutsumi on 2017/08/29.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import Foundation
import ARKit

extension ARPlaneAnchor {
    
    @discardableResult
    func addPlaneNode(on node: SCNNode, geometry: SCNGeometry, contents: Any) -> SCNNode {
        guard let material = geometry.materials.first else { fatalError() }
        
        if let program = contents as? SCNProgram {
            // シェーダをマテリアルに適用
            material.program = program
        } else {
            material.diffuse.contents = contents
        }
        
        let planeNode = SCNNode(geometry: geometry)
        
        DispatchQueue.main.async(execute: {
            node.addChildNode(planeNode)
        })
        
        return planeNode
    }
    
    @discardableResult
    func addPlaneNode(on node: SCNNode, contents: Any) -> SCNNode {
        // 平面ジオメトリを作成
        let geometry = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
        // 平面ジオメトリを持つノードを作成してaddChildNode
        let planeNode = addPlaneNode(on: node, geometry: geometry, contents: contents)
        // 平面ジオメトリを持つノードをx軸まわりに90度回転
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)

        return planeNode
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
        DispatchQueue.main.async(execute: {
            guard let plane = self.findPlaneNode(on: node)?.geometry as? SCNPlane else { return }
            guard !PlaneSizeEqualToExtent(plane: plane, extent: self.extent) else { return }
            
            // 平面ジオメトリのサイズを更新
            plane.width = CGFloat(self.extent.x)
            plane.height = CGFloat(self.extent.z)
        })
    }
}

fileprivate func PlaneSizeEqualToExtent(plane: SCNPlane, extent: vector_float3) -> Bool {
    if plane.width != CGFloat(extent.x) || plane.height != CGFloat(extent.z) {
        return false
    } else {
        return true
    }
}
