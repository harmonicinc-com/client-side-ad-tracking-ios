//
//  ContentView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 19/1/2023.
//

import SwiftUI
import HarmonicClientSideAdTracking

let AD_TRACING_METADATA_FILE_NAME = "metadata"
let EARLY_FETCH_MS: Double = 5000
let METADATA_UPDATE_INTERVAL: TimeInterval = 4

struct ContentView: View {
    @StateObject
    private var adTracker = HarmonicAdTracker()
    
    @StateObject
    private var session = Session()
    
    @State
    private var lastDataRange: DataRange?
    
    private let refreshMetadataTimer = Timer.publish(every: METADATA_UPDATE_INTERVAL, on: .main, in: .common).autoconnect()
    
    private let decoder = JSONDecoder()
    
    var body: some View {
        VStack {
            PlayerView()
                .environmentObject(adTracker)
                .environmentObject(session)
            SessionView()
                .environmentObject(session)
            AdPodListView()
                .environmentObject(adTracker)
            Spacer()
        }
        .onAppear {
            session.load = loadMedia
        }
        .onReceive(refreshMetadataTimer) { _ in
            Task {
                await checkNeedUpdate()
            }
        }
    }
}

extension ContentView {
    private func checkNeedUpdate() async {
        guard var url = session.sessionInfo?.adTrackingMetadataUrl else {
            return
        }
        let lastPlayheadTime = adTracker.getPlayheadTime()
        let result = await refreshMetadata(url: url, time: lastPlayheadTime)
        if let lastDataRange = lastDataRange {
            if !isInRange(time: lastPlayheadTime, range: lastDataRange) && !result {
                url += "&start=\(Int(lastPlayheadTime))"
                _ = await refreshMetadata(url: url, time: nil)
            }
        }
    }
    
    private func refreshMetadata(url: String, time: Double?) async -> Bool {
        guard let url = URL(string: url) else {
            // TODO: throw error
            return false
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                // TODO: throw error
                return false
            }
            if httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {
                // TODO: throw error
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
            // TODO: throw error
            return false
        }
    }
    
    private func loadMedia(urlString: String) async {
        guard let url = URL(string: urlString) else {
            // TODO: throw error
            return
        }
        var manifestUrl, adTrackingMetadataUrl: String
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else {
                // TODO: throw error
                return
            }
            if httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {
                // TODO: throw error
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
            
            _ = await refreshMetadata(url: adTrackingMetadataUrl, time: nil)
        } catch {
            // TODO: throw error
        }
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
        ContentView()
    }
}
