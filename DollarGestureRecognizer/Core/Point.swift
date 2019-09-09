//
//  Point.swift
//  DollarGestureRecognizer
//
//  Created by Daniel Cardona Rojas on 8/15/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

typealias Number = Double

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
    static var zero: Point = Point(x: 0, y: 0)

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

    static func * (_ lhs: Point, _ rhs: Double) -> Point {
        return Point(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    static func / (_ lhs: Point, _ rhs: Double) -> Point {
        return lhs * ( 1 / rhs )
    }

    static func squareEuclideanDistance(_ a: Point, _ b: Point) -> Double {
        let dx = (a.x - b.x)
        let dy = (a.y - b.y)
        return (dx * dx + dy * dy)
    }


}

// MARK: PointPath extensions
public extension Array where Element == CGPoint {
    func toPoints() -> [Point] {
        return self.map { p in Point(point: p) }
    }
}

