//
//  ViewController.swift
//  MetalCameraTest
//
//  Created by HasegawaYasuo on 2018/08/11.
//  Copyright © 2018年 HasegawaYasuo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var metalView: MetalView!
    
    /*
    required convenience init(coder aDecoder: NSCoder) {
        self.init()
        metalView = MetalView(coder: aDecoder)
        view.insertSubview(metalView, at: 0)
        //metalView.renderer.setFrame(view.bounds)
        print(">>>>> init")
        print("view.bounds : \(view.bounds)")
    }
    */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //self.view.addSubview(<#T##view: UIView##UIView#>)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

