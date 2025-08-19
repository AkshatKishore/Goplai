//
//  ProcessedClip.swift
//  Goplai
//
//  Created by Akshat Kishore on 8/8/25.
//
import Foundation

struct ProcessedClip: Identifiable {
    let id = UUID()
    let url: URL
    let duration: Double
    let confidence: Double
}
