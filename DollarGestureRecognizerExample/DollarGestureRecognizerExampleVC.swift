//
//  ViewController.swift
//  DollarGestureRecognizerExample
//
//  Created by Daniel Cardona Rojas on 8/6/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

import UIKit
import DollarGestureRecognizer

class DollarGestureRecognizerExampleVC: UIViewController {

    lazy var algorithSelectorButton: UISegmentedControl = {
        let control = UISegmentedControl(items: ["$1", "$Q"])
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(didChangeAlgorithmSelection(sender:)), for: .valueChanged)
        control.selectedSegmentIndex = 0
        return control
    }()

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

    lazy var gestureView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var catalogImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = #imageLiteral(resourceName: "dollar_1_figures")
        return imageView
    }()

    lazy var d1GestureRecognizer: OneDollarGestureRecognizer = {
        let d1 = OneDollarGestureRecognizer(target: self, action: #selector(didRecognizeD1Gesture(_:)), templates: [])
        return d1
    }()

    lazy var dQGestureRecognizer: DollarQGestureRecognizer = {
        let dQ = DollarQGestureRecognizer(target: self, action: #selector(didRecognizeDQGesture(_:)), templates: [])
        return dQ
    }()

    init() {
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
        }
    }

    @objc func didRecognizeDQGesture(_ sender: DollarQGestureRecognizer) {
        if sender.state == .ended {
            if let (template, score, name) = sender.matchResult {
                let roundedScore = Double(round(score * 100)) / 100
                recognitionResultLabel.text = "Score: \(roundedScore) idx: \(template) name: \(name ?? "Not found")"
            }
            recognitionResultLabel.text = "No match"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        let fileNames = SingleStrokePath.DefaultTemplate.allCases.map { $0.rawValue }
        SingleStrokeParser.loadStrokePatterns(files: fileNames, completion: { paths in
            self.d1GestureRecognizer.setTemplates(paths)
        })

        let multiStrokeFileNames = MultiStrokePath.DefaultTemplate.allCases.map { $0.rawValue }
        MultiStrokeParser.loadStrokePatterns(files: multiStrokeFileNames, completion: { strokes in
            self.dQGestureRecognizer.setTemplates(strokes)
        })

        updateToAlgorithm(0)
    }

    private func setupViews() {
        view.addSubview(gestureView)
        view.addSubview(recognitionResultLabel)
        view.addSubview(titleLabel)
        view.addSubview(catalogImageView)
        view.addSubview(algorithSelectorButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            algorithSelectorButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            algorithSelectorButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gestureView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            gestureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gestureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gestureView.bottomAnchor.constraint(equalTo: catalogImageView.topAnchor),
            catalogImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            catalogImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            catalogImageView.heightAnchor.constraint(equalToConstant: 200),
            catalogImageView.widthAnchor.constraint(equalTo: catalogImageView.heightAnchor),
            recognitionResultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recognitionResultLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])

    }

    @objc func didChangeAlgorithmSelection(sender: UISegmentedControl) {
        let value = sender.selectedSegmentIndex
        updateToAlgorithm(value)
    }

    func updateToAlgorithm(_ value: Int) {
        if value == 0 {
            titleLabel.text = "$1 Recognizer"
            catalogImageView.image = UIImage(named: "dollar_1_figures")
            gestureView.addGestureRecognizer(d1GestureRecognizer)
            gestureView.removeGestureRecognizer(dQGestureRecognizer)
        } else if value == 1 {
            titleLabel.text = "$Q Recognizer"
            catalogImageView.image = UIImage(named: "dollar_Q_multistrokes")
            gestureView.addGestureRecognizer(dQGestureRecognizer)
            gestureView.removeGestureRecognizer(d1GestureRecognizer)
        }
    }
}
