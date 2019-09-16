//
//  MultiStrokeParser.swift
//  DollarGestureRecognizer
//
//  Created by Daniel Cardona Rojas on 8/14/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

import Foundation

public class MultiStrokeParser: NSObject, XMLParserDelegate {
    public typealias ParsingCompletion = (MultiStrokePath) -> Void
    var xmlData: Data
    var completion: ParsingCompletion

    //Parsing book keeping
    private var currentElement: String?
    private var xCoord: String = ""
    private var yCoord: String = ""
    private var gestureName: String?
    private var strokes: [[Point]] = []
    private var currentStroke = [Point]()
    private var currentStrokeId: Int = -1

    public static func loadStrokePattern(fromFile named: String, bundle customBundle: Bundle? = nil, completion: ParsingCompletion?) throws {
        let bundle = customBundle ?? Bundle(for: OneDollar.self)
        guard
            let url = bundle.url(forResource: named, withExtension: "xml")
            else {
                return
        }

        let data = try Data(contentsOf: url)
        let parser = MultiStrokeParser(xmlData: data, completion: { pointPath in
            let namedPath = pointPath
            namedPath.name = named
            completion?(namedPath)
        })

        parser.run()
    }

    public static func loadStrokePatterns(files: [String], bundle: Bundle? = nil, completion: (([MultiStrokePath]) -> Void)?) {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "thread-safe", attributes: .concurrent)
        var array = Array<MultiStrokePath?>(repeating: nil, count: files.count)

        for (idx, f) in files.enumerated() {
            do {
                try MultiStrokeParser.loadStrokePattern(fromFile: f, bundle: bundle) { path in
                    group.enter()
                    queue.async(flags: .barrier) {
                        array[idx] = path
                        group.leave()
                    }
                }
            } catch let e {
                print(e)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            print("Done loading templates")
            let pathArray = array.compactMap { $0 }
            completion?(pathArray)
        }
    }

    lazy var parser: XMLParser = {
        let parser = XMLParser(data: self.xmlData)
        return parser
    }()

    init(xmlData: Data, completion: @escaping ParsingCompletion) {
        self.xmlData = xmlData
        self.completion = completion
        super.init()
        parser.delegate = self
        parser.parse()
    }

    public func run() {
        parser.parse()
    }

    // MARK: - XMLParserDelegate
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "Point" {
            xCoord = attributeDict["X"] ?? ""
            yCoord = attributeDict["Y"] ?? ""
        } else if elementName == "Stroke" {
            currentStroke = []
            currentStrokeId = attributeDict["index"].flatMap { Int($0) } ?? -1
        } else if elementName == "Gesture" {
            gestureName = attributeDict["Name"]
        }
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Point" {
            if let x = Int(xCoord), let y = Int(yCoord) {
                let point = Point(x: Double(x), y: Double(y), strokeId: currentStrokeId)
                currentStroke.append(point)
            }
        } else if elementName == "Stroke" {
            strokes.append(currentStroke)
        }
    }

    public func parserDidEndDocument(_ parser: XMLParser) {
        let path = MultiStrokePath(strokes: strokes, name: gestureName)
        self.completion(path)
    }
}
