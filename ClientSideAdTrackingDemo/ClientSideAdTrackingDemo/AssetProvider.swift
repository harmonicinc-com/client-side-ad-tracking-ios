//
//  AssetProvider.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 31/1/2023.
//

import Foundation
import os

let USERDEFAULTS_ASSETS_KEY = "assets"

class AssetProvider: ObservableObject {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AssetProvider.self)
    )
    
    @Published
    var assets: [AssetItem] = []
    
    init() {
        loadAssetsFromUserDefaults()
    }
    
    func saveAsset(_ asset: AssetItem) {
        assets.append(asset)
        saveAssetsToUserDefaults()
    }
    
    func deleteAsset(_ asset: AssetItem) {
        assets.removeAll(where: { $0.id == asset.id })
        saveAssetsToUserDefaults()
    }
    
    private func loadAssetsFromUserDefaults() {
        if let data = UserDefaults.standard.object(forKey: USERDEFAULTS_ASSETS_KEY) as? Data {
            do {
                assets = try JSONDecoder().decode([AssetItem].self, from: data)
            } catch {
                Self.logger.error("Failed to decode assets: \(error, privacy: .public)")
            }
        }
    }
    
    private func saveAssetsToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(assets)
            UserDefaults.standard.set(data, forKey: USERDEFAULTS_ASSETS_KEY)
        } catch {
            Self.logger.error("Failed to encode assets: \(error, privacy: .public)")
        }
    }
    
}
