//
//  APIService.swift
//  Goplai
//
//  Created by Akshat Kishore on 8/19/25.
//
import Foundation

class APIService {
    static let baseURL = "http://3.15.204.107:8000"
    
    // presigned URL
    static func getUploadURL(filename: String, completion: @escaping (Result<UploadResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/upload-url?filename=\(filename)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { return }
            
            do {
                let response = try JSONDecoder().decode(UploadResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // upload  to S3
    static func uploadToS3(uploadResponse: UploadResponse, videoURL: URL, completion: @escaping (Bool) -> Void) {
        guard let uploadURL = URL(string: uploadResponse.upload_url) else { return }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
        request.setValue(uploadResponse.metadata["original-filename"], forHTTPHeaderField: "x-amz-meta-original-filename")
        request.setValue(uploadResponse.metadata["session-id"], forHTTPHeaderField: "x-amz-meta-session-id")
        request.setValue(uploadResponse.metadata["upload-timestamp"], forHTTPHeaderField: "x-amz-meta-upload-timestamp")
        
        do {
            let videoData = try Data(contentsOf: videoURL)
            URLSession.shared.uploadTask(with: request, from: videoData) { _, response, error in
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    completion(true)
                } else {
                    completion(false)
                }
            }.resume()
        } catch {
            completion(false)
        }
    }
    
    // processing
    static func startProcessing(sessionID: String, s3Key: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/sessions/\(sessionID)/start") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["s3_key": s3Key]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
}
