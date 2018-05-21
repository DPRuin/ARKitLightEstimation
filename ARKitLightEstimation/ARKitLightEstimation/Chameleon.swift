/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This file manages the movements and display of the Chameleon using SceneKit.
 */

import Foundation
import SceneKit
import ARKit

class Chameleon: SCNScene {
	
	// Special nodes used to control animations of the model
	private let contentRootNode = SCNNode()
	private var geometryRoot: SCNNode!
    
    private var head: SCNNode!

	private var skin: SCNMaterial!
    
	// State variables
	private var modelLoaded: Bool = false
    
	private var changeColorTimer: Timer?
	private var lastColorFromEnvironment = SCNVector3(130.0 / 255.0, 196.0 / 255.0, 174.0 / 255.0)
	
	// MARK: - Initialization and Loading
	
	override init() {
		super.init()
		
		// Load the environment map
		self.lightingEnvironment.contents = UIImage(named: "art.scnassets/environment_blur.exr")!
		
		// Load the chameleon
		loadModel()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func loadModel() {
		guard let virtualObjectScene = SCNScene(named: "chameleon", inDirectory: "art.scnassets") else {
			return
		}
		
		let wrapperNode = SCNNode()
		for child in virtualObjectScene.rootNode.childNodes {
			wrapperNode.addChildNode(child)
		}
		self.rootNode.addChildNode(contentRootNode)
		contentRootNode.addChildNode(wrapperNode)
		hide()
		
		setupSpecialNodes()
		setupShader()
		resetState()
		
		modelLoaded = true
	}
	
	// MARK: - Public API
    func showHead() {
        head.isHidden = false
    }
    func hideHide() {
        head.isHidden = true
    }
    
	func show() {
		contentRootNode.isHidden = false
	}
	
	func hide() {
		contentRootNode.isHidden = true
		resetState()
	}
	
	func isVisible() -> Bool {
		return !contentRootNode.isHidden
	}
	
	func setTransform(_ transform: simd_float4x4) {
		contentRootNode.simdTransform = transform
	}
}

// MARK: - React To Placement and Tap

extension Chameleon {
	
	func reactToPositionChange(in view: ARSCNView) {
		self.reactToPlacement(in: view)
	}
	
	func reactToInitialPlacement(in view: ARSCNView) {
		self.reactToPlacement(in: view, isInitial: true)
	}
	
	private func reactToPlacement(in sceneView: ARSCNView, isInitial: Bool = false) {
		if isInitial {
			DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
				self.getColorFromEnvironment(sceneView: sceneView)
				self.activateCamouflage(true)
			})
		} else {
			DispatchQueue.main.async {
                self.updateCamouflage(sceneView: sceneView)
			}
		}
	}
	
	func activateCamouflage(_ activate: Bool) {
		skin.setValue(NSValue(scnVector3: lastColorFromEnvironment), forKey: "skinColorFromEnvironment")
		
		let blendFactor = activate ? 1.0 : 0.0
		
		SCNTransaction.begin()
		SCNTransaction.animationDuration = 1.5
		skin.setValue(blendFactor, forKey: "blendFactor")
		SCNTransaction.commit()
	}
	
	private func updateCamouflage(sceneView: ARSCNView) {
		getColorFromEnvironment(sceneView: sceneView)
		
		SCNTransaction.begin()
		SCNTransaction.animationDuration = 1.5
		self.skin.setValue(NSValue(scnVector3: lastColorFromEnvironment), forKey: "skinColorFromEnvironment")
		SCNTransaction.commit()
	}
    
    private func getColorFromEnvironment(sceneView: ARSCNView) {
        let worldPos = sceneView.projectPoint(contentRootNode.worldPosition)
        let colorVector = sceneView.averageColorFromEnvironment(at: worldPos)
        lastColorFromEnvironment = colorVector
    }
    
}

// MARK: - React To Rendering

extension Chameleon {
	
	func reactToRendering(in sceneView: ARSCNView) {
		// Update environment map to match ambient light level
		lightingEnvironment.intensity = (sceneView.session.currentFrame?.lightEstimate?.ambientIntensity ?? 1000) / 100
	}
}

// MARK: - Helper functions

extension Chameleon {
	
	private func rad(_ deg: Float) -> Float {
		return deg * Float.pi / 180
	}
	
	private func randomlyUpdate(_ vector: inout simd_float3) {
		switch arc4random() % 400 {
		case 0: vector.x = 0.1
		case 1: vector.x = -0.1
		case 2: vector.y = 0.1
		case 3: vector.y = -0.1
		case 4, 5, 6, 7: vector = simd_float3()
		default: break
		}
	}
	
	private func setupSpecialNodes() {
		// Retrieve nodes we need to reference for animations.
		geometryRoot = self.rootNode.childNode(withName: "Chameleon", recursively: true)
        head = self.rootNode.childNode(withName: "Neck02", recursively: true)

		skin = geometryRoot.geometry?.materials.first
		
		// Fix materials
		geometryRoot.geometry?.firstMaterial?.lightingModel = .physicallyBased
		geometryRoot.geometry?.firstMaterial?.roughness.contents = "art.scnassets/textures/chameleon_ROUGHNESS.png"
		let shadowPlane = self.rootNode.childNode(withName: "Shadow", recursively: true)
		shadowPlane?.castsShadow = false
	}
	
	private func resetState() {
        
		if changeColorTimer != nil {
			changeColorTimer?.invalidate()
			changeColorTimer = nil
		}
	}
	
    /// 设置着色修改器
	private func setupShader() {
		guard let path = Bundle.main.path(forResource: "skin", ofType: "shaderModifier", inDirectory: "art.scnassets"),
			let shader = try? String(contentsOfFile: path, encoding: String.Encoding.utf8) else {
			return
		}
		// 字典
		skin.shaderModifiers = [SCNShaderModifierEntryPoint.surface: shader]

		skin.setValue(Double(0), forKey: "blendFactor")
		skin.setValue(NSValue(scnVector3: SCNVector3Zero), forKey: "skinColorFromEnvironment")
		
		let sparseTexture = SCNMaterialProperty(contents: UIImage(named: "art.scnassets/textures/chameleon_DIFFUSE_BASE.png")!)
		skin.setValue(sparseTexture, forKey: "sparseTexture")
	}
}
