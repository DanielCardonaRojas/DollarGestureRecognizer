//
//  DollarPath.swift
//  DollarGestureRecognizer
//
//  Created by Daniel Cardona Rojas on 8/14/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

import Foundation

public class SingleStrokePath {
    public var path: [Point]
    public var name: String?

    public init (path: [Point], name: String? = nil) {
        self.path = path
        self.name = name
    }

    public convenience init(path: [CGPoint], name: String? = nil) {
        self.init(path: path.toPoints(), name: name)
    }

    @available(iOS 11.0, *)
    convenience init(path: UIBezierPath) {
        self.init(path: path.cgPath)
    }

    @available(iOS 11.0, *)
    public init(path: CGPath) {
        let range = stride(from: 0, to: 1, by: 0.015)
        let points: [CGPoint] = PathElement.evaluate(path: path.elements(), every: Array(range))
        self.path = points.map { p in Point(point: p) }
    }
}

extension SingleStrokePath {
    public enum DefaultTemplate: String, CustomStringConvertible, CaseIterable {
        case arrow
        case caret
        case check
        case circle
        case deleteMark = "delete_mark"
        case leftCurlyBrace = "left_curly_brace"
        case leftSquareBracket = "left_sq_bracket"
        case pigtail
        case questionMark
        case rectangle
        case rightCurlyBrace = "right_curly_brace"
        case rightSquareBracket = "right_sq_bracket"
        case star
        case triangle
        case v
        case x

        public var description: String {
            return self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
