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