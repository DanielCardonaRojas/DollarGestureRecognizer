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
    static func polynomials(order n: Int) -> [Polynomial] {
        var polynomials: [Polynomial] = []
        for i in 0...n {
            let binomialCoefficient = combinations(from: n, taking: i)
            polynomials.append({ t in t.power(i) * (1-t).power(n - 1) * Double(binomialCoefficient) })
        }
        return polynomials
    }
    
    static func evaluatedPolynomials(polynomials: [Polynomial], at t: Double) -> [Double] {
        return polynomials.map { poly in poly(t) }
    }

    static func combinations(from n: Int, taking k: Int) -> Int{
        return n.factorial() / (k.factorial() * (n - k).factorial())
    }
}

class Bezier {
    private var controlPoints: [CGPoint]
    var order: Int {
        return controlPoints.count
    }
    lazy var polynomials:[Polynomial] = {
        return Bernstein.polynomials(order: order)
    }()
    
    init(controlPoints: [CGPoint]) {
        self.controlPoints = controlPoints
    }
    
    // Create a bezier curve from control points
    private func evaluateSingle(at t: Double) -> CGPoint? {
        let order = controlPoints.count
        if order < 2 { return nil }
        let evaluatedPolynomials = Bernstein.evaluatedPolynomials(polynomials: polynomials, at: t)
        let evaluated = zip(controlPoints, evaluatedPolynomials).map { (arg) -> CGPoint in
            let (p, coef) = arg
            return CGPoint(x: p.x * CGFloat(coef), y: p.y * CGFloat(coef))
        }
        return evaluated.reduce(CGPoint(x: 0, y: 0)) { (acc, p) -> CGPoint in CGPoint(x: acc.x + p.x, y: acc.y + p.y)}
    }
    
    public func evaluate(at ts: [Double]) -> [CGPoint] {
        var result: [CGPoint] = []
        for t in ts {
            guard let point = evaluateSingle(at: t) else{
                continue
            }
            result.append(point)
        }
        return result
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
            switch element {
            case .moveToPoint(let p):
                currentPoint = p
            case .addLineToPoint(let p):
                iterationPoints = Bezier(controlPoints: [currentPoint, p]).evaluate(at: ts)
                currentPoint = p
            case .addQuadCurveToPoint(let p0, let p1):
                iterationPoints = Bezier(controlPoints: [p0, p1]).evaluate(at: ts)
                currentPoint = p1
            case .addCurveToPoint(let p0, let p1, let p2):
                iterationPoints = Bezier(controlPoints: [p0, p1, p2]).evaluate(at: ts)
                currentPoint = p2
            case .closeSubpath:
                break
            }
            points += iterationPoints
            k += 1
        }
        return points
    }
    

}

private extension Int {
    func factorial() -> Int{
        var fact = 1
        if self == 0 { return 1 }
        for i in 2...self {
            fact *= i
        }
        return fact
    }
}

private extension Double {
    func power(_ x: Int) -> Double {
        var power: Double = 1
        for _ in 1...x{
           power *= self
        }
        return power
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
