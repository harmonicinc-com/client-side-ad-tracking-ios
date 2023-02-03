//
//  AssetDetailView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 31/1/2023.
//

import SwiftUI

struct AssetDetailView: View {
    @State
    var asset: AssetItem
    
    @Binding
    var presentedAsModal: Bool
    
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
                        presentedAsModal = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Confirm") {
                        assetProvider.saveAsset(asset)
                        presentedAsModal = false
                    }
                    .disabled(asset.name.isEmpty || asset.urlString.isEmpty)
                }
            }
        }
    }
}

struct AssetDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AssetDetailView(asset: AssetItem(), presentedAsModal: .constant(false))
            .environmentObject(AssetProvider())
    }
}
