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
        let templates = DollarQTests.templates
        let templateNames = templates.compactMap({ $0.name })

        XCTAssert(!templates.isEmpty)
        XCTAssert(templateNames.contains("line"))
        XCTAssert(templateNames.contains("H"))
        XCTAssert(templateNames.contains("D"))
        XCTAssert(templateNames.contains("P"))
    }

    func testParserLoadsCorrectNumberOfTemplateStrokes() {
        let asteriskTemplate = DollarQTests.templates[0]
        XCTAssert(asteriskTemplate.strokes.count == 3)
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
        XCTAssert(lut?.count == dollarQ.lutSize )
        XCTAssert(lut?[0].count == dollarQ.lutSize )
    }

    func testComputedLookUpTablesForTemplatesAreDifferent() {
        let dollarQ = DollarQ(templates: DollarQTests.templates)
        let templates = dollarQ.templates
        var allDifferent = false

        for i in 1..<templates.count {
            let current = templates[i].lut!
            let previous = templates[i - 1].lut!
            allDifferent = current != previous
        }

        XCTAssert(allDifferent)
    }

    func testLoadedTemplatesHaveBoundedValues() {
        let template = DollarQTests.templates[0]
        let allBounded = template.asPoints.allSatisfy({ !$0.x.isNaN && !$0.y.isNaN })
        XCTAssert(allBounded)
    }

    func testDollarQRecognizesTemplate() {
        let index = 1
        let templates = DollarQTests.templates
        let dollarQ = DollarQ(templates: templates)
        let result = try? dollarQ.recognize(points: templates[index])
        XCTAssertNotNil(result)
        XCTAssert(result?.templateIndex == index)
        XCTAssert(result!.score < 0.3)
    }

    func testTemplatesAreSampledToCorrectSize() {
        let template = DollarQTests.templates[0]
        let cloudSize = 32
        let normalized = DollarQ.resample(points: template.asPoints, size: cloudSize)
        XCTAssert(normalized.count == cloudSize)
    }

    func testScaledPointCoordinatesBoundedToLookUpTableSize() {
        let template = DollarQTests.templates[0]
        let templatePoints = template.asPoints
        let lookUpTableSize = 64
        let cloudSize = 32
        let normalized = DollarQ.normalize(points: templatePoints, cloudSize: cloudSize, lookUpTableSize: lookUpTableSize)
        let bounded = normalized.allSatisfy({ $0.x < Double(lookUpTableSize) && $0.y < Double(lookUpTableSize) })
        XCTAssert(bounded)
    }

    func testUpsamplesEachStrokeToDesiredSize() {
        let strokes = [
            Point(x: 0, y: 0, strokeId: 0),
            Point(x: 0, y: 1, strokeId: 0),
            Point(x: 1, y: 0, strokeId: 1),
            Point(x: 1, y: 1, strokeId: 1)
        ]

        let size = 8
        let resampled = DollarQ.resample(points: strokes, size: size)
        let grouped = resampled.groupedByStrokeId()
        XCTAssert(resampled.count == size)
        XCTAssert(grouped.count == 2)
    }

    func testDownSamplesEachStrokeToDesiredSize() {
        let strokes = [
            Point(x: 0, y: 0, strokeId: 0),
            Point(x: 0, y: 0.5, strokeId: 0),
            Point(x: 0, y: 1, strokeId: 0),
            Point(x: 1, y: 0, strokeId: 1),
            Point(x: 1, y: 0.5, strokeId: 1),
            Point(x: 1, y: 1, strokeId: 1)
        ]

        let size = 4
        let resampled = DollarQ.resample(points: strokes, size: size)
        let grouped = resampled.groupedByStrokeId()
        XCTAssert(resampled.count == size)
        XCTAssert(grouped.count == 2)
    }
}
