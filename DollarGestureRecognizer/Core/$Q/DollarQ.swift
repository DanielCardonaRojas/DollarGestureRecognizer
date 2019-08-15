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
    static func lookUpTable(points: [Point], m: Int, n: Int) -> LookUpTable<Int>  {
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

}
