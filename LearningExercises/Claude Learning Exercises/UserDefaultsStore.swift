// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public enum StorageError: Error {
    case encodingFailed(underlying: Error)
    case decodingFailed(underlying: Error)
}

public final class UserDefaultsStore {
    
    private let standard: UserDefaults
    public init(standard: UserDefaults) { self.standard = standard }
    
    @discardableResult
    public func save<T: Codable>(_ value: T, forKey key: String) throws -> String? {
        do {
            let data = try JSONEncoder().encode(value)
            standard.set(data, forKey: key)
            return String(data: data, encoding: .utf8)
        } catch {
            throw StorageError.encodingFailed(underlying: error)
        }
    }

    public func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        do {
            guard let data = standard.data(forKey: key) else { return nil }
            let object = try JSONDecoder().decode(T.self, from: data)
            return object
        } catch {
            throw StorageError.decodingFailed(underlying: error)
        }
    }
    
    public func delete(forKey key: String) {
        standard.removeObject(forKey: key)
    }

    public func exists(forKey key: String) -> Bool {
        standard.object(forKey: key) != nil
    }
}

public struct User: Codable, Equatable {
    public let id: UUID
    public let name: String
    public let email: String
    public let createdAt: Date
    public let preferences: Preferences
    
    public init(id: UUID, name: String, email: String, createdAt: Date, preferences: Preferences) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = createdAt
        self.preferences = preferences
    }
    
    public struct Preferences: Codable, Equatable {
        public let isDarkMode: Bool
        public let notificationsEnabled: Bool
        
        public init(isDarkMode: Bool, notificationsEnabled: Bool) {
            self.isDarkMode = isDarkMode
            self.notificationsEnabled = notificationsEnabled
        }
    }
    
    public static var none: User {
        User(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, name: "none", email: "none", createdAt: Date(timeIntervalSince1970: 0), preferences: Preferences(isDarkMode: false, notificationsEnabled: false))
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name = "full_name"
        case email = "electronic_mail"
        case createdAt
        case preferences
    }
    
}

@propertyWrapper public struct UserDefault<T: Codable> {
    private let key: String
    private let store: UserDefaultsStore
    private var defaultValue: T

    public init(_ key: String, store: UserDefaultsStore, defaultValue: T) {
        self.key = key
        self.store = store
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        set {
            do { try store.save(newValue, forKey: key) }
            catch { assertionFailure(error.localizedDescription) }
        }
        get {
            do {
                return try store.load(T.self, forKey: key) ?? defaultValue
            } catch {
                print(error)
                return defaultValue
            }
        }
    }
}

