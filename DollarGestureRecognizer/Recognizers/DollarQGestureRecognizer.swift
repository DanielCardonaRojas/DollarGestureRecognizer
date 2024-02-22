//
//  DollarQGestureRecognizer.swift
//  DollarGestureRecognizer
//
//  Created by Daniel Cardona Rojas on 9/12/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

import UIKit

public class DollarQGestureRecognizer: UIGestureRecognizer {
    public var samples: [Point] = []
    private var dq: DollarQ
    private var currentTouchCount: Int = 0
    private var milliStep: Double = 50
    private var result: (template: Template, templateIndex: Int, score: Double)? //Template index, score, exceed threshold?
    private(set) var idleTimeThreshold: TimeInterval

    private var idleTime: TimeInterval = 0 {
        didSet {
            if idleTime >= idleTimeThreshold {
                if samples.count > 20 {
                    processTouches()
                }
                clear()
            }
        }
    }

    private lazy var timer: Timer = {
        return self.createTimer()
    }()

    private func createTimer() -> Timer {
        let timer = Timer.scheduledTimer(withTimeInterval: milliStep / 1000, repeats: true, block: { timer in
            self.idleTime += self.milliStep
            print(self.idleTime)
        })
//        let timer = Timer(timeInterval: 1.0 / 1000, target: self, selector: #selector(updateTimer(_:)), userInfo: nil, repeats: true)
        return timer
    }

    public var matchResult: (templateIndex: Int, score: Double, templateName: String?)? {
        guard let r = result, self.state == .ended else {
            return nil
        }
        let name = dq.templates[r.templateIndex].name
        return (r.templateIndex, r.score, name)
    }

    /**
     Returns a 3 element tuple where the
     first element is the matched template index,
     second element is the score [0, 1]
     third element mostly informative if exceeded the desired threshold.
     */
    public init(target: Any?, action: Selector?, templates: [MultiStrokePath], idleTimeThreshold: TimeInterval = 1500) {
        self.idleTimeThreshold = idleTimeThreshold
        self.dq = DollarQ(templates: templates)
        super.init(target: target, action: action)
    }

    @objc private func updateTimer(_ sender: Timer) {
        idleTime += 1
        print(idleTime)
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
//        print("touchesBegan")
        currentTouchCount += 1
        idleTime = 0
        if timer.isValid {
            timer.invalidate()
        }
        if touches.count != 1 {
            state = .failed
        }

        // Capture the first touch and store some information about it.
        if let firstTouch = touches.first {
            self.addSample(for: firstTouch)
        }
        state = .began
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
        clear()
    }

    public func setTemplates(_ templates: [MultiStrokePath]) {
        self.dq.templates = templates
    }

    override public func reset() {
        clear()
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        self.addSample(for: touches.first!)
//        restartTimer()
//        print("touchesEnded")
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .failed { return }
        addSample(for: touches.first!)
        state = .changed
    }

    // MARK: Processing
    public func processTouches() {
        let candidate = MultiStrokePath(points: samples)
        
        do {
            result = try dq.recognize(points: candidate)
            print(result!.templateIndex, result!.score)
            guard let _ = result else {
                print("Returned nil")
                state = .failed
                return
            }
            //Up to client code to determine if this should pass or not
            state = .ended
        } catch DollarError.EmptyTemplates {
            state = .failed
        } catch DollarError.TooFewPoints {
            state = .failed
        } catch let error {
            print("Error: \(error)")
            state = .failed
        }
    }

    private func addSample(for touch: UITouch) {
        let newSample = touch.location(in: self.view)
        let point = Point(point: newSample, strokeId: currentTouchCount)
        samples.append(point)
    }

    public func clear() {
        idleTime = 0
        currentTouchCount = 0
        samples.removeAll()
        if timer.isValid {
            timer.invalidate()
        }
    }

    private func restartTimer() {
        timer.invalidate()
        timer = createTimer()
    }
}
