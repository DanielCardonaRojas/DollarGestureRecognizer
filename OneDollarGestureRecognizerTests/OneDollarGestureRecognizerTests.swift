//
//  OneDollarGestureRecognizerTests.swift
//  OneDollarGestureRecognizerTests
//
//  Created by Daniel Cardona on 12/16/17.
//  Copyright © 2017 Daniel Cardona. All rights reserved.
//

import XCTest
@testable import OneDollarGestureRecognizer

class OneDollarGestureRecognizerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testEmptyPathsThrowsException() {
        let candidate = OneDollarPath(path: [])
        let od = OneDollar(candidate: candidate, templates: [candidate])
        XCTAssertThrowsError(try od.recognize(), "Did not throw empty templates error") { (error) -> Void in
            XCTAssertEqual(error as? OneDollarError, OneDollarError.EmptyTemplates)
        }
    }
    
    func testFewPointsThrowsException() {
        let candidate = OneDollarPath(path: [Point(x: 1, y: 1)])
        let od = OneDollar(candidate: candidate, templates: [candidate])
        XCTAssertThrowsError(try od.recognize(), "Did not throw few points error") { (error) -> Void in
            XCTAssertEqual(error as? OneDollarError, OneDollarError.TooFewPoints)
        }
    }
    
    func testLoadFromBezierPathProducesNonEmptyPath() {
        let bezierRect = UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: CGSize(width: 4, height: 4)))
        let candidate = OneDollarPath.from(path: bezierRect)
        XCTAssert(!candidate.path.isEmpty)
    }
    
    func testScaleInvariance() {
        let bezierCircle = UIBezierPath(ovalIn: CGRect(origin: CGPoint.zero, size: CGSize(width: 4, height: 4)))
        let scaledCircle = bezierCircle
        let candidate = OneDollarPath.from(path: bezierCircle)
        let template = OneDollarPath.from(path: bezierCircle)
        let scaledTemplate = OneDollarPath.from(path: scaledCircle)
        do {
            let (_, score1)  = (try OneDollar(candidate: candidate, templates: [template]).recognize())!
            let (_, score2)  = (try OneDollar(candidate: candidate, templates: [scaledTemplate]).recognize())!
            XCTAssert( abs(score1 - score2) <= 0.1 )
            //TODO: Assert d is considarably  similary to another d if the circle is scaled
        } catch {
           print("Exception in test scale invariance")
        }
    }
    
    func testEqualGestureScoreMax() {
//        let candidate = OneDollarPath.from(path: <#T##UIBezierPath#>)
//        let od = OneDollar(candidate: <#T##OneDollarPath#>, templates: <#T##[OneDollarTemplate]#>)
    }
    
    func testRotationInveriant() {
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
    

}
