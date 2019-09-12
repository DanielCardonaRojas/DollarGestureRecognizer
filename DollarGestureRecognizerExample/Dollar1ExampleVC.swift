//
//  ViewController.swift
//  DollarGestureRecognizerExample
//
//  Created by Daniel Cardona Rojas on 8/6/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

import UIKit
import DollarGestureRecognizer

class Dollar1ExampleVC: UIViewController {

    typealias RecognitionHandler = ((OneDollarGestureRecognizer) -> Void)?
    var recognitionHandler: RecognitionHandler

    lazy var recognitionResultLabel: UILabel = {
        let label = UILabel()
        label.accessibilityLabel = "ResultLabel"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "Dollar gesture recognizer"
        label.accessibilityLabel = "TitleLabel"
        return label
    }()

    lazy var catalogImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = #imageLiteral(resourceName: "dollar_1_figures")
        return imageView
    }()

    lazy var gestureRecognizer: OneDollarGestureRecognizer = {
        let d1 = OneDollarGestureRecognizer(target: self, action: #selector(didRecognizeD1Gesture(_:)), templates: [])
        return d1
    }()

    init(recognitionHandler: RecognitionHandler = nil) {
        self.recognitionHandler = recognitionHandler
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .white
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func didRecognizeD1Gesture(_ sender: OneDollarGestureRecognizer) {
        if sender.state == .ended {
            let (_, score, name) = sender.matchResult
            if score > 0.5 {
                let roundedScore = Double(round(score * 100)) / 100
                recognitionResultLabel.text = "Score: \(roundedScore) pattern: \(name ?? "Not found")"
            } else {
                recognitionResultLabel.text = "No match"
            }

            recognitionHandler?(sender)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        setupGestureRecognizers()
        let fileNames = SingleStrokePath.DefaultTemplate.allCases.map { $0.rawValue }
        SingleStrokeParser.loadStrokePatterns(files: fileNames, completion: { paths in
            self.gestureRecognizer.setTemplates(paths)
        })

        let multiStrokeFileNames = MultiStrokePath.DefaultTemplate.allCases.map { $0.rawValue }
        MultiStrokeParser.loadStrokePatterns(files: multiStrokeFileNames, completion: { strokes in
            print(strokes)
        })

        var template = Template()
        template.lut = DollarQ.LookUpTable()
        let LUT = template.lut
    }

    private func setupGestureRecognizers() {
        view.addGestureRecognizer(gestureRecognizer)
    }

    private func setupViews() {
        view.addSubview(recognitionResultLabel)
        view.addSubview(titleLabel)
        view.addSubview(catalogImageView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            catalogImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            catalogImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            catalogImageView.heightAnchor.constraint(equalToConstant: 200),
            catalogImageView.widthAnchor.constraint(equalTo: catalogImageView.heightAnchor),
            recognitionResultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recognitionResultLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])

    }
}
