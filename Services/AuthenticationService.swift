//
//  AuthenticationService.swift
//  Ascendr
//
//  Firebase Authentication service
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthenticationService: ObservableObject {
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    init() {
        auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.fetchUserData(userId: user.uid)
                self?.isAuthenticated = true
            } else {
                self?.currentUser = nil
                self?.isAuthenticated = false
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }
    
    func signUp(email: String, password: String, username: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        let user = User(id: result.user.uid, email: email, username: username)
        
        try await db.collection("users").document(user.id).setData(from: user)
        self.currentUser = user
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    private func fetchUserData(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let snapshot = snapshot, error == nil else { return }
            
            do {
                self?.currentUser = try snapshot.data(as: User.self)
            } catch {
                print("Error decoding user: \(error)")
            }
        }
    }
}

