//
//  WebSocketManager.swift
//  Goplai
//
//  Created by Akshat Kishore on 8/19/25.
//

import Foundation
import AVKit
import PhotosUI
import AVFoundation

enum WebSocketEvent {
    case userInputRequired(players: [Player], frameNum: Int?, frameURL: String?, frameBase64: String?)
    case completed
    case statusUpdate(Double?)
    case unknown
}

class WebSocketManager: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    
    @Published var players: [Player] = []
    @Published var currentFrameNum: Int? = nil
    @Published var fps: Double? = nil
    @Published var isCompleted: Bool = false
    @Published var requiresReassignment: Bool = false
    @Published var highlights: [Highlight] = []
    
    @Published var progress: Double = 0.0
    
    func connect(sessionID: String) {
        guard let url = URL(string: "ws://3.15.204.107:8000/ws/\(sessionID)") else { return }
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        listen()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message,
                   let data = text.data(using: .utf8) {
                    do {
                        let msg = try JSONDecoder().decode(WebSocketMessage.self, from: data)
                        DispatchQueue.main.async {
                            switch msg.type {
                            case "user_input_required":
                                print("Received user_input_required with type=\(msg.input_type)")
                                if msg.input_type! == "player_selection" {
                                    print("Received user_input_required with input type player_selection")
                                    if let data = msg.data {
                                        print(data.available_players)
                                        self?.players = data.available_players ?? []
                                        self?.currentFrameNum = msg.frame_num
                                    }
                                }
                                else if msg.input_type! == "reassignment_selection" {
                                    print("Received user_input_required with input type reassignment_selection")
                                    if let data = msg.data {
                                        print(data.suggestions)
                                        self?.players = data.suggestions ?? []
                                        self?.currentFrameNum = msg.frame_num
                                        self?.requiresReassignment = true
                                    }
                                }
                                else if msg.input_type == "confirmation" {
                                    self?.sendConfirmationSelection()
//                                    self?.currentFrameNum = msg.frame_num
//                                    if let data = msg.data {
//                                        print(data.current_bbox)
//                                    }
                                }
                                
                            //case "reassignment_selection":
                                
                            case "completed":
                                print("Received completed")
                                //TODO: uncomment the below lines to show the highlights of the selected player ONLY (commented for demo purposes)
                                //if let highlights = msg.summary!.highlights {
                                //    self?.highlights = highlights.filter{ $0.tracked_player_won }
                                //}
                                self?.highlights = msg.summary!.highlights ?? []
                                self?.isCompleted = true
                                print("data received at complete: \(msg)")
                            case "status_update":
                                print("Received status_update frame num=\(msg.frame_num ?? -1)")
                                self?.fps = msg.fps
                                if let frameNum = msg.frame_num {
                                    self?.progress = Double(frameNum)
                                }
                            default:
                                print("unknown message \(msg.message)")
                                print("unknown message type \(msg.type)")
                            }
                        }
                    } catch {
                        print("Decode error: \(error)")
                        print("Raw text: \(text)")
                    }
                }
                self?.listen() // continue listening
            case .failure(let error):
                print("WebSocket error: \(error)")
            }
        }
    }

    
    func sendSelection(playerID: Int) {
        let response: [String: Any] = [
            "response_type": "player_selection",
            "player_id": playerID
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: response),
           let text = String(data: data, encoding: .utf8) {
            
            webSocketTask?.send(.string(text)) { error in
                if let error = error {
                    print("Send error: \(error)")
                } else {
                    print("Successfully sent selection for player \(playerID)")
                }
            }
        } else {
            print("Failed to encode")
        }
    }
    
    func sendReassignmentSelection(playerID: Int) {
        let response: [String: Any] = [
            "response_type": "reassignment_selection",
            "player_id": playerID
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: response),
           let text = String(data: data, encoding: .utf8) {
            
            webSocketTask?.send(.string(text)) { error in
                if let error = error {
                    print("Send error: \(error)")
                } else {
                    print("Successfully sent reassignment selection for player \(playerID)")
                }
            }
        } else {
            print("Failed to encode")
        }
    }
    
    func sendConfirmationSelection() {
        let response: [String: Any] = [
            "response_type": "confirmation",
            "confirmed": true
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: response),
           let text = String(data: data, encoding: .utf8) {
            
            webSocketTask?.send(.string(text)) { error in
                if let error = error {
                    print("Send error: \(error)")
                } else {
                    print("Successfully sent reassignment selection for player")
                }
            }
        } else {
            print("Failed to encode")
        }
    }
    
    // exporting the clip for slicing at result screen
    func exportClip(from videoURL: URL, startTime: CMTime, endTime: CMTime, completion: @escaping (URL?) -> Void) {
        let asset = AVAsset(url: videoURL)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            completion(nil)
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = timeRange
        
        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                completion(outputURL)
            } else {
                print("Export failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
}

