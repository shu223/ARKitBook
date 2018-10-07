//
//  ARPlaneAnchor+PlaneGeometry.swift
//  VirtualObject
//
//  Created by Shuichi Tsutsumi on 2018/10/01.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import ARKit

@available(iOS 11.3, *)
extension ARPlaneAnchor {
    
    func findPlaneGeometryNode(on node: SCNNode) -> SCNNode? {
        for childNode in node.childNodes {
            if childNode.geometry as? ARSCNPlaneGeometry != nil {
                return childNode
            }
        }
        return nil
    }
    
    func updatePlaneGeometryNode(on node: SCNNode) {
        DispatchQueue.main.async(execute: {
            guard let planeGeometry = self.findPlaneGeometryNode(on: node)?.geometry as? ARSCNPlaneGeometry else { return }
            planeGeometry.update(from: self.geometry)
        })
    }
}

