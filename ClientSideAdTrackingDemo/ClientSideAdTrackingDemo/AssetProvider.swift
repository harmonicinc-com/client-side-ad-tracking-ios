//
//  AssetProvider.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 31/1/2023.
//

import Foundation

let USERDEFAULTS_ASSETS_KEY = "assets"

class AssetProvider: ObservableObject {
    
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
                print("Failed to decode assets: \(error)")
            }
        }
    }
    
    private func saveAssetsToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(assets)
            UserDefaults.standard.set(data, forKey: USERDEFAULTS_ASSETS_KEY)
        } catch {
            print("Failed to encode assets: \(error)")
        }
    }
    
}
