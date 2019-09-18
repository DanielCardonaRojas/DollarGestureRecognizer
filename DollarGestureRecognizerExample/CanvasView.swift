//
//  CanvasView.swift
//  DollarGestureRecognizerExample
//
//  Created by Daniel Cardona Rojas on 9/16/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

import UIKit

final class CanvasView: UIView {

    typealias Line = [CGPoint]
    private var currentLine = Line()
    private var lines: [Line] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(7)
        context.setLineCap(.butt)

        lines.forEach { line in
            for (i, p) in line.enumerated() {
                if i == 0 {
                    context.move(to: p)
                } else {
                    context.addLine(to: p)
                }
            }
        }

        context.strokePath()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self), var lastLine = lines.popLast() else {
            return
        }

        lastLine.append(point)
        lines.append(lastLine)
        setNeedsDisplay()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lines.append(Line())
    }

    public func clear() {
        lines.removeAll()
        setNeedsDisplay()
    }
}
