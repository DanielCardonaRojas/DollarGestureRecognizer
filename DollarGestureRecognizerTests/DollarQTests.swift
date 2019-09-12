//
//  DollarQTests.swift
//  DollarGestureRecognizerTests
//
//  Created by Daniel Cardona Rojas on 9/11/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

import XCTest
@testable import DollarGestureRecognizer

class DollarQTests: XCTestCase {

    static var templates: [MultiStrokePath] = []

    override class func setUp() {
        super.setUp()
        let multiStrokeFileNames = MultiStrokePath.DefaultTemplate.allCases.map { $0.rawValue }
        var finished = false

        MultiStrokeParser.loadStrokePatterns(files: multiStrokeFileNames, completion: { strokes in
            templates = strokes
            finished = true
        })

        while !finished {
            RunLoop.current.run(mode: .default, before: Date.distantFuture)
        }
    }
    
    override func setUp() {

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLoadsTemplates() {
        XCTAssert(!DollarQTests.templates.isEmpty)
        XCTAssert(!DollarQTests.templates[0].strokes.isEmpty)
    }

    func testCanAttachLookUpTableToMultiStrokePath() {
        let multiStroke = MultiStrokePath(strokes: [Template()], name: nil)
        multiStroke.lut = DollarQ.LookUpTable(repeating: [1], count: 1)
        let lut = multiStroke.lut
        XCTAssertNotNil(lut)
        XCTAssert(lut?.isEmpty == false)
    }

    func testPreLoadsLookupTablesToTemplates() {
        let dollarQ = DollarQ(templates: DollarQTests.templates)
        let template = dollarQ.templates[0]
        let lut = template.lut
        XCTAssertNotNil(lut)
    }

    func testComputedLookUpTableIsMbyM() {
        let dollarQ = DollarQ(templates: DollarQTests.templates)
        let template = dollarQ.templates[0]
        let lut = template.lut
        XCTAssert(lut?.count == dollarQ.m )
        XCTAssert(lut?[0].count == dollarQ.m )
    }
}
