//
//  BaseMetalView.swift
//  MetalCameraTest
//
//  Created by HasegawaYasuo on 2018/08/11.
//  Copyright © 2018年 HasegawaYasuo. All rights reserved.
//

import Foundation
import MetalKit

public class BaseMetalView: MTKView {
    
    var renderer:MTKViewDelegate!
    var arcBall:Arcball!
    
    required public init(coder: NSCoder) {
        
        super.init(coder:coder)
        
        //
        sampleCount = 1
        
        //
        self.depthStencilPixelFormat = .depth32Float
        self.framebufferOnly = false
        
        // we will call MTKView.draw() explicitly
        isPaused = true
        enableSetNeedsDisplay = true
        
        device = MTLCreateSystemDefaultDevice()!
        
        arcBall = Arcball(view:self)
        
        addGestureRecognizer(UIPanGestureRecognizer.init(
            target: arcBall,
            action: #selector(Arcball.arcBallPanHandler)))
        
    }
}
