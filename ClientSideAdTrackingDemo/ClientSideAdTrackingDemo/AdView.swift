//
//  AdView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 27/1/2023.
//

import SwiftUI
import HarmonicClientSideAdTracking

struct AdView: View {
    @ObservedObject
    var ad: Ad
    
    @State
    private var expandAd = true
    
    var body: some View {
        DisclosureGroup("Ad: \(ad.id ?? "nil")", isExpanded: $expandAd) {
            ForEach(ad.trackingEvents, id: \.event) { trackingEvent in
                TrackingEventView(trackingEvent: trackingEvent)
            }
        }
    }
}

struct AdView_Previews: PreviewProvider {
    static var previews: some View {
        AdView(ad: sampleAdBeacon?.adBreaks.first?.ads.first ?? Ad())
    }
}
