//
//  Session.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 19/1/2023.
//

import Foundation
import HarmonicClientSideAdTracking

class Session: ObservableObject {
    
    @Published
    var sessionInfo: SessionInfo? = nil
    
    @Published
    var mediaUrl: String? = nil
    
    @Published
    var manifestUrl: String? = nil
    
    @Published
    var adTrackingMetadataUrl: String? = nil
    
    @Published
    var load: ((_ url: String) async -> Void)? = nil
    
    init(sessionInfo: SessionInfo?, mediaUrl: String?, manifestUrl: String?, adTrackingMetadataUrl: String?, load: ((_ url: String) -> Void)?) {
        self.sessionInfo = sessionInfo
        self.mediaUrl = mediaUrl
        self.manifestUrl = manifestUrl
        self.adTrackingMetadataUrl = adTrackingMetadataUrl
        self.load = load
    }
    
}
