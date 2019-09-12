//
//  OneDollarGestureRecognizerTests.swift
//  OneDollarGestureRecognizerTests
//
//  Created by Daniel Cardona on 12/16/17.
//  Copyright © 2017 Daniel Cardona. All rights reserved.
//

import XCTest
@testable import DollarGestureRecognizer

class OneDollarTests: XCTestCase {
    
    let scaleTransformation = CGAffineTransform().scaledBy(x: 1.5, y: 1)
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEmptyPathsThrowsException() {
        let path: [Point] = []
        let candidate = SingleStrokePath(path: path)
        let od = OneDollar(templates: candidate)
        XCTAssertThrowsError(try od.recognize(candidate: candidate), "Did not throw empty templates error") { (error) -> Void in
            XCTAssertEqual(error as? DollarError, DollarError.EmptyTemplates)
        }
    }
    
    func testFewPointsThrowsException() {
        let candidate = SingleStrokePath(path: [Point(x: 1, y: 1)])
        let od = OneDollar(templates: candidate)
        XCTAssertThrowsError(try od.recognize(candidate: candidate), "Did not throw few points error") { (error) -> Void in
            XCTAssertEqual(error as? DollarError, DollarError.TooFewPoints)
        }
    }
    
    func testLoadFromBezierPathProducesNonEmptyPath() {
        let bezierRect = UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: CGSize(width: 4, height: 4)))
        let candidate = SingleStrokePath(path: bezierRect)
        XCTAssert(!candidate.path.isEmpty)
    }
    
    func testScoreHighestWhenPathAndTemplateAreEqual() {
        let bz = UIBezierPath()
        bz.move(to: CGPoint.zero)
        bz.addQuadCurve(to: CGPoint(x: 10, y: 0), controlPoint: CGPoint(x: 5, y: 5))
        let candidate = SingleStrokePath(path: bz)
        let template = SingleStrokePath(path: bz)
        let (_, score) = (try! OneDollar(templates: template).recognize(candidate: candidate))!
        XCTAssert(score > 0.8)
    }
    
    func testCircleVsOval() {
        let bezierCircle = UIBezierPath(ovalIn: CGRect(origin: CGPoint.zero, size: CGSize(width: 4, height: 4)))
        let oval = UIBezierPath(ovalIn: CGRect(origin: CGPoint.zero, size: CGSize(width: 6, height: 4)))
        let candidate = SingleStrokePath(path: bezierCircle)
        let template = SingleStrokePath(path: bezierCircle)
        let scaledTemplate = SingleStrokePath(path: oval)
        let (_, score1) = (try! OneDollar(templates: template).recognize(candidate: candidate))!
        let (_, score2) = (try! OneDollar(templates: scaledTemplate).recognize(candidate: candidate))!
        print("\nScores 1: \(score1) 2: \(score2) \n")
        XCTAssert( abs(score1 - score2) <= 0.1 )
    }
    
    func testRotationInveriant() {
    }
    
    func testRecognizesVShape() {
        let v1 = [CGPoint(x: 50, y: 50), CGPoint(x: 200, y: 200), CGPoint(x: 450, y: 50)]
        let v2 = [CGPoint(x: 150, y: 150), CGPoint(x: 300, y: 300), CGPoint(x: 350, y: 150)]
        let candidate = SingleStrokePath(path: v2.toPoints())
        let template = SingleStrokePath(path: v1.toPoints())
        let d1 = OneDollar(templates: template)
        let (_, score) = (try! d1.recognize(candidate: candidate))!
        print(score)
        XCTAssert(score > 0.7)
    }
    
    func testRecognizesUShape() {
        let u1 = [CGPoint(x: 50, y: 200), CGPoint(x: 50, y: 50), CGPoint(x: 200, y: 50), CGPoint(x: 200, y: 200)]
        let u2 = [CGPoint(x: 70, y: 200), CGPoint(x: 70, y: 70), CGPoint(x: 180, y: 70), CGPoint(x: 180, y: 200)]
        let candidate = SingleStrokePath(path: u2.toPoints())
        let template = SingleStrokePath(path: u1.toPoints())
        let d1 = OneDollar(templates: template)
        let (_, score) = (try! d1.recognize(candidate: candidate))!
        print(score)
        XCTAssert(score > 0.7)
    }
    
    func testIsTranslationInvariant() {
        let bezierCircle = UIBezierPath(ovalIn: CGRect(origin: CGPoint.zero, size: CGSize(width: 4, height: 4)))
        let bezierCircle2 = UIBezierPath(ovalIn: CGRect(origin: CGPoint.zero, size: CGSize(width: 4, height: 4)))
        let candidate = SingleStrokePath(path: bezierCircle)
        let template = SingleStrokePath(path: bezierCircle2)
        let translatedTemplate = SingleStrokePath(path: bezierCircle2)
        let (_, score1) = (try! OneDollar(templates: template).recognize(candidate: candidate))!
        let (_, score2) = (try! OneDollar(templates: translatedTemplate).recognize(candidate: candidate))!
        print("\nScores 1: \(score1) 2: \(score2) \n")
        XCTAssert( abs(score1 - score2) <= 0.1 )
    }
    
    func testCanSampleBezierPath() {
        let bezierRect = UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: CGSize(width: 4, height: 4)))
        let elems: [PathElement] = bezierRect.cgPath.elements()
        let points = PathElement.evaluate(path: elems, delta: 0.5)
        XCTAssert(points.count > elems.count)
    }
    
    func testResamplesLineToSpecifiedLength() {
        let linePoints = [Point(x: 0, y: 0), Point(x: 8, y: 0)]
        let newPoints = OneDollar.resample(points: linePoints, totalPoints: 4)
        print(newPoints)
        XCTAssert(newPoints.count == 4)
        XCTAssert(newPoints.pathLength() == linePoints.pathLength())
    }
    
    func testCallingResampleOnInstanceYieldsEqualLengthPaths() {//Make shure templates and candidate are same length
        let linePoints = [Point(x: 0, y: 0), Point(x: 8, y: 0)]
        let linePoints2 = [Point(x: 0, y: 0), Point(x: 4, y: 4), Point(x: 8, y: 8)]
        let candidate = SingleStrokePath(path: linePoints)
        let template = SingleStrokePath(path: linePoints2)
        let od = OneDollar(templates: template)
        od.candidatePath = candidate.path
        try! od.resample()
        XCTAssert(od.candidatePath.count == od.templates[0].count)
    }
    
    func testDownsamplesToSpecifiedLength() { //What if the path has more points than required.
        let linePoints2 = [Point(x: 0, y: 0), Point(x: 4, y: 4), Point(x: 8, y: 8)]
        let newPoints: [Point] = OneDollar.resample(points: linePoints2, totalPoints: 2)
        XCTAssert(newPoints.count == 2)
        XCTAssert(newPoints.pathLength() == linePoints2.pathLength())
        XCTAssert(newPoints[0].cgPoint() == linePoints2[0].cgPoint())
        XCTAssert(newPoints.last!.cgPoint() == linePoints2.last!.cgPoint())
    }
    
}
