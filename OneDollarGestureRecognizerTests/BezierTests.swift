//
//  BezierEvaluationTests.swift
//  OneDollarGestureRecognizerTests
//
//  Created by Daniel Cardona on 12/17/17.
//  Copyright © 2017 Daniel Cardona. All rights reserved.
//

import XCTest
@testable import OneDollarGestureRecognizer

class BezierTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testCanRetrieveElementsFromCGPath(){
        let bezierRect = UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: CGSize(width: 4, height: 4)))
        let elems: [PathElement] = bezierRect.cgPath.elements()
        print("Number of elements: \(elems.count)")
        XCTAssert(elems.count > 0)
        for e in elems {
            debugPrint(e)
        }
    }
    
    func testPathLengthOfSampledLineIsEqualToLengthOfUnsampledLine() {
        let bezier = UIBezierPath()
        let lineLength = 4.0
        bezier.move(to: CGPoint.zero)
        bezier.addLine(to: CGPoint(x: lineLength, y: 0.0))
        let elems: [PathElement] = bezier.cgPath.elements()
        let points: [Point] = PathElement.evaluate(path: elems, every: [0.0, 1.0]).toPoints()
        print("Control points: \(elems)")
        print("Bezier control points count: \(elems.count), points at [0, 1]: \(points)")
        XCTAssert(points.pathLength() == lineLength)
    }
    
    func testEvaluatedPointsOnQuadCurveAreActuallyOnTheCurve() {
        let bezier = UIBezierPath()
        bezier.move(to: CGPoint.zero)
        bezier.addQuadCurve(to: CGPoint(x: 10, y: 0), controlPoint: CGPoint(x: 5, y: 5))
        let elems: [PathElement] = bezier.cgPath.elements()
        var onCurve: Int = 0
        let iterations: Int = 100
        for _ in 1...iterations {
            let t = Double.random
            let points: [CGPoint] = PathElement.evaluate(path: elems, every: [t])
            if bezier.contains(points.first!){
                onCurve +=  1
            }
        }
        //At least more then the majority of points are on the line ... who know what the core algorithm is.
        print("\nScore for points on quad curve: \(onCurve) from \(iterations) iterations \n ")
        XCTAssert(onCurve > Int(Double(iterations) * 0.4))
    }
    
    func testEvaluatedPointsOnCubicCurveAreActuallyOnTheCurveBernstein() {
        // Evaluating Bernstein polynomials is expensive and prone to error
        let bezier = UIBezierPath()
        bezier.move(to: CGPoint.zero)
        let cp1: CGPoint = CGPoint(x: 5, y: 5)
        let cp2: CGPoint = CGPoint(x: 8, y: 8)
        bezier.addCurve(to: CGPoint(x: 10, y: 0), controlPoint1: cp1, controlPoint2: cp2)
        let elems: [PathElement] = bezier.cgPath.elements()
        var onCurve: Int = 0
        let iterations: Int = 100
        for _ in 1...iterations {
            let t = Double.random
            let points: [CGPoint] = PathElement.evaluate(path: elems, every: [t])
            if bezier.contains(points.first!){
                onCurve +=  1
            }
        }
        //At lear X % of points are on the line ... who know what the core algorithm is, rounding errors, etc.
        print("\nScore for points on cubic curve: \(onCurve) from \(iterations) iterations \n ")
        XCTAssert(onCurve > Int(Double(iterations) * 0.4))
    }
    
    func testEvaluatedPointsOnCubicCurveAreActuallyOnTheCurveDeCastelJau() {
        let bezier = UIBezierPath()
        let cp0: CGPoint = CGPoint.zero
        let cp1: CGPoint = CGPoint(x: 5, y: 5)
        let cp2: CGPoint = CGPoint(x: 8, y: 8)
        let cp3: CGPoint = CGPoint(x: 10, y: 0)
        bezier.move(to: cp0)
        bezier.addCurve(to: cp3, controlPoint1: cp1, controlPoint2: cp2)
        let n: Double = 100
        let ts = Array(stride(from: 0.0, to: 1.0, by: 1.0 / n))
        let points: [CGPoint] = Bezier(controlPoints: cp0, cp1, cp2, cp3).evaluateDeCasteljau(at: ts)
        let onCurvePoints = points.filter{ p in bezier.contains(p)}
        print("\n DeCasteljau score for points on cubic curve: \(onCurvePoints.count) from \(n) evaluated t's \n ")
        XCTAssert(onCurvePoints.count > Int(n * 0.4))
    }
    
    func testEvaluatedPointsOnQuadCurveAreSanelyWithinItsRectBounds() {//If this doesn't pass we are @#$?!
        let bezier = UIBezierPath()
        bezier.move(to: CGPoint.zero)
        let iterations = 30
        bezier.addQuadCurve(to: CGPoint(x: 10, y: 0), controlPoint: CGPoint(x: 5, y: 5))
        let elems: [PathElement] = bezier.cgPath.elements()
        let ts = Array(repeating: (), count: iterations).map{_ in Double.random}
        let points: [CGPoint] = PathElement.evaluate(path: elems, every: ts)
        let pointsWithinRectBound = points.filter { p in bezier.bounds.contains(p)}
        XCTAssert(pointsWithinRectBound.count == points.count)
    }
    
    func testEvaluatedPointsOnCubicCurveAreSanelyWithinItsRectBounds() {//If this doesn't pass we are @#$?!
        let bezier = UIBezierPath()
        bezier.move(to: CGPoint.zero)
        let cp1: CGPoint = CGPoint(x: 5, y: 5)
        let cp2: CGPoint = CGPoint(x: 8, y: 8)
        let iterations = 30
        bezier.addCurve(to: CGPoint(x: 10, y: 0), controlPoint1: cp1, controlPoint2: cp2)
        let elems: [PathElement] = bezier.cgPath.elements()
        let ts = Array(repeating: (), count: iterations).map{_ in Double.random}
        let points: [CGPoint] = PathElement.evaluate(path: elems, every: ts)
        let pointsWithinRectBound = points.filter { p in bezier.bounds.contains(p)}
        XCTAssert(pointsWithinRectBound.count == points.count)
    }
    
    func testBezierThereIsACoeficientForEachControlPoint() {
        let p0 = CGPoint(x: 0, y: 0)
        let p1 = CGPoint(x: 4.0, y: 0.0)
        let bz = Bezier(controlPoints: p0, p1)
        XCTAssert(bz.controlPoints.count == bz.polynomials.count)
        
    }
    func testBezierExtremePointAreCorrectlyEvaluated() {
        let p0 = CGPoint(x: 0, y: 0)
        let p1 = CGPoint(x: 4.0, y: 0.0)
        let bz = Bezier(controlPoints: p0, p1)
        let _p0 = bz.evaluateSingle(at: 0.0)
        let _p1 = bz.evaluateSingle(at: 1.0)
        XCTAssert(_p0 == p0)
        XCTAssert(_p1 == p1)
    }
    
    func testBezierEvaluatesLineCorrectly() {
        let p0 = CGPoint(x: 0, y: 0)
        let p1 = CGPoint(x: 4.0, y: 0.0)
        let bz = Bezier(controlPoints: p0, p1)
        let p_mid = bz.evaluateSingle(at: 0.5)
        print("Line middle point is: \(p_mid)")
        let firstSegment: [Point] = [p0, p_mid].toPoints()
        let secondSegment: [Point] = [p0, p_mid].toPoints()
        XCTAssert(firstSegment.pathLength() == secondSegment.pathLength())
    }
    
    func testBernsteinPolynomials() {
        XCTAssert(Bernstein.evaluatePolynomial(0, order: 3, at: 0.5) == 0.125)
    }
    
    func testCombinationsFunction() {
        let r1 = Bernstein.combinations(from: 5, taking: 2)
        XCTAssert(r1 == 10)
        let r2 = Bernstein.combinations(from: 13, taking: 3)
        XCTAssert(r2 == 286)
    }
    
    
    func testCanSampleBezierPath() {
        let bezierRect = UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: CGSize(width: 4, height: 4)))
        let elems: [PathElement] = bezierRect.cgPath.elements()
        let points = PathElement.evaluate(path: elems, delta: 0.5)
        XCTAssert(points.count > elems.count)
        for p in points {
            print(p)
        }
    }
    
    func testDeCasteljauSplit() {
        let cp0: CGPoint = CGPoint.zero
        let cp1: CGPoint = CGPoint(x: 5, y: 5)
        let cp2: CGPoint = CGPoint(x: 8, y: 8)
        let cp3: CGPoint = CGPoint(x: 10, y: 0)
        let controlPoints = [cp0, cp1, cp2, cp3]
        let (left, right) = DeCasteljau.split(controlPoints: controlPoints, at: 0.5)
        XCTAssert(left.last! == right.first)
        XCTAssert(left.count == right.count)
        XCTAssert(left.count == controlPoints.count)
    }
    
    func testDeCasteljauSample() {
        let cp0: CGPoint = CGPoint.zero
        let cp1: CGPoint = CGPoint(x: 5, y: 5)
        let cp2: CGPoint = CGPoint(x: 8, y: 8)
        let cp3: CGPoint = CGPoint(x: 10, y: 0)
        let percent = 0.01
        let controlPoints = [cp0, cp1, cp2, cp3]
        let subpaths: [[CGPoint]] = DeCasteljau.splitToSample(controlPoints: controlPoints, percent: percent)
        let areSameOrder = subpaths.map({ s in s.count == controlPoints.count}).reduce(true, { acc, b in acc && b})
        let lengthDiff = subpaths.map({ (s:[CGPoint]) -> Double in
            s.pathLength() - [s.first!, s.last!].pathLength()
            }).reduce(0, { acc, diff in acc + diff})
        XCTAssert(areSameOrder)
        XCTAssert(lengthDiff - (percent * Double(controlPoints.count)) <= 0.01)
        //Flatten subpaths drop first and last elements every right adjacent element should equate.
        var flattened = subpaths.map({s in [s.first!, s.last!]}).reduce([], {acc, x in acc + x })
        flattened = Array(flattened.dropFirst())
        flattened = Array(flattened.dropLast())
        XCTAssert(flattened[0] == flattened[1])

    }
    
    
}

