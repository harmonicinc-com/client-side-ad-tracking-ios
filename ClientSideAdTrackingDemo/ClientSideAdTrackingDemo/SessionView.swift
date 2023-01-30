//
//  SessionView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 30/1/2023.
//

import SwiftUI
import HarmonicClientSideAdTracking

struct SessionView: View {
    @EnvironmentObject
    var session: Session
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Manifest: \(session.sessionInfo?.manifestUrl ?? "nil")")
            Text("Ad metadata: \(session.sessionInfo?.adTrackingMetadataUrl ?? "nil")")
        }
        .font(.caption)
        .padding()
    }
}

struct SessionInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView()
    }
}
