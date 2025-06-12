# client-side-ad-tracking for iOS and tvOS

There are currently 2 projects in this repository:

### 1. HarmonicClientSideAdTracking

A Swift package that consists of the client-side ad beaconing logic and some SwiftUI views that may be reused. (The submodule is in this repo: https://github.com/harmonicinc-com/client-side-ad-tracking-ios-lib)

### 2. ClientSideAdTrackingDemo

An app for iOS/iPadOS and tvOS that uses the above package to demo client-side ad beaconing.

## How to run

*Requires iOS/iPadOS/tvOS 15 or above*

1. Clone this repository

2. Init the package submodule: `git submodule update --init --recursive`

3. Open `client-side-ad-tracking.xcworkspace` with Xcode

4. Select the scheme `ClientSideAdTrackingDemo` and build+run for your device or simulator

## Notes for LL-HLS + HLS Interstitial Playback 

1. “automaticallyWaitsToMinimizeStalling” is recommended to be **enabled** to playback smoothly
https://developer.apple.com/documentation/avfoundation/avplayer/automaticallywaitstominimizestalling

2. “automaticallyPreservesTimeOffsetFromLive” is recommended to be **disabled**
https://developer.apple.com/documentation/avfoundation/avplayeritem/automaticallypreservestimeoffsetfromlive

Based on Apple’s doc, this option applies adjustment to the time offset based on whether a buffering operation has happened. However, from our HLS interstitial test, the transition from ad break back to live has already adjusted the playhead to the time: interstitial start + interstitial duration.
It is found that sometimes this additional adjustment can cause trouble when trying to adjust the playhead at the interstitial ends (i.e. another attempt to adjust the playhead), so it is recommended to leave this option to false, to let the interstitial controller be the single factor controlling the playhead.

3. “Synchronized Playback” was not used, as this is not an option natively provided by the AVPlayer
