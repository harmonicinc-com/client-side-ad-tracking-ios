//
//  PlayerControlView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 8/2/2023.
//

import SwiftUI
import AVFoundation
import HarmonicClientSideAdTracking

let BUTTON_HEIGHT: CGFloat = 15

struct PlayerControlView: View {
    
    @ObservedObject private var session: AdBeaconingSession
    @ObservedObject private var playerObserver: PlayerObserver
    
    init(session: AdBeaconingSession, playerObserver: PlayerObserver) {
        self.session = session
        self.playerObserver = playerObserver
    }
    
    var body: some View {
        HStack {
            Button {
                let currentTime = session.player.currentTime()
                let newTime = currentTime - CMTime(seconds: 10, preferredTimescale: 600)
                session.player.seek(to: newTime)
            } label: {
                Image(systemName: "backward.fill")
                    .resizable()
                    .frame(height: BUTTON_HEIGHT)
            }
            Button {
                if session.player.timeControlStatus == .playing {
                    session.player.pause()
                } else {
                    session.player.play()
                }
            } label: {
                Image(systemName: (playerObserver.primaryStatus ?? .paused) == .playing ? "pause.fill" : "play.fill")
                    .resizable()
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
                    .frame(height: BUTTON_HEIGHT)
            }
        }
        .frame(width: 560)
    }
}

struct PlayerControlView_Previews: PreviewProvider {
    static var previews: some View {
        let session = AdBeaconingSession()
        PlayerControlView(session: session, playerObserver: session.playerObserver)
    }
}
