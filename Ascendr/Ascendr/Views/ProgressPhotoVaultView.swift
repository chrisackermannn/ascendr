//
//  ProgressPhotoVaultView.swift
//  Ascendr
//
//  Local progress photo vault view
//

import SwiftUI

struct ProgressPhotoVaultView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.dismiss) var dismiss
    @State private var photos: [String] = []
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingImageSourcePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedPhoto: String?
    @State private var showingFullScreen = false
    
    private let photoStorage = LocalPhotoStorage.shared
    
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("Progress Photos")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingImageSourcePicker = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                }
                .confirmationDialog("Add Photo", isPresented: $showingImageSourcePicker, titleVisibility: .visible) {
                    cameraButton
                    photoLibraryButton
                    Button("Cancel", role: .cancel) {}
                }
                .sheet(isPresented: $showingImagePicker) {
                    VaultImagePicker(image: $selectedImage, sourceType: imagePickerSourceType)
                }
                .fullScreenCover(isPresented: $showingFullScreen) {
                    FullScreenPhotoViewContainer(
                        selectedPhoto: selectedPhoto,
                        photoStorage: photoStorage,
                        onDelete: {
                            if let selectedPhoto = selectedPhoto {
                                photoStorage.deletePhoto(filename: selectedPhoto)
                                photoStorage.refreshCache()
                                loadPhotos()
                                showingFullScreen = false
                            }
                        },
                        onDismiss: {
                            showingFullScreen = false
                        }
                    )
                    .environmentObject(appSettings)
                }
                .onAppear {
                    photoStorage.refreshCache()
                    loadPhotos()
                }
                .onChange(of: selectedImage) { oldValue, newValue in
                    handleImageSelection(newValue)
                }
        }
    }
    
    private var contentView: some View {
        ZStack {
            appSettings.primaryBackground
                .ignoresSafeArea()
            
            if photos.isEmpty {
                emptyStateView
            } else {
                photoGridView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(appSettings.primaryText.opacity(0.3))
            
            Text("No Progress Photos")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(appSettings.primaryText)
            
            Text("Start tracking your fitness journey")
                .font(.subheadline)
                .foregroundColor(appSettings.primaryText.opacity(0.7))
            
            Button(action: {
                showingImageSourcePicker = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Photo")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(appSettings.buttonGradient)
                .cornerRadius(12)
            }
        }
    }
    
    private var photoGridView: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    ForEach(photos, id: \.self) { filename in
                        photoGridItem(filename: filename)
                    }
                }
                .padding(12)
            }
            
            localStorageNotice
        }
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }
    
    private func photoGridItem(filename: String) -> some View {
        Group {
            if let image = photoStorage.loadPhoto(filename: filename) {
                Button(action: {
                    selectedPhoto = filename
                    showingFullScreen = true
                }) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: photoItemSize, height: photoItemSize)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(appSettings.accentColor.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var photoItemSize: CGFloat {
        (UIScreen.main.bounds.width - 48) / 3
    }
    
    private var localStorageNotice: some View {
        Text("All photos are stored locally on your iPhone")
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(appSettings.primaryText.opacity(0.6))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(appSettings.cardBackground.opacity(0.5))
    }
    
    @ViewBuilder
    private var cameraButton: some View {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            Button("Camera") {
                imagePickerSourceType = .camera
                showingImagePicker = true
            }
        }
    }
    
    private var photoLibraryButton: some View {
        Button("Photo Library") {
            imagePickerSourceType = .photoLibrary
            showingImagePicker = true
        }
    }
    
    private func handleImageSelection(_ image: UIImage?) {
        guard let image = image else { return }
        if let filename = photoStorage.savePhoto(image) {
            photoStorage.refreshCache()
            loadPhotos()
            selectedImage = nil
        }
    }
    
    private func loadPhotos() {
        photos = photoStorage.getAllPhotoFilenames()
    }
    
}

// MARK: - Vault Image Picker

struct VaultImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            picker.sourceType = .photoLibrary
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VaultImagePicker
        
        init(_ parent: VaultImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Full Screen Photo View Container

struct FullScreenPhotoViewContainer: View {
    let selectedPhoto: String?
    let photoStorage: LocalPhotoStorage
    let onDelete: () -> Void
    let onDismiss: () -> Void
    @EnvironmentObject var appSettings: AppSettings
    
    @ViewBuilder
    var body: some View {
        if let selectedPhoto = selectedPhoto,
           let image = photoStorage.loadPhoto(filename: selectedPhoto) {
            let timestamp = photoStorage.getPhotoTimestamp(filename: selectedPhoto) ?? Date()
            FullScreenPhotoView(
                image: image,
                filename: selectedPhoto,
                timestamp: timestamp,
                onDelete: onDelete,
                onDismiss: onDismiss
            )
        }
    }
}

// MARK: - Full Screen Photo View

struct FullScreenPhotoView: View {
    let image: UIImage
    let filename: String
    let timestamp: Date
    let onDelete: () -> Void
    let onDismiss: () -> Void
    @EnvironmentObject var appSettings: AppSettings
    @State private var showingDeleteConfirmation = false
    @State private var showingShareSheet = false
    
    init(image: UIImage, filename: String, timestamp: Date, onDelete: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.image = image
        self.filename = filename
        self.timestamp = timestamp
        self.onDelete = onDelete
        self.onDismiss = onDismiss
    }
    
    private var photoStorage = LocalPhotoStorage.shared
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()
            
            VStack {
                // Top bar with close button and timestamp
                HStack {
                    // Timestamp
                    VStack(alignment: .leading, spacing: 2) {
                        Text(timestamp, style: .date)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        Text(timestamp, style: .time)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            Capsule()
                                .fill(Color.black.opacity(0.5))
                            BlurView(style: .systemMaterialDark)
                                .clipShape(Capsule())
                        }
                    )
                    
                    Spacer()
                    
                    Button(action: {
                        onDismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }
                    .padding()
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Bottom bar with share and delete buttons
                HStack(spacing: 16) {
                    // Share button
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                    BlurView(style: .systemMaterialDark)
                                        .clipShape(Circle())
                                }
                            )
                    }
                    
                    // Delete button (smaller)
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.7))
                                    BlurView(style: .systemMaterialDark)
                                        .clipShape(Circle())
                                }
                            )
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [image])
        }
        .confirmationDialog("Delete Photo", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this photo?")
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Blur View

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
