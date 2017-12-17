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
    
    func testCanEvaluateLineBezier() {
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
    
    func testBezier() {
        let bz = Bezier(controlPoints: [CGPoint(x: 0, y: 0), CGPoint(x: 4.0, y: 0.0)])
        let p0 = bz.evaluateSingle(at: 0.0)
        let p1 = bz.evaluateSingle(at: 1.0)
        print("Initial point: \(String(describing: p0)) end point: \(String(describing: p1))")
    }
    
    func testBernsteinPolynomials() {
        let polynomials = Bernstein.polynomials(order: 3)
        let firstPoly = polynomials.first!
        let t = 0.5
        let result = firstPoly(t)
        print("\nFirst polynomail evaluated at: \(t) result: \(result)\n")
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
