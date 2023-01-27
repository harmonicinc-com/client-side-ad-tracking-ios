//
//  PlayerView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 19/1/2023.
//

import SwiftUI
import AVKit
import HarmonicClientSideAdTracking

struct PlayerView: View {
    
    @EnvironmentObject
    var session: Session
    
//    @EnvironmentObject
    var adTracker: ClientSideAdTracker?
    
    @State
    var player = AVPlayer()
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            VideoPlayer(player: player)
                .frame(height: 300)
                .onAppear {
                    if let load = session.load {
                        Task {
                            await load("http://10.50.110.66:20202/variant/v1/dai/HLS/Live/channel(c071e4fd-e7cd-4312-e884-d7546870490e)/variant.m3u8")

                        }
                    }
                    
//                    let url = URL(string: "http://10.50.110.66:20202/variant/v1/dai/HLS/Live/channel(c071e4fd-e7cd-4312-e884-d7546870490e)/variant.m3u8")!
//                    player.replaceCurrentItem(with: AVPlayerItem(url: url))
//                    player.play()
                }
                .onReceive(timer) { _ in
                    let playhead = (player.currentItem?.currentDate()?.timeIntervalSince1970 ?? 0) * 1000
//                    print("playhead: \(playhead)")
                    Task {
                        await adTracker?.updatePlayheadTime(playhead)
                        await adTracker?.needSendBeacon(time: playhead)
                    }
                }
                .onReceive(session.$sessionInfo) { info in
                    print("Received info: \(info)")
                    if let info = info {
                        let url = URL(string: info.manifestUrl ?? "")!
                        player.replaceCurrentItem(with: AVPlayerItem(url: url))
                        print("player.currentItem: \(player.currentItem.debugDescription)")
                        player.play()
                    }
                }
            Spacer()
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
    }
}
