
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
            #if DEBUG
            print("❌ Failed to save password in Keychain: \(error)")
            #endif
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
            #if DEBUG
            print("❌ Failed to load password from Keychain: \(error)")
            #endif
        }
        return nil
    }

    /// Clears any stored credentials from `UserDefaults` and Keychain.
    func clear() {
        if let email = UserDefaults.standard.string(forKey: emailKey) {
            do {
                try KeychainHelper.delete(forEmail: email)
            } catch {
                #if DEBUG
                print("❌ Failed to delete password from Keychain: \(error)")
                #endif
            }
        }
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: passwordKey)
    }
}

