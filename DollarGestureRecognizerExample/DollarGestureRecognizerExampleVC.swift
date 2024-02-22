//
//  ViewController.swift
//  DollarGestureRecognizerExample
//
//  Created by Daniel Cardona Rojas on 8/6/19.
//  Copyright © 2019 Daniel Cardona. All rights reserved.
//

import UIKit
import DollarGestureRecognizer

class DollarGestureRecognizerExampleVC: UIViewController, UITextFieldDelegate{

    lazy var algorithSelectorButton: UISegmentedControl = {
        let control = UISegmentedControl(items: ["$1", "$Q"])
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(didChangeAlgorithmSelection(sender:)), for: .valueChanged)
        control.selectedSegmentIndex = 1
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
    
    lazy var saveButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: .normal)
        button.addTarget(self, action: #selector(save(_:)), for: .touchUpInside)
        button.layer.borderColor = UIColor.white.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
        button.layer.borderWidth = 2.0
        button.layer.cornerRadius = 6.0
        return button
    }()
    
    lazy var textfield: UITextField = {
        // Set x, y and width and height to place UITextField.
        let width: CGFloat = 250
        let height: CGFloat = 50
        let posX: CGFloat = (self.view.bounds.width - width)/2
        let posY: CGFloat = (self.view.bounds.height - height)/2
        
        // Create a UITextField.
        let textField = UITextField(frame: CGRect(x: posX, y: posY, width: width, height: height))
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.text = ""
        textField.delegate = self
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        textField.backgroundColor = .white
        textField.textColor = .black
        return textField
    }()

    // Called just before UITextField is edited
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("textFieldDidBeginEditing: \((textField.text) ?? "Empty")")
    }
    
    // Called immediately after UITextField is edited
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("textFieldDidEndEditing: \((textField.text) ?? "Empty")")
    }
    
    // Called when the line feed button is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("textFieldShouldReturn \((textField.text) ?? "Empty")")
        
        // Process of closing the Keyboard when the line feed button is pressed.
        textField.resignFirstResponder()
        
        return true
    }

    @objc func clearCanvas(_ sender: UIButton) {
        gestureView.clear()
        recognitionResultLabel.text = ""
    }

    @objc func recognize(_ sender: UIButton) {
        dQGestureRecognizer.processTouches()
        dQGestureRecognizer.clear()
    }
    
    @objc func save(_ sender: UIButton) {
        if let text = textfield.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // The text field is not empty and not just whitespace
            let writer = MultiStrokeWrite()
            writer.startGesture(name: text, subject: "01", multistroke: MultiStrokePath(points: dQGestureRecognizer.samples))
            print(writer.endDocument())
            writer.saveToDirectory(directory: text, fileName: text)
            let multiStrokeFileNames = MultiStrokePath.DefaultTemplate.allCases.map { $0.rawValue }
            MultiStrokeParser.loadAllStrokePatterns(bundleFiles: multiStrokeFileNames, completion: { strokes in
                print("Loaded multistrokes: \(strokes.compactMap{ $0.name }.joined(separator: " "))")
                self.dQGestureRecognizer.setTemplates(strokes)
            })
            textfield.text = ""
        } else {
            // The text field is empty or contains only whitespace
        }
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
        
        // Loading stroke patterns from MultiStroke Path
        let multiStrokeFileNames = MultiStrokePath.DefaultTemplate.allCases.map { $0.rawValue }
        MultiStrokeParser.loadAllStrokePatterns(bundleFiles: multiStrokeFileNames, completion: { strokes in
            print("Loaded multistrokes: \(strokes.compactMap{ $0.name }.joined(separator: " "))")
            self.dQGestureRecognizer.setTemplates(strokes)
        })

        updateToAlgorithm(1)
    }

    private func setupViews() {
        view.addSubview(gestureView)
        view.addSubview(clearButton)
        view.addSubview(recognizeButton)
        view.addSubview(recognitionResultLabel)
        view.addSubview(titleLabel)
        view.addSubview(textfield)
        view.addSubview(saveButton)
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
            gestureView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            textfield.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -5),
            textfield.heightAnchor.constraint(equalToConstant: 35),
            textfield.widthAnchor.constraint(equalToConstant: 200),
            textfield.leadingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -55),
            saveButton.bottomAnchor.constraint(equalTo: gestureView.bottomAnchor, constant: -10),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
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
//            catalogImageView.image = UIImage(named: "dollar_1_figures")
            gestureView.addGestureRecognizer(d1GestureRecognizer)
            gestureView.removeGestureRecognizer(dQGestureRecognizer)
            saveButton.isHidden = true
            textfield.isHidden = true
        } else if value == 1 {
            titleLabel.text = "$Q Recognizer"
//            catalogImageView.image = UIImage(named: "dollar_Q_multistrokes")
            gestureView.addGestureRecognizer(dQGestureRecognizer)
            gestureView.removeGestureRecognizer(d1GestureRecognizer)
            saveButton.isHidden = false
            textfield.isHidden = false
        }
    }
}
