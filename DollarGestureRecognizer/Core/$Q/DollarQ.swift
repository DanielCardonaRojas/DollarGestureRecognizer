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

    private var _templates: [MultiStrokePath] = []

    var templates: [MultiStrokePath] {
        set(newValue) {
            var updateTemplates = [MultiStrokePath]()
            for t in newValue {
                let points = t.asPoints
                let normalizedTemplate = DollarQ.normalize(points: points, cloudSize: cloudSize, lookUpTableSize: lutSize)
                let mstroke = MultiStrokePath(points: normalizedTemplate, name: t.name)
                let lut = DollarQ.computeLookUpTable(points: normalizedTemplate, m: lutSize, n: cloudSize)
                mstroke.lut = lut
                updateTemplates.append(mstroke)
            }
            self._templates = updateTemplates
        }

        get {
            return self._templates
        }

    }

    let cloudSize: Int
    let lutSize: Int

    init(templates: [MultiStrokePath], cloudSize: Int = 32, lookUpTableSize: Int = 64) {
        self.cloudSize = cloudSize
        self.lutSize = lookUpTableSize
        self.templates = templates
    }

    func recognize(points: MultiStrokePath) throws -> (template: Template, templateIndex: Int, score: Double)? {
        var score = Double.greatestFiniteMagnitude
        let normalizedPoints = DollarQ.normalize(points: points.asPoints, cloudSize: cloudSize, lookUpTableSize: lutSize)
        let lut = DollarQ.computeLookUpTable(points: normalizedPoints, m: lutSize, n: cloudSize)
        let updatedCandidate = MultiStrokePath(points: normalizedPoints)
        updatedCandidate.lut = lut
        var match: Template?
        var templateIndex: Int?

        for (k, multiStroke) in templates.enumerated() {
            let d = DollarQ.cloudMatch(points: updatedCandidate, template: multiStroke, n: cloudSize, min: score)
            if d < score {
                score = d
                match = multiStroke.asPoints
                templateIndex = k
            }
        }

        guard let result = match, let tmpIndex = templateIndex else {
            return nil
        }
        return (result, tmpIndex, score)
    }

    // MARK: - Base algorithm methods
    static func computeLookUpTable(points: [Point], m: Int, n: Int) -> LookUpTable {
        var lut = [[Int]](repeating: [Int].init(repeating: -1, count: m), count: m)
        for x in 0...(m - 1) {
            for y in 0...(m - 1) {
                let point = Point(x: Double(x), y: Double(y))
                let distances = points.map({ $0.nonSqrtDistance(point: point) })
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
        let lowerBound1 = computeLowerBound(points: points.asPoints, template: template.asPoints, step: step, n: n, lut: template.lut!)
        let lowerBound2 = computeLowerBound(points: template.asPoints, template: points.asPoints, step: step, n: n, lut: points.lut!)
        var minSoFar = minimum

        for i in stride(from: 0, to: n - 1, by: step) {
            let index = i / step
            if lowerBound1[index] < minSoFar {
                let distance = DollarQ.cloudDistance(points: points.asPoints, template: template.asPoints, n: n, start: i, minSoFar: minSoFar)
                minSoFar = min(minSoFar, distance)
            }

            if lowerBound2[index] < minSoFar {
                let distance = DollarQ.cloudDistance(points: template.asPoints, template: points.asPoints, n: n, start: i, minSoFar: minSoFar)
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

        repeat {
            var min = Double.greatestFiniteMagnitude
            var index: Int?
            for j in unmatched {
                let d = Point.squareEuclideanDistance(points[i], template[j])
                if d < min {
                    min = d
                    index = j
                }
            }

            if let idx = index, idx < unmatched.count {
                unmatched.remove(at: idx)
            }

            sum += Double(weight) * min

            if sum >= minSoFar {
                return sum
            }

            weight -= 1
            i = (i + 1) % n

        } while i != start
        return sum
    }

    static func computeLowerBound(points: [Point], template: [Point], step: Int, n: Int, lut: LookUpTable) -> [Double] {
        var lowerBound: [Double] = [0.0] //Array(repeating: 0.0, count: (n / step) + 1)
        var summedAreaTable = [Double]()

        for i in 0..<n {
            let point = points[i]
            let x = Int(point.x)
            let y = Int(point.y)
            let index = lut[x][y]
            let distance = Point.squareEuclideanDistance(point, template[index])
            let area = i == 0 ? distance : summedAreaTable[i - 1] + distance
            summedAreaTable.insert(area, at: i)
            lowerBound[0] = lowerBound[0] + Double(n - i) * distance
        }

        for i in stride(from: step, to: n - 1, by: step) {
            let nextValue = lowerBound[0] + (Double(i) * summedAreaTable[n - 1]) - (Double(n) * summedAreaTable[i - 1])
            lowerBound.insert(nextValue, at: i / step)
        }
        return lowerBound
    }

    static func normalize(points: [Point], cloudSize: Int, lookUpTableSize: Int) -> [Point] {
        let resampled = resample(points: points, size: cloudSize)
//        let translatedQ = translateToOriginQ(points: resampled, n: cloudSize)
        let translated = translateToOrigin(points: resampled, n: cloudSize)
        let scaledQ = scaleQ(points: translated, m: lookUpTableSize)
//        let scaled = scale(points: translated, m: lookUpTableSize)
        return scaledQ
    }
    
//    static func translateToOriginQ(points: [Point], n: Int) -> [Point] {
//        let centroid = calculateCentroidQ(points: points, n: n)
//        
//        let translatedPoints = points.map{ point -> Point in
//            print("DollarQ Translation (X, Y)", point.x - centroid.x, point.y - centroid.y)
//            return Point(x: point.x - centroid.x, y: point.y - centroid.y, strokeId: point.strokeId)
//        }
//        return translatedPoints
//    }
//    
//    static func calculateCentroidQ(points: [Point], n: Int) -> Point {
//        let sum = points.reduce(Point(x: 0, y: 0)) { (acc, p) in
//            return Point(x: acc.x + p.x, y: acc.y + p.y)
//        }
//        return Point(x: sum.x / Double(n), y: sum.y / Double(n))
//    }
    
    static func translateToOrigin(points: [Point], n: Int) -> [Point] {
        return OneDollar.translate(points: points, to: .zero)
    }

    static func resample(points: [Point], size: Int) -> [Point] {
        let interval = points.pathLength() / Double(size - 1)
        var accumulatedLength: Double = 0
        var newPoints = [points[0]]
        var initialPoints = points
        var i = 1

        while let currentPoint = initialPoints[safe: i] {
            if newPoints.count == size {
                break
            }

            let previousPoint = initialPoints[i - 1]
            if previousPoint.strokeId == currentPoint.strokeId {
                let delta = previousPoint.distanceTo(point: currentPoint)
                if delta + accumulatedLength >= interval {
                    let interpolationFactor = (interval - accumulatedLength) / delta
                    let qx = previousPoint.x + interpolationFactor * (currentPoint.x - previousPoint.x)
                    let qy = previousPoint.y + interpolationFactor * (currentPoint.y - previousPoint.y)
                    let interpolatedPoint = Point(x: qx, y: qy, strokeId: currentPoint.strokeId)
                    newPoints.append(interpolatedPoint)
                    initialPoints.insert(interpolatedPoint, at: i)
                    accumulatedLength = 0.0
                } else {
                    accumulatedLength += delta
                }
            }
            i += 1
        }

        if newPoints.count == size - 1 {
            newPoints.append(points.last!)
        }

        return newPoints
    }
    
    static func scaleQ(points: [Point], m: Int) -> [Point] {
        var xmin = Double.infinity
        var xmax = -Double.infinity
        var ymin = Double.infinity
        var ymax = -Double.infinity
        
        // Step 2: Find the minimum and maximum x and y values
        for p in points {
            xmin = min(xmin, p.x)
            ymin = min(ymin, p.y)
            xmax = max(xmax, p.x)
            ymax = max(ymax, p.y)
        }

        // Step 3: Calculate the scale factor
        let s = max(xmax - xmin, ymax - ymin) / Double(m - 1)

        // Step 4: Scale each point to fit within the range 0 to m-1
        let scaledPoints = points.map { p -> Point in
            let scaledX = (p.x - xmin) / s
            let scaledY = (p.y - ymin) / s
            return Point(x: scaledX, y: scaledY, strokeId: p.strokeId)
        }
        return scaledPoints
        
    }

    static func scale(points: [Point], m: Int) -> [Point] {
        let (minimum, maximum) = points.boundingRect()
        let scaleFactor = max(maximum.x - minimum.x, maximum.y - minimum.y) / Double(m - 1)
        let result = points.map { Point(x: $0.x - minimum.x, y: $0.y - minimum.y, strokeId: $0.strokeId) / scaleFactor }
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
