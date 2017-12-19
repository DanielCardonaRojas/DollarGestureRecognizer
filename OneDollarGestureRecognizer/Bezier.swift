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
    static func splitCurve(controlPoints: [CGPoint], at t: Double) -> ([CGPoint], [CGPoint]){
        if controlPoints.isEmpty {
            return ([],[])
        }
        var left: [CGPoint] = []
        var right: [CGPoint] = []
        for k in 0...(controlPoints.count - 1) {
            if k == 0 {
                right.append(controlPoints[k])
            }
            if k == controlPoints.count - 1 {
                left.append(controlPoints[k])
                break
            }
            let _ = controlPoints[k].multiplyBy(1 - t) + controlPoints[k + 1].multiplyBy(t)
        }
        
        return (left, right)
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
