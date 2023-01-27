//
//  AdBeaconData.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 27/1/2023.
//

import Foundation
import HarmonicClientSideAdTracking

var sampleAdBeacon = loadPreviewData("sample-metadata.json")
    
private func loadPreviewData(_ filename: String) -> AdBeacon? {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil) else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .millisecondsSince1970
    
    do {
        return try decoder.decode(AdBeacon.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(AdBeacon.self):\n\(error)")
    }
}
