//
//  WorldMappingStatus+Description.swift
//
//  Created by Shuichi Tsutsumi on 2018/09/16.
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import ARKit

extension ARFrame.WorldMappingStatus {
    
    public var description: String {
        switch self {
        case .notAvailable:
            return "World mapping is not available."
        case .limited:
            return "World mapping is available but has limited features."
        case .extending:
            return "World mapping is actively extending the map with the user's motion."
        case .mapped:
            return "World mapping has adequately mapped the visible area."
        @unknown default:
            fatalError()
        }
    }
}
