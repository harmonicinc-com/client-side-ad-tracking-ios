//
//  PlayerView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 19/1/2023.
//

import SwiftUI
import AVKit
import HarmonicClientSideAdTracking

let BEACON_UPDATE_INTERVAL: TimeInterval = 0.5

struct PlayerView: View {
    
    @EnvironmentObject
    var session: Session
    
    @EnvironmentObject
    var adTracker: HarmonicAdTracker
    
    @State
    private var player = AVPlayer()
    
    private let checkNeedSendBeaconTimer = Timer.publish(every: BEACON_UPDATE_INTERVAL, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            VideoPlayer(player: player)
                .frame(height: 250)
                .onReceive(checkNeedSendBeaconTimer) { _ in
                    let playhead = (player.currentItem?.currentDate()?.timeIntervalSince1970 ?? 0) * 1000
                    Task {
                        await adTracker.needSendBeacon(time: playhead)
                    }
                }
                .onReceive(session.$sessionInfo) { info in
                    if let url = URL(string: info.manifestUrl) {
                        player.replaceCurrentItem(with: AVPlayerItem(url: url))
                        player.play()
                    }
                }
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
            .environmentObject(sampleSession)
            .environmentObject(HarmonicAdTracker())
    }
}
