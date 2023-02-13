//
//  AssetDetailView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 31/1/2023.
//

import SwiftUI

struct AssetDetailView: View {
    @ObservedObject
    var asset: AssetItem
    
    let isNewItem: Bool
    
    @Environment(\.dismiss)
    private var dismiss
    
    @EnvironmentObject
    var assetProvider: AssetProvider
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $asset.name)
                TextField("URL", text: $asset.urlString)
                    .keyboardType(.URL)
                    .autocorrectionDisabled(true)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isNewItem {
                        Button("Confirm") {
                            assetProvider.saveAsset(asset)
                            dismiss()
                        }
                        .disabled(asset.name.isEmpty || asset.urlString.isEmpty)
                    } else {
                        Button("Update") {
                            assetProvider.editAsset(asset)
                            dismiss()
                        }
                        .disabled(asset.name.isEmpty || asset.urlString.isEmpty)
                    }
                }
            }
        }
    }
}

struct AssetDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AssetDetailView(asset: AssetItem(), isNewItem: false)
            .environmentObject(AssetProvider())
    }
}
