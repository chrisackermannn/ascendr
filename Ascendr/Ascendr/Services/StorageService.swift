//
//  StorageService.swift
//  Ascendr
//
//  Firebase Storage service for images
//

import Foundation
import UIKit
import FirebaseStorage

class StorageService {
    private let storage = Storage.storage()
    
    // Resize image to a maximum dimension while maintaining aspect ratio
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat = 800) -> UIImage {
        let size = image.size
        
        // If image is already smaller than max dimension, return as is
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension * (size.height / size.width))
        } else {
            newSize = CGSize(width: maxDimension * (size.width / size.height), height: maxDimension)
        }
        
        // Render resized image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    func uploadProfileImage(_ image: UIImage, userId: String) async throws -> String {
        // Resize image to max 800x800 to reduce file size and ensure compatibility
        let resizedImage = resizeImage(image, maxDimension: 800)
        
        // Compress image with quality 0.8 (good balance between quality and file size)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        // Check file size (max 5MB)
        let maxSize = 5 * 1024 * 1024 // 5MB
        if imageData.count > maxSize {
            // If still too large, compress more aggressively
            guard let compressedData = resizedImage.jpegData(compressionQuality: 0.5) else {
                throw NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
            }
            return try await uploadImageData(compressedData, userId: userId)
        }
        
        return try await uploadImageData(imageData, userId: userId)
    }
    
    private func uploadImageData(_ imageData: Data, userId: String) async throws -> String {
        let ref = storage.reference().child("profileImages/\(userId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload the image
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageMetadata, Error>) in
            ref.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    print("❌ Storage upload error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let metadata = metadata {
                    print("✅ Image uploaded successfully")
                    continuation.resume(returning: metadata)
                } else {
                    continuation.resume(throwing: NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                }
            }
        }
        
        // Get download URL
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            ref.downloadURL { url, error in
                if let error = error {
                    print("❌ Failed to get download URL: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let url = url {
                    print("✅ Download URL: \(url.absoluteString)")
                    continuation.resume(returning: url.absoluteString)
                } else {
                    continuation.resume(throwing: NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"]))
                }
            }
        }
    }
    
    func uploadProgressPic(_ image: UIImage, userId: String, postId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let ref = storage.reference().child("progressPics/\(userId)/\(postId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageMetadata, Error>) in
            ref.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let metadata = metadata {
                    continuation.resume(returning: metadata)
                } else {
                    continuation.resume(throwing: NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                }
            }
        }
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            ref.downloadURL { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url.absoluteString)
                } else {
                    continuation.resume(throwing: NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"]))
                }
            }
        }
    }
}

