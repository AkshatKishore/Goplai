//
//  UploadResponse.swift
//  Goplai
//
//  Created by Akshat Kishore on 8/19/25.
//

import Foundation

struct UploadResponse: Codable {
    let session_id: String
    let upload_url: String
    let s3_key: String
    let metadata: [String: String]
}
