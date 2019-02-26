//
// Created by Matthias Neubert on 2019-02-26.
// Copyright (c) 2019 LongGames. All rights reserved.
//

import Foundation

struct UserInfoKeys {

    static let soundName = "soundName"
    static let index = "index"
    static let snoozeEnabled = "snoozeEnabled"
    static let repeating = "repeating"
}

class UserInfo {

    var userInfoDictionary: [AnyHashable: Any]

    var isSnoozeEnabled: Bool {
        get {
            if let value = self.userInfoDictionary[UserInfoKeys.snoozeEnabled] as? Bool {
                return value
            }
            return false
        }
        set {
            self.userInfoDictionary[UserInfoKeys.snoozeEnabled] = newValue
        }
    }

    var soundName: String {
        get {
            if let value = self.userInfoDictionary[UserInfoKeys.soundName] as? String {
                return value
            }
            return ""
        }
        set {
            self.userInfoDictionary[UserInfoKeys.soundName] = newValue
        }
    }

    var index: Int {
        get {
            if let value = self.userInfoDictionary[UserInfoKeys.index] as? Int {
                return value
            }
            return -1
        }
        set {
            self.userInfoDictionary[UserInfoKeys.index] = newValue
        }
    }

    var repeating: Bool {
        get {
            if let value = self.userInfoDictionary[UserInfoKeys.repeating] as? Bool {
                return value
            }
            return false
        }
        set {
            self.userInfoDictionary[UserInfoKeys.repeating] = newValue
        }
    }

    init(userInfo: [AnyHashable: Any]) {
        self.userInfoDictionary = userInfo
    }

    init() {
        self.userInfoDictionary = [AnyHashable: Any]()
    }
}
