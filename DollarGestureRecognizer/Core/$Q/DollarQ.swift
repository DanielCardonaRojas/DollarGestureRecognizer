//
//  DollarQ.swift
//  DollarGestureRecognizer
//
//  Created by Daniel Cardona Rojas on 8/14/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

import Foundation

public class DollarQ {

    typealias LookUpTable<T> = [[T]]

    // MARK: - Base algorithm methods
    static func lookUpTable(points: [Point], m: Int, n: Int) -> LookUpTable<Int> {
        var lut = [[Int]]()
        for x in 0...(m - 1) {
            for y in 0...(m - 1) {
                let point = Point(x: Double(x), y: Double(y))
                let distances = points.map({ $0.distanceTo(point: point) })
                let result = distances.enumerated().min(by: { $0.1 < $1.1 })
                if let (index, _) = result {
                    lut[x][y] = index
                }
            }
        }

        return lut
    }

    static func cloudMatch(points: [Point], template: [Point], n: Int, min: Int) -> Double {
        return 0
    }

    static func cloudDistance(points: [Point], template: [Point], n: Int, start: Int, minSoFar: Float) -> Double {
        return 0
    }

    static func computeLowerBound(points: [Point], template: [Point], step: Int, lut: LookUpTable<Int>) -> Double {
        return 0
    }

    static func normalize(points: [Point], n: Int, m: Int) -> [Point] {
       return []
    }
    
    static func translateToOrigin(points: [Point], n: Int) -> [Point] {
        return OneDollar.translate(points: points, to: .zero)
    }

    static func resample(points: [Point], size: Int) -> [Point] {
        return []
    }

    static func scale(points: [Point], m: Int) -> [Point] {
        let (minimum, maximum) = points.boundingRect()
        let scaleFactor = max(maximum.x - minimum.x, maximum.y - minimum.y) / Double(m - 1)
        let result = points.map { Point(x: $0.x - minimum.x, y: $0.y - minimum.y) / scaleFactor } 
        return result
    }
}
