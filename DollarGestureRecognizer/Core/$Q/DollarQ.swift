//
//  DollarQ.swift
//  DollarGestureRecognizer
//
//  Created by Daniel Cardona Rojas on 8/14/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

import Foundation

public class DollarQ {

    public typealias LookUpTable = [[Int]]

    private var candidate: MultiStrokePath?
    private var _templates: [MultiStrokePath] = []

    var templates: [MultiStrokePath] {
        set(newValue) {
            var updateTemplates = [MultiStrokePath]()
            for t in newValue {
                let lut = DollarQ.computeLookUpTable(points: t.asTemplate, m: m, n: n)
                t.lut = lut
                updateTemplates.append(t)
            }
            self._templates = updateTemplates
        }

        get {
            return self._templates
        }

    }

    let n: Int
    let m: Int

    init(templates: [MultiStrokePath], n: Int = 32, m: Int = 64) {
        self.n = n
        self.m = m
        self.templates = templates
    }

    func recognize(points: MultiStrokePath) throws -> (template: Template, score: Double)? {
        var score = Double.greatestFiniteMagnitude
        let normalizedPoints = DollarQ.normalize(points: points.asTemplate, n: n, m: m)
        let lut = DollarQ.computeLookUpTable(points: normalizedPoints, m: m, n: n)
        points.lut = lut
        candidate = points
        var match: Template?

        for multiStroke in templates {
            let d = DollarQ.cloudMatch(points: points, template: multiStroke, n: n, min: score)
            if d < score {
                score = d
                match = multiStroke.asTemplate
            }
        }

        guard let result = match else {
            return nil
        }

        return (result, score)
    }

    // MARK: - Base algorithm methods
    static func computeLookUpTable(points: [Point], m: Int, n: Int) -> LookUpTable {
        var lut = [[Int]](repeating: [Int].init(repeating: -1, count: m), count: m)
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

    static func cloudMatch(points: MultiStrokePath, template: MultiStrokePath, n: Int, min minimum: Double) -> Double {
        let step = Int(sqrt(Double(n)).rounded())
        let lowerBound1 = computeLowerBound(points: points.asTemplate, template: template.asTemplate, step: step, n: n, lut: template.lut!)
        let lowerBound2 = computeLowerBound(points: template.asTemplate, template: points.asTemplate, step: step, n: n, lut: points.lut!)
        var minSoFar = minimum

        for i in 0..<n {
            let index = i / step
            if lowerBound1[index] < minSoFar {
                let distance = DollarQ.cloudDistance(points: points.asTemplate, template: template.asTemplate, n: n, start: i, minSoFar: minSoFar)
                minSoFar = min(minSoFar, distance)
            }

            if lowerBound2[index] < minSoFar {
                let distance = DollarQ.cloudDistance(points: template.asTemplate, template: points.asTemplate, n: n, start: i, minSoFar: minSoFar)
                minSoFar = min(minSoFar, distance)
            }

        }

        return minSoFar
    }

    static func cloudDistance(points: [Point], template: [Point], n: Int, start: Int, minSoFar: Double) -> Double {
        var i = start
        var unmatched = Array(0..<n)
        var weight = n
        var sum = 0.0
        var min = Double.greatestFiniteMagnitude

        repeat {
            for j in unmatched {
                let d = points[i].distanceTo(point: template[j])
                if d < min {
                    min = d
                    unmatched.remove(at: j)
                }

                sum += Double(weight) * min

                if sum >= minSoFar {
                    return sum
                }

                weight -= 1
                i = (i + 1) % n
            }

        } while i == start

        return sum
    }

    static func computeLowerBound(points: [Point], template: [Point], step: Int, n: Int, lut: LookUpTable) -> [Double] {
        var lowerBound = Array(repeating: 0.0, count: n / (step + 1))
        var summedAreaTable = Array(repeating: 0.0, count: n)

        for i in 0..<n {
            let point = points[i]
            let x = Int(point.x)
            let y = Int(point.y)
            let index = lut[x][y]
            let distance = point.distanceTo(point: template[index])
            summedAreaTable[i] = i == 0 ? distance : summedAreaTable[i - 1] + distance
            lowerBound[0] = lowerBound[0] + Double(n - i) * distance
        }

        for i in step..<n {
            lowerBound[i/step] = lowerBound[0] + Double(i) * summedAreaTable[n - 1] - Double(n) * summedAreaTable[i - 1]
        }
        return lowerBound
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

extension MultiStrokePath {
    struct Keys {
        static var lut = "LUT"
    }

    @objc public var lut: DollarQ.LookUpTable? {
        get {
            guard let value = objc_getAssociatedObject(self, &Keys.lut) else {
                return nil
            }
            
            return value as? DollarQ.LookUpTable
        }

        set(newValue) {
            objc_setAssociatedObject(self, &Keys.lut, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

}
