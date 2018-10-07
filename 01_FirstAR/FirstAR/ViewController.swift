//
//  ViewController.swift
//  FirstAR
//
//  Created by Shuichi Tsutsumi on 2017/07/17.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // シーンを生成してARSCNViewにセット
        sceneView.scene = SCNScene(named: "art.scnassets/ship.scn")!

        // セッションのコンフィギュレーションを生成
        let configuration = ARWorldTrackingConfiguration()
        
        // セッション開始
        sceneView.session.run(configuration)
    }
}
