//
//  Chameleon.swift
//  ARKitLightEstimation
//
//  Created by mac126 on 2018/5/21.
//  Copyright © 2018年 mac126. All rights reserved.
//

import UIKit
import SceneKit

class Chameleon2: SCNReferenceNode {

    private var skin: SCNMaterial!
    
    private var lastColorFromEnvironment = SCNVector3(130.0 / 255.0, 196.0 / 255.0, 174.0 / 255.0)

    
    override init?(url referenceURL: URL) {
        super.init(url: referenceURL)
        
        setupShader()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadModel() {
        
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
