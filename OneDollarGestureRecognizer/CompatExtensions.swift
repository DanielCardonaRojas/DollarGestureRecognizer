//
//  GestureTemplate.swift
//  OneDollarGestureRecognizer
//
//  Created by Daniel Cardona on 12/16/17.
//  Copyright © 2017 Daniel Cardona. All rights reserved.
//

import Foundation
import UIKit

typealias Polynomial = (Double) -> Double
enum Bernstein {
    static func evaluatePolynomial(_ i: Int, order n: Int, at t: Double) -> Double {
        let binomialCoefficient = combinations(from: n, taking: i)
        let ti = pow(t, Double(i))
        let tn = pow((1.0 - t), Double(n - i))
        return ti * tn * Double(binomialCoefficient)
    }
    static func polynomial(_ k: Int, order n: Int) -> Polynomial {
        let binomialCoefficient = combinations(from: n, taking: k)
        return { t in pow(t, Double(k)) * pow(1.0 - t, Double(n - k)) * Double(binomialCoefficient) }
    }
    
    static func polynomials(order n: Int) -> [Polynomial] {
        return Array(0...n).map { i in Bernstein.polynomial(i, order: n)}
    }
    
    static func evaluatedPolynomials(polynomials: [Polynomial], at t: Double) -> [Double] {
        return polynomials.map { poly in poly(t) }
    }

    static func combinations(from n: Int, taking k: Int) -> Int{
        return n.factorial() / (k.factorial() * (n - k).factorial())
    }
}

class Bezier {
    var controlPoints: [CGPoint]
    var order: Int {
        return controlPoints.count - 1
    }
    var polynomials:[Polynomial] {
        return Bernstein.polynomials(order: order)
    }
    
    init(controlPoints: CGPoint...){
        //Using variadic parameter with required labels enforces at leas one control point
        self.controlPoints = controlPoints
        
    }
    
    // Create a bezier curve from control points
    func evaluateSingle(at t: Double) -> CGPoint {
        let evaluatedPolynomials = Bernstein.evaluatedPolynomials(polynomials: polynomials, at: t)
        let evaluated = zip(controlPoints, evaluatedPolynomials).map { (arg) -> CGPoint in
            let (p, coef) = arg
            return CGPoint(x: p.x * CGFloat(coef), y: p.y * CGFloat(coef))
        }
        return evaluated.reduce(CGPoint(x: 0, y: 0)) { (acc, p) -> CGPoint in CGPoint(x: acc.x + p.x, y: acc.y + p.y)}
    }
    
    public func evaluate(at ts: [Double]) -> [CGPoint] {
        return ts.map { t in evaluateSingle(at: t)}
    }
}

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
                iterationPoints = Bezier(controlPoints: currentPoint, p).evaluate(at: ts)
                currentPoint = p
            case .addQuadCurveToPoint(let p1, let p2):
                iterationPoints = Bezier(controlPoints: p0, p1, p2).evaluate(at: ts)
                currentPoint = p1
            case .addCurveToPoint(let p1, let p2, let p3):
                iterationPoints = Bezier(controlPoints: p0, p1, p2, p3).evaluate(at: ts)
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

