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

// MARK: - Types -
public struct Point {
    var x: Double
    var y: Double
}

typealias PointPath = [Point]
typealias Template = PointPath
typealias OneDollarTemplate = SingleStrokePath
typealias Degrees = Int
typealias Radians = Double

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

// MARK: Core Algorithm
public class OneDollar {
    private var candidate: PointPath

    var dollarTemplates: [OneDollarTemplate] {
        didSet {
           self.templates = self.sampledTemplates(dollarTemplates)
        }
    }

    private var configuration: OneDollarConfig
    var candidatePath: PointPath {
        get {
            return self.candidate
        }
        set(newValue) {
           self.candidate = newValue
        }
    }

    private(set) lazy var templates: [Template] = {
        return sampledTemplates(self.dollarTemplates)
    }()

    func sampledTemplates(_ dollarTemplates: [OneDollarTemplate]) -> [Template] {
        return dollarTemplates.map { t in
            let points = t.path
            let result = OneDollar.resample(points: points, totalPoints: configuration.numPoints)
            return result
        }
    }

    convenience init(templates: OneDollarTemplate..., configuration: OneDollarConfig = OneDollarConfig.defaultConfig()) {
        self.init(templates: templates, configuration: configuration)
    }
    
    init(templates: [OneDollarTemplate], configuration: OneDollarConfig = OneDollarConfig.defaultConfig()) {
        self.candidate = []
        self.configuration = configuration
        self.dollarTemplates = templates
    }
    
    public func reconfigure(templates: [SingleStrokePath], configuration: OneDollarConfig? = nil) {
        self.dollarTemplates = templates
        self.templates = templates.map { dt in dt.path }
        if let newConf = configuration {
           self.configuration = newConf
        }
    }
    
    // MARK: - Algorithm steps -
    //Step 1: Resample a points path into n evenly spaced points.
    func resample () throws { // 32 <= N <= 256
        candidate = OneDollar.resample(points: candidate, totalPoints: configuration.numPoints)

        if candidate.count < configuration.numPoints {
            throw OneDollarError.TooFewPoints
        }
    }
    
    //Step 2: Rotate Once Based on the “Indicative Angle” so its zero.
    private func rotate() {
        candidate = OneDollar.rotate(points: candidate, by: -candidate.indicativeAngle())
        templates = templates.map { t in OneDollar.rotate(points: t, by: -t.indicativeAngle()) }
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
    public func recognize(candidate c: SingleStrokePath) throws -> (templateIndex: Int, score: Double)? {
        self.candidate = c.path
        if templates.count == 0 || candidate.count == 0 { throw OneDollarError.EmptyTemplates }
        if !templates.filter({ t in t.count == 0 }).isEmpty { throw OneDollarError.EmptyTemplates }

        var bestDistance = Double.infinity
        var bestTemplate: Int?
        var templateIdx: Int = 0
        
        try resample()
        rotate()
        scaleAndTranslate()

        for template in templates {
            let templateDistance = OneDollar.distanceAtBestAngle(
                 points: candidate, template: template,
                 from: -configuration.angleRange, to: configuration.angleRange,
                 threshold: configuration.anglePrecision
            )
            if templateDistance < bestDistance {
                bestDistance = templateDistance
                bestTemplate = templateIdx
            }
            templateIdx += 1
        }
        let size = configuration.squareSize
        let score: Double = 1 - bestDistance / (0.5 * sqrt(pow(size, 2) + pow(size, 2)))
        guard let bestTemplateIdx = bestTemplate else { return nil }
        return (bestTemplateIdx, score)
    }
}

// MARK: - OneDollar Extensions -
extension OneDollar {
    static func resample(points: PointPath, totalPoints: Int) -> PointPath {
        let interval = points.pathLength() / Double(totalPoints - 1)
        var initialPoints = points
        var D: Double = 0.0
        if points.count == 0 { return [] }
        var newPoints: [Point] = [points.first!]
        var i: Int = 1
        
        while i < initialPoints.count {
            let currentLength = initialPoints[i - 1].distanceTo(point: initialPoints[i])
            if ( (D + currentLength) >= interval) {
                let qx = initialPoints[i - 1].x + ((interval - D) / currentLength) * (initialPoints[i].x - initialPoints[i - 1].x)
                let qy = initialPoints[i - 1].y + ((interval - D) / currentLength) * (initialPoints[i].y - initialPoints[i - 1].y)
                let q = Point(x: qx, y: qy)
                newPoints.append(q)
                initialPoints.insert(q, at: i)
                D = 0.0
            } else {
                D += currentLength
            }
            i += 1
        }
        if newPoints.count == totalPoints - 1 {
            newPoints.append(points.last!)
        }
        return newPoints
    }
    
    static func pathDistance(pointPath1: PointPath, pointPath2: PointPath) -> Double {
        let zipped = zip(pointPath1, pointPath2)
        let unormalizedDistance = zipped.map { (p1, p2) in Point.distance(from: p1, to: p2) }.reduce(0, +)
        return unormalizedDistance / Double(pointPath1.count)
    }
    
    static func translate(points: PointPath, to: Point) -> PointPath {
        let centroid = points.centroid()
        return points.map { (p: Point) -> Point in
            let newX = p.x + (to.x - centroid.x)
            let newY = p.y + (to.y - centroid.y)
            return Point(x: newX, y: newY)
        }
    }
    
    static func scaleToBoundingBox(points: PointPath, size: Double) -> PointPath { //Perform nonuniform scaling
        let boundingBox = BoundingRect.fromPath(points)
        let newPath = points.map { p in Point(x: p.x * (size / boundingBox.width), y: p.y * (size / boundingBox.height) ) }
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
        var x1 = DollarConstants.Phi * fromAngle + (1.0 - DollarConstants.Phi) * toAngle
        var f1 = OneDollar.distanceAtAngle(points, template: template, angle: x1)
        var x2 = (1.0 - DollarConstants.Phi) * fromAngle + DollarConstants.Phi * toAngle
        var f2 = OneDollar.distanceAtAngle(points, template: template, angle: x2)

        while ( abs(toAngle - fromAngle) > threshold ) {
            if f1 < f2 {
                toAngle = x2
                x2 = x1
                f2 = f1
                x1 = DollarConstants.Phi * fromAngle + (1.0 - DollarConstants.Phi) * toAngle
                f1 = OneDollar.distanceAtAngle(points, template: template, angle: x1)
            } else {
                fromAngle = x1
                x1 = x2
                f1 = f2
                x2 = (1.0 - DollarConstants.Phi) * fromAngle + DollarConstants.Phi * toAngle
                f2 = OneDollar.distanceAtAngle(points, template: template, angle: x2)
            }
        }
        return min(f1, f2)
    }
}

// MARK: Point extensions
extension Point {
    public init(point: CGPoint) {
        self.x = Double(point.x); self.y = Double(point.y)
    }
    
    static func distance(from: Point, to: Point) -> Double {
        let dx = (from.x - to.x)
        let dy = (from.y - to.y)
        return sqrt(dx * dx + dy * dy)
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

private extension Double {
    func toRadians ( ) -> Radians {
       return (self / 180.0) * Double.pi
    }
}
