//
//  MultiStrokePath.swift
//  DollarGestureRecognizer
//
//  Created by Daniel Cardona Rojas on 8/14/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

public class MultiStrokePath: NSObject {
    public var strokes: [[Point]]
    public var name: String?

    var asPoints: Template {
        return self.strokes.flatMap({ $0 })
    }

    public init (strokes: [[Point]], name: String? = nil) {
        self.strokes = strokes
        self.name = name
    }

    public convenience init(strokes: [[CGPoint]], name: String? = nil) {
        self.init(strokes: strokes.map { $0.toPoints() }, name: name)
    }

    public convenience init(points: [Point], name: String? = nil) {
        let strokes = points.groupedByStrokeId()
        self.init(strokes: strokes, name: name)
    }
}

extension MultiStrokePath {
    public enum DefaultTemplate: String, CustomStringConvertible, CaseIterable {
        case asterisk
        case pitchfork
        case letterD = "D"
        case letterH = "H"
        case letterP = "P"
        case letterX = "X"
        case letterT = "T"
        case letterN = "N"
        case letterI = "I"
        case null = "null"
        case exclamation = "exclamation_point"
        case horizontalLine = "line"
        case sixPointStar = "six_point_star"
        case fivePointStar = "five_point_star"
        case arrow = "arrowhead"

        public var description: String {
            return self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
