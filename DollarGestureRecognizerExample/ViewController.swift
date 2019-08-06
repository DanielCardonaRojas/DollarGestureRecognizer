//
//  ViewController.swift
//  DollarGestureRecognizerExample
//
//  Created by Daniel Cardona Rojas on 8/6/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

import UIKit
import DollarGestureRecognizer

class ViewController: UIViewController {

    @IBOutlet weak var recognitionResultLabel: UILabel!

    lazy var gestureRecognizer: OneDollarGestureRecognizer = {
        let path = OneDollarPath(path: OneDollarTemplates.Pigtail)
        let templates: [OneDollarPath] = [path]
        let d1 = OneDollarGestureRecognizer(target: self, action: #selector(didRecognizeD1Gesture(_:)), templates: templates )
        return d1
    }()

    @objc func didRecognizeD1Gesture(_ sender: OneDollarGestureRecognizer) {
        let (templateIndex, score, _) = sender.matchResult
        if score > 0.5 {
            recognitionResultLabel.text = templateIndex == 0 ? "Pigtail" : "Unknown"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGestureRecognizers()
    }

    private func setupGestureRecognizers() {
        self.view.addGestureRecognizer(gestureRecognizer)
    }
}
