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
        var leftPoints: [CGPoint] = []
        var rightPoints: [CGPoint] = []

        if controlPoints.count < 2 { return ([], [])}
        if controlPoints.count == 2 { //Is  line
           return ([controlPoints[0]], [controlPoints[1]] )
        }
        
        while (rightCount - leftCount) >= -1  {
            let leftPoint = controlPoints[leftCount].multiplyBy(1 - t) + controlPoints[leftCount + 1].multiplyBy(t)
            let rightPoint = controlPoints[rightCount].multiplyBy(1 - t) + controlPoints[rightCount - 1].multiplyBy(t)
            leftPoints.append(leftPoint)
            rightPoints.append(rightPoint)
            leftCount += 1
            rightCount -= 1
        }
        
        leftPoints.insert(controlPoints.first!, at: 0)
        rightPoints.append(controlPoints.last!)
        return (leftPoints, rightPoints)
    }
    
    static func splitToSample(controlPoints: [CGPoint], percent: Double) -> [CGPoint] {
        //Splits path into subpaths until the subpaths are to a degree straight lines.
        if controlPoints.count <= 1 { return [] }
        if controlPoints.count == 2 { return controlPoints }
        let lengthControl = controlPoints.toPoints().pathLength()
        var distances: [Double] = []
        let lengthExtremes = [controlPoints.first!, controlPoints.last!].toPoints().pathLength()
        let diff = abs(lengthControl - lengthExtremes)
        
        for i in 1...(controlPoints.count - 1) {
           distances.append([controlPoints[i - 1], controlPoints[i]].toPoints().pathLength())
        }
        
        if diff <= percent || lengthControl < 5 || distances.any { d in d < 1 } {
            return controlPoints
        }
        
        let (left, right) = DeCasteljau.split(controlPoints: controlPoints, at: 0.5)
        let leftSamples = splitToSample(controlPoints: left, percent: percent)
        let rightSamples = splitToSample(controlPoints: right, percent: percent)
        return  Array(leftSamples.dropLast()) + Array(rightSamples.dropFirst())
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
