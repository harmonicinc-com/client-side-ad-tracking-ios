//
//  AssetPlaybackView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 19/1/2023.
//

import SwiftUI
import Combine
import AVFoundation
import HarmonicClientSideAdTracking
import os

let AD_TRACING_METADATA_FILE_NAME = "metadata"
let EARLY_FETCH_MS: Double = 5_000
let METADATA_UPDATE_INTERVAL: TimeInterval = 2

struct AssetPlaybackView: View {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: AssetPlaybackView.self)
    )
    
    let asset: AssetItem
    
    @Environment(\.dismiss)
    private var dismiss
    
    @EnvironmentObject
    private var assetProvider: AssetProvider
    
    @StateObject
    private var adTracker = HarmonicAdTracker()
    
    @StateObject
    private var session = Session()
    
    @StateObject
    private var playerVM = PlayerViewModel()
    
    @State
    private var lastDataRange: DataRange?
    
    @State
    private var showError = false
    
    @State
    private var errorMessage = ""
    
    @State
    private var presentEditScreen = false
    
#if os(tvOS)
    @State
    private var showDeleteAlert = false
#endif
    
    @State
    private var refreshMetadataTimer = Timer.publish(every: METADATA_UPDATE_INTERVAL, on: .main, in: .common)
    
    @State
    private var connectedTimer: Cancellable?
    
    private let decoder = JSONDecoder()
    
    var body: some View {
        Group {
#if os(iOS)
            VStack {
                PlayerView()
                VStack {
                    SessionView()
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
                        SessionView()
                        Spacer()
                    }
                    .frame(width: 640)
                    .focusSection()
                    AdPodListView()
                        .focusSection()
                }
                .padding()
            }
#endif
        }
        .environmentObject(adTracker)
        .environmentObject(session)
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
                    await loadMedia(urlString: session.sessionInfo.mediaUrl)
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
#endif
        .onAppear {
#if os(tvOS)
            Task {
                await loadMedia(urlString: session.sessionInfo.mediaUrl)
            }
#endif
            refreshMetadataTimer = Timer.publish(every: METADATA_UPDATE_INTERVAL, on: .main, in: .common)
            connectedTimer = refreshMetadataTimer.connect()
        }
        .onDisappear {
            connectedTimer?.cancel()
        }
        .onReceive(asset.$urlString) { url in
            session.sessionInfo.mediaUrl = url
        }
        .onReceive(refreshMetadataTimer) { _ in
            Task {
                await checkNeedUpdate()
            }
        }
    }
}

extension AssetPlaybackView {
    private func loadMedia(urlString: String) async {
        guard !urlString.isEmpty else { return }
        var manifestUrl, adTrackingMetadataUrl: String
        do {
            guard let (_, httpResponse) = try await makeRequestTo(urlString) else {
                return
            }
            
            if let redirectedUrl = httpResponse.url {
                manifestUrl = redirectedUrl.absoluteString
                adTrackingMetadataUrl = rewriteUrlToMetadataUrl(redirectedUrl.absoluteString)
            } else {
                manifestUrl = urlString
                adTrackingMetadataUrl = rewriteUrlToMetadataUrl(urlString)
            }
            
            session.sessionInfo = SessionInfo(localSessionId: Date().ISO8601Format(),
                                              mediaUrl: urlString,
                                              manifestUrl: manifestUrl,
                                              adTrackingMetadataUrl: adTrackingMetadataUrl)
            
            _ = await refreshMetadata(urlString: adTrackingMetadataUrl, time: nil)
        } catch {
            errorMessage = "Error loading media with URL: \(urlString); Error: \(error)"
            showError = true
            Self.logger.error("\(errorMessage, privacy: .public)")
        }
    }
    
    private func checkNeedUpdate() async {
        var url = session.sessionInfo.adTrackingMetadataUrl
        let lastPlayheadTime = await adTracker.getPlayheadTime()
        Self.logger.trace("Calling refreshMetadata without start; playhead is \(Date(timeIntervalSince1970: lastPlayheadTime/1_000), privacy: .public)")
        let result = await refreshMetadata(urlString: url, time: lastPlayheadTime)
        if let lastDataRange = lastDataRange {
            if !isInRange(time: lastPlayheadTime, range: lastDataRange) && !result {
                url += "&start=\(Int(lastPlayheadTime))"
                Self.logger.trace("Calling refreshMetadata with start: \(Date(timeIntervalSince1970: lastPlayheadTime/1_000), privacy: .public) with url: \(url, privacy: .public)")
                if await !refreshMetadata(urlString: url, time: nil) {
                    Self.logger.warning("refreshMetadata for url with start: \(url, privacy: .public) returned false.")
                }
            }
        }
    }
    
    private func refreshMetadata(urlString: String, time: Double?) async -> Bool {
        guard !urlString.isEmpty else { return false }
        do {
            guard let (data, _) = try await makeRequestTo(urlString) else {
                return false
            }
            
            decoder.dateDecodingStrategy = .millisecondsSince1970
            let adBeacon = try decoder.decode(AdBeacon.self, from: data)
            
            let adPodIDs = adBeacon.adBreaks.map { $0.id ?? "nil" }
            var startDate: Date = .distantPast
            var endDate: Date = .distantPast
            
            if let lastDataRange = adBeacon.dataRange {
                self.lastDataRange = lastDataRange
                startDate = Date(timeIntervalSince1970: (lastDataRange.start ?? 0) / 1_000)
                endDate = Date(timeIntervalSince1970: (lastDataRange.end ?? 0) / 1_000)
                if !isInRange(time: time, range: lastDataRange) {
                    let timeDate = Date(timeIntervalSince1970: (time ?? 0) / 1_000)
                    Self.logger.warning("Invalid metadata (with ad pods: \(adPodIDs, privacy: .public)):  Time (\(timeDate, privacy: .public)) not in range (start: \(startDate, privacy: .public), end: \(endDate, privacy: .public))")
                    return false
                }
            } else {
                Self.logger.warning("No DataRange returned in metadata.")
                return false
            }
            
            Self.logger.trace("Going to update \(adBeacon.adBreaks.count) ad pods: \(adPodIDs, privacy: .public) with DataRange: \(startDate) to \(endDate)")
            await adTracker.updatePods(adBeacon.adBreaks)
            
            return true
        } catch {
            errorMessage = "Error refreshing metadata with URL: \(urlString); Error: \(error)"
            showError = true
            Self.logger.error("\(errorMessage, privacy: .public)")
            return false
        }
    }
    
    private func makeRequestTo(_ urlString: String) async throws -> (Data, HTTPURLResponse)? {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL: \(urlString)"
            showError = true
            Self.logger.error("\(errorMessage, privacy: .public)")
            return nil
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            errorMessage = "Cannot cast URLResponse as HTTPURLResponse for URL: \(urlString)"
            showError = true
            Self.logger.error("\(errorMessage, privacy: .public)")
            return nil
        }
        if !(200...299 ~= httpResponse.statusCode) {
            errorMessage = "Invalid response status: \(httpResponse.statusCode) for URL: \(urlString)"
            showError = true
            Self.logger.error("\(errorMessage, privacy: .public)")
            return nil
        }
        return (data, httpResponse)
    }
    
    private func rewriteUrlToMetadataUrl(_ url: String) -> String {
        return url.replacingOccurrences(of: "\\/[^\\/?]+(\\??[^\\/]*)$",
                                        with: "/\(AD_TRACING_METADATA_FILE_NAME)$1",
                                        options: .regularExpression)
    }
    
    private func isInRange(time: Double?, range: DataRange) -> Bool {
        if let time = time {
            if let start = range.start, let end = range.end {
                return start...(end-EARLY_FETCH_MS) ~= time
            } else {
                return false
            }
        } else {
            return true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AssetPlaybackView(asset: AssetItem())
            .environmentObject(AssetProvider())
    }
}
