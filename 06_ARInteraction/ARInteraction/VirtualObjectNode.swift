//
//  VirtualObjectNode.swift
//  ARInteraction
//
//  Created by Shuichi Tsutsumi on 2017/09/13.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import ARKit

class VirtualObjectNode: SCNNode {

    init(anchorId: UUID) {
        self.anchorId = anchorId
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let anchorId: UUID
}
