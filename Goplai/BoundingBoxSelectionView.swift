//
//  BoundingBoxSelectionView.swift
//  Goplai
//
//  Created by Akshat Kishore on 8/8/25.
//

import SwiftUI

struct BoundingBoxSelectionView: View {
    @StateObject private var wsManager = WebSocketManager()
    @State private var selectedBoxID: Int? = nil
    @State private var isLoading = false
    @State private var navigateToClips = false
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
                            destination: ClipsView().navigationBarBackButtonHidden(true),
                            isActive: $navigateToClips
                        ) {
                            EmptyView()
                        }
                    }
                    Spacer()
                }
                .navigationTitle("Select Object")
                .navigationBarItems(leading:
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                )
                .onAppear {
                    wsManager.connect(sessionID: sessionID)
                }
                .onDisappear {
                    wsManager.disconnect()
                }
                
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Processing...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .padding(20)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: isLoading)
                }
            }
        }
    }
    
    // Frame + Bounding Boxes
    private var frameView: some View {
        Group {
            if let frameURL = wsManager.frameURL, let url = URL(string: frameURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit().overlay(boundingBoxesOverlay)
                } placeholder: {
                    ProgressView().padding()
                }
            } else if let base64 = wsManager.frameBase64,
                      let data = Data(base64Encoded: base64),
                      let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .overlay(boundingBoxesOverlay)
            } else {
                ProgressView().padding()
            }
        }
    }
    
    private var boundingBoxesOverlay: some View {
        GeometryReader { geo in
            ForEach(wsManager.players) { player in
                Rectangle()
                    .stroke(selectedBoxID == player.id ? Color.blue : Color.red, lineWidth: 2)
                    .frame(width: player.rect.width, height: player.rect.height)
                    .position(x: player.rect.midX, y: player.rect.midY)
                    .onTapGesture {
                        selectedBoxID = player.id
                        isLoading = true
                        wsManager.sendSelection(playerID: player.id)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            isLoading = false
                            navigateToClips = true
                        }
                    }
            }
        }
    }
}

#Preview {
    BoundingBoxSelectionView(sessionID: "preview-session-id")
}
