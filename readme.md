# Dollar Recognizers 

[![Build Status](https://travis-ci.org/DanielCardonaRojas/DollarGestureRecognizer.svg?branch=develop)](https://travis-ci.org/DanielCardonaRojas/DollarGestureRecognizer) ![License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)


Implements the family of popular dollar recognizers in swift and expose them as a set of custom UIGestureRecognizer
subclasses.

For a detailed discription on how all this works refer to the [papers](http://depts.washington.edu/acelab/proj/dollar/index.html)

For example usage refer to DollarGestureRecognizerExampleVC.swift.


## Features

- Load templates from bezier paths.
- UIGestureRecognizer subclasses for single and multiple stroke patterns.
- XML parsers for loading templates.
- Comes with standard templates loaded in the bundle

## Installation

**Cocoa pods**
```sh
# Add this to your Podfile
pod 'DollarGestureRecognizer', :git => 'https://github.com/DanielCardonaRojas/DollarGestureRecognizer', :branch => 'develop',  :tag => 'v1.0.1'
```

## Dollar family algorithms

- [x] $1 recognizer with protractor optimization
- [x] $Q recognizer
- [ ] $P recognizer
- [ ] $N recognizer

## Screenshots

![](dollar_q_screenshot.png)

## TODO

- [ ] Record templates
- [ ] Use automatic mechanisms for gesture completion on multiple stroke detection (idle timeout, or stroke count)
