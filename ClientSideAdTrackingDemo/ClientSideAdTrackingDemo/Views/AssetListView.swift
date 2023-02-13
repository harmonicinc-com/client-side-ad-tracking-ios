//
//  AssetListView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 31/1/2023.
//

import SwiftUI

struct AssetListView: View {
    @ObservedObject
    private var assetProvider = AssetProvider()
    
    @State
    private var presentAddScreen = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(assetProvider.assets) { asset in
                    NavigationLink(destination: AssetPlaybackView(asset: asset)) {
                        Text(asset.name)
                    }
#if os(iOS)
                    .swipeActions {
                        Button("Delete") {
                            assetProvider.deleteAsset(asset)
                        }
                        .tint(.red)
                    }
#endif
                }
            }
            .navigationTitle("Assets")
            .toolbar {
                Button {
                    presentAddScreen = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $presentAddScreen) {
            AssetDetailView(asset: AssetItem(), isNewItem: true)
        }
        .environmentObject(assetProvider)
    }
}

struct AssetList_Previews: PreviewProvider {
    static var previews: some View {
        AssetListView()
    }
}
