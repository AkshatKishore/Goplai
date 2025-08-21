//
//  ClipsView.swift
//  Goplai
//
//  Created by Akshat Kishore on 8/8/25.
//
import AVKit
import SwiftUI

private struct ClipCard: View {
    let clip: ProcessedClip
    let onSave: (URL) -> Void

    var body: some View {
        VStack(spacing: 6) {
            VideoPlayerContainer(url: clip.url)
                .frame(width: 200, height: 150)
                .cornerRadius(10)

            Text("Duration: \(String(format: "%.1f", clip.duration))s")
                .font(.subheadline)
                .foregroundColor(.secondary)

//            Text("Confidence: \(Int(clip.confidence * 100))%")
//                .font(.subheadline)
//                .foregroundColor(.secondary)

            //TODO: uncomment below to allow for download functionality. Currently has a bug
//            Button { onSave(clip.url) } label: {
//                Label("Save", systemImage: "arrow.down.circle")
//                    .font(.subheadline)
//            }
        }
        .frame(width: 200)
    }
}

private struct VideoPlayerContainer: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
            } else {
                Color.black.opacity(0.05)
                    .overlay(ProgressView())
            }
        }
        .onAppear {
            if player == nil { player = AVPlayer(url: url) }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

import SwiftUI
import AVKit
import PhotosUI
import AVFoundation

struct ClipsView: View {
    @ObservedObject var wsManager: WebSocketManager
    
    let sessionID: String
    let videoURL: URL

    @Environment(\.dismiss) private var dismiss
    
    @State private var downloadMessage: String? = nil
    @State private var showAlert = false
    
    @State private var highlightClips: [ProcessedClip] = []

    var body: some View {
        NavigationView {
            content
                .navigationTitle("Result Clips")
            //TODO: uncomment below to get a back button
//                .toolbar {
//                    ToolbarItem(placement: .topBarLeading) {
//                        Button(action: { dismiss() }) {
//                            Image(systemName: "arrow.left")
//                        }
//                    }
//                }
                .onDisappear {
                    wsManager.disconnect()
                }
                .onAppear() {
                    guard highlightClips.isEmpty else { return }
                    print("clips from web socket manager: \(wsManager.highlights)")
                    generateHighlightClips() //populates self.highlightClips : [ProcessedClip]
                    print("clips from highlight generator: \(self.highlightClips)")
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text(downloadMessage ?? "Error"))
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if highlightClips.isEmpty {
            Text("No Highlights Found for Selected Player")
                .foregroundColor(.secondary)
                .padding()
        } else {
            VStack{
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 20) {
                        ForEach(highlightClips) { clip in
                            ClipCard(clip: clip, onSave: downloadVideo)
                        }
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }

    private func downloadVideo(_ url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                URLSession.shared.downloadTask(with: url) { tempURL, _, error in
                    guard let tempURL, error == nil else {
                        DispatchQueue.main.async {
                            downloadMessage = "Failed to download video."
                            showAlert = true
                        }
                        return
                    }
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
                    }) { success, _ in
                        DispatchQueue.main.async {
                            downloadMessage = success ? "Video saved to Photos." : "Failed to save video."
                            showAlert = true
                        }
                    }
                }.resume()

            default:
                DispatchQueue.main.async {
                    downloadMessage = "Permission denied. Enable Photos access in Settings."
                    showAlert = true
                }
            }
        }
    }

    // Slice the original video into highlight clips using start/end times from wsManager.highlights
    private func generateHighlightClips() {
        //highlightClips.removeAll()

        for h in wsManager.highlights {
            let start = CMTime(seconds: max(0, h.start_time), preferredTimescale: 600)
            let end   = CMTime(seconds: max(h.start_time, h.end_time), preferredTimescale: 600)

            wsManager.exportClip(from: videoURL, startTime: start, endTime: end) { clipURL in
                guard let clipURL = clipURL else { return }
                let processed = ProcessedClip(
                    url: clipURL,
                    duration: h.duration,
                    confidence: h.tracked_player_won ? 1.0 : 0.0
                )
                DispatchQueue.main.async {
                    highlightClips.append(processed)
                }
            }
        }
    }
}



//import SwiftUI
//import AVKit
//import PhotosUI
//import AVFoundation
//
//struct ClipsView: View {
//    @StateObject private var wsManager = WebSocketManager()
//    let sessionID: String
//    let videoURL: URL
//    
//    @Environment(\.dismiss) private var dismiss
//    
//    @State private var downloadMessage: String? = nil
//    @State private var showAlert = false
//    
//    @State private var highlightClips: [ProcessedClip] = []
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                if highlightClips.isEmpty {
//                    Text("No Highlights Found")
//                        .frame(alignment: .center)
//                        .foregroundColor(.secondary)
//                        .padding()
//                } else {
//                    ScrollView(.horizontal, showsIndicators: true) {
//                        HStack(spacing: 20) {
//                            ForEach(highlightClips, id: \.url) { clip in
//                                VStack(spacing: 6) {
//                                    VideoPlayer(player: AVPlayer(url: clip.url))
//                                        .frame(width: 200, height: 150)
//                                        .cornerRadius(10)
//                                    
//                                    Text("Duration: \(String(format: "%.1f", clip.duration))s")
//                                        .font(.subheadline)
//                                        .foregroundColor(.secondary)
//                                    
//                                    Text("Confidence: \(Int(clip.confidence * 100))%")
//                                        .font(.subheadline)
//                                        .foregroundColor(.secondary)
//                                    
//                                    Button(action: { downloadVideo(from: clip.url) }) {
//                                        Label("Save", systemImage: "arrow.down.circle")
//                                            .font(.subheadline)
//                                            .foregroundColor(.blue)
//                                    }
//                                }
//                                .frame(width: 200)
//                            }
//                        }
//                        .padding()
//                    }
//                }
//                Spacer()
//            }
//            .navigationTitle("Result Clips")
//            .navigationBarItems(leading:
//                Button(action: { dismiss() }) {
//                    Image(systemName: "arrow.left")
//                        .font(.title2)
//                        .foregroundColor(.black)
//                }
//            )
//            .onChange(of: wsManager.highlights) { _ in
//                generateHighlightClips()
//            }
//            .onAppear {
//                wsManager.connect(sessionID: sessionID)
//            }
//            .onDisappear {
//                wsManager.disconnect()
//            }
//            .alert(isPresented: $showAlert) {
//                Alert(title: Text(downloadMessage ?? "Error"))
//            }
//        }
//    }
//    
//    private func downloadVideo(from url: URL) {
//        PHPhotoLibrary.requestAuthorization { status in
//            if status == .authorized {
//                URLSession.shared.downloadTask(with: url) { tempURL, _, error in
//                    guard let tempURL = tempURL, error == nil else {
//                        DispatchQueue.main.async {
//                            downloadMessage = "Failed to download video."
//                            showAlert = true
//                        }
//                        return
//                    }
//                    PHPhotoLibrary.shared().performChanges({
//                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
//                    }) { success, _ in
//                        DispatchQueue.main.async {
//                            downloadMessage = success ? "Video saved to Photos." : "Failed to save video."
//                            showAlert = true
//                        }
//                    }
//                }.resume()
//            } else {
//                DispatchQueue.main.async {
//                    downloadMessage = "Permission denied. Enable Photos access in Settings."
//                    showAlert = true
//                }
//            }
//        }
//    }
//    
//    // MARK: - Generate exported clips
//    private func generateHighlightClips() {
//        //guard let fps = wsManager.fps ?? 30.0 as Double? else { return }
//        highlightClips.removeAll()
//        
//        for highlight in wsManager.highlights {
//            let startTime = CMTime(seconds: highlight.start_time, preferredTimescale: 600)
//            let endTime = CMTime(seconds: highlight.end_time, preferredTimescale: 600)
//            let duration = highlight.duration
//            let confidence = highlight.tracked_player_won ? 1.0 : 0.0
//            
//            wsManager.exportClip(
//                from: videoURL,
//                startTime: startTime,
//                endTime: endTime
//            ) { clipURL in
//                if let clipURL = clipURL {
//                    let processed = ProcessedClip(url: clipURL, duration: duration, confidence: confidence)
//                    DispatchQueue.main.async {
//                        highlightClips.append(processed)
//                    }
//                }
//            }
//        }
//    }
//}
//
