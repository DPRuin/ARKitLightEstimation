//
//  ViewController.swift
//  ARKitLightEstimation
//
//  Created by mac126 on 2018/5/18.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {


    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var instructionLabel: UILabel!
    
    @IBOutlet weak var mainStackView: UIStackView!
    @IBOutlet weak var lightEstimationStackView: UIStackView!
    
    @IBOutlet weak var ambientIntensityLabel: UILabel!
    @IBOutlet weak var ambientIntensitySlider: UISlider!
    
    @IBOutlet weak var ambientColorTemperatureLabel: UILabel!
    @IBOutlet weak var ambientColorTemperatureSlider: UISlider!
    
    @IBOutlet weak var lightEstimationSwitch: UISwitch!
    
    var sphereMaterial: SCNMaterial?
    
    /// 光源节点
    var lightNodes = [SCNNode]()
    var detectedHorizontalPlane = false {
        didSet {
            DispatchQueue.main.async {
                self.mainStackView.isHidden = !self.detectedHorizontalPlane
                self.instructionLabel.isHidden = self.detectedHorizontalPlane
                self.lightEstimationStackView.isHidden = !self.detectedHorizontalPlane
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Create a new scene
        // let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        // sceneView.scene = scene
        // sceneView.automaticallyUpdatesLighting
        // sceneView.autoenablesDefaultLighting
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSceneView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    private func setupSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        sceneView.delegate = self
    }
    
    // MARK: - switch and slider
    
    @IBAction func ambientColorTemperatureSliderValueDidChange(_ sender: UISlider) {
        // print("-color-\(sender.value)")
        DispatchQueue.main.async {
            let ambientColorTemperature = sender.value * 6500
            self.ambientColorTemperatureLabel.text = "Ambient Color Temperature: \(ambientColorTemperature)"
            
            guard !self.lightEstimationSwitch.isOn else {
                return
            }
            
            for lightNode in self.lightNodes {
                guard let light = lightNode.light else {
                    continue
                }
                light.temperature = CGFloat(ambientColorTemperature)
            }
        }
        
    }
    
    @IBAction func ambientIntensitySliderValueDidChange(_ sender: UISlider) {
        // print("-intensity-\(sender.value)")
        DispatchQueue.main.async {
            let ambientIntensity = sender.value * 2000
            self.ambientIntensityLabel.text = "Ambient Intensity: \(ambientIntensity)"
            
            guard !self.lightEstimationSwitch.isOn else {
                return
            }
            
            for lightNode in self.lightNodes {
                guard let light = lightNode.light else {
                    continue
                }
                light.intensity = CGFloat(ambientIntensity)
            }
        }
    }
    
    @IBAction func lightEstimationSwitchValueDidChange(_ sender: UISwitch) {
        print("-light-\(sender.isOn)")

        if sender.isOn {// 光照估计打开 光源更新光照估计
           updateLightNodesLightEstimation()
        } else { // 光照估计未打开，光源更新为slider的值
            ambientIntensitySliderValueDidChange(ambientIntensitySlider)
            ambientColorTemperatureSliderValueDidChange(ambientColorTemperatureSlider)
        }
        
    }
    
    /// 更新光源的光照估计
    private func updateLightNodesLightEstimation() {
        DispatchQueue.main.async {
            guard self.lightEstimationSwitch.isOn , let lightEstimation = self.sceneView.session.currentFrame?.lightEstimate else {
                return
            }
            // 场景的光估计
            let ambientIntensity = Float(lightEstimation.ambientIntensity)
            let ambientColorTemperature: Float = Float(lightEstimation.ambientColorTemperature)
            
            self.ambientIntensitySlider.value = ambientIntensity / 2000.0
            self.ambientColorTemperatureSlider.value = ambientColorTemperature / 6500.0
            self.ambientColorTemperatureLabel.text = "Ambient Color Temperature: \(ambientColorTemperature)"
            self.ambientIntensityLabel.text = "Ambient Intensity: \(ambientIntensity)"
            
            // 环境强度改变时节点材质颜色改变
            if let material = self.sphereMaterial {
                if (ambientIntensity / 2000.0) > 0.5 {
                    material.diffuse.contents = UIColor.orange
                } else {
                    material.diffuse.contents = UIColor.green
                }
            }
            
            // 设置光源的光估计
            for lightNode in self.lightNodes {
                guard let light = lightNode.light else {
                    continue
                }
                
                light.intensity = CGFloat(ambientIntensity)
                light.temperature = CGFloat(ambientColorTemperature)
            }
        }
    }
    
    /// 创建圆球节点
    private func getSphereNode(withPositon position:SCNVector3) -> SCNNode {
        let sphere = SCNSphere(radius: 0.1)
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = position
        sphereNode.position.y += Float(sphere.radius)
        
        
        let material = SCNMaterial()
        sphereMaterial = material
        material.diffuse.contents = UIColor.white
        
        sphere.materials = [material]
        
        return sphereNode
    }
    
    /// 创建光源节点
    private func getLightNode() -> SCNNode {
        let light = SCNLight()
        light.type = .omni
        light.intensity = 0
        light.temperature = 0
        
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(x: -1, y: 1, z: 0.5)
        
        return lightNode
    }
    
    /// 添加光源到节点
    func addLightNodeTo(node: SCNNode) {
        let lightNode = getLightNode()
        node.addChildNode(lightNode)
        lightNodes.append(lightNode)
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor  else {
            return
        }
        
        // 识别到平面添加圆球
        let planeAnchorCenter = SCNVector3(planeAnchor.center)
        let sphereNode = getSphereNode(withPositon: planeAnchorCenter)
        // 添加光源
        addLightNodeTo(node: sphereNode)
        node.addChildNode(sphereNode)
        detectedHorizontalPlane = true
        // 更新光源的光照估计
        updateLightNodesLightEstimation()

    }
    
    // 每帧调用
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // 更新光源的光照估计
        updateLightNodesLightEstimation()
        
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}
