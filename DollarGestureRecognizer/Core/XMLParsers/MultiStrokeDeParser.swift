//
//  MultiStrokeDeParser.swift
//  DollarGestureRecognizer
//
//  Created by Yunseo Lee on 1/5/24.
//  Copyright © 2024 Daniel Cardona. All rights reserved.
//
import Foundation

public class MultiStrokeDeParser {
    
    private var xmlString: String = ""
    private var strokeCount: Int
    
    public init() {
        strokeCount = 0
        startDocument()
    }
    
    // Starts a new document
    public func startDocument() {
        xmlString = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>\n"
    }
    
    // Starts a new element with optional attributes
    public func startGesture(name: String, subject: String, inputType: UITouch.TouchType = .direct, numPoints: Int) {
        var touchStyle: String
        switch inputType {
        case .stylus:
            touchStyle = "stylus"
        case .direct:
            touchStyle = "finger"
        default:
            touchStyle = "finger"
        }
        // ex. <Gesture Name="image~01" Subject="73" InputType="finger" Speed="MEDIUM" NumPts="102">
        xmlString += "<Gesture Name=\"\(name)\" Subject=\"\(subject)\" InputType=\"\(touchStyle)\" Speed=\"MEDIUM\" NumPts=\"\(numPoints)\">\n"
    }
    // Ends the document and returns the final XML string
    public func endDocument() -> String {
        return xmlString
    }
    
    // Function to write MultiStrokePath to XML
    public func write(multiStrokePath: MultiStrokePath) {
        for stroke in multiStrokePath.strokes {
            strokeCount += 1
            xmlString += "\t<Stroke index=\"\(strokeCount)\">\n"
            for point in stroke {
                xmlString += "\t\t<Point X=\"\(point.x)\" Y=\"\(point.y)\" T=\"\(point.time ?? 0 )\" Pressure=\"\(point.pressure ?? 0)\"/>\n"
            }
            xmlString += "\t<\\Stroke>\n"
        }
        
        xmlString += "<\\Gesture>"
    }
    
    // Save the XML to a file
    public func save(to url: URL) throws {
        try xmlString.write(to: url, atomically: true, encoding: .utf8)
    }
}

// Usage:
// let writer = XMLWriter()
// writer.write(multiStrokePath: yourMultiStrokePathObject)
// try? writer.save(to: URL(fileURLWithPath: "path/to/your/file.xml"))
