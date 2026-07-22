//
//  LocalPhotoStorage.swift
//  Ascendr
//
//  Local photo storage service for progress photos
//

import Foundation
import UIKit

class LocalPhotoStorage {
    static let shared = LocalPhotoStorage()
    
    private let photosDirectory: URL
    private var imageCache: [String: UIImage] = [:]
    private var timestampCache: [String: Date] = [:]
    
    private init() {
        // Create directory in app's documents folder
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        photosDirectory = documentsPath.appendingPathComponent("ProgressPhotos", isDirectory: true)
        
        // Create directory if it doesn't exist
        createDirectoryIfNeeded()
        loadCache()
    }
    
    private func loadCache() {
        // Pre-load all images and timestamps into memory for instant access
        guard let files = try? FileManager.default.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        
        let filenames = files
            .filter { $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "jpeg" }
            .map { $0.lastPathComponent }
            .sorted { $0 > $1 } // Sort newest first
        
        for filename in filenames {
            if let image = loadPhotoFromDisk(filename: filename) {
                imageCache[filename] = image
            }
            if let timestamp = getPhotoTimestamp(filename: filename) {
                timestampCache[filename] = timestamp
            }
        }
    }
    
    private func createDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: photosDirectory.path) {
            try? FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }
    }
    
    // Save photo to local storage
    func savePhoto(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        // Generate unique filename with timestamp
        let timestamp = Date()
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = photosDirectory.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            
            // Save timestamp
            let timestampData = timestamp.timeIntervalSince1970
            let timestampURL = photosDirectory.appendingPathComponent("\(filename).timestamp")
            try String(timestampData).write(to: timestampURL, atomically: true, encoding: .utf8)
            
            // Cache image and timestamp in memory
            imageCache[filename] = image
            timestampCache[filename] = timestamp
            
            return filename
        } catch {
            print("Error saving photo: \(error)")
            return nil
        }
    }
    
    private func loadPhotoFromDisk(filename: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        guard let imageData = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    func getPhotoTimestamp(filename: String) -> Date? {
        // Check cache first
        if let cachedTimestamp = timestampCache[filename] {
            return cachedTimestamp
        }
        
        // Load from disk
        let timestampURL = photosDirectory.appendingPathComponent("\(filename).timestamp")
        guard let timestampString = try? String(contentsOf: timestampURL),
              let timestampValue = Double(timestampString) else {
            // If no timestamp file, use file modification date
            let fileURL = photosDirectory.appendingPathComponent(filename)
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let modDate = attributes[.modificationDate] as? Date {
                timestampCache[filename] = modDate
                return modDate
            }
            return Date() // Fallback to current date
        }
        
        let timestamp = Date(timeIntervalSince1970: timestampValue)
        timestampCache[filename] = timestamp
        return timestamp
    }
    
    // Load photo from local storage (uses cache for instant access)
    func loadPhoto(filename: String) -> UIImage? {
        // Check cache first for instant access
        if let cachedImage = imageCache[filename] {
            return cachedImage
        }
        
        // Load from disk if not in cache
        if let image = loadPhotoFromDisk(filename: filename) {
            imageCache[filename] = image
            return image
        }
        
        return nil
    }
    
    // Get all photo filenames
    func getAllPhotoFilenames() -> [String] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return files
            .filter { $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "jpeg" }
            .map { $0.lastPathComponent }
            .sorted { $0 > $1 } // Sort newest first
    }
    
    // Delete photo
    func deletePhoto(filename: String) -> Bool {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        let timestampURL = photosDirectory.appendingPathComponent("\(filename).timestamp")
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            // Also delete timestamp file if it exists
            if FileManager.default.fileExists(atPath: timestampURL.path) {
                try? FileManager.default.removeItem(at: timestampURL)
            }
            
            // Remove from cache
            imageCache.removeValue(forKey: filename)
            timestampCache.removeValue(forKey: filename)
            
            return true
        } catch {
            print("Error deleting photo: \(error)")
            return false
        }
    }
    
    // Refresh cache (call after adding new photos)
    func refreshCache() {
        imageCache.removeAll()
        timestampCache.removeAll()
        loadCache()
    }
    
    // Get photo count
    func getPhotoCount() -> Int {
        return getAllPhotoFilenames().count
    }
    
    // Get file URL for a photo (for sharing or other uses)
    func getPhotoURL(filename: String) -> URL? {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
}

