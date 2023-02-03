//
//  AssetItem.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 31/1/2023.
//

import Foundation

class AssetItem: ObservableObject, Codable, Identifiable {
    static func == (lhs: AssetItem, rhs: AssetItem) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    var id = UUID()
    
    @Published
    var name: String = ""
    
    @Published
    var urlString: String = ""
    
    enum CodingKeys: CodingKey {
        case id, name, urlString
    }
    
    init() {}
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(urlString, forKey: .urlString)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.urlString = try container.decode(String.self, forKey: .urlString)
    }
}
