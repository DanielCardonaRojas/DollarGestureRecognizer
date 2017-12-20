//
//  Bezier.swift
//  OneDollarGestureRecognizer
//
//  Created by Daniel Cardona on 12/17/17.
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

enum DeCasteljau {
    //Splits a bezier curve in two and returns the new control points for the two new segments.
    static func split(controlPoints: [CGPoint], at t: Double) -> ([CGPoint], [CGPoint]){
        let n = controlPoints.count
        var leftCount: Int = 0
        var rightCount: Int = n - 1
        var leftPoints = Array(repeating: CGPoint.zero, count: n)
        var rightPoints = Array(repeating: CGPoint.zero, count: n)
        
        while rightCount - leftCount > 1  {
            leftPoints[leftCount] = controlPoints[leftCount].multiplyBy(1 - t) + controlPoints[leftCount + 1].multiplyBy(t)
            rightPoints[rightCount] = controlPoints[rightCount].multiplyBy(1 - t) + controlPoints[rightCount - 1].multiplyBy(t)
            leftCount += 1
            rightCount -= 1
        }
    
        return (leftPoints,rightPoints)
    }
    
    static func splitToSample(controlPoints: [CGPoint], percent: Double) -> [[CGPoint]] {
        //Splits path into subpaths until the subpaths are to a degree straight lines.
        if controlPoints.count == 0 { return [] }
        let lengthControl = controlPoints.toPoints().pathLength()
        let lengthExtremes = [controlPoints.first!, controlPoints.last!].toPoints().pathLength()
        let diff = (lengthControl - lengthExtremes) / lengthControl
        if diff <= percent {
            return [controlPoints]
        }
        
        let (left, right) = DeCasteljau.split(controlPoints: controlPoints, at: 0.5)
        return splitToSample(controlPoints: left, percent: percent) + splitToSample(controlPoints:right, percent:percent)
    }
    
    static func evaluateBezier(controlPoints: [CGPoint], at t: Double) -> CGPoint {
        //Interpolate all lines defined by control points until on point is left
        let n = controlPoints.count
        if n == 1 {
            return controlPoints[0]
        }
        var newPoints = Array(repeating: CGPoint.zero, count: n - 1) //Of size n-1
        //Find the t % point along all lines formed by the control points
        for i in 0..<(n - 1) {
           newPoints[i] = controlPoints[i].multiplyBy(1 - t) + controlPoints[i + 1].multiplyBy(t)
        }
        return DeCasteljau.evaluateBezier(controlPoints: newPoints, at: t)
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
        return evaluated.reduce(CGPoint(x: 0, y: 0)) { (acc, p) -> CGPoint in acc + p}
    }
    
    public func evaluate(at ts: [Double]) -> [CGPoint] {
        return ts.map { t in evaluateSingle(at: t)}
    }
    
    public func evaluateDeCasteljau(at ts:[Double]) -> [CGPoint] {
        return ts.map { t in DeCasteljau.evaluateBezier(controlPoints: controlPoints, at: t)}
    }
}
