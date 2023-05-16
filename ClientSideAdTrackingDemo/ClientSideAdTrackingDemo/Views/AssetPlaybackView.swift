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
    let player = AVPlayer()
    
    @EnvironmentObject private var assetProvider: AssetProvider
    @StateObject private var session = AdBeaconingSession()
    
    @State private var adTracker: HarmonicAdTracker?
    @State private var presentEditScreen = false
    
#if os(tvOS)
    @State private var showDeleteAlert = false
    @FocusState private var playerControlIsFocused: Bool
#else
    @State private var presentLogsScreen = false
#endif
    
    @Environment(\.dismiss)
    private var dismiss
    
    var body: some View {
        Group {
#if os(iOS)
            VStack {
                PlayerView(session: session)
                VStack {
                    ToggleView(session: session)
                    SessionView(session: session, playerObserver: session.playerObserver)
                    DetailedDebugInfoView(session: session)
                    AdPodListView(session: session)
                }
                .padding()
                Spacer()
            }
#else
            NavigationView {
                HStack {
                    VStack {
                        PlayerView(session: session)
                        Group {
                            PlayerControlView(session: session, playerObserver: session.playerObserver)
                            ScrollView {
                                ToggleView(session: session)
                                SessionView(session: session, playerObserver: session.playerObserver)
                            }
                        }
                        .focused($playerControlIsFocused)
                        Spacer()
                    }
                    .frame(width: 640)
                    .focusSection()
                    AdPodListView(session: session)
                        .focusSection()
                }
                .padding()
            }
            .onChange(of: playerControlIsFocused) { newValue in
                session.playerControlIsFocused = newValue
            }
#endif
        }
        .toolbar(content: {
#if os(tvOS)
            Button("Delete") {
                showDeleteAlert = true
            }
#else
            Button("Logs") {
                presentLogsScreen = true
            }
#endif
            Button("Edit") {
                presentEditScreen = true
            }
            Button("Reload") {
                session.player.pause()
                session.mediaUrl = asset.urlString
            }
        })
        .navigationTitle(asset.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $presentLogsScreen) {
            LogsListView(session: session)
        }
#endif
        .sheet(isPresented: $presentEditScreen) {
            AssetDetailView(asset: asset, isNewItem: false)
        }
#if os(tvOS)
        .alert("Confirm to delete this asset?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                assetProvider.deleteAsset(asset)
                dismiss()
            }
        }
#endif
        .onAppear {
            session.player = player
            adTracker = HarmonicAdTracker(session: session)
            adTracker?.start()
        }
        .onDisappear {
            session.player.pause()
            session.player.replaceCurrentItem(with: nil)
            adTracker?.stop()
        }
        .onReceive(asset.$urlString) { url in
            session.mediaUrl = url
        }
        .onReceive(session.sessionInfo.$manifestUrl) { manifestUrl in
            if !manifestUrl.isEmpty {
                guard let url = URL(string: manifestUrl) else {
                    Utility.log("Failed to intiailize URL with manifestUrl: \(manifestUrl)",
                                to: session, level: .warning, with: Self.logger)
                    return
                }
                let playerItem = AVPlayerItem(url: url)
                playerItem.automaticallyPreservesTimeOffsetFromLive = session.automaticallyPreservesTimeOffsetFromLive
                session.player.replaceCurrentItem(with: playerItem)
                session.player.play()
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
