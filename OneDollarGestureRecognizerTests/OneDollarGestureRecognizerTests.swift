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
        
    }
    

}
