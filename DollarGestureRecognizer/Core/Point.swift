//
//  Point.swift
//  DollarGestureRecognizer
//
//  Created by Daniel Cardona Rojas on 8/15/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

public struct Point {
    var x: Double
    var y: Double
    var strokeId: Int?

    init(x: Double, y: Double, strokeId: Int? = nil) {
        self.x = x
        self.y = y
        self.strokeId = strokeId
    }
}

// MARK: Point extensions
extension Point {
    public init(point: CGPoint) {
        self.x = Double(point.x); self.y = Double(point.y)
    }

    static func distance(from: Point, to: Point) -> Double {
        return sqrt(Point.squareEuclideanDistance(from, to))
    }

    func distanceTo(point: Point) -> Double {
        return Point.distance(from: self, to: point)
    }

    func cgPoint() -> CGPoint {
        return CGPoint(x: CGFloat(self.x), y: CGFloat(self.y))
    }

    static func modify(_ point: Point, _ function: (Double) -> Double) -> Point { //Applies function to both components
        return Point(x: function(point.x), y: function(point.y))
    }

    func apply(_ function: (Double) -> Double) -> Point {
        return Point.modify(self, function)
    }

    static func + (_ lhs: Point, _ rhs: Point) -> Point {
        return Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func squareEuclideanDistance(_ a: Point, _ b: Point) -> Double {
        let dx = (a.x - b.x)
        let dy = (a.y - b.y)
        return (dx * dx + dy * dy)
    }


}

// MARK: PointPath extensions
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

}

public extension Array where Element == CGPoint {
    func toPoints() -> [Point] {
        return self.map { p in Point(point: p) }
    }
}

