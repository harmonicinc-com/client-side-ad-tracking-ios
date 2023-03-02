//
//  AssetPlaybackView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 19/1/2023.
//

import SwiftUI
import AVFoundation
import HarmonicClientSideAdTracking
import os

struct AssetPlaybackView: View {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AssetPlaybackView.self)
    )
    
    let asset: AssetItem
    
    @EnvironmentObject
    private var assetProvider: AssetProvider
    
    @StateObject
    private var adTracker = HarmonicAdTracker()
    
    @StateObject
    private var playerVM = PlayerViewModel()
    
    @State
    private var showError = false
    
    @State
    private var errorMessage = ""
    
    @State
    private var presentEditScreen = false
    
#if os(tvOS)
    @State
    private var showDeleteAlert = false
    
    @FocusState
    private var playerControlIsFocused: Bool
#endif
    
    @Environment(\.dismiss)
    private var dismiss
    
    var body: some View {
        Group {
#if os(iOS)
            VStack {
                PlayerView()
                VStack {
                    ToggleView()
                    SessionView()
                    DetailedDebugInfoView()
                    AdPodListView()
                }
                .padding()
                Spacer()
            }
#else
            NavigationView {
                HStack {
                    VStack {
                        PlayerView()
                        PlayerControlView()
                            .focused($playerControlIsFocused)
                        ScrollView {
                            ToggleView()
                            SessionView()
                        }
                        Spacer()
                    }
                    .frame(width: 640)
                    .focusSection()
                    AdPodListView()
                        .focusSection()
                }
                .padding()
            }
            .onChange(of: playerControlIsFocused) { newValue in
                playerVM.setPlayerControlIsFocused(newValue)
            }
#endif
        }
        .environmentObject(adTracker)
        .environmentObject(playerVM)
        .toolbar(content: {
#if os(tvOS)
            Button("Delete") {
                showDeleteAlert = true
            }
#endif
            Button("Edit") {
                presentEditScreen = true
            }
            Button("Load") {
                Task {
                    await adTracker.setMediaUrl(asset.urlString)
                }
            }
        })
        .navigationTitle(asset.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .sheet(isPresented: $presentEditScreen) {
            AssetDetailView(asset: asset, isNewItem: false)
        }
        .alert(errorMessage, isPresented: $showError) {
            Button("OK", role: .cancel) {}
        }
#if os(tvOS)
        .alert("Confirm to delete this asset?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                assetProvider.deleteAsset(asset)
                dismiss()
            }
        }
        .onAppear {
            Task {
                await adTracker.setMediaUrl(asset.urlString)
            }
        }
#endif
        .onDisappear {
            Task {
                await adTracker.stop()
            }
        }
        .onReceive(asset.$urlString) { url in
            Task {
                await adTracker.setMediaUrl(asset.urlString)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AssetPlaybackView(asset: AssetItem())
            .environmentObject(AssetProvider())
    }
}
