# Dollar Recognizers 

[![Build Status](https://travis-ci.org/DanielCardonaRojas/DollarGestureRecognizer.svg?branch=develop)](https://travis-ci.org/DanielCardonaRojas/DollarGestureRecognizer) ![License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)

Welcome to the DollarGestureRecognizer project! This project is organized into several key directories, each with a specific purpose. Here's a brief overview to help you navigate:

## Directories
### DollarGestureRecognizer/Resources
This directory contains XML data related to drawing. It's where we store the data that our application uses to recognize and process gestures.

### DollarGestureRecognizer/Core
This is the heart of the project. It contains the implementation for key features such as XML parsing and recognizer calculation, based on the research paper. It also holds data related to drawing and gestures, such as points and strokes.

### DollarGestureRecognizerExample/
This directory contains the main View Controller (DollarGestureRecognizerExampleVC.swift) and the drawing canvas UI (CanvasView.swift).

### DollarGestureRecognizerExample/DollarGestureRecognizerExampleVC.swift
This is the main View Controller for the application. It's responsible for managing the interactions between the user interface and underlying data.

### DollarGestureRecognizerExample/CanvasView.swift
This is the drawing canvas UI. It's where the user's gestures are captured and displayed.

## Getting Started
To get started with this project, you'll want to first familiarize yourself with the code in the DollarGestureRecognizer/Core directory, as it contains the core functionality. From there, take a look at the DollarGestureRecognizerExampleVC.swift and CanvasView.swift files to understand how the user interface works.

## Running the Project
On a mac device with XCode, open up *DollarGestureRecognizer.xcworkspace* (NOTE: *DollarGestureRecognizer.xcodeproj* may not work). You may need to change your "Team" under "Signing & Capabilities" before you start. There are 2 Schemes you can build and run, DollarGestureRecognizer or DollarGestureRecognizerExample, the DollarGestureRecognizerExample is the drawing app.

Happy coding!
