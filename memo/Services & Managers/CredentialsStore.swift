//
//  CredentialsStore.swift
//  memo
//
//  Created by OpenAI Assistant on 2025-08-14.
//
//  This helper abstracts persistence of user credentials using
//  UserDefaults and the Keychain. It allows `SessionManager`
//  to focus solely on authentication logic.
//
import Foundation

struct CredentialsStore {
    private let emailKey = "memoAppUserEmail"
    private let passwordKey = "memoAppUserPassword"

    /// Saves the provided e-mail and password using `UserDefaults` and Keychain.
    func save(email: String, password: String) {
        UserDefaults.standard.set(email, forKey: emailKey)
        do {
            try KeychainHelper.save(password: password, forEmail: email)
        } catch {
            // In a production app we would log this error.
            print("❌ Failed to save password in Keychain: \(error)")
        }
    }

    /// Loads the stored e-mail and password pair if available.
    func load() -> (email: String, password: String)? {
        guard let email = UserDefaults.standard.string(forKey: emailKey) else {
            return nil
        }
        do {
            if let password = try KeychainHelper.load(forEmail: email) {
                return (email, password)
            }
        } catch {
            print("❌ Failed to load password from Keychain: \(error)")
        }
        return nil
    }

    /// Clears any stored credentials from `UserDefaults` and Keychain.
    func clear() {
        if let email = UserDefaults.standard.string(forKey: emailKey) {
            do {
                try KeychainHelper.delete(forEmail: email)
            } catch {
                print("❌ Failed to delete password from Keychain: \(error)")
            }
        }
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: passwordKey)
    }
}

