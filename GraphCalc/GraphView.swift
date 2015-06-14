//
//  GraphView.swift
//  GraphCalc
//
//  Created by Todd Laney on 6/2/15.
//  Copyright (c) 2015 Todd Laney. All rights reserved.
//

import UIKit

protocol GraphViewDataSource: class {
    func evaluateGraph(sender: GraphView, atX: Double) -> Double?
}

@IBDesignable
class GraphView: UIView {
    
    var axisColor = UIColor.blueColor()
    var lineColor = UIColor.redColor()
    let lineWidth = 1.0
    let pointsPerUnit = 32.0
    
    @IBInspectable
    var scale = 1.0 {
        didSet {setNeedsDisplay()}
    }
    
    @IBInspectable
    var offset = CGPointZero {
        didSet {setNeedsDisplay()}
    }
    
    weak var dataSource : GraphViewDataSource? {
        didSet {setNeedsDisplay()}
    }
    
    private var viewCenter : CGPoint {
        return convertPoint(center, fromView: superview)
    }
    
    private var axisCenter : CGPoint {
        return CGPoint(x: viewCenter.x + offset.x, y: viewCenter.y + offset.y)
    }

    override func drawRect(rect: CGRect) {
        println("AXIS DRAW: \(rect) \(bounds)")
        let axis = AxesDrawer(color: axisColor, contentScaleFactor: self.contentScaleFactor)
        axis.drawAxesInRect(rect, origin: axisCenter, pointsPerUnit: CGFloat(pointsPerUnit * scale))
        
        if let dataSource = dataSource {
            drawFunction(dataSource, rect:rect, origin:axisCenter, pointsPerUnit: CGFloat(pointsPerUnit * scale))
        }
    }
    
    private func drawFunction(ds:GraphViewDataSource, rect:CGRect, origin:CGPoint, pointsPerUnit:CGFloat) {
        
        // px,py is (x,y) in points
        // fx,fy is (x,y) in function space
        
        var path = UIBezierPath()
        path.lineWidth = CGFloat(lineWidth)
        lineColor.set()
        
        for var px = bounds.minX; px < bounds.maxX; px += (1.0 / self.contentScaleFactor) {
            
            var fx = (px - origin.x) / pointsPerUnit
            
            if let fy = ds.evaluateGraph(self, atX: Double(fx)) where (fy.isNormal || fy.isZero) {
                var py = origin.y - CGFloat(fy) * pointsPerUnit
                if path.empty {
                    path.moveToPoint(CGPoint(x:px, y:py))
                } else {
                    path.addLineToPoint(CGPoint(x:px, y:py))
                }
            } else {
                path.stroke()
                path.removeAllPoints()
            }
        }
        path.stroke()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "pan:"))
        self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: "pinch:"))
        let tap = UITapGestureRecognizer(target: self, action: "center:")
        tap.numberOfTapsRequired = 1
        self.addGestureRecognizer(tap)
        let tap2 = UITapGestureRecognizer(target: self, action: "reset:")
        tap2.numberOfTapsRequired = 2
        self.addGestureRecognizer(tap2)
    }
    
    // MARK: Gesture reconizer handlers
    
    func reset(gesture: UITapGestureRecognizer) {
        println("RESET")
        scale = 1.0
        offset = CGPointZero
    }
    func center(gesture: UITapGestureRecognizer) {
        println("CENTER: \(gesture.locationInView(self))")
        var tap = gesture.locationInView(self)
        var origin = convertPoint(center, fromView: superview)
        offset.x = tap.x - origin.x
        offset.y = tap.y - origin.y
    }
    func pinch(gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            let p0 = gesture.locationOfTouch(0, inView:self)
            let p1 = gesture.locationOfTouch(1, inView:self)
            let angle = Double(atan2(abs(p1.y - p0.y), abs(p1.x - p0.x))) * 180.0 / M_PI;
            
            println("PINCH: scale=\(gesture.scale) angle=\(angle)")
            scale *= Double(gesture.scale)
            gesture.scale = 1.0
        default: break
        }
    }
    func pan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            let delta = gesture.translationInView(self)
            println("PAN: \(delta)")
            offset.x += delta.x
            offset.y += delta.y
            gesture.setTranslation(CGPointZero, inView:self)
        default: break
        }
    }
}
