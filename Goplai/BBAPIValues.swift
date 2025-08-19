//
//  BBAPIValues.swift
//  Goplai
//
//  Created by Akshat Kishore on 8/19/25.
//

//
//  BBAPIValues.swift
//  Goplai
//
//  Created by Akshat Kishore on 8/19/25.
//

import Foundation
import CoreGraphics

struct WebSocketMessage: Codable {
    let type: String
    let frame_num: Int?
    let frame_total: Int?
    let fps: Double?
    let message: String?
    let data: UserInputData?
}

struct UserInputData: Codable {
    let available_players: [Player]?
    let frame_url: String?        // 🔥 backend can send image URL
    let frame_base64: String?     // 🔥 OR base64 encoded frame
}

struct Player: Codable, Identifiable {
    let id: Int
    let bbox: [CGFloat] // [x1, y1, x2, y2]
    let center: [CGFloat]
    let confidence: Double
    
    var rect: CGRect {
        guard bbox.count == 4 else { return .zero }
        let x1 = bbox[0], y1 = bbox[1], x2 = bbox[2], y2 = bbox[3]
        return CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
    }
}
