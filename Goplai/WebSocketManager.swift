//
//  WebSocketManager.swift
//  Goplai
//
//  Created by Akshat Kishore on 8/19/25.
//

import Foundation

class WebSocketManager: ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    
    @Published var players: [Player] = []
    @Published var frameURL: String? = nil
    @Published var frameBase64: String? = nil
    
    func connect(sessionID: String) {
        guard let url = URL(string: "ws://your-server:8000/ws/\(sessionID)") else { return }
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
                            if msg.type == "user_input_required",
                               let data = msg.data {
                                self?.players = data.available_players ?? []
                                self?.frameURL = data.frame_url
                                self?.frameBase64 = data.frame_base64
                            }
                        }
                    } catch {
                        print("Decode error: \(error)")
                    }
                }
                self?.listen() // keep listening
            case .failure(let error):
                print("WebSocket error: \(error)")
            }
        }
    }
    
    func sendSelection(playerID: Int) {
        let response = [
            "response_type": "player_selection",
            "player_id": playerID
        ] as [String : Any]
        if let data = try? JSONSerialization.data(withJSONObject: response),
           let text = String(data: data, encoding: .utf8) {
            webSocketTask?.send(.string(text)) { error in
                if let error = error { print("Send error: \(error)") }
            }
        }
    }
}
