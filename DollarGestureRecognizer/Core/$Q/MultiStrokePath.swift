//
//  MultiStrokePath.swift
//  DollarGestureRecognizer
//
//  Created by Daniel Cardona Rojas on 8/14/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//


public class MultiStrokePath {
    public var strokes: [[Point]]
    public var name: String?

    public init (strokes: [[Point]], name: String? = nil) {
        self.strokes = strokes
        self.name = name
    }

    public convenience init(strokes: [[CGPoint]], name: String? = nil) {
        self.init(strokes: strokes.map { $0.toPoints()}, name: name)
    }
}

extension MultiStrokePath {
    public enum DefaultTemplate: String, CustomStringConvertible, CaseIterable {
        case asterisk
        case pitchfork

        public var description: String {
            return self.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
