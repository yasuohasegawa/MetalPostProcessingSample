//
//  Quad.swift
//  MetalCameraTest
//
//  Created by HasegawaYasuo on 2018/08/11.
//  Copyright © 2018年 HasegawaYasuo. All rights reserved.
//

import Foundation
import Metal
import GLKit

struct Quad {
    
    let vertices = [
        Vertex(xyz: GLKVector3(v:(-1, -1,  0)), n: GLKVector3(v:(0, 0, 1)), rgba: GLKVector4(v:(1, 0, 0, 1)), st: GLKVector2(v:(0, 1))),
        Vertex(xyz: GLKVector3(v:( 1, -1,  0)), n: GLKVector3(v:(0, 0, 1)), rgba: GLKVector4(v:(0, 1, 0, 1)), st: GLKVector2(v:(1, 1))),
        Vertex(xyz: GLKVector3(v:( 1,  1,  0)), n: GLKVector3(v:(0, 0, 1)), rgba: GLKVector4(v:(0, 0, 1, 1)), st: GLKVector2(v:(1, 0))),
        Vertex(xyz: GLKVector3(v:(-1,  1,  0)), n: GLKVector3(v:(0, 0, 1)), rgba: GLKVector4(v:(1, 1, 0, 1)), st: GLKVector2(v:(0, 0))),
        ]
    
    let vertexIndices: [UInt16] =
        [
            0, 1, 2,
            2, 3, 0
    ]
    
    var vertexMetalBuffer: MTLBuffer
    var vertexIndexMetalBuffer: MTLBuffer
    var metallicTransform: MTTransform
    var indexCount: Int {
        return vertexIndexMetalBuffer.length / MemoryLayout<UInt16>.size
    }
    
    init(device: MTLDevice) {
        let vertexSize = MemoryLayout<Vertex>.size
        let vertexCount = self.vertices.count
        
        self.vertexMetalBuffer      = device.makeBuffer(bytes: self.vertices,      length: vertexSize * vertexCount,       options: [])!
        self.vertexIndexMetalBuffer = device.makeBuffer(bytes: self.vertexIndices, length: MemoryLayout<UInt16>.size * self.vertexIndices.count , options: [])!
        
        self.metallicTransform = MTTransform(device: device)
        
    }
    
}
