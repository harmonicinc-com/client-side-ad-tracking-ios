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
    
    @EnvironmentObject
    private var playerVM: PlayerViewModel
    
    @StateObject
    private var playerObserver = PlayerObserver()
    
    var body: some View {
        HStack {
            Button {
                let currentTime = playerVM.player.currentTime()
                let newTime = currentTime - CMTime(seconds: 10, preferredTimescale: 600)
                playerVM.player.seek(to: newTime)
            } label: {
                Image(systemName: "backward.fill")
                    .resizable()
                    .frame(height: BUTTON_HEIGHT)
            }
            Button {
                if playerVM.player.timeControlStatus == .playing {
                    playerVM.player.pause()
                } else {
                    playerVM.player.play()
                }
            } label: {
                Image(systemName: playerObserver.primaryStatus == .playing ? "pause.fill" : "play.fill")
                    .resizable()
                    .frame(height: BUTTON_HEIGHT)
            }
            Button {
                let currentTime = playerVM.player.currentTime()
                let newTime = currentTime + CMTime(seconds: 10, preferredTimescale: 600)
                guard let seekableTimeRange = playerVM.player.currentItem?.seekableTimeRanges.last as? CMTimeRange else {
                    return
                }
                playerVM.player.seek(to: min(newTime, newTime + seekableTimeRange.end))
            } label: {
                Image(systemName: "forward.fill")
                    .resizable()
                    .frame(height: BUTTON_HEIGHT)
            }
            Button {
                guard let seekableTimeRange = playerVM.player.currentItem?.seekableTimeRanges.last as? CMTimeRange else {
                    return
                }
                playerVM.player.seek(to: seekableTimeRange.end)
            } label: {
                Image(systemName: "forward.end.fill")
                    .resizable()
                    .frame(height: BUTTON_HEIGHT)
            }
        }
        .frame(width: 560)
        .onAppear {
            playerObserver.setPlayer(playerVM.player)
        }
    }
}

struct PlayerControlView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerControlView()
            .environmentObject(PlayerViewModel())
    }
}
