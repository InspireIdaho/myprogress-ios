//  User.swift
//
//  Copyright © 2018 InspireIdaho under MIT License.

import Foundation

/**
 The User class represents the participant, once registered at the REST API service.
 This class maintains state as authenticated or not, and abstracts from local persistent storage -
 currently within the UserDefaults store - as well as, managing api interactions via DataBroker
 
 */
class User {
    
    /**
     Enum to consolidate keys used for UserDefaults access.
     */
    enum UserSettingsKeys: String {
        case email = "EmailAddress"
        case savePassword = "ShouldSavePassword"
        case password = "Password"
        case token = "X-Auth-Token"
    }
    
    // MARK: - Class-level properties/methods

    /// the single user of this app; optional as this will be nil upon first time app used
    /// actually user can only be *created* upon successful registration at server
    static var principle: User?
    
    /// class method, called at app launch to initialize/store principle user
    static func initAtLaunch() {
        // if data exists in UserDefaults, user will be created, if not, nil
        User.principle = User(store: UserDefaults.standard)
    }
    
    /// a delete function is needed if user ever needs to change (email is ID).
    /// in normal use, this should not be needed, but
    /// was needed for testing, so probably useful
    static func deletePrinciple() {
        if let user = principle {
            user.delete()
            principle = nil
        }
    }

    // MARK: - Instance properties
    
    /// private properties to impl read-only below
    private var _email: String
    private var _hasChanges: Bool

    /// read-only property, since once created, a new email == new user
    var email: String {
        get {
            return _email
        }
    }
    
    /// read-only property, as class manages prop changes
    var hasChanges: Bool {
        get {
            return _hasChanges
        }
    }
    
    /// password may exist in mem while using Login UI, but will only be persisted if user OKs.
    /// saves in clear text for now
    var password: String? {
        //TODO: implement basic obfuscation of password as stored in UserDefaults
        didSet {
            if shouldSavePassword {
                _hasChanges = true
            }
        }
    }
    
    /// users option to store password or not
    var shouldSavePassword: Bool = false {
        didSet {
            _hasChanges = true
        }
    }
    
    /// this will be nil if not logged in, will store x-auth token if logged in
    var token: String? {
        didSet {
            _hasChanges = true
        }
    }
    
    // MARK: - Instance initializers

    /**
     only intended to create new user with validated email (and password) from successful registration at server
     */
    init(email: String) {
        self._email = email
        self._hasChanges = false
    }
    
    /**
     this is so cool!  failable initializer, given a UserDefaults store.
     if User was never saved in store, will return nil; or if one was saved, presto
     - as you would expect
     */
    convenience init?(store: UserDefaults) {
        guard let email = store.string(forKey: UserSettingsKeys.email.rawValue)
            else { return nil }
        self.init(email: email)
        self.shouldSavePassword = store.bool(forKey: UserSettingsKeys.savePassword.rawValue)
        self.password = store.string(forKey: UserSettingsKeys.password.rawValue)
        self.token = store.string(forKey: UserSettingsKeys.token.rawValue)
        
        // need to clear, since just loaded from store
        self._hasChanges = false
    }
    
    // MARK: - Instance methods

    /// self-explanitory, encapsulates logic
    func isAuthenticated() -> Bool {
        return (token != nil)
    }
    
    /// saves user info to UserDefaults, so accessible across app launches
    func save() {
        // save to UserDefaults
        let store = UserDefaults.standard
        store.set(_email, forKey: UserSettingsKeys.email.rawValue)
        store.set(shouldSavePassword, forKey: UserSettingsKeys.savePassword.rawValue)
        if shouldSavePassword {
            store.set(password, forKey: UserSettingsKeys.password.rawValue)
        }
        store.set(token, forKey: UserSettingsKeys.token.rawValue)
        _hasChanges = false
    }
    
    /// removes user info from UserDefaults, needed for testing multiple users/logins
    /// but not expected to be a typical use case
    func delete() {
        // remover all info from UserDefaults
        let store = UserDefaults.standard
        store.removeObject(forKey: UserSettingsKeys.email.rawValue)
        store.removeObject(forKey: UserSettingsKeys.password.rawValue)
        store.removeObject(forKey: UserSettingsKeys.savePassword.rawValue)
        store.removeObject(forKey: UserSettingsKeys.token.rawValue)
    }
}
