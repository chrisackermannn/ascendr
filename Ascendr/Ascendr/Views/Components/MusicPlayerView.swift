//
//  MusicPlayerView.swift
//  Ascendr
//
//  Liquid glass music player with Spotify integration
//

import SwiftUI
import SpotifyiOS
import Combine
import AVFoundation
import MediaPlayer
import UIKit

struct MusicPlayerView: View {
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var spotifyManager = SpotifyManager.shared
    @StateObject private var musicState = MusicState()
    @State private var showingConnectionAlert = false
    @State private var connectionAlertMessage = ""
    
    var body: some View {
        liquidGlassMusicPlayer
            .onAppear {
                musicState.startUpdating()
                musicState.onConnectionFailed = { [weak musicState] message in
                    connectionAlertMessage = message
                    showingConnectionAlert = true
                }
            }
            .onDisappear {
                musicState.stopUpdating()
            }
            .alert("Spotify Connection", isPresented: $showingConnectionAlert) {
                Button("Authorize in Spotify") {
                    spotifyManager.authorize()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(connectionAlertMessage)
            }
            .onChange(of: spotifyManager.isConnected) { isConnected in
                if isConnected {
                    // Connection successful, start updating
                    musicState.updatePlayerState()
                }
            }
    }
    
    private var liquidGlassMusicPlayer: some View {
        HStack(spacing: 16) {
            // Album Artwork (larger)
            albumArtworkView
            
            // Track Info & Controls (centered and organized)
            VStack(alignment: .center, spacing: 12) {
                trackInfoView
                controlsView
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            // Liquid Glass Effect
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
    
    private var albumArtworkView: some View {
        Group {
            if let artwork = musicState.currentArtwork {
                Image(uiImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    appSettings.accentColor.opacity(0.3),
                                    appSettings.accentColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "music.note")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(appSettings.accentColor.opacity(0.6))
                }
            }
        }
        .frame(width: 90, height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
    
    private var trackInfoView: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(musicState.currentTitle ?? "Not Playing")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(appSettings.primaryText)
                .lineLimit(1)
                .multilineTextAlignment(.center)
            
            Text(musicState.currentArtist ?? (spotifyManager.isAuthorized ? "Connect to Spotify" : "Tap to connect"))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(appSettings.primaryText.opacity(0.7))
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
    }
    
    private var controlsView: some View {
        HStack(spacing: 20) {
            // Previous Button
            Button(action: {
                musicState.skipToPrevious()
            }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(appSettings.primaryText)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            
            // Play/Pause Button (larger, centered)
            Button(action: {
                musicState.togglePlayPause()
            }) {
                Image(systemName: musicState.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(appSettings.primaryText)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        appSettings.accentColor.opacity(0.4),
                                        appSettings.accentColor.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                    )
                    .shadow(color: appSettings.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            // Next Button
            Button(action: {
                musicState.skipToNext()
            }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(appSettings.primaryText)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
        }
    }
    
    private var volumeSliderView: some View {
        VStack(spacing: 4) {
            // Volume up icon
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(appSettings.primaryText.opacity(0.7))
            
            // Vertical slider with visible track
            VolumeSliderView(
                volume: Binding(
                    get: { musicState.currentVolume },
                    set: { musicState.setVolume($0) }
                )
            )
            .frame(width: 24, height: 70)
            
            // Volume down icon
            Image(systemName: "speaker.wave.1.fill")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(appSettings.primaryText.opacity(0.7))
        }
    }
    
    private var addToLikedButton: some View {
        Button(action: {
            musicState.addToLikedSongs()
        }) {
            Image(systemName: musicState.isLiked ? "heart.fill" : "plus")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(musicState.isLiked ? .red : appSettings.primaryText)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    musicState.isLiked ? Color.red.opacity(0.3) : Color.white.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                )
        }
        .disabled(!spotifyManager.isConnected)
        .opacity(spotifyManager.isConnected ? 1.0 : 0.5)
    }
}

// MARK: - Volume Slider View

struct VolumeSliderView: UIViewRepresentable {
    @Binding var volume: Float
    
    func makeUIView(context: Context) -> VerticalVolumeSlider {
        let slider = VerticalVolumeSlider()
        slider.setupVolumeControl()
        slider.onVolumeChanged = { newVolume in
            self.volume = newVolume
        }
        return slider
    }
    
    func updateUIView(_ uiView: VerticalVolumeSlider, context: Context) {
        uiView.updateVolume(volume)
    }
}

class VerticalVolumeSlider: UIView {
    private var systemSlider: UISlider?
    private var customSlider: UISlider?
    private var trackView: UIView?
    var onVolumeChanged: ((Float) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupVolumeControl() {
        // Create hidden MPVolumeView to access system volume slider
        let volumeView = MPVolumeView(frame: .zero)
        volumeView.showsVolumeSlider = true
        volumeView.showsRouteButton = false
        volumeView.isHidden = true
        
        // Add to window to make it functional
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(volumeView)
            
            // Find the system volume slider and get current volume
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let systemSlider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
                    self.systemSlider = systemSlider
                    // Get current volume first
                    let currentVolume = systemSlider.value
                    self.onVolumeChanged?(currentVolume)
                    self.createCustomSlider()
                }
            }
        }
    }
    
    private func createCustomSlider() {
        guard let systemSlider = systemSlider else { return }
        
        // Create visible track background
        let trackBackground = UIView()
        trackBackground.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.3)
        trackBackground.layer.cornerRadius = 2
        addSubview(trackBackground)
        trackBackground.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            trackBackground.centerXAnchor.constraint(equalTo: centerXAnchor),
            trackBackground.centerYAnchor.constraint(equalTo: centerYAnchor),
            trackBackground.widthAnchor.constraint(equalToConstant: 3),
            trackBackground.heightAnchor.constraint(equalTo: heightAnchor, constant: -8)
        ])
        trackView = trackBackground
        
        // Create custom vertical slider
        let slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.value = systemSlider.value // Set to current system volume
        
        // Rotate to vertical
        slider.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        
        // Style the slider with visible track
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .clear // Make max track transparent so our custom track shows
        slider.thumbTintColor = .systemBlue
        
        // Make the track thicker and more visible
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            slider.centerXAnchor.constraint(equalTo: centerXAnchor),
            slider.centerYAnchor.constraint(equalTo: centerYAnchor),
            slider.widthAnchor.constraint(equalTo: heightAnchor),
            slider.heightAnchor.constraint(equalTo: widthAnchor)
        ])
        
        customSlider = slider
        
        // Update track fill based on current volume
        updateTrackFill(volume: systemSlider.value)
        
        // Listen for system volume changes
        systemSlider.addTarget(self, action: #selector(systemVolumeChanged(_:)), for: .valueChanged)
    }
    
    private func updateTrackFill(volume: Float) {
        guard let trackView = trackView else { return }
        
        // Remove existing fill view
        trackView.subviews.forEach { $0.removeFromSuperview() }
        
        // Create fill view based on volume
        let fillHeight = trackView.bounds.height * CGFloat(volume)
        let fillView = UIView()
        fillView.backgroundColor = .systemBlue
        fillView.layer.cornerRadius = 2
        trackView.addSubview(fillView)
        fillView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            fillView.centerXAnchor.constraint(equalTo: trackView.centerXAnchor),
            fillView.widthAnchor.constraint(equalTo: trackView.widthAnchor),
            fillView.heightAnchor.constraint(equalToConstant: fillHeight)
        ])
    }
    
    @objc private func sliderValueChanged(_ sender: UISlider) {
        systemSlider?.setValue(sender.value, animated: false)
        updateTrackFill(volume: sender.value)
        onVolumeChanged?(sender.value)
    }
    
    @objc private func systemVolumeChanged(_ sender: UISlider) {
        customSlider?.setValue(sender.value, animated: true)
        updateTrackFill(volume: sender.value)
        onVolumeChanged?(sender.value)
    }
    
    func updateVolume(_ volume: Float) {
        customSlider?.setValue(volume, animated: true)
        updateTrackFill(volume: volume)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let slider = customSlider {
            updateTrackFill(volume: slider.value)
        }
    }
}

// MARK: - Music State Manager

@MainActor
class MusicState: ObservableObject {
    @Published var currentTitle: String?
    @Published var currentArtist: String?
    @Published var currentArtwork: UIImage?
    @Published var isPlaying: Bool = false
    @Published var currentVolume: Float = 0.5
    @Published var isLiked: Bool = false
    @Published var currentTrackURI: String?
    
    private let spotifyManager = SpotifyManager.shared
    private var updateTimer: Timer?
    private var volumeView: MPVolumeView?
    private var volumeSlider: UISlider?
    var onConnectionFailed: ((String) -> Void)?
    
    private func getVolumeSlider() -> UISlider? {
        // Create MPVolumeView to access the system volume slider
        let volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
        volumeView.showsVolumeSlider = true
        volumeView.showsRouteButton = false
        
        // Add to window temporarily to make it functional
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(volumeView)
            
            // Find the volume slider after a brief delay to ensure it's initialized
            var slider: UISlider?
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
                volumeView.removeFromSuperview()
            }
            
            // Try to get slider immediately
            if let foundSlider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
                return foundSlider
            }
            
            // Return slider from async if found
            return slider
        }
        
        // Fallback: try to find slider without adding to window
        return volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
    }
    
    func startUpdating() {
        // Don't auto-connect on startup - let user control when to connect via controls
        // This prevents connection attempts when Spotify might not be ready
        
        // Listen for player state changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SpotifyPlayerStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let playerState = notification.object as? SPTAppRemotePlayerState {
                self?.updateFromPlayerState(playerState)
            }
        }
        
        // Listen for connection failures
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SpotifyConnectionFailed"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let message = notification.userInfo?["message"] as? String {
                self?.onConnectionFailed?(message)
            }
        }
        
        // Update periodically only if connected
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, self.spotifyManager.isConnected else { return }
            self.updatePlayerState()
        }
        
        // Try initial update if already connected
        if spotifyManager.isConnected {
            updatePlayerState()
        }
    }
    
    func updatePlayerState() {
        guard spotifyManager.isConnected else { return }
        
        spotifyManager.getPlayerState { [weak self] playerState, error in
            if let playerState = playerState {
                self?.updateFromPlayerState(playerState)
            }
        }
    }
    
    func stopUpdating() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    
    private func updateFromPlayerState(_ playerState: SPTAppRemotePlayerState) {
        currentTitle = playerState.track.name
        currentArtist = playerState.track.artist.name
        isPlaying = !playerState.isPaused
        currentTrackURI = playerState.track.uri
        
        // Update volume from system
        updateSystemVolume()
        
        // Check if track is liked
        if let trackURI = currentTrackURI {
            spotifyManager.checkIfLiked(trackURI: trackURI) { [weak self] isLiked in
                DispatchQueue.main.async {
                    self?.isLiked = isLiked ?? false
                }
            }
        }
        
        // Fetch artwork
        spotifyManager.fetchArtwork(from: playerState.track) { [weak self] image in
            DispatchQueue.main.async {
                self?.currentArtwork = image
            }
        }
    }
    
    private func updateSystemVolume() {
        if volumeSlider == nil {
            setupVolumeSlider()
        }
        if let slider = volumeSlider {
            currentVolume = slider.value
        }
    }
    
    private func setupVolumeSlider() {
        if volumeView == nil {
            volumeView = MPVolumeView(frame: .zero)
            volumeView?.showsVolumeSlider = true
            volumeView?.showsRouteButton = false
            volumeView?.isHidden = true
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.addSubview(volumeView!)
                
                // Get current volume after a brief delay to ensure slider is initialized
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else { return }
                    if let slider = self.volumeView?.subviews.first(where: { $0 is UISlider }) as? UISlider {
                        self.volumeSlider = slider
                        self.currentVolume = slider.value
                        slider.addTarget(self, action: #selector(self.volumeChanged), for: .valueChanged)
                    }
                }
            }
        } else {
            // If volumeView already exists, try to get slider immediately
            volumeSlider = volumeView?.subviews.first(where: { $0 is UISlider }) as? UISlider
            
            // Listen for volume changes
            volumeSlider?.addTarget(self, action: #selector(volumeChanged), for: .valueChanged)
            
            if let slider = volumeSlider {
                currentVolume = slider.value
            }
        }
    }
    
    @objc private func volumeChanged() {
        if let slider = volumeSlider {
            currentVolume = slider.value
        }
    }
    
    func setVolume(_ volume: Float) {
        setupVolumeSlider()
        volumeSlider?.setValue(volume, animated: false)
        currentVolume = volume
    }
    
    func addToLikedSongs() {
        guard let trackURI = currentTrackURI else { return }
        
        if isLiked {
            // Remove from liked songs
            spotifyManager.removeFromLikedSongs(trackURI: trackURI) { [weak self] success in
                DispatchQueue.main.async {
                    if success {
                        self?.isLiked = false
                    }
                }
            }
        } else {
            // Add to liked songs
            spotifyManager.addToLikedSongs(trackURI: trackURI) { [weak self] success in
                DispatchQueue.main.async {
                    if success {
                        self?.isLiked = true
                    }
                }
            }
        }
    }
    
    func skipToNext() {
        // First check authorization
        if !spotifyManager.isAuthorized {
            print("Spotify: Not authorized, opening Spotify for authorization...")
            spotifyManager.authorize()
            return
        }
        
        // Then check connection
        if !spotifyManager.isConnected {
            print("Spotify: Not connected, attempting to connect...")
            print("Spotify: Make sure Spotify app is open and music is playing")
            spotifyManager.connect()
            // Retry after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self = self, self.spotifyManager.isConnected else { return }
                self.spotifyManager.skipToNext { success, _ in
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.updatePlayerState()
                        }
                    }
                }
            }
            return
        }
        
        spotifyManager.skipToNext { [weak self] success, _ in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.updatePlayerState()
                }
            }
        }
    }
    
    func skipToPrevious() {
        // First check authorization
        if !spotifyManager.isAuthorized {
            print("Spotify: Not authorized, opening Spotify for authorization...")
            spotifyManager.authorize()
            return
        }
        
        // Then check connection
        if !spotifyManager.isConnected {
            print("Spotify: Not connected, attempting to connect...")
            print("Spotify: Make sure Spotify app is open and music is playing")
            spotifyManager.connect()
            // Retry after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self = self, self.spotifyManager.isConnected else { return }
                self.spotifyManager.skipToPrevious { success, _ in
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.updatePlayerState()
                        }
                    }
                }
            }
            return
        }
        
        spotifyManager.skipToPrevious { [weak self] success, _ in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.updatePlayerState()
                }
            }
        }
    }
    
    func togglePlayPause() {
        // First check authorization
        if !spotifyManager.isAuthorized {
            print("Spotify: Not authorized, opening Spotify for authorization...")
            spotifyManager.authorize()
            return
        }
        
        // Then check connection
        if !spotifyManager.isConnected {
            print("Spotify: Not connected, attempting to connect...")
            print("Spotify: Make sure Spotify app is open and music is playing")
            spotifyManager.connect()
            // Retry after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self = self, self.spotifyManager.isConnected else { return }
                if self.isPlaying {
                    self.spotifyManager.pause { success, _ in
                        if success {
                            self.isPlaying = false
                        }
                    }
                } else {
                    self.spotifyManager.resume { success, _ in
                        if success {
                            self.isPlaying = true
                        }
                    }
                }
            }
            return
        }
        
        if isPlaying {
            spotifyManager.pause { [weak self] success, _ in
                if success {
                    self?.isPlaying = false
                }
            }
        } else {
            spotifyManager.resume { [weak self] success, _ in
                if success {
                    self?.isPlaying = true
                }
            }
        }
    }
    
}

