//
//  ViewController.swift
//  SimpleSVGParserDemo
//
//  Created by Masaki Sueda on 2015/06/29.
//  Copyright (c) 2015年 Masaki Sueda. All rights reserved.
//

import UIKit
import SimpleSVGParser

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.blackColor()
        
        var path = SimpleSVGParser.buildPathFromSVG("sample")
        let shapeLayer = CAShapeLayer()
        
        shapeLayer.path = path
        shapeLayer.fillColor = UIColor.whiteColor().CGColor
        shapeLayer.transform = CATransform3DMakeScale(5.0, 5.0, 1.0)
        
        NSLog("\(path)")
        self.view.layer.addSublayer(shapeLayer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

