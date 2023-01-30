//
//  AdPodListView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 30/1/2023.
//

import SwiftUI
import HarmonicClientSideAdTracking

struct AdPodListView: View {
    @EnvironmentObject
    var adTracker: HarmonicAdTracker
    
    @State
    private var expandAdPods = true
    
    var body: some View {
        ScrollView {
            DisclosureGroup("Tracking Events", isExpanded: $expandAdPods) {
                ForEach(adTracker.adPods) { pod in
                    AdBreakView(adBreak: pod)
                }
            }
            .padding()
        }
    }
}

struct AdPodListView_Previews: PreviewProvider {
    static var previews: some View {
        AdPodListView()
    }
}
