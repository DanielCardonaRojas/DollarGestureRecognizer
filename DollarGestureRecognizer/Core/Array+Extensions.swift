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

    subscript(safe index: Int) -> Element? {
        guard index < self.count && index >= 0 else {
            return nil
        }
        return self[index]
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
        let haveStrokeIds = allSatisfy({ $0.strokeId != nil })
        for idx in 1...(self.count - 1) {
            let previousPoint = self[idx - 1]
            let currentPoint = self[idx]
            if haveStrokeIds && previousPoint.strokeId != currentPoint.strokeId {
                continue
            }
            totalDistance += previousPoint.distanceTo(point: currentPoint)
        }
        return totalDistance
    }

    func indicativeAngle() -> Double {
        let centroid = self.centroid()
        return atan2(centroid.y - self.first!.y, centroid.x - self.first!.x)
    }

    func boundingRect() -> (min: Point, max: Point) {
        guard let firstPoint = self.first else {
            return (Point(x: .greatestFiniteMagnitude, y: .greatestFiniteMagnitude), Point(x: -.greatestFiniteMagnitude, y: -.greatestFiniteMagnitude))

        }

        let maximum = self.reduce(firstPoint, {
            return Point(x: Swift.max($0.x, $1.x), y: Swift.max($0.y, $1.y))
        })

        let minimum = self.reduce(firstPoint, {
            Point(x: Swift.min($0.x, $1.x), y: Swift.min($0.y, $1.y))
        })
        return (minimum, maximum)
    }

    func groupedByStrokeId() -> [[Point]] {
        return self.groupBy({ $0.strokeId == $1.strokeId && $0.strokeId != nil && $1.strokeId != nil })
    }
}
