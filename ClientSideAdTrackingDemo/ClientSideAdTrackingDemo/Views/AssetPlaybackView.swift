//
//  AssetPlaybackView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 19/1/2023.
//

import SwiftUI
import AVFoundation
import HarmonicClientSideAdTracking

let AD_TRACING_METADATA_FILE_NAME = "metadata"
let EARLY_FETCH_MS: Double = 5_000
let METADATA_UPDATE_INTERVAL: TimeInterval = 4

struct AssetPlaybackView: View {
    let asset: AssetItem
    
    @StateObject
    private var adTracker = HarmonicAdTracker()
    
    @StateObject
    private var session = Session()
    
    @State
    private var lastDataRange: DataRange?
    
    @State
    private var showError = false
    
    @State
    private var errorMessage = ""
    
    private let player = AVPlayer()
    
    private let decoder = JSONDecoder()
    
    private let refreshMetadataTimer = Timer.publish(every: METADATA_UPDATE_INTERVAL, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            PlayerView(player: player)
            VStack {
                SessionView(playerObserver: PlayerObserver(player: player))
                AdPodListView()
            }
            .padding()
            Spacer()
        }
        .toolbar(content: {
            Button("Load") {
                Task {
                    await loadMedia(urlString: session.sessionInfo.mediaUrl)
                }
            }
        })
        .navigationTitle(asset.name)
        .navigationBarTitleDisplayMode(.inline)
        .environmentObject(adTracker)
        .environmentObject(session)
        .onAppear {
            session.sessionInfo.mediaUrl = asset.urlString
        }
        .onReceive(refreshMetadataTimer) { _ in
            Task {
                await checkNeedUpdate()
            }
        }
        .alert(errorMessage, isPresented: $showError) {
            Button("OK", role: .cancel) {}
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
            errorMessage = "Error loading media: \(error)"
            showError = true
        }
    }
    
    private func checkNeedUpdate() async {
        var url = session.sessionInfo.adTrackingMetadataUrl
        let lastPlayheadTime = adTracker.getPlayheadTime()
        let result = await refreshMetadata(urlString: url, time: lastPlayheadTime)
        if let lastDataRange = lastDataRange {
            if !isInRange(time: lastPlayheadTime, range: lastDataRange) && !result {
                url += "&start=\(Int(lastPlayheadTime))"
                _ = await refreshMetadata(urlString: url, time: nil)
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
            if let lastDataRange = adBeacon.dataRange {
                self.lastDataRange = lastDataRange
                if !isInRange(time: time, range: lastDataRange) {
                    print("Invalid metadata: Not in range. Time: \(String(describing: time))")
                    return false
                }
            }
            adTracker.updatePods(adBeacon.adBreaks)
            
            return true
        } catch {
            errorMessage = "Error refreshing metadata: \(error)"
            showError = true
            return false
        }
    }
    
    private func makeRequestTo(_ urlString: String) async throws -> (Data, HTTPURLResponse)? {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL: \(urlString)"
            showError = true
            return nil
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            errorMessage = "Cannot cast URLResponse as HTTPURLResponse"
            showError = true
            return nil
        }
        if !(200...299 ~= httpResponse.statusCode) {
            errorMessage = "Invalid response status: \(httpResponse.statusCode)"
            showError = true
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
        if let time = time, let start = range.start, let end = range.end {
            return start...end-EARLY_FETCH_MS ~= time
        } else {
            return true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AssetPlaybackView(asset: AssetItem())
    }
}