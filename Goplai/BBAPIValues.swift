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
    let input_type: String?
    let frame_num: Int?
    let frame_total: Int?
    let fps: Double?
    let message: String?
    let data: UserInputData?
    let summary: Summary? //summary at completed
}


struct UserInputData: Codable {
    let available_players: [Player]?
    let suggestions: [Player]?
    let frame_url: String?
    let frame_base64: String?
    
    let current_bbox: [Double]?
    var rect: CGRect {
        guard current_bbox?.count == 4 else { return .zero }
        let x1 = current_bbox?[0], y1 = current_bbox?[1], x2 = current_bbox?[2], y2 = current_bbox?[3]
        return CGRect(x: x1 ?? 0, y: y1 ?? 0, width: (x2 ?? 0) - (x1 ?? 0), height: (y2 ?? 0) - (y1 ?? 0))
    }
}

struct Summary: Codable {
    let highlights: [Highlight]?
    let tracked_player_highlights: Int
}


struct Highlight: Codable {
    let interval: [Int]
    let start_time: Double
    let end_time: Double
    let duration: Double
    let possessions: [String: Int]
    let winner: Winner
    let tracked_player_won: Bool
}

struct Winner: Codable {
    let player_id: Int
    let frames: Int
}

struct Player: Codable, Identifiable, Equatable {
    let id: Int
    let bbox: [Double] // [x1, y1, x2, y2]
    let center: [Double]?
    let confidence: Double
    
    var rect: CGRect {
        guard bbox.count == 4 else { return .zero }
        let x1 = bbox[0], y1 = bbox[1], x2 = bbox[2], y2 = bbox[3]
        return CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1)
    }
}
