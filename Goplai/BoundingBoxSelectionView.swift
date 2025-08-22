//
//  BoundingBoxSelectionView.swift
//  Goplai
//
//  Created by Akshat Kishore on 8/8/25.
//

import SwiftUI
import AVFoundation
import UIKit

struct BoundingBoxSelectionView: View {
    @StateObject private var wsManager = WebSocketManager()
    let videoURL: URL
    @State private var selectedBoxID: Int? = nil
    @State private var isLoading = false
    @State private var navigateToClips = false
    @State private var reassignmentChecker = false
    
    @State private var progress: Double = 0
    @State private var totalFrames: Int = 0
    
    @Environment(\.dismiss) private var dismiss
    
    var sessionID: String
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Text("Find yourself in the image and tap the box around you.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.footnote)
                        .padding(.leading)

                    ZStack {
                        frameView
                        
                        NavigationLink(
                            destination: ClipsView(wsManager: wsManager, sessionID: sessionID, videoURL: videoURL).navigationBarBackButtonHidden(true),
                            isActive: $navigateToClips
                        ) {
                            EmptyView()
                        }
                    }
                    Spacer()
                    
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                .navigationTitle("Select Object")
                //.navigationBarItems(leading:
                //    Button(action: { dismiss() }) {
                //        Image(systemName: "arrow.left")
                //            .font(.title2)
                //            .foregroundColor(.black)
                //    }
                //)
                .onAppear {
                    wsManager.connect(sessionID: sessionID)
                    let asset = AVAsset(url: videoURL)
                    let duration = asset.duration.seconds
                    let fps = wsManager.fps ?? 30
                    self.totalFrames = Int(duration * fps)
                }
                .onChange(of: wsManager.currentFrameNum) { _ in
                    isLoading = false // new frame
                }
                .onChange(of: wsManager.isCompleted) { done in
                    if done {
                        isLoading = false
                        navigateToClips = true
                        progress = 1.0
                    }
                }
                .onChange(of: wsManager.progress){
                    self.progress = wsManager.progress / Double(totalFrames)
                }
//                MARK: the code below allows for a different type of progressview()
//                if isLoading {
//                    ZStack {
//                        Color.black.opacity(0.4).ignoresSafeArea()
//                        VStack(spacing: 12) {
//                            ProgressView()
//                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                            Text("Processing...")
//                                .foregroundColor(.white)
//                                .font(.headline)
//                        }
//                        .padding(20)
//                        .background(Color.black.opacity(0.6))
//                        .cornerRadius(10)
//                    }
//                    .transition(.opacity)
//                    .animation(.easeInOut(duration: 0.2), value: isLoading)
//                }
            }
        }
    }
    
    // MARK: frame + bounding Boxes
    private var frameView: some View {
        Group {
            if isLoading {
                // while waiting for the backend to send a new frame
                ProgressView("Waiting for frame...").padding()
            } else if let frameNum = wsManager.currentFrameNum,
                      let image = extractFrame(from: videoURL,
                                               at: frameNum,
                                               fps: wsManager.fps ?? 30) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .overlay(boundingBoxesOverlay)
            } else {
                // initial load before first frame
                ProgressView("Waiting for frame...").padding()
            }
        }
    }

    
    private var boundingBoxesOverlay: some View {
        GeometryReader { geo in
            if let frameNum = wsManager.currentFrameNum,
               let frameImage = extractFrame(from: videoURL,
                                             at: frameNum,
                                             fps: wsManager.fps ?? 30) {
                
                let imgSize = frameImage.size
                let scaleX = geo.size.width / imgSize.width
                let scaleY = geo.size.height / imgSize.height
                
                ForEach(wsManager.players) { player in
                    Rectangle()
                        .stroke(selectedBoxID == player.id ? Color.blue : Color.red, lineWidth: 2)
                        .frame(width: player.rect.width * scaleX, height: player.rect.height * scaleY)
                        .position(x: player.rect.midX * scaleX, y: player.rect.midY * scaleY)
                        .onTapGesture {
                            selectedBoxID = player.id
                            isLoading = true
                            if wsManager.requiresReassignment {
                                wsManager.sendReassignmentSelection(playerID: player.id)
                            } else {
                                wsManager.sendSelection(playerID: player.id)
                            }
                        }
                }
            }
        }
    }
}


func extractFrame(from videoURL: URL, at frameNum: Int, fps: Double) -> UIImage? {
    let asset = AVAsset(url: videoURL)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    
    let time = CMTime(value: CMTimeValue(frameNum), timescale: CMTimeScale(fps))
    
    do {
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        return UIImage(cgImage: cgImage)
    } catch {
        print("Frame extraction failed: \(error)")
        return nil
    }
}
