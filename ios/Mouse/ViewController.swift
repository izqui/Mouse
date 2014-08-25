//
//  ViewController.swift
//  Mouse
//
//  Created by Jorge Izquierdo on 22/08/14.
//  Copyright (c) 2014 Jorge Izquierdo. All rights reserved.
//

import UIKit
import CoreMotion
import QuartzCore

class Canvas: UIView {
    
    var path = UIBezierPath()
    
    required init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.path.moveToPoint(self.center)
        self.backgroundColor = UIColor.whiteColor()
        
    }
    
    func addPoint(p: CGPoint){
        
        //println(p)
        self.path.addLineToPoint(CGPoint(x: p.x, y: p.y))
        self.setNeedsDisplay()
    }
    
    override func drawRect(rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSetStrokeColorWithColor(context, UIColor.redColor().CGColor)
        CGContextSetLineWidth(context, 1.0)
        CGContextAddPath(context, self.path.CGPath)
        CGContextStrokePath(context)
    }
}
class ViewController: UIViewController {
    
    let motionManager = CMMotionManager()
    var canvas: Canvas?
    
    override func viewDidLoad() {
        
        self.canvas = Canvas(frame: self.view.frame)
        self.view.addSubview(self.canvas!)
        
        //self.accelerometer()
        //self.gyroscope()
        self.deviceMotion()
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func deviceMotion() {
        
        var s0 = self.canvas!.path.currentPoint
        var v0 = CGPoint(x: 0, y: 0)
        var accx: CGFloat? = 0.0
        var accy: CGFloat? = 0.0
        var blockedx = false
        var blockedy = false
        
        var t0 = CACurrentMediaTime()
        
        if self.motionManager.deviceMotionAvailable && !motionManager.deviceMotionActive {
            self.motionManager.deviceMotionUpdateInterval = Double(CGFloat(1.0/70.0))
            self.motionManager.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrameXArbitraryCorrectedZVertical, toQueue: NSOperationQueue.mainQueue()){
                
                (data: CMDeviceMotion!, error: NSError!) in
                
                let a = CGPoint(x: -CGFloat(data.userAcceleration.x), y: CGFloat(data.userAcceleration.y))
                
                //KIND OF
                
                let currentTime = CACurrentMediaTime()
                let t = CGFloat(currentTime - t0)
                t0 = currentTime
                
                v0.x += a.x * t
                v0.y += a.y * t
                
                //println(v0)
        
                if sqrt(pow(a.x, 2) + pow(a.y, 2))>0.03/* > 0.009*/ {
                    
                    s0.x = s0.x + v0.x*t*10000
                    s0.y = s0.y + v0.y*t*10000
                    
                    println(v0)
                   
                    //self.canvas?.addPoint(s0)
                    
                } else {
                    
                    v0.x = 0
                    v0.y = 0
                }
                return
            }
        }

    }
    
    func accelerometer() {
        
        var s0 = self.canvas!.path.currentPoint
        var v0 = CGPoint(x: 0, y: 0)
    
        let t = CGFloat(1.0/20.0)
        
        if self.motionManager.accelerometerAvailable && !motionManager.accelerometerActive {
            self.motionManager.accelerometerUpdateInterval = Double(t)
            self.motionManager.startAccelerometerUpdatesToQueue (NSOperationQueue.mainQueue()) {
                
                (data: CMAccelerometerData!, error: NSError!) in
                
                let a = CGPoint(x: CGFloat(data.acceleration.x)*30000, y: CGFloat(data.acceleration.y)*30000)
                
                s0 = CGPoint(x: s0.x + v0.x*t + 0.5*a.x*pow(t,2.0), y: s0.y + v0.y*t + 0.5*a.y*pow(t,2.0))
                v0 = CGPoint(x: v0.x + a.x * t, y: v0.y + a.y * t)
                
                self.canvas?.addPoint(s0)
                println("\(data.acceleration.x),\(data.acceleration.y)")
                return
            }
        }
    }
    
    func gyroscope() {
        
        if self.motionManager.gyroAvailable && !motionManager.gyroActive {
            self.motionManager.gyroUpdateInterval = 1.0/20.0
            self.motionManager.startGyroUpdatesToQueue(NSOperationQueue.mainQueue()) {
                
                (data: CMGyroData!, error: NSError!) in
                
                //println("x: \(data.rotationRate.x) y: \(data.rotationRate.y) z: \(data.rotationRate.z)")
                
                return
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

