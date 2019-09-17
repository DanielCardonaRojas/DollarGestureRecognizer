//
//  OneDollarGestureRecognizer.swift
//  OneDollarGestureRecognizer
//
//  Created by Daniel Esteban Cardona Rojas on 12/18/17.
//  Copyright © 2017 Daniel Cardona. All rights reserved.
//

import UIKit

public class OneDollarGestureRecognizer: UIGestureRecognizer {
    private var samples: [CGPoint] = []
    var trackedTouch: UITouch? // Reference to the touch being tracked
    private var d1: OneDollar
    private var result: (Int, Double)? //Template index, score, exceed threshold?

    /**
     Returns a 3 element tuple where the
         first element is the matched template index,
         second element is the score [0, 1]
         third element mostly informative if exceeded the desired threshold.
     */
    public var matchResult: (templateIndex: Int, score: Double, templateName: String?) {
        guard let r = result, self.state == .ended else {
            return (-1, 0.0, nil)
        }
        let template = d1.dollarTemplates[r.0]
        return (r.0, r.1, template.name)
    }

    public init(target: Any?, action: Selector?, templates: [SingleStrokePath]) {
        self.d1 = OneDollar(templates: templates)
        super.init(target: target, action: action)
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if touches.count != 1 {
            state = .failed
        }
        
        // Capture the first touch and store some information about it.
        if self.trackedTouch == nil {
            if let firstTouch = touches.first {
                self.trackedTouch = firstTouch
                self.addSample(for: firstTouch)
                state = .began
            }
        } else {
            // Ignore all but the first touch.
            for touch in touches {
                if touch != self.trackedTouch {
                    self.ignore(touch, for: event)
                }
            }
        }
        state = .began
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
        processTouches()
        samples.removeAll()
    }
    
    public func setTemplates(_ templates: [SingleStrokePath]) {
        self.d1.dollarTemplates = templates
    }

    override public func reset() {
        samples.removeAll()
        self.trackedTouch = nil
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        self.addSample(for: touches.first!)
        processTouches()
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .failed { return }
        addSample(for: touches.first!)
        state = .changed
    }
    
    // MARK: Processing
    private func processTouches() {
        let candidate = SingleStrokePath(path: samples.toPoints())
        do {
            result = try d1.recognize(candidate: candidate)
            guard let _ = result else {
                print("Returned nil")
                state = .failed
                return
            }
            //Up to client code to determine if this should pass or not
            state = .ended
        } catch DollarError.EmptyTemplates {
            state = .failed
            print("Supply non empty paths to instance")
        } catch DollarError.TooFewPoints {
            state = .failed
            print("Needs better configuration to sample")
        } catch let error {
            print("Error: \(error)")
            state = .failed
        }
    }
    
    private func addSample(for touch: UITouch) {
        let newSample = touch.location(in: self.view)
        samples.append(newSample)
    }
}
