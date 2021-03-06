//
//  Mesh.swift
//  MetalCameraTest
//
//  Created by HasegawaYasuo on 2018/08/12.
//  Copyright © 2018年 HasegawaYasuo. All rights reserved.
//

import Foundation
import ModelIO

import SceneKit
import SceneKit.ModelIO

import MetalKit
import MetalKit.MTKModel

import GLKit

class Mesh {
    
    var metallicTransform: MTTransform
    
    var modelIOMeshMetallic: MDLMesh
    var modelIOMesh:MDLMesh
    var metalMesh: MTKMesh
    
    var metalVertexDescriptor:MTLVertexDescriptor
    
    var vertexMetalBuffer:MTLBuffer
    var vertexIndexMetalBuffer:MTLBuffer
    
    var primitiveType:MTLPrimitiveType
    
    var indexCount:Int
    
    var indexType:MTLIndexType
    
    private init(device:MTLDevice, mdlMeshProvider:() -> MDLMesh) {
        
        metallicTransform = MTTransform(device:device)
        
        // Metal vertex descriptor
        metalVertexDescriptor = MTLVertexDescriptor.xyz_n_st_vertexDescriptor()
        
        // Model I/O vertex descriptor
        let modelIOVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(metalVertexDescriptor)
        (modelIOVertexDescriptor.attributes[ 0 ] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (modelIOVertexDescriptor.attributes[ 1 ] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (modelIOVertexDescriptor.attributes[ 2 ] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        
        metalVertexDescriptor = MTLVertexDescriptor.xyz_n_st_vertexDescriptor()
        
        modelIOMeshMetallic = mdlMeshProvider()
        modelIOMeshMetallic.vertexDescriptor = modelIOVertexDescriptor
        
        do {
            metalMesh = try MTKMesh(mesh:modelIOMeshMetallic, device:device)
        } catch {
            fatalError("Error: Can not create Metal mesh")
        }
        
        indexCount = metalMesh.submeshes[ 0 ].indexCount
        indexType = metalMesh.submeshes[ 0 ].indexType
        
        vertexIndexMetalBuffer = metalMesh.submeshes[ 0 ].indexBuffer.buffer
        
        vertexMetalBuffer = metalMesh.vertexBuffers[ 0 ].buffer
        
        primitiveType = metalMesh.submeshes[ 0 ].primitiveType
        
        // unused - to shut compiler up
        modelIOMesh = MDLMesh.newPlane(withDimensions:vector_float2(4, 4),
                                       segments:vector_uint2(2, 2),
                                       geometryType:.triangles,
                                       allocator:nil)
        
        
    }
    
    private init(device:MTLDevice, sceneName:String, nodeName:String) {
        
        metallicTransform = MTTransform(device:device)
        
        // Metal vertex descriptor
        metalVertexDescriptor = MTLVertexDescriptor.xyz_n_st_vertexDescriptor()
        
        // Model I/O vertex descriptor
        let modelIOVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(metalVertexDescriptor)
        (modelIOVertexDescriptor.attributes[ 0 ] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (modelIOVertexDescriptor.attributes[ 1 ] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (modelIOVertexDescriptor.attributes[ 2 ] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        
        metalVertexDescriptor = MTLVertexDescriptor.xyz_n_st_vertexDescriptor()
        
        guard let scene = SCNScene(named:sceneName) else {
            fatalError("Error: Can not create SCNScene with \(sceneName)")
        }
        
        guard let sceneNode = scene.rootNode.childNode(withName:nodeName, recursively:true) else {
            fatalError("Error: Can not create sceneNode")
        }
        
        guard let sceneGeometry = sceneNode.geometry else {
            fatalError("Error: Can not create sceneGeometry")
        }
        
        modelIOMesh = MDLMesh(scnGeometry:sceneGeometry, bufferAllocator:nil)
        modelIOMesh.vertexDescriptor = modelIOVertexDescriptor
        
        
        
        // To create that cool low-poly look
        modelIOMesh.makeVerticesUnique()
        modelIOMesh.addNormals(withAttributeNamed:MDLVertexAttributeNormal, creaseThreshold:1.0)
        
        
        
        let mdlSubmesh:MDLSubmesh = modelIOMesh.submeshes?[ 0 ] as! MDLSubmesh
        
        indexCount = mdlSubmesh.indexCount
        indexType = (.uInt32 == mdlSubmesh.indexType) ? .uint32 : .uint16;
        
        let indexBuffer = mdlSubmesh.indexBuffer
        vertexIndexMetalBuffer = device.makeBuffer(bytes:indexBuffer.map().bytes,
                                                   length:indexBuffer.length,
                                                   options:MTLResourceOptions.storageModeShared)!
        
        let vertexBuffer = modelIOMesh.vertexBuffers[ 0 ]
        vertexMetalBuffer = device.makeBuffer(bytes:vertexBuffer.map().bytes,
                                              length:vertexBuffer.length,
                                              options:MTLResourceOptions.storageModeShared)!
        
        modelIOMeshMetallic = MDLMesh.newPlane(withDimensions:vector_float2(4, 4),
                                               segments:vector_uint2(2, 2),
                                               geometryType:.triangles,
                                               allocator: MTKMeshBufferAllocator(device:device))
        
        modelIOMeshMetallic.vertexDescriptor = modelIOVertexDescriptor
        
        do {
            metalMesh = try MTKMesh(mesh:modelIOMeshMetallic, device:device)
        } catch {
            fatalError("Error: Can not create Metal mesh")
        }
        
        primitiveType = metalMesh.submeshes[ 0 ].primitiveType
        
    }
    
    class func plane(device: MTLDevice,
                     xExtent:Float,
                     zExtent:Float,
                     xTesselation:UInt32,
                     zTesselation:UInt32) -> Mesh {
        
        return Mesh(device:device, mdlMeshProvider:{
            
            return MDLMesh.newPlane(withDimensions:vector_float2(xExtent, zExtent), segments:vector_uint2(xTesselation, zTesselation), geometryType:.triangles, allocator: MTKMeshBufferAllocator(device:device))
            
        })
        
    }
    
    class func cube(device: MTLDevice,
                    xExtent:Float,
                    yExtent:Float,
                    zExtent:Float,
                    xTesselation:UInt32,
                    yTesselation:UInt32,
                    zTesselation:UInt32) -> Mesh {
        
        return Mesh(device:device, mdlMeshProvider:{
            
            return MDLMesh.newBox(withDimensions: vector_float3(xExtent, yExtent, zExtent),
                                  segments: vector_uint3(xTesselation, yTesselation, zTesselation),
                                  geometryType: .triangles,
                                  inwardNormals: false,
                                  allocator: MTKMeshBufferAllocator(device: device))
            
        })
        
    }
    
    class func sphere(device: MTLDevice,
                      xRadius:Float,
                      yRadius:Float,
                      zRadius:Float,
                      uTesselation:Int,
                      vTesselation:Int) -> Mesh {
        
        return Mesh(device:device, mdlMeshProvider:{
            
            return MDLMesh.newEllipsoid(withRadii: vector_float3(xRadius, yRadius, zRadius),
                                        radialSegments: uTesselation,
                                        verticalSegments: vTesselation,
                                        geometryType: .triangles,
                                        inwardNormals: false,
                                        hemisphere: false,
                                        allocator: MTKMeshBufferAllocator(device: device))
            
        })
        
    }
    
    class func sceneMesh(device:MTLDevice, sceneName:String, nodeName:String) -> Mesh {
        return Mesh(device:device, sceneName:sceneName, nodeName:nodeName)
    }
    
}
