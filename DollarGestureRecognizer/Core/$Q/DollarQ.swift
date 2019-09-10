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

    var candidateLUT: LookUpTable<Int> = LookUpTable()

    func recognize(points: [Point], templates: [Template]) throws -> (template: Template, score: Double)? {
        let n = 32
        let m = 64
        var score = Double.greatestFiniteMagnitude
        let normalizedPoints = DollarQ.normalize(points: points, n: n, m: m)
        let lut = DollarQ.computeLookUpTable(points: normalizedPoints, m: m, n: n)
        candidateLUT = lut
        var match: Template?

        for template in templates {
            let d = DollarQ.cloudMatch(points: points, template: template, n: n, min: score)
            if d < score {
                score = d
                match = template
            }
        }

        guard let result = match else {
            return nil
        }

        return (result, score)
    }

    // MARK: - Base algorithm methods
    static func computeLookUpTable(points: [Point], m: Int, n: Int) -> LookUpTable<Int> {
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

    static func cloudMatch(points: [Point], template: Template, n: Int, min minimum: Double) -> Double {
        let step = Int(sqrt(Double(n)).rounded())
        let templateLUT = computeLookUpTable(points: template, m: 64, n: 32)
        let pointsLUT = computeLookUpTable(points: points, m: 64, n: 32)
        let lowerBound1 = computeLowerBound(points: points, template: template, step: step, lut: templateLUT)
        let lowerBound2 = computeLowerBound(points: template, template: points, step: step, lut: pointsLUT)
        var minSoFar = minimum
        
        for i in 0..<n {
            let index = i / step
            if lowerBound1[index] < minSoFar {
                let distance = DollarQ.cloudDistance(points: points, template: template, n: n, start: i, minSoFar: minSoFar)
                minSoFar = min(minSoFar, distance)
            }

            if lowerBound2[index] < minSoFar {
                let distance = DollarQ.cloudDistance(points: template, template: points, n: n, start: i, minSoFar: minSoFar)
                minSoFar = min(minSoFar, distance)
            }

        }

        return minSoFar
    }

    static func cloudDistance(points: [Point], template: [Point], n: Int, start: Int, minSoFar: Double) -> Double {
        return 0
    }

    static func computeLowerBound(points: [Point], template: [Point], step: Int, lut: LookUpTable<Int>) -> [Double] {
        return [0]
    }

    static func normalize(points: [Point], n: Int, m: Int) -> [Point] {
        let resampled = resample(points: points, size: n)
        let translated = translateToOrigin(points: resampled, n: n)
        let scaled = scale(points: translated, m: m)
        return scaled
    }
    
    static func translateToOrigin(points: [Point], n: Int) -> [Point] {
        return OneDollar.translate(points: points, to: .zero)
    }

    static func resample(points: [Point], size: Int) -> [Point] {
        let interval = points.pathLength() / Double(size - 1)
        var accumulatedLength: Double = 0
        var newPoints = [Point]()
        var initialPoints = points

        for i in 1..<size {
            let previousPoint = initialPoints[i - 1]
            let currentPoint = initialPoints[i]
            let delta = previousPoint.distanceTo(point: currentPoint)

            if delta + accumulatedLength >= interval {
                let interpolationFactor = interval - accumulatedLength / delta
                let qx = previousPoint.x + interpolationFactor * (currentPoint.x - previousPoint.x)
                let qy = previousPoint.y + interpolationFactor * (currentPoint.y - previousPoint.y)
                let interpolatedPoint = Point(x: qx, y: qy)
                newPoints.append(interpolatedPoint)
                initialPoints.insert(interpolatedPoint, at: i)

            } else {
                accumulatedLength += delta
            }

        }

       return newPoints
    }

    static func scale(points: [Point], m: Int) -> [Point] {
        let (minimum, maximum) = points.boundingRect()
        let scaleFactor = max(maximum.x - minimum.x, maximum.y - minimum.y) / Double(m - 1)
        let result = points.map { Point(x: $0.x - minimum.x, y: $0.y - minimum.y) / scaleFactor } 
        return result
    }
}
