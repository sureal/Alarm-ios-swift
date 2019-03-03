//
//  AlarmModelController.swift
//  Alarm-ios-swift
//
//  Created by longyutao on 15-2-28.
//  Updated on 17-01-24
//  Copyright (c) 2015年 LongGames. All rights reserved.
//

import Foundation
import MediaPlayer

class AlarmModelController {

    let userDefaults: UserDefaults = UserDefaults.standard

    var alarms: [Alarm] = [] {
        //observer, sync with UserDefaults
        didSet {
            storeToUserDefaults()
        }
    }

    var alarmCount: Int {
        return alarms.count
    }

    init() {
        sync()
    }

    func sync() {
        alarms = loadAlarmsFromUserDefaults()
    }

    func storeToUserDefaults() {

        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self.alarms)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                print("Cannot convert alarms array to string")
                return
            }

            userDefaults.set(jsonString, forKey: Identifier.Persistence.alarmListPersistKey)
            userDefaults.synchronize()

        } catch {
            print("Cannot convert alarm array to string")
        }
    }

    private func deleteAlarmsFromUserDefaults() {
        for key in userDefaults.dictionaryRepresentation().keys {
            UserDefaults.standard.removeObject(forKey: key.description)
        }
    }

    private func loadAlarmsFromUserDefaults() -> [Alarm] {

        let jsonString = UserDefaults.standard.string(forKey: Identifier.Persistence.alarmListPersistKey)
        guard let json = jsonString else {
            print("No alarms found in User Defaults")
            return []
        }

        guard let jsonData = json.data(using: .utf8) else {
            print("Cannot create json data from json string")
            deleteAlarmsFromUserDefaults()
            return []
        }
        let decoder = JSONDecoder()

        do {
            let alarmArray: [Alarm] = try decoder.decode([Alarm].self, from: jsonData)
            return alarmArray
        } catch {
            print("Cannot decode Alarm Array from jsonData")
        }

        deleteAlarmsFromUserDefaults()
        return []
    }
}
