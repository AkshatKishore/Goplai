//
//  ClipsView.swift
//  Goplai
//
//  Created by Akshat Kishore on 8/8/25.
//

import SwiftUI
import AVKit
import PhotosUI

struct ClipsView: View {
    // TODO: Replace with actual video clip URLs from backend
    let clips: [ProcessedClip] = [
        ProcessedClip(url: URL(string: "https://www.example.com/clip1.mp4")!,
                      duration: 5.2,
                      confidence: 0.92),
        ProcessedClip(url: URL(string: "https://www.example.com/clip2.mp4")!,
                      duration: 4.8,
                      confidence: 0.87)
    ]
    @Environment(\.dismiss) private var dismiss
    @State private var downloadMessage: String? = nil
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 20) {
                        ForEach(clips) { clip in
                            VStack(spacing: 6) {
                                VideoPlayer(player: AVPlayer(url: clip.url))
                                    .frame(width: 200, height: 150)
                                    .cornerRadius(10)
                                
                                Text("Duration: \(String(format: "%.1f", clip.duration))s")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("Confidence: \(Int(clip.confidence * 100))%")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Button(action: {
                                    downloadVideo(from: clip.url)
                                }) {
                                    Label("Save", systemImage: "arrow.down.circle")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            .frame(width: 200)
                        }
                    }
                    .padding()
                }
                Spacer()
            }
            .navigationTitle("Result Clips")
            .navigationBarItems(leading:
                                    Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundColor(.black)
            }
            )
        }
    }
    //TODO: move to a modelview file when created
    private func downloadVideo(from url: URL) {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    URLSession.shared.downloadTask(with: url) { tempURL, response, error in
                        guard let tempURL = tempURL, error == nil else {
                            DispatchQueue.main.async {
                                downloadMessage = "Failed to download video."
                                showAlert = true
                            }
                            return
                        }
                        
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
                        }) { success, error in
                            DispatchQueue.main.async {
                                if success {
                                    downloadMessage = "Video saved to Photos."
                                } else {
                                    downloadMessage = "Failed to save video."
                                }
                                showAlert = true
                            }
                        }
                    }.resume()
                } else {
                    DispatchQueue.main.async {
                        downloadMessage = "Permission denied. Enable Photos access in Settings."
                        showAlert = true
                    }
                }
            }
        }
}
#Preview {
    ClipsView()
}
