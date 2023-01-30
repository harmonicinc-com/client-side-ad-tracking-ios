//
//  AdBreakView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 27/1/2023.
//

import SwiftUI
import HarmonicClientSideAdTracking

struct AdBreakView: View {
    @EnvironmentObject
    var adTracker: HarmonicAdTracker
    
    @ObservedObject
    var adBreak: AdBreak
    
    @State
    private var expandAdBreak = true
    
    var body: some View {
        DisclosureGroup("Ad Pod: \(adBreak.id ?? "nil")", isExpanded: $expandAdBreak) {
            ForEach(adBreak.ads) { ad in
                AdView(ad: ad, adBreakId: adBreak.id)
            }
        }
        .onReceive(adTracker.$adPods) { adPods in
            if let pod = adPods.first(where: { $0.id == adBreak.id }),
                let startTime = pod.startTime,
                let duration = pod.duration {
                expandAdBreak = adTracker.getPlayheadTime() <= startTime + duration + 2000
            }
        }
    }
}

struct AdBreakView_Previews: PreviewProvider {
    static var previews: some View {
        AdBreakView(adBreak: sampleAdBeacon?.adBreaks.first ?? AdBreak())
    }
}
