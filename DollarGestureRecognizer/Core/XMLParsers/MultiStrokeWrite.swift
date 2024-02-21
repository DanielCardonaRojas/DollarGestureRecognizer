//
//  MultiStrokeWrite.swift
//  DollarGestureRecognizer
//
//  Created by Yunseo Lee on 1/5/24.
//
//
import Foundation

public class MultiStrokeWrite {
    
    private var xmlString: String = ""
    private var strokeCount: Int
    
    let fileManager = FileManager.default
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("XMLData", isDirectory: true)
    
    public init() {
        strokeCount = 0
        startDocument()
        if !FileManager.default.fileExists(atPath: documentsURL.path) {
            do {
                try FileManager.default.createDirectory(atPath: documentsURL.path, withIntermediateDirectories: true)
            }
            catch {
                print("Error creating XMLData directory: " + error.localizedDescription)
            }
        }
    }
    
    // Starts a new document
    public func startDocument() {
        xmlString = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>\n"
    }
    
    // Starts a new element with optional attributes
    public func startGesture(name: String, subject: String, inputType: UITouch.TouchType = .direct, multistroke: MultiStrokePath) {
        var touchStyle: String
        switch inputType {
        case .stylus:
            touchStyle = "stylus"
        case .direct:
            touchStyle = "finger"
        default:
            touchStyle = "finger"
        }
        let count = multistroke.strokes.reduce(0) {$0 + $1.count}
        
        // ex. <Gesture Name="image~01" Subject="73" InputType="finger" Speed="MEDIUM" NumPts="102">
        xmlString += "<Gesture Name=\"\(name)\" Subject=\"\(subject)\" InputType=\"\(touchStyle)\" Speed=\"MEDIUM\" NumPts=\"\(count)\">\n"
        
        write(multiStrokePath: multistroke)
    }
    // Ends the document and returns the final XML string
    public func endDocument() -> String {
        return xmlString
    }
    
    // Function to write MultiStrokePath to XML
    private func write(multiStrokePath: MultiStrokePath) {
        for stroke in multiStrokePath.strokes {
            strokeCount += 1
            xmlString += "\t<Stroke index=\"\(strokeCount)\">\n"
            for point in stroke {
                xmlString += "\t\t<Point X=\"\(String(describing: Int(exactly: point.x.rounded())!))\" Y=\"\(String(describing: Int(exactly: point.y.rounded())!))\" T=\"\(point.time ?? 0 )\" Pressure=\"\(point.pressure ?? 128)\"/>\n"
            }
            xmlString += "\t</Stroke>\n"
        }
        
        xmlString += "</Gesture>"
    }
    
    // Save the XML to a file
    private func save(directory: URL) {
        if let data = xmlString.data(using: .utf8) {
            let success = fileManager.createFile(atPath: directory.path, contents: data)
            if success {
                print("File created and data written successfully to: " + directory.path)
            } else {
                print("Failed to create file.")
            }
        } else {
            print("Failed to convert string to data.")
        }
    }
    
    private func generateUniqueName(directory: URL, baseFileName: String) -> String{
        let directoryContents: [URL]
        do {
            directoryContents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        } catch {
            print("Error reading directory contents: \(error)")
            return baseFileName
        }
        
        var uniqueFileName = baseFileName
        var counter = 0
        var fileExists = false
        repeat {
            fileExists = directoryContents.contains { $0.lastPathComponent == "\(uniqueFileName).xml" }
            if fileExists {
                counter += 1
                print("\(uniqueFileName) already exists, trying to save as \(baseFileName)\(counter)")
                uniqueFileName = "\(baseFileName)\(counter)"
            }
        } while fileExists
        return uniqueFileName + ".xml"
    }
    
    public func saveToDirectory(directory: String, fileName: String) {
        let directory = directory.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let fileName = fileName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let dir_path = documentsURL.appendingPathComponent(directory, isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: dir_path.path) {
            do {
                try FileManager.default.createDirectory(atPath: dir_path.path, withIntermediateDirectories: true)
            }
            catch {
                print("Error creating XMLData directory: " + error.localizedDescription)
            }
        } else {
            print("Found path to \(directory)")
        }
        
        let newFileName = generateUniqueName(directory: dir_path, baseFileName: fileName)
        let file_path = dir_path.appendingPathComponent(newFileName)
        save(directory: file_path)
    }
}

// Usage:
// let writer = XMLWriter()
// writer.write(multiStrokePath: yourMultiStrokePathObject)
// try? writer.save(to: URL(fileURLWithPath: "path/to/your/file.xml"))
