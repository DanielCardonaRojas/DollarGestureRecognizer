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

    lazy var clearButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Clear", for: .normal)
        button.addTarget(self, action: #selector(clearCanvas(_:)), for: .touchUpInside)
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 2.0
        button.layer.cornerRadius = 6.0
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        return button
    }()

    lazy var recognizeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Recognize", for: .normal)
        button.addTarget(self, action: #selector(recognize(_:)), for: .touchUpInside)
        button.layer.borderColor = UIColor.white.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        button.layer.borderWidth = 2.0
        button.layer.cornerRadius = 6.0
        return button
    }()

    @objc func clearCanvas(_ sender: UIButton) {
        gestureView.clear()
        recognitionResultLabel.text = ""
    }

    @objc func recognize(_ sender: UIButton) {
        dQGestureRecognizer.processTouches()
        dQGestureRecognizer.clear()
    }

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "Dollar gesture recognizer"
        label.accessibilityLabel = "TitleLabel"
        return label
    }()

    lazy var gestureView: CanvasView = {
        let view = CanvasView()
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
        d1.cancelsTouchesInView = false
        return d1
    }()

    lazy var dQGestureRecognizer: DollarQGestureRecognizer = {
        let dQ = DollarQGestureRecognizer(target: self, action: #selector(didRecognizeDQGesture(_:)), templates: [])
        dQ.cancelsTouchesInView = false
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.gestureView.clear()
                }
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
            } else {
                recognitionResultLabel.text = "No match"
            }
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
            print("Loaded multistrokes: \(strokes.compactMap{ $0.name }.joined(separator: " "))")
            self.dQGestureRecognizer.setTemplates(strokes)
        })

        updateToAlgorithm(0)
    }

    private func setupViews() {
        view.addSubview(gestureView)
        view.addSubview(clearButton)
        view.addSubview(recognizeButton)
        view.addSubview(recognitionResultLabel)
        view.addSubview(titleLabel)
        view.addSubview(catalogImageView)
        view.addSubview(algorithSelectorButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            algorithSelectorButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            algorithSelectorButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gestureView.topAnchor.constraint(equalTo: algorithSelectorButton.bottomAnchor, constant: 10),
            gestureView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gestureView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gestureView.bottomAnchor.constraint(equalTo: catalogImageView.topAnchor),
            catalogImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            catalogImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            catalogImageView.heightAnchor.constraint(equalToConstant: 200),
            catalogImageView.widthAnchor.constraint(equalTo: catalogImageView.heightAnchor),
            recognitionResultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recognitionResultLabel.topAnchor.constraint(equalTo: gestureView.topAnchor, constant: 8),
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            clearButton.bottomAnchor.constraint(equalTo: gestureView.bottomAnchor, constant: -10),
            recognizeButton.trailingAnchor.constraint(equalTo: gestureView.trailingAnchor, constant: -10),
            recognizeButton.bottomAnchor.constraint(equalTo: gestureView.bottomAnchor, constant: -10)
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
