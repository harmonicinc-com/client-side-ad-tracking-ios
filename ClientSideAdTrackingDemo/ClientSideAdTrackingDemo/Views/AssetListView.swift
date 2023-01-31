//
//  AssetListView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 31/1/2023.
//

import SwiftUI

struct AssetListView: View {
    @StateObject
    private var assetProvider = AssetProvider()
    
    @State
    private var presentDetail = false
    
    var body: some View {
        NavigationView {
            List(assetProvider.assets) { asset in
                NavigationLink(destination: AssetPlaybackView(asset: asset)) {
                    Text(asset.name)
                        .swipeActions {
                            Button("Delete") {
                                assetProvider.deleteAsset(asset)
                            }
                            .tint(.red)
                        }
                }
            }
            .navigationTitle("Assets")
            .toolbar {
                Button {
                    presentDetail = true
                } label: {
                    Image(systemName: "plus")
                }
                .sheet(isPresented: $presentDetail) {
                    AssetDetailView(asset: AssetItem(), presentedAsModal: $presentDetail)
                        .environmentObject(assetProvider)
                }
            }
        }
    }
}

struct AssetList_Previews: PreviewProvider {
    static var previews: some View {
        AssetListView()
    }
}
