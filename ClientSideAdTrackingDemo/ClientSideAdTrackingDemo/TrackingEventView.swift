//
//  TrackingEventView.swift
//  ClientSideAdTrackingDemo
//
//  Created by Michael on 27/1/2023.
//

import SwiftUI
import HarmonicClientSideAdTracking

struct TrackingEventView: View {
    let dateFormatter: DateFormatter
    
//    @State
    var trackingEvent: TrackingEvent?
    
    init(trackingEvent: TrackingEvent? = nil) {
        self.trackingEvent = trackingEvent
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
    }

    var dateString: String {
        return dateFormatter.string(from: Date(timeIntervalSince1970: (trackingEvent?.startTime ?? 0) / 1_000))
    }
    
    var body: some View {
        HStack {
            Image(systemName: getSystemImageName(for: trackingEvent?.reportingState))
                .resizable()
                .frame(width: 30, height: 30)
            VStack(alignment: .leading) {
                Text("Event: \((trackingEvent?.event ?? .unknown).rawValue)")
                    .bold()
                    .font(.subheadline)
                ForEach(trackingEvent?.signalingUrls ?? [], id: \.self) { url in
                    Text("URL: \(url)")
                        .font(.caption)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
                Text("Time: \(dateString)")
                    .font(.caption)
            }
        }
//        .padding()
    }
}

extension TrackingEventView {
    private func getSystemImageName(for reportingState: ReportingState?) -> String {
        switch reportingState {
        case .connecting:
            return "hourglass.circle"
        case .done:
            return "checkmark.circle"
        case .failed:
            return "exclamationmark.circle"
        default:
            return "circle.dashed"
        }
    }
}

struct TrackingEventView_Previews: PreviewProvider {    
    static var previews: some View {
        TrackingEventView(trackingEvent: sampleAdBeacon?.adBreaks.first?.ads.first?.trackingEvents.first)
            .previewLayout(.fixed(width: 300, height: 80))
    }
}
