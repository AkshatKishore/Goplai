//
//  ContentView.swift
//  Goplai
//
//  Created by Akshat Kishore on 8/8/25.
//

import SwiftUI
import AVKit

struct ContentView: View {
    
    @State private var selectedVideoURL: URL?
    @State private var showVideoPicker = false
    @State private var navigateToProcessedFrame = false
    @State private var sessionID: String? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let selectedVideoURL = selectedVideoURL {
                    VideoPlayer(player: AVPlayer(url: selectedVideoURL))
                        .frame(height: 200)
                        .cornerRadius(10)
                        .shadow(radius: 4)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                        
                        Button("Upload Video") {
                            showVideoPicker = true
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color("AccentColor"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .foregroundColor(.gray)
                    )
                    .padding(.horizontal)
                }
                
                Button {
                    if let videoURL = selectedVideoURL {
                        print("🚀 Starting process for video: \(videoURL.lastPathComponent)")
                        let filename = videoURL.lastPathComponent
                        
                        APIService.getUploadURL(filename: filename) { result in
                            switch result {
                            case .success(let uploadResponse):
                                print("✅ Got upload URL for session: \(uploadResponse.session_id)")
                                
                                APIService.uploadToS3(uploadResponse: uploadResponse, videoURL: videoURL) { success in
                                    if success {
                                        print("Upload to S3 succeeded")
                                        APIService.startProcessing(sessionID: uploadResponse.session_id,
                                                                   s3Key: uploadResponse.s3_key) { started in
                                            if started {
                                                print("Processing started for session \(uploadResponse.session_id)")
                                                DispatchQueue.main.async {
                                                    self.sessionID = uploadResponse.session_id
                                                    navigateToProcessedFrame = true
                                                }
                                            } else {
                                                print("Failed to start processing")
                                            }
                                        }
                                    } else {
                                        print("Upload to S3 failed")
                                    }
                                }
                            case .failure(let error):
                                print("Error getting upload URL: \(error)")
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Process")
                            .foregroundColor(.white)
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                    }
                }
                .frame(width: UIScreen.main.bounds.width - 28, height: 50)
                .background(Color("AccentColor"))
                .cornerRadius(10)

                //.disabled(selectedVideoURL == nil)
                
                NavigationLink(
                    isActive: $navigateToProcessedFrame,
                    destination: {
                        if let sessionID = sessionID {
                            BoundingBoxSelectionView(sessionID: sessionID)
                                .navigationBarBackButtonHidden(true)
                        } else {
                            EmptyView()
                        }
                    },
                    label: {
                        EmptyView()
                    }
                )
                
                Spacer()
            }
            .sheet(isPresented: $showVideoPicker) {
                VideoPicker(videoURL: $selectedVideoURL)
            }
            .navigationTitle("Video Upload")
        }
    }
}

#Preview {
    ContentView()
}
