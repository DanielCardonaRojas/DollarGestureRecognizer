//
//  OneDollar.swift
//  CustomGestureRecognizers
//
//  Created by Daniel Esteban Cardona Rojas on 12/15/17.
//  Copyright © 2017 Daniel Esteban Cardona Rojas. All rights reserved.
//  An implementation of the OneDollar gesture recognition algorithm.
//  https://faculty.washington.edu/wobbrock/pubs/uist-07.01.pdf
// http://depts.washington.edu/madlab/proj/dollar/

import Foundation
import UIKit

//MARK: -- Types --
struct Point {
    var x: Double
    var y: Double
}

typealias PointPath = [Point]
typealias Template = PointPath
typealias OneDollarTemplate = OneDollarPath
typealias Degrees = Int
typealias Radians = Double

public struct OneDollarPath {
    var path: PointPath
    
    static func from(path: UIBezierPath) -> OneDollarPath {
        return OneDollarPath.from(path: path.cgPath)
    }
    
    static func from(path: CGPath) -> OneDollarPath {
        let points: [CGPoint] = PathElement.evaluate(path: path.elements(), every: [0.0, 0.5, 1.0])
        return OneDollarPath(path: points.map {p in Point(point: p)})
    }
}

public enum OneDollarError: Error {
    case MatchNotFound // thrown when recognize doesn't match score expectations.
    case EmptyTemplates
    case TooFewPoints
}

public struct OneDollarConfig {
    let numPoints: Int
    let squareSize: Double
    let zeroPoint: Point
    let angleRange: Double
    let anglePrecision: Double
    var diagonal: Double {
        return sqrt( squareSize * squareSize + squareSize * squareSize )
    }
    var halfDiagonal: Double {
        return (diagonal * 0.5)
    }
    
    static func defaultConfig() -> OneDollarConfig {
        let zeroPointRef = Point(point: CGPoint.zero)
        return OneDollarConfig(numPoints: 64,
                               squareSize: 250.0,
                               zeroPoint: zeroPointRef,
                               angleRange: Double(45.0).toRadians(),
                               anglePrecision: Double(2.0).toRadians()
        )
    }
}

enum OneDollarConsts {
    public static let Phi: Double = (0.5 * (-1.0 + sqrt(5.0)))
}

struct BoundingRect { //A rectangle that resizes to fit a shape
    private var bottomLeft: Point
    private var upperRight: Point
    
    var height: Double {
        return abs(self.bottomLeft.y - self.upperRight.y)
    }
    
    var width: Double {
        return abs(self.bottomLeft.x - self.upperRight.x)
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

// Mark: Core Algorithm
public class OneDollar {
    private var candidate: PointPath
    private var templates: [Template]
    private var dollarTemplates: [OneDollarTemplate]
    private var configuration: OneDollarConfig
    
    init(candidate: OneDollarPath, templates: [OneDollarTemplate], configuration: OneDollarConfig = OneDollarConfig.defaultConfig()) {
        self.candidate = candidate.path
        self.configuration = configuration
        self.dollarTemplates = templates
        self.templates = templates.map { dt in dt.path }
    }
    
    public func reconfigure(candidate: OneDollarPath, templates: [OneDollarPath], configuration: OneDollarConfig? = nil) {
        self.candidate = candidate.path
        self.dollarTemplates = templates
        self.templates = templates.map { dt in dt.path }
        if let newConf = configuration {
           self.configuration = newConf
        }
    }
    
    //MARK:  ---- Algorithm steps -----
    //Step 1: Resample a points path into n evenly spaced points.
    private func resample() { // 32 <= N <= 256
        let length = configuration.numPoints
        candidate = OneDollar.resample(points: candidate, totalPoints: length)
        templates = templates.map{ t in OneDollar.resample(points: t, totalPoints: length)}
    }
    
    //Step 2: Rotate Once Based on the “Indicative Angle” so its zero.
    private func rotate() {
        candidate = OneDollar.rotate(points: candidate, by: -candidate.indicativeAngle())
        templates = templates.map { t in OneDollar.rotate(points: t, by: -t.indicativeAngle())}
    }
    
    //Step 3: Scale points so that the resulting bounding box
    private func scaleAndTranslate() {
        candidate = OneDollar.scaleToBoundingBox(points: candidate, size: configuration.squareSize)
        candidate = OneDollar.translate(points: candidate, to: configuration.zeroPoint)
        templates = templates.map { (t: Template) -> Template in
            var newTemplate: Template
            newTemplate = OneDollar.scaleToBoundingBox(points: t, size: configuration.squareSize)
            newTemplate = OneDollar.translate(points: newTemplate, to: configuration.zeroPoint)
            return newTemplate
        }
    }
    
    //Step 4: Match points against a set of templates
    public func recognize(minThreshold: Double = 0.8) throws -> (template: OneDollarPath, score: Double)? {
        if templates.count == 0 || candidate.count == 0 { throw OneDollarError.EmptyTemplates }
        if candidate.count < 10 { throw OneDollarError.TooFewPoints }
        
        var bestDistance = Double.infinity
        var bestTemplate: OneDollarTemplate?
        var templateIdx: Int = 0
        
        resample()
        rotate()
        scaleAndTranslate()

        for template in templates {
            let templateDistance = OneDollar.distanceAtBestAngle(
                 points: candidate, template: template,
                 from:  -configuration.angleRange, to: configuration.angleRange,
                 threshold: configuration.anglePrecision
            )
            if templateDistance < bestDistance {
                bestDistance = templateDistance
                bestTemplate = dollarTemplates[templateIdx]
            }
            templateIdx += 1
        }
        
        guard let matchingTemplate = bestTemplate else { return nil }
        if bestDistance < minThreshold { throw OneDollarError.MatchNotFound }
        return Optional.some((matchingTemplate, bestDistance))
    }
}

//MARK: OneDollar Extensions
extension OneDollar {
    static func resample(points: PointPath, totalPoints: Int) -> PointPath {
        let interval = points.pathLength() / Double(totalPoints - 1)
        var initialPoints = points
        var totalLength: Double = 0.0
        var newPoints: [Point] = [points.first!]
        for i in 1...(points.count - 1) {
            let currentLength = initialPoints[i-1].distanceTo(point: initialPoints[i])
            if ( (totalLength+currentLength) >= interval) {
                let qx = initialPoints[i-1].x + ((interval - totalLength) / currentLength) * (initialPoints[i].x - initialPoints[i-1].x)
                let qy = initialPoints[i-1].y + ((interval - totalLength) / currentLength) * (initialPoints[i].y - initialPoints[i-1].y)
                let q = Point(x: qx, y: qy)
                newPoints.append(q)
                initialPoints.insert(q, at: i)
                totalLength = 0.0
            } else {
                totalLength += currentLength
            }
        }
        if newPoints.count == totalPoints-1 {
            newPoints.append(points.last!)
        }
        return newPoints
    }
    
    static func pathDistance(pointPath1: PointPath, pointPath2: PointPath) -> Double {
        let zipped = zip(pointPath1, pointPath2)
        let unormalizedDistance = zipped.map { (p1, p2) in Point.distance(from: p1, to: p2)}.reduce(0, +)
        return unormalizedDistance / Double(pointPath1.count)
    }
    
    static func translate(points: PointPath, to: Point) -> PointPath{
        let centroid = points.centroid()
        return points.map { (p: Point) -> Point in
            let newX = p.x + (to.x - centroid.x)
            let newY = p.y + (to.y - centroid.y)
            return Point(x: newX, y: newY)
        }
    }
    
    static func scaleToBoundingBox(points: PointPath, size: Double) -> PointPath { //Perform nonuniform scaling
        let boundingBox = BoundingRect.fromPath(points)
        let newPath = points.map {p in Point(x: p.x * (size / boundingBox.width), y: p.y * (size / boundingBox.height) ) }
        return newPath
    }

    static func rotate(points: PointPath, by: Radians) -> PointPath {
        let centroid = points.centroid()
        let cosvalue = cos(by)
        let sinvalue = sin(by)
        return points.map { (p: Point) -> Point in
            let qx = (p.x - centroid.x) * cosvalue - (p.y - centroid.y) * sinvalue + centroid.x
            let qy = (p.x - centroid.x) * sinvalue + (p.y - centroid.y) * cosvalue + centroid.y
            return Point(x: qx, y: qy)
        }
    }
    
    static func distanceAtAngle(_ candidate: PointPath, template: PointPath, angle: Radians) -> Double {
        let adjustedCandidate = OneDollar.rotate(points: candidate, by: angle)
        return OneDollar.pathDistance(pointPath1: adjustedCandidate, pointPath2: template)
    }
    
    static func distanceAtBestAngle(points: PointPath, template: PointPath, from: Radians, to: Radians, threshold: Double) -> Double {
        var toAngle = to
        var fromAngle = from
        var x1 = OneDollarConsts.Phi * fromAngle + (1.0 - OneDollarConsts.Phi) * toAngle
        var f1 = OneDollar.distanceAtAngle(points, template: template, angle: x1)
        var x2 = (1.0 - OneDollarConsts.Phi) * fromAngle + OneDollarConsts.Phi * toAngle
        var f2 = OneDollar.distanceAtAngle(points, template: template, angle: x2)

        while ( abs(toAngle-fromAngle) > threshold ) {
            if f1 < f2 {
                toAngle = x2
                x2 = x1
                f2 = f1
                x1 = OneDollarConsts.Phi * fromAngle + (1.0 - OneDollarConsts.Phi) * toAngle
                f1 = OneDollar.distanceAtAngle(points, template: template, angle: x1)
            } else {
                fromAngle = x1
                x1 = x2
                f1 = f2
                x2 = (1.0 - OneDollarConsts.Phi) * fromAngle + OneDollarConsts.Phi * toAngle
                f2 = OneDollar.distanceAtAngle(points, template: template, angle: x2)
            }
        }
        return min(f1,f2)
    }
    

}

//MARK: Point extensions
extension Point {
    public init(point: CGPoint) {
        self.x = Double(point.x); self.y = Double(point.y)
    }
    
    static func distance(from: Point, to: Point) -> Double {
        let dx = (from.x - to.x)
        let dy = (from.y - to.y)
        return sqrt(dx*dx + dy*dy)
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
    
}

//MARK: PointPath extensions
extension Array where Element == Point {
    func centroid() -> Point {
        var centroidPoint = self.reduce(Point(x: 0, y: 0)) { (acc, p) -> Point in
            Point(x: acc.x + p.x, y: acc.y + p.y)
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

extension Array where Element == CGPoint {
    func toPoints() -> [Point] {
        return self.map {p in Point(point: p)}
    }
}

private extension Double {
    func toRadians ( ) -> Radians {
       return (self/180) * Double.pi
    }
}

