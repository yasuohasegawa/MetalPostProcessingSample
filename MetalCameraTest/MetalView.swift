//
//  MetalView.swift
//  MetalCameraTest
//
//  Created by HasegawaYasuo on 2018/08/11.
//  Copyright © 2018年 HasegawaYasuo. All rights reserved.
//

import Foundation
import MetalKit

public class MetalView: BaseMetalView {
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        renderer = Renderer(view: self, device: device!)
        delegate = renderer
    }
}
