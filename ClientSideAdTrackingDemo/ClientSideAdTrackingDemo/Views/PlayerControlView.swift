//
//  PlayerControlView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 8/2/2023.
//

import SwiftUI
import AVFoundation
import HarmonicClientSideAdTracking
import Combine
import os

#if os(tvOS)
let BUTTON_HEIGHT: CGFloat = 15
#else
let BUTTON_HEIGHT: CGFloat = 24
#endif

struct PlayerControlView: View {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: PlayerControlView.self)
    )
    
    @ObservedObject private var session: AdBeaconingSession
    @ObservedObject private var playerObserver: PlayerObserver
    private var adTracker: HarmonicAdTracker?
    
    @State private var isMuted: Bool = false
    @State private var wasPlayingBeforePause: Bool = false
    @State private var muteObservation: AnyCancellable?
    @State private var rateObservation: AnyCancellable?
    
    init(session: AdBeaconingSession, playerObserver: PlayerObserver, adTracker: HarmonicAdTracker? = nil) {
        self.session = session
        self.playerObserver = playerObserver
        self.adTracker = adTracker
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Playback controls
            HStack(spacing: platformSpacing) {
                Button {
                    let currentTime = session.player.currentTime()
                    let newTime = currentTime - CMTime(seconds: 10, preferredTimescale: 600)
                    session.player.seek(to: newTime)
                } label: {
                    Image(systemName: "backward.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: BUTTON_HEIGHT)
                }
                Button {
                    togglePlayPause()
                } label: {
                    Image(systemName: (playerObserver.primaryStatus ?? .paused) == .playing ? "pause.fill" : "play.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: BUTTON_HEIGHT)
                }
                Button {
                    let currentTime = session.player.currentTime()
                    let newTime = currentTime + CMTime(seconds: 10, preferredTimescale: 600)
                    guard let seekableTimeRange = session.player.currentItem?.seekableTimeRanges.last as? CMTimeRange else {
                        return
                    }
                    session.player.seek(to: min(newTime, newTime + seekableTimeRange.end))
                } label: {
                    Image(systemName: "forward.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: BUTTON_HEIGHT)
                }
                Button {
                    guard let seekableTimeRange = session.player.currentItem?.seekableTimeRanges.last as? CMTimeRange else {
                        return
                    }
                    session.player.seek(to: seekableTimeRange.end)
                } label: {
                    Image(systemName: "forward.end.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: BUTTON_HEIGHT)
                }
                
                Spacer()
                
                // Mute/Unmute button
                Button {
                    toggleMute()
                } label: {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: BUTTON_HEIGHT)
                }
            }
            .frame(maxWidth: maxFrameWidth)
            .padding(.horizontal)
        }
        .onAppear {
            setupObservers()
            isMuted = session.player.isMuted
        }
        .onDisappear {
            muteObservation?.cancel()
            rateObservation?.cancel()
        }
    }
    
    /// Toggle mute state and report to ad tracker for beacon firing
    private func toggleMute() {
        let newMuteState = !session.player.isMuted
        session.player.isMuted = newMuteState
        isMuted = newMuteState
        
        // Report mute/unmute event to ad tracker for beacon firing
        Task {
            if newMuteState {
                let sent = await adTracker?.reportMute() ?? false
                Self.logger.debug("Mute beacon sent: \(sent)")
            } else {
                let sent = await adTracker?.reportUnmute() ?? false
                Self.logger.debug("Unmute beacon sent: \(sent)")
            }
        }
    }
    
    /// Toggle play/pause state and report to ad tracker for beacon firing
    private func togglePlayPause() {
        if session.player.timeControlStatus == .playing {
            session.player.pause()
            // Report pause event to ad tracker for beacon firing
            Task {
                let sent = await adTracker?.reportPause() ?? false
                Self.logger.debug("Pause beacon sent: \(sent)")
            }
        } else {
            session.player.play()
            // Report resume event to ad tracker for beacon firing
            Task {
                let sent = await adTracker?.reportResume() ?? false
                Self.logger.debug("Resume beacon sent: \(sent)")
            }
        }
    }
    
    /// Set up observers to track player state changes from external sources
    private func setupObservers() {
        // Observe mute state changes (e.g., from system controls or other UI)
        muteObservation = session.player.publisher(for: \.isMuted)
            .removeDuplicates()
            .sink { [self] newMuteState in
                // Only update local state, don't send beacons for external changes
                // Beacons are sent only when user interacts via our controls
                if isMuted != newMuteState {
                    isMuted = newMuteState
                }
            }
    }
    
    // MARK: - Platform-specific layout values
    
    private var platformSpacing: CGFloat {
        #if os(tvOS)
        return 20
        #else
        return 24
        #endif
    }
    
    private var maxFrameWidth: CGFloat {
        #if os(tvOS)
        return 560
        #else
        return .infinity
        #endif
    }
}

struct PlayerControlView_Previews: PreviewProvider {
    static var previews: some View {
        let session = AdBeaconingSession()
        PlayerControlView(session: session, playerObserver: session.playerObserver)
    }
}
