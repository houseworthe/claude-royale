#!/usr/bin/env swift
// ocr.swift - Extract text from image using Apple Vision framework
// Usage: swift ocr.swift <image_path>

import Foundation
import Vision
import AppKit

guard CommandLine.arguments.count > 1 else {
    fputs("Usage: swift ocr.swift <image_path>\n", stderr)
    exit(1)
}

let imagePath = CommandLine.arguments[1]
guard let image = NSImage(contentsOfFile: imagePath),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fputs("ERROR: Could not load image: \(imagePath)\n", stderr)
    exit(1)
}

let request = VNRecognizeTextRequest { request, error in
    guard let observations = request.results as? [VNRecognizedTextObservation] else {
        fputs("ERROR: No text found\n", stderr)
        return
    }

    for observation in observations {
        if let topCandidate = observation.topCandidates(1).first {
            print(topCandidate.string)
        }
    }
}

request.recognitionLevel = .accurate
request.usesLanguageCorrection = true

let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
do {
    try handler.perform([request])
} catch {
    fputs("ERROR: \(error.localizedDescription)\n", stderr)
    exit(1)
}
