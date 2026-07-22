//
//  SpotifyManager.swift
//  Ascendr
//
//  Spotify iOS SDK integration
//

import Foundation
import SpotifyiOS
import Combine

@MainActor
class SpotifyManager: NSObject, ObservableObject {
    static let shared = SpotifyManager()
    
    @Published var isConnected = false
    @Published var isAuthorized = false
    
    private var appRemote: SPTAppRemote?
    private var accessToken: String? {
        didSet {
            if let token = accessToken {
                UserDefaults.standard.set(token, forKey: "SpotifyAccessToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "SpotifyAccessToken")
            }
        }
    }
    
    private let clientID = "6d3e64c52a324fe99918e0f9836df792"
    private let redirectURI = URL(string: "ascendr://spotify-callback")!
    
    private override init() {
        super.init()
        loadSavedToken()
        setupAppRemote()
    }
    
    private func loadSavedToken() {
        if let savedToken = UserDefaults.standard.string(forKey: "SpotifyAccessToken"), !savedToken.isEmpty {
            accessToken = savedToken
            isAuthorized = UserDefaults.standard.bool(forKey: "SpotifyIsAuthorized")
        }
    }
    
    private func setupAppRemote() {
        let configuration = SPTConfiguration(
            clientID: clientID,
            redirectURL: redirectURI
        )
        
        appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote?.delegate = self
    }
    
    // MARK: - Public Methods
    
    func authorize() {
        guard let appRemote = appRemote else { return }
        
        print("Spotify: Opening Spotify app for authorization...")
        appRemote.authorizeAndPlayURI("") { [weak self] spotifyInstalled in
            DispatchQueue.main.async {
                if !spotifyInstalled {
                    print("Spotify: Spotify app is not installed")
                } else {
                    print("Spotify: Authorization flow started")
                }
            }
        }
    }
    
    func connect() {
        guard let appRemote = appRemote else {
            print("Spotify: AppRemote not initialized")
            return
        }
        
        if isConnected {
            print("Spotify: Already connected")
            return
        }
        
        guard let token = accessToken, !token.isEmpty else {
            print("Spotify: No access token - need to authorize first")
            authorize()
            return
        }
        
        // Set token and delegate
        appRemote.connectionParameters.accessToken = token
        appRemote.delegate = self
        
        print("Spotify: Attempting to connect...")
        print("Spotify: ⚠️ Make sure Spotify app is OPEN and music is PLAYING")
        appRemote.connect()
    }
    
    func disconnect() {
        appRemote?.disconnect()
        isConnected = false
    }
    
    func handleAuthorizationCallback(url: URL) {
        guard let appRemote = appRemote else { return }
        
        let parameters = appRemote.authorizationParameters(from: url)
        
        if let token = parameters?[SPTAppRemoteAccessTokenKey] as? String {
            print("Spotify: ✅ Authorization successful")
            accessToken = token
            appRemote.connectionParameters.accessToken = token
            isAuthorized = true
            UserDefaults.standard.set(true, forKey: "SpotifyIsAuthorized")
            
            // Don't auto-connect after authorization - let user control when to connect
            // Connection will happen when they use controls and Spotify is ready
            print("Spotify: Authorization complete. Use controls to connect when Spotify is playing.")
        } else if let error = parameters?[SPTAppRemoteErrorDescriptionKey] as? String {
            print("Spotify: ❌ Authorization error: \(error)")
            isAuthorized = false
            UserDefaults.standard.set(false, forKey: "SpotifyIsAuthorized")
        }
    }
    
    // MARK: - Playback Controls
    
    func skipToNext(completion: @escaping (Bool, Error?) -> Void) {
        guard let appRemote = appRemote, isConnected else {
            completion(false, NSError(domain: "SpotifyManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not connected"]))
            return
        }
        
        appRemote.playerAPI?.skip(toNext: { result, error in
            DispatchQueue.main.async {
                completion(error == nil, error)
            }
        })
    }
    
    func skipToPrevious(completion: @escaping (Bool, Error?) -> Void) {
        guard let appRemote = appRemote, isConnected else {
            completion(false, NSError(domain: "SpotifyManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not connected"]))
            return
        }
        
        appRemote.playerAPI?.skip(toPrevious: { result, error in
            DispatchQueue.main.async {
                completion(error == nil, error)
            }
        })
    }
    
    func pause(completion: @escaping (Bool, Error?) -> Void) {
        guard let appRemote = appRemote, isConnected else {
            completion(false, NSError(domain: "SpotifyManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not connected"]))
            return
        }
        
        appRemote.playerAPI?.pause { result, error in
            DispatchQueue.main.async {
                completion(error == nil, error)
            }
        }
    }
    
    func resume(completion: @escaping (Bool, Error?) -> Void) {
        guard let appRemote = appRemote, isConnected else {
            completion(false, NSError(domain: "SpotifyManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not connected"]))
            return
        }
        
        appRemote.playerAPI?.resume { result, error in
            DispatchQueue.main.async {
                completion(error == nil, error)
            }
        }
    }
    
    func getPlayerState(completion: @escaping (SPTAppRemotePlayerState?, Error?) -> Void) {
        guard let appRemote = appRemote, isConnected else {
            completion(nil, NSError(domain: "SpotifyManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not connected"]))
            return
        }
        
        appRemote.playerAPI?.getPlayerState { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, error)
                } else if let playerState = result as? SPTAppRemotePlayerState {
                    completion(playerState, nil)
                } else {
                    completion(nil, NSError(domain: "SpotifyManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid player state"]))
                }
            }
        }
    }
    
    // MARK: - Liked Songs
    
    func addToLikedSongs(trackURI: String, completion: @escaping (Bool) -> Void) {
        guard isConnected, let token = accessToken else {
            completion(false)
            return
        }
        
        // Extract track ID from URI (format: spotify:track:TRACK_ID)
        guard trackURI.hasPrefix("spotify:track:") else {
            completion(false)
            return
        }
        
        let trackID = String(trackURI.dropFirst("spotify:track:".count))
        let urlString = "https://api.spotify.com/v1/me/tracks?ids=\(trackID)"
        
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    completion(httpResponse.statusCode == 200 || httpResponse.statusCode == 201)
                } else {
                    completion(error == nil)
                }
            }
        }.resume()
    }
    
    func removeFromLikedSongs(trackURI: String, completion: @escaping (Bool) -> Void) {
        guard isConnected, let token = accessToken else {
            completion(false)
            return
        }
        
        // Extract track ID from URI
        guard trackURI.hasPrefix("spotify:track:") else {
            completion(false)
            return
        }
        
        let trackID = String(trackURI.dropFirst("spotify:track:".count))
        let urlString = "https://api.spotify.com/v1/me/tracks?ids=\(trackID)"
        
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    completion(httpResponse.statusCode == 200)
                } else {
                    completion(error == nil)
                }
            }
        }.resume()
    }
    
    func checkIfLiked(trackURI: String, completion: @escaping (Bool?) -> Void) {
        guard isConnected, let token = accessToken else {
            completion(nil)
            return
        }
        
        // Extract track ID from URI
        guard trackURI.hasPrefix("spotify:track:") else {
            completion(nil)
            return
        }
        
        let trackID = String(trackURI.dropFirst("spotify:track:".count))
        let urlString = "https://api.spotify.com/v1/me/tracks/contains?ids=\(trackID)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Spotify: Error checking if liked: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [Bool],
                      let isLiked = json.first else {
                    completion(nil)
                    return
                }
                
                completion(isLiked)
            }
        }.resume()
    }
    
    // MARK: - Artwork
    
    func fetchArtwork(from track: SPTAppRemoteTrack, completion: @escaping (UIImage?) -> Void) {
        guard isConnected, let token = accessToken else {
            completion(nil)
            return
        }
        
        let album = track.album
        let albumURI = album.uri
        
        guard albumURI.hasPrefix("spotify:album:") else {
            completion(nil)
            return
        }
        
        let albumID = String(albumURI.dropFirst("spotify:album:".count))
        let urlString = "https://api.spotify.com/v1/albums/\(albumID)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Spotify: Error fetching album: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let images = json["images"] as? [[String: Any]],
                  let firstImage = images.first,
                  let imageURLString = firstImage["url"] as? String,
                  let imageURL = URL(string: imageURLString) else {
                completion(nil)
                return
            }
            
            URLSession.shared.dataTask(with: imageURL) { imageData, _, _ in
                DispatchQueue.main.async {
                    if let imageData = imageData, let image = UIImage(data: imageData) {
                        completion(image)
                    } else {
                        completion(nil)
                    }
                }
            }.resume()
        }.resume()
    }
    
    // MARK: - Player State Subscription
    
    private func subscribeToPlayerState() {
        guard let appRemote = appRemote, isConnected else { return }
        
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { [weak self] result, error in
            if let error = error {
                print("Spotify: Subscription error: \(error.localizedDescription)")
            } else {
                print("Spotify: Subscribed to player state")
                self?.getPlayerState { playerState, _ in
                    if let playerState = playerState {
                        NotificationCenter.default.post(name: NSNotification.Name("SpotifyPlayerStateChanged"), object: playerState)
                    }
                }
            }
        })
    }
}

// MARK: - SPTAppRemoteDelegate

extension SpotifyManager: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("Spotify: ✅ Connection established!")
        isConnected = true
        isAuthorized = true
        UserDefaults.standard.set(true, forKey: "SpotifyIsAuthorized")
        subscribeToPlayerState()
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        let errorDescription = error?.localizedDescription ?? "Unknown error"
        print("Spotify: ❌ Connection failed: \(errorDescription)")
        isConnected = false
        
        // Post notification for connection failure
        var message = "Unable to connect to Spotify."
        if errorDescription.contains("Connection refused") || errorDescription.contains("Stream error") {
            message = "Please authorize in Spotify app. Make sure Spotify is open and music is playing, then authorize the connection."
        } else if errorDescription.contains("unauthorized") || errorDescription.contains("401") {
            message = "Authorization expired. Please authorize again in Spotify."
            accessToken = nil
            isAuthorized = false
            UserDefaults.standard.set(false, forKey: "SpotifyIsAuthorized")
        }
        
        NotificationCenter.default.post(
            name: NSNotification.Name("SpotifyConnectionFailed"),
            object: nil,
            userInfo: ["message": message]
        )
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("Spotify: Disconnected")
        isConnected = false
    }
}

// MARK: - SPTAppRemotePlayerStateDelegate

extension SpotifyManager: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        NotificationCenter.default.post(name: NSNotification.Name("SpotifyPlayerStateChanged"), object: playerState)
    }
}

