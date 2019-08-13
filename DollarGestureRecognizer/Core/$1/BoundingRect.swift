//
//  BoundingRect.swift
//  DollarGestureRecognizer
//
//  Created by Daniel Cardona Rojas on 8/14/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

struct BoundingRect { //A rectangle that resizes to fit a shape
    private var bottomLeft: Point
    private var upperRight: Point

    var height: Double {
        return abs(self.bottomLeft.y - self.upperRight.y)
    }

    var width: Double {
        return abs(self.bottomLeft.x - self.upperRight.x)
    }

    var diagonal: Double {
        return sqrt(pow(height, 2) + pow(width, 2))
    }

    static func initialRect() -> BoundingRect {
        let plusInfinity = +Double.infinity
        let minusInfinity = -Double.infinity
        let bottomLeft = Point(x: plusInfinity, y: plusInfinity)
        let upperRight = Point(x: minusInfinity, y: minusInfinity)
        return BoundingRect(bottomLeft: bottomLeft, upperRight: upperRight)
    }

    private init(bottomLeft: Point, upperRight: Point) {
        self.bottomLeft = bottomLeft
        self.upperRight = upperRight
    }

    mutating func updateBoundaries(point: Point) {
        bottomLeft.x = min(bottomLeft.x, point.x)
        upperRight.x = max(upperRight.x, point.x)
        bottomLeft.y = min(bottomLeft.y, point.y)
        upperRight.y = max(upperRight.y, point.y)
    }

    static func fromPath(_ path: PointPath) -> BoundingRect {
        //Mutates the the rect until it captures all boundaries of path
        var rect = initialRect()
        for point in path {
            rect.updateBoundaries(point: point)
        }
        return rect
    }

}
