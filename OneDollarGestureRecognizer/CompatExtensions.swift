//
//  GestureTemplate.swift
//  OneDollarGestureRecognizer
//
//  Created by Daniel Cardona on 12/16/17.
//  Copyright © 2017 Daniel Cardona. All rights reserved.
//

import Foundation
import UIKit

/// A Swiftified representation of a `CGPathElement` https://oleb.net/blog/2015/06/c-callbacks-in-swift/
public enum PathElement {
    case moveToPoint(CGPoint)
    case addLineToPoint(CGPoint)
    case addQuadCurveToPoint(CGPoint, CGPoint)
    case addCurveToPoint(CGPoint, CGPoint, CGPoint)
    case closeSubpath
    
    init(element: CGPathElement) {
        switch element.type {
        case .moveToPoint:
            self = .moveToPoint(element.points[0])
        case .addLineToPoint:
            self = .addLineToPoint(element.points[0])
        case .addQuadCurveToPoint:
            self = .addQuadCurveToPoint(
                element.points[0], element.points[1])
        case .addCurveToPoint:
            self = .addCurveToPoint(element.points[0], element.points[1], element.points[2])
        case .closeSubpath:
            self = .closeSubpath
        }
    }
    
    //Samples the all bezier path segments
    static func evaluate(path: [PathElement], every ts: [Double]) -> [CGPoint] {
        //Ensure the first element for path is a moveToPoint otherwise prepend
        let pathElements = path
        var points: [CGPoint] = []
        var iterationPoints: [CGPoint] = []
        var currentPoint: CGPoint = CGPoint.zero
        var k = 0
        for element in pathElements {
            if k == 0 {
               //First iteration
            }
            let p0: CGPoint = currentPoint
            switch element {
            case .moveToPoint(let p):
                currentPoint = p
            case .addLineToPoint(let p):
                iterationPoints = Bezier(controlPoints: currentPoint, p).evaluateDeCasteljau(at: ts)
                currentPoint = p
            case .addQuadCurveToPoint(let p1, let p2):
                iterationPoints = Bezier(controlPoints: p0, p1, p2).evaluateDeCasteljau(at: ts)
                currentPoint = p1
            case .addCurveToPoint(let p1, let p2, let p3):
                iterationPoints = Bezier(controlPoints: p0, p1, p2, p3).evaluateDeCasteljau(at: ts)
                currentPoint = p2
            case .closeSubpath:
                break
            }
            points += iterationPoints
            k += 1
        }
        return points
    }
    
    static func evaluate(path: [PathElement], delta: Double) -> [CGPoint] {
        //Ensure the first element for path is a moveToPoint otherwise prepend
        let pathElements = path
        var points: [CGPoint] = []
        var iterationPoints: [CGPoint] = []
        var currentPoint: CGPoint = CGPoint.zero
        var k = 0
        for element in pathElements {
            let p0 = currentPoint
            switch element {
            case .moveToPoint(let p1):
                currentPoint = p1
                iterationPoints = [p1]
            case .addLineToPoint(let p1):
                let controlPoints = [p0, p1]
                let controlPointsDistance = controlPoints.toPoints().pathLength()
                let ts = Array(stride(from: 0, to: 1, by: delta/controlPointsDistance))
                let bz = Bezier(controlPoints: p0, p1)
                iterationPoints = bz.evaluate(at: ts)
                currentPoint = p1
            case .addQuadCurveToPoint(let p1, let p2):
                let controlPoints = [p0, p1, p2]
                let controlPointsDistance = controlPoints.toPoints().pathLength()
                let ts = Array(stride(from: 0, to: 1, by: delta/controlPointsDistance))
                iterationPoints = Bezier(controlPoints: p0, p1, p2).evaluate(at: ts)
                currentPoint = p2
            case .addCurveToPoint(let p1, let p2, let p3):
                let controlPoints = [p0, p1, p2, p3]
                let controlPointsDistance = controlPoints.toPoints().pathLength()
                let ts = Array(stride(from: 0, to: 1, by: delta/controlPointsDistance))
                iterationPoints = Bezier(controlPoints: p0, p1, p2, p3).evaluate(at: ts)
                currentPoint = p3
            case .closeSubpath:
                break
            }
            points += iterationPoints
            k += 1
        }
        return points
    }
    


}

extension Int {
    func factorial() -> Int{
        var fact = 1
        if self == 0 { return 1 }
        if self == 1 { return 1 }
        for i in 2...self {
            fact *= i
        }
        return fact
    }
}

extension Double {
    public static var random: Double {
        return Double(arc4random()) / 0xFFFFFFFF
    }
}

extension CGPoint {
    func multiplyBy(_ value: Double) -> CGPoint {
        let val = CGFloat(value)
        return CGPoint(x: self.x * val, y: self.y * val)
    }
    
    static func + (_ lhs: CGPoint, _ rhs: CGPoint ) -> CGPoint{
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
}

extension Array where Element == CGPoint {
    func pathLength() -> Double {
        let pointPath = self.map {p in Point(point: p)}
        return pointPath.pathLength()
    }
}

//MARK: - CGPath extensions
extension CGPath {
    func elements() -> [PathElement] {
        var points: [PathElement] = []
        self.applyWithBlock { (element: UnsafePointer<CGPathElement>) in
           points.append(PathElement(element: element.pointee))
        }
        return points
    }
}

extension PathElement: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case let .moveToPoint(point):
            return "moveto \(point)"
        case let .addLineToPoint(point):
            return "lineto \(point)"
        case let .addQuadCurveToPoint(point1, point2):
            return "quadcurveto \(point1), \(point2)"
        case let .addCurveToPoint(point1, point2, point3):
            return "curveto \(point1), \(point2), \(point3)"
        case .closeSubpath:
            return "closepath"
        }
    }
}

