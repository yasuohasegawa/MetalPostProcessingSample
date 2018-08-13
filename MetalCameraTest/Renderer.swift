//
//  Renderer.swift
//  MetalCameraTest
//
//  Created by HasegawaYasuo on 2018/08/11.
//  Copyright © 2018年 HasegawaYasuo. All rights reserved.
//

import Foundation
import MetalKit
import GLKit

class Renderer: NSObject, MTKViewDelegate {
    
    var camera:Camera
    
    var scnModel: Mesh
    var scnModelTexture:MTLTexture
    var scnModelPipelineState:MTLRenderPipelineState!
    
    var bgPlane: Mesh
    var bgPlaneTexture: MTLTexture
    var bgPlanePipelineState: MTLRenderPipelineState!
    
    var renderPipelineState: MTLRenderPipelineState!
    var depthStencilState: MTLDepthStencilState!
    var commandQueue:MTLCommandQueue!
    
    var view:MTKView!
    var device:MTLDevice
    
    // render to texture
    var renderToTexturePassDescriptor: MTLRenderPassDescriptor!
    
    var timeBuffer: MTLBuffer!
    var startDate:Date!
    
    init(view: MTKView, device: MTLDevice) {
        
        self.view = view
        self.device = device
        
        startDate = Date()
        
        self.timeBuffer = self.device.makeBuffer(length: MemoryLayout<Float>.size, options: [])!
        self.timeBuffer.label = "time"
        
        let library = device.makeDefaultLibrary()
        
        camera = Camera(location:GLKVector3(v:(0, 0, 500)), target:GLKVector3(v:(0, 0, 0)), approximateUp:GLKVector3(v:(0, 1, 0)))
        
        scnModel = Mesh.sceneMesh(device:device,
                                   sceneName:"high-res-head-no-groups.scn",
                                   nodeName:"highResHeadIdentity")
        
        do {
            scnModelTexture = try makeTexture(device: device, name: "swirl")
        } catch {
            fatalError("Error: Can not load texture")
        }
        
        do {
            
            let renderPipelineDescriptor =
                MTLRenderPipelineDescriptor(view:view,
                                            library:library!,
                                            vertexShaderName:"showMIOVertexShader",
                                            fragmentShaderName:"showMIOFragmentShader",
                                            doIncludeDepthAttachment: false,
                                            vertexDescriptor: scnModel.metalVertexDescriptor)
            
            renderPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float;
            
            scnModelPipelineState = try device.makeRenderPipelineState(descriptor:renderPipelineDescriptor)
            
        } catch let e {
            Swift.print("\(e)")
        }
        
        
        // camera render plane
        bgPlane = Mesh.plane(device:device, xExtent:2, zExtent:2, xTesselation:4, zTesselation:4)
        
        do {
            bgPlaneTexture = try makeTexture(device: device, name: "bg")
        } catch {
            fatalError("Error: Can not load texture")
        }
        
        do {
            let renderPipelineDescriptor =
                MTLRenderPipelineDescriptor(view:view,
                                            library:library!,
                                            vertexShaderName:"textureMIOVertexShader",
                                            fragmentShaderName:"textureMIOFragmentShader",
                                            doIncludeDepthAttachment: false,
                                            vertexDescriptor: bgPlane.metalVertexDescriptor)
            
            renderPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float;
            
            bgPlanePipelineState = try device.makeRenderPipelineState(descriptor:renderPipelineDescriptor)
            
        } catch let e {
            Swift.print("\(e)")
        }
        
        // Descriptor for rendertexture
        renderToTexturePassDescriptor = MTLRenderPassDescriptor(clearColor:MTLClearColorMake(1, 1, 1, 1), clearDepth:1)
        
        // for post process
        do {
            let renderPipelineDescriptor =
                MTLRenderPipelineDescriptor(view:view,
                                            library:library!,
                                            vertexShaderName:"mapTexture",
                                            fragmentShaderName:"displayTexture",
                                            doIncludeDepthAttachment: false,
                                            vertexDescriptor: nil)
            
            renderPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float;
            
            renderPipelineState = try device.makeRenderPipelineState(descriptor:renderPipelineDescriptor)
            
        } catch let e {
            Swift.print("\(e)")
        }
        
        // stencil
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
        
        commandQueue = device.makeCommandQueue()!
        
        let view2 = view as! BaseMetalView
        view2.arcBall.reshape(viewBounds: self.view.bounds)
        
        camera.setProjection(fovYDegrees:Float(35), aspectRatioWidthOverHeight:Float(view.bounds.size.width / view.bounds.size.height), near: 100, far: 8000)
        
        // color
        let rgbaTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:view.colorPixelFormat, width:Int(view.bounds.size.width), height:Int(view.bounds.size.height), mipmapped:true)
        rgbaTextureDescriptor.usage = [.renderTarget, .shaderRead]
        
        // depth
        let depthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:.depth32Float, width:Int(view.bounds.size.width), height:Int(view.bounds.size.height), mipmapped:false)
        depthTextureDescriptor.usage = .renderTarget
        
        renderToTexturePassDescriptor.colorAttachments[ 0 ].texture = view.device?.makeTexture(descriptor:rgbaTextureDescriptor)
        renderToTexturePassDescriptor.depthAttachment.texture       = view.device?.makeTexture(descriptor:depthTextureDescriptor)
        
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func update(view: BaseMetalView, drawableSize:CGSize) {
        
        bgPlane.metallicTransform.update(camera: camera, transformer: {
            return camera.createRenderPlaneTransform(distanceFromCamera: 0.75 * camera.far) * GLKMatrix4MakeRotation(GLKMathDegreesToRadians(90), 1, 0, 0)
        })
        
        scnModel.metallicTransform.update(camera: camera, transformer: {
            return view.arcBall.rotationMatrix * GLKMatrix4MakeScale(500, 500, 500) * GLKMatrix4MakeTranslation(0.0, 0.075, 0.101)
            //return view.arcBall.rotationMatrix * GLKMatrix4MakeScale(150, 150, 1)
        })
    }
    
    func defaultSampler(device: MTLDevice) -> MTLSamplerState {
        let sampler = MTLSamplerDescriptor()
        sampler.minFilter             = MTLSamplerMinMagFilter.nearest
        sampler.magFilter             = MTLSamplerMinMagFilter.nearest
        sampler.mipFilter             = MTLSamplerMipFilter.nearest
        sampler.maxAnisotropy         = 1
        sampler.sAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.tAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.rAddressMode          = MTLSamplerAddressMode.clampToEdge
        sampler.normalizedCoordinates = true
        sampler.lodMinClamp           = 0
        sampler.lodMaxClamp           = Float.greatestFiniteMagnitude
        return device.makeSamplerState(descriptor: sampler)!
    }
    
    public func draw(in view: MTKView) {
        update(view: view as! BaseMetalView, drawableSize: view.bounds.size)
        
        let pTimeData = timeBuffer.contents()
        let vTimeData = pTimeData.bindMemory(to: Float.self, capacity: 1 / MemoryLayout<Float>.stride)
        vTimeData[0] = Float(Date().timeIntervalSince(startDate))
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        let renderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderToTexturePassDescriptor)
        
        renderCommandEncoder?.setDepthStencilState(depthStencilState)
        renderCommandEncoder?.setFrontFacing(.counterClockwise)
        
        //renderCommandEncoder?.setTriangleFillMode(.fill)
        renderCommandEncoder?.setCullMode(.none)
        //renderCommandEncoder.setTriangleFillMode(.lines)
        
        // render plane
        renderCommandEncoder?.setRenderPipelineState(bgPlanePipelineState)
        renderCommandEncoder?.setVertexBuffer(bgPlane.vertexMetalBuffer, offset: 0, index: 0)
        renderCommandEncoder?.setVertexBuffer(bgPlane.metallicTransform.metalBuffer, offset: 0, index: 1)
        renderCommandEncoder?.setFragmentTexture(bgPlaneTexture, index: 0)
        renderCommandEncoder?.drawIndexedPrimitives(
            type: bgPlane.primitiveType,
            indexCount: bgPlane.indexCount,
            indexType: bgPlane.indexType,
            indexBuffer: bgPlane.vertexIndexMetalBuffer,
            indexBufferOffset: 0)
        
        
        // render model
        renderCommandEncoder?.setRenderPipelineState(scnModelPipelineState)
        renderCommandEncoder?.setVertexBuffer(scnModel.vertexMetalBuffer, offset: 0, index: 0)
        renderCommandEncoder?.setVertexBuffer(scnModel.metallicTransform.metalBuffer, offset: 0, index: 1)
        renderCommandEncoder?.setFragmentTexture(scnModelTexture, index: 0)
        renderCommandEncoder?.drawIndexedPrimitives(
            type: scnModel.primitiveType,
            indexCount: scnModel.indexCount,
            indexType: scnModel.indexType,
            indexBuffer: scnModel.vertexIndexMetalBuffer,
            indexBufferOffset: 0)
        renderCommandEncoder?.endEncoding()
        
        // final pass
        if let passDescriptor = view.currentRenderPassDescriptor, let drawable = view.currentDrawable {
            
            passDescriptor.colorAttachments[ 0 ].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0)
            
            let renderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: passDescriptor)
            renderCommandEncoder?.setDepthStencilState(depthStencilState)
            renderCommandEncoder?.setFrontFacing(.counterClockwise)
            
            //renderCommandEncoder?.setTriangleFillMode(.fill)
            renderCommandEncoder?.setCullMode(.none)
            
            renderCommandEncoder?.setRenderPipelineState(renderPipelineState)
            renderCommandEncoder?.setFragmentTexture(renderToTexturePassDescriptor.colorAttachments[ 0 ].texture, index: 0)
            renderCommandEncoder?.setFragmentBuffer(timeBuffer, offset: 0, index: 0)
            renderCommandEncoder?.setFragmentSamplerState(defaultSampler(device: self.device), index: 0)
            renderCommandEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
            
            renderCommandEncoder?.endEncoding()
            
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
        
    }
    
}
