//
//  AdBreakView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 27/1/2023.
//

import SwiftUI
import HarmonicClientSideAdTracking

struct AdBreakView: View {
    var adBreak: AdBreak?
    
    @State private var expandAdBreak = true
    
    var body: some View {
        DisclosureGroup("Ad Pod: \(adBreak?.id ?? "nil")", isExpanded: $expandAdBreak) {
            ForEach(adBreak?.ads ?? []) { ad in
                AdView(ad: ad)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
//        .padding()
    }
}

struct AdBreakView_Previews: PreviewProvider {
    static var previews: some View {
        AdBreakView(adBreak: sampleAdBeacon?.adBreaks.first)
    }
}
