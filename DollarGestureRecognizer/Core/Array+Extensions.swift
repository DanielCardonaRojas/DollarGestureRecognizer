//
//  Array+Extensions.swift
//  DollarGestureRecognizer
//
//  Created by Daniel Cardona Rojas on 9/9/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

import Foundation

// MARK: - Generic
extension Array {
    // Pairs contigious array elements returning based on a comparison function
    func groupBy(_ f: (Element, Element) -> Bool) -> [[Element]]  {
        guard let firstElement = first else {
            return []
        }

        return reduce(into: [[]], { acc, next in
            guard let lastGroup = acc.last else {
                acc.append([next])
                return
            }

            let previous = lastGroup.last ?? firstElement

            if f(previous, next) {
                var previousGroup = lastGroup
                previousGroup.append(next)
                let count = acc.count
                acc[count - 1] = previousGroup
            } else {
                acc.append([next])
            }
        })
    }
}

// MARK: - Business logic related
extension Array where Element == Point {
    func centroid() -> Point {
        var centroidPoint = self.reduce(Point(x: 0, y: 0)) { (acc, p) -> Point in
            acc + p
        }
        let totalPoints = Double(self.count)
        centroidPoint.x = (centroidPoint.x / totalPoints)
        centroidPoint.y = (centroidPoint.y / totalPoints)
        return centroidPoint
    }

    func pathLength() -> Double {
        guard self.count > 1 else { return 0 }
        var totalDistance: Double = 0
        for idx in 1...(self.count - 1) {
            totalDistance += self[idx - 1].distanceTo(point: self[idx])
        }
        return totalDistance
    }

    func indicativeAngle() -> Double {
        let centroid = self.centroid()
        return atan2(centroid.y - self.first!.y, centroid.x - self.first!.x)
    }

    func boundingRect() -> (min: Point, max: Point) {
        let minimum = self.min(by: { point1, point2 in
            return point1.x < point2.x && point1.y < point2.y
        }) ?? Point(x: Double.greatestFiniteMagnitude, y: Double.greatestFiniteMagnitude)

        let maximum = self.max(by: { point1, point2 in
            return point1.x > point2.x && point1.y > point2.y
        }) ?? Point(x: -Double.greatestFiniteMagnitude, y: -Double.greatestFiniteMagnitude)

        return (minimum, maximum)
    }

    func groupedByStrokeId() -> [[Point]] {
        return self.groupBy({ $0.strokeId == $1.strokeId && $0.strokeId != nil && $1.strokeId != nil })
    }

}

