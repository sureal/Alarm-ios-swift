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

class AlarmModelController: AlarmObserver {

    let userDefaults: UserDefaults = UserDefaults.standard

    let alarmScheduler: AlarmScheduler!
    let notificationReceiver: NotificationReceiver!

    private var alarms: [Alarm]!

    var alarmCount: Int {
        return alarms.count
    }

    init() {
        self.alarmScheduler = AlarmScheduler()
        self.notificationReceiver = NotificationReceiver()
        self.alarmScheduler.timerElapsedDelegate = self.notificationReceiver

        self.alarms = loadAlarmsFromUserDefaults()
        self.alarmScheduler.alarmModelController = self
        self.notificationReceiver.alarmModelController = self

        observeAlarms()
    }

    func getAlarmAtTableIndex(index: Int) -> Alarm? {

        for alarm in alarms where alarm.indexInTable == index {
                return alarm
        }
        return nil
    }

    func addAlarm(alarm: Alarm) {

        alarm.indexInTable = alarms.endIndex
        alarms.append(alarm)
        persist()

        observeAlarms()

        self.alarmScheduler.recreateNotificationsFromDataModel()
    }

    func removeAlarm(alarm: Alarm) {
        self.removeAlarmAtIndex(index: alarm.indexInTable)
    }

    func removeAlarmAtIndex(index: Int) {
        if index >= 0 && index < self.alarmCount {
            alarms.remove(at: index)
        }
        correctAlarmIndices()
        persist()
        self.alarmScheduler.recreateNotificationsFromDataModel()
    }

    func alarmChanged(alarm: Alarm) {
        print("Alarm changed")
        persist()
    }

    private func correctAlarmIndices() {
        for alarmIndex in 0..<alarmCount {
            let alarm = self.alarms[alarmIndex]
            alarm.indexInTable = alarmIndex
        }
    }

    func disableAllAlarms() {

        for alarmIndex in 0..<alarmCount {
            if let alarm = getAlarmAtTableIndex(index: alarmIndex) {
                alarm.enabled = false
            }
        }
    }

    private func observeAlarms() {
        self.alarms.forEach { alarm in
            alarm.observer = self
        }
    }

    private func persist() {

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

    private func deleteAllAlarmsFromUserDefaults() {
        for key in userDefaults.dictionaryRepresentation().keys {
            userDefaults.removeObject(forKey: key.description)
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
            deleteAllAlarmsFromUserDefaults()
            return []
        }
        let decoder = JSONDecoder()

        do {
            let alarmArray: [Alarm] = try decoder.decode([Alarm].self, from: jsonData)
            return alarmArray
        } catch {
            print("Cannot decode Alarm Array from jsonData")
        }

        deleteAllAlarmsFromUserDefaults()
        return []
    }
}
