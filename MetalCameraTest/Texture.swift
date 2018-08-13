//
//  Texture.swift
//  MetalCameraTest
//
//  Created by HasegawaYasuo on 2018/08/11.
//  Copyright © 2018年 HasegawaYasuo. All rights reserved.
//

import Foundation
import MetalKit

enum TextureError: Error {
    case UIImageCreationError
    case MTKTextureLoaderError
}

func makeTexture(device: MTLDevice, name:String) throws -> MTLTexture {
    
    guard let image = UIImage(named:name) else {
        throw TextureError.UIImageCreationError
    }
    
    do {
        let textureLoader = MTKTextureLoader(device: device)
        return try textureLoader.newTexture(cgImage: image.cgImage!, options: [ MTKTextureLoader.Option(rawValue: MTKTextureLoader.Option.SRGB.rawValue):false ])
    }
    
}
