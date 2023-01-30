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
    
    @FocusState
    private var textIsFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Enter media URL:")
                .bold()
            TextField("Media URL", text: $session.sessionInfo.mediaUrl)
                .focused($textIsFocused)
                .submitLabel(.go)
                .onSubmit {
                    tryLoadMedia()
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Button("Cancel") {
                            textIsFocused = false
                        }
                        Spacer()
                    }
                }
            DisclosureGroup("Session Info") {
                VStack(alignment: .leading) {
                    Text("Manifest URL")
                        .bold()
                    Text("\(session.sessionInfo.manifestUrl)")
                        .font(.caption2)
                        .textSelection(.enabled)
                    Text("Ad tracking metadata URL")
                        .bold()
                    Text("\(session.sessionInfo.adTrackingMetadataUrl)")
                        .font(.caption2)
                        .textSelection(.enabled)
                }
            }
        }
        .font(.caption)
    }
}

extension SessionView {
    private func tryLoadMedia() {
        if let load = session.load {
            Task {
                await load(session.sessionInfo.mediaUrl)
            }
        }
    }
}

struct SessionInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SessionView()
            .environmentObject(sampleSession)
    }
}
