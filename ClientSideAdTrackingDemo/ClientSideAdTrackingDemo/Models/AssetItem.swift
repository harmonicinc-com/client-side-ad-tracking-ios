//
//  AssetItem.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 31/1/2023.
//

import Foundation

struct AssetItem: Hashable, Codable, Identifiable {
    var id = UUID()
    var name: String = ""
    var urlString: String = ""
}
