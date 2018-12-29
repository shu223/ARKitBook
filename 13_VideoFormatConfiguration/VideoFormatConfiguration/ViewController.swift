//
//  ViewController.swift
//
//  Copyright © 2018 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var segmentedCtl: UISegmentedControl!
    @IBOutlet weak var configurationLabel: UILabel!

    private var supportedVideoFormats: [ARConfiguration.VideoFormat]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene = SCNScene()
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        
        runSession()
    }
    
    private func runSession(videoFormat: ARConfiguration.VideoFormat? = nil) {
        let configuration = createConfiguration(for: segmentedCtl.selectedSegmentIndex)

        supportedVideoFormats = type(of: configuration).supportedVideoFormats
        
        if let videoFormat = videoFormat {
            configuration.videoFormat = videoFormat
            print("selected video format: \(videoFormat)")
        }

        DispatchQueue.main.async(execute: {
            self.configurationLabel.text = String(describing: type(of: configuration)) + "\n" + configuration.videoFormat.description
        })

        sceneView.session.run(configuration)
    }
    
    private func createConfiguration(for index: Int) -> ARConfiguration {
        switch index {
        case 0:
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]
            return configuration
        case 1:
            return AROrientationTrackingConfiguration()
        case 2:
            return ARFaceTrackingConfiguration()
        case 3:
            if #available(iOS 12.0, *) {
                return ARImageTrackingConfiguration()
            } else {
                fatalError()
            }
        case 4:
            if #available(iOS 12.0, *) {
                return ARObjectScanningConfiguration()
            } else {
                fatalError()
            }
        default:
            fatalError()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func selectButtonTapped(_ sender: UIButton) {
        var options: [String] = []
        supportedVideoFormats.forEach { (format) in
            options.append(format.description)
        }
        print("\(configurationLabel.text!): \(options)")
        
        showChooser(options: options) { (selectedIndex: Int) in
            let selectedVideoFormat = self.supportedVideoFormats[selectedIndex]
            self.runSession(videoFormat: selectedVideoFormat)
        }
    }
    
    @IBAction func configurationChanged(_ sender: UISegmentedControl) {
        runSession()
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("anchor:\(anchor), node: \(node), node geometry: \(String(describing: node.geometry))")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("\(self.classForCoder)/" + #function)
    }
    
}

extension ViewController {
    func showChooser(options: [String], title: String? = nil, message: String? = nil, handler: @escaping (Int) -> Void) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .actionSheet)
        for index in 0..<options.count {
            let action = UIAlertAction(title: options[index], style: .default) { (action) in
                handler(index)
            }
            alert.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}

extension ARConfiguration.VideoFormat {
    open override var description: String {
        return "res: \(imageResolution), fps: \(framesPerSecond)"
    }
}
