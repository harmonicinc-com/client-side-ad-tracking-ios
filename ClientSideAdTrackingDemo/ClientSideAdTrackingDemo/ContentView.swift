//
//  ContentView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 19/1/2023.
//

import SwiftUI
import HarmonicClientSideAdTracking
import RegexBuilder

let AD_TRACING_METADATA_FILE_NAME = "metadata"
let EARLY_FETCH_SEC: Double = 5000
let UPDATE_INTERVAL: TimeInterval = 4

struct ContentView: View {
    let refreshMetadataTimer = Timer.publish(every: UPDATE_INTERVAL, on: .main, in: .common).autoconnect()
    
    let decoder = JSONDecoder()
    
//    init() {
//        session.sessionInfo = sessionInfo
//        session.load = loadMedia
//    }
//
    @State
    private var sessionInfo: SessionInfo?
    
//    @State
//    private var lastPlayheadTime: Double = 0
    
    @State
    private var adPods: [AdBreak] = []
    
    @State private var expandAdPods = true
    
    @State
    private var lastDataRange: DataRange?
    
    @StateObject
    var session = Session(sessionInfo: nil,
                          mediaUrl: nil,
                          manifestUrl: nil,
                          adTrackingMetadataUrl: nil,
                          load: nil)
    
//    @StateObject
    @State
    var adTracker: ClientSideAdTracker?
    
    var body: some View {
        VStack {
            PlayerView(adTracker: adTracker)
                .environmentObject(session)
    //            .environmentObject(adTracking)
                .onReceive(refreshMetadataTimer) { _ in
                    Task {
                        await checkNeedUpdate()
                    }
                }
                
            ScrollView {
                DisclosureGroup("Tracking Events", isExpanded: $expandAdPods) {
                    ForEach(adPods) { pod in
                        AdBreakView(adBreak: pod)
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .onAppear {
            session.sessionInfo = sessionInfo
            session.load = loadMedia
        }
    }
    
    private func rewriteUrlToMetadataUrl(_ url: String) -> String {
//        let regex = Regex {
//            "/"
//            OneOrMore(.anyOf("/?").inverted)
//            Capture {
//                Regex {
//                    Optionally {
//                        "?"
//                    }
//                    ZeroOrMore(.anyOf("/").inverted)
//                }
//            }
//            Anchor.endOfLine
//        }
        return url.replacingOccurrences(of: "\\/[^\\/?]+(\\??[^\\/]*)$",
                                        with: "/\(AD_TRACING_METADATA_FILE_NAME)$1",
                                        options: .regularExpression)
    }
    
    private func isInRange(time: Double?, range: DataRange) -> Bool {
        if let time = time, let start = range.start, let end = range.end {
            return time >= start && time <= end - EARLY_FETCH_SEC
        } else {
            return true
        }
    }
    
    private func refreshMetadata(url: String, time: Double?) async -> Bool {
        guard let url = URL(string: url) else {
            // TODO: throw error
            return false
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
//            print("refreshMetadata resposne: \(response)")
            guard let httpResponse = response as? HTTPURLResponse else {
                // TODO: throw error
                return false
            }
            if httpResponse.statusCode < 200 || httpResponse.statusCode > 299 {
                // TODO: throw error
                return false
            }
            
//            print("Raw string: \(String(data: data, encoding: .utf8))")
            
            decoder.dateDecodingStrategy = .millisecondsSince1970
            guard let adBeacon = try? decoder.decode(AdBeacon.self, from: data) else {
                // TODO: throw error
                print("refreshMetadata: JSON failed")
                return false
            }
//            print("refreshMetadata called: \(adBeacon)")
            lastDataRange = adBeacon.dataRange
            if let lastDataRange = lastDataRange {
                if !isInRange(time: time, range: lastDataRange) {
                    print("Invalid metadata: Not in range. Time: \(String(describing: time))")
                    return false
                }
            }
            
//            if let adBreaks =  {
                adTracker?.updatePods(adBeacon.adBreaks)
//            }
            
            return true
        } catch {
            // TODO: throw error
            return false
        }
    }
    
    private func loadMedia(urlString: String) async {
        print("loadMedia called")
        guard let url = URL(string: urlString) else {
            // TODO: throw error
            return
        }
        var manifestUrl, adTrackingMetadataUrl: String
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            print(response)
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
            
//            if let streamUrl = URL(string: "01.m3u8", relativeTo: url) {
//                let (_, _) = try await URLSession.shared.data(from: streamUrl)
//            }
            
            adPods = []
            adTracker = HarmonicAdTracker(adPods: adPods, delegate: self)
            sessionInfo = SessionInfo(localSessionId: Date().ISO8601Format(),
                                      mediaUrl: urlString,
                                      manifestUrl: manifestUrl,
                                      adTrackingMetadataUrl: adTrackingMetadataUrl)
            print("sessionInfo: \(sessionInfo)")
            session.sessionInfo = sessionInfo
            
            _ = await refreshMetadata(url: adTrackingMetadataUrl, time: nil)
        } catch {
            // TODO: throw error
        }
    }
    
    private func checkNeedUpdate() async {
        guard var url = sessionInfo?.adTrackingMetadataUrl, let lastPlayheadTime = adTracker?.getPlayheadTime() else {
            return
        }
        let result = await refreshMetadata(url: url, time: lastPlayheadTime)
        if let lastDataRange = lastDataRange {
            if !isInRange(time: lastPlayheadTime, range: lastDataRange) && !result {
                url += "&start=\(Int(lastPlayheadTime))"
                _ = await refreshMetadata(url: url, time: nil)
            }
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension ContentView: HarmonicAdTrackerDelegate {
    func receiveUpdate() {
        adPods = adTracker?.getAdPods() ?? []
//        print("receiveUpdate: \(adPods)")
    }
}
