//
//  AlarmScheduler.swift
//  Alarm-ios-swift
//
//  Created by longyutao on 16/1/15.
//  Copyright (c) 2016年 LongGames. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

class AlarmScheduler {
    var alarmModel: AlarmModel = AlarmModel()

    func setupNotificationSettings() {
        var snoozeEnabled: Bool = false
        UNUserNotificationCenter.current().getPendingNotificationRequests { (pendingNotificationRequests) in

            if let result = self.minFireDateWithIndex(notificationRequests: pendingNotificationRequests) {
                let index = result.1
                snoozeEnabled = self.alarmModel.alarms[index].snoozeEnabled
            }
        }

        // Specify the notification actions.
        let stopAction = UNNotificationAction(
                identifier: AlarmAppIdentifiers.stopIdentifier,
                title: "OK",
                options: [])
        //stopAction.activationMode = UIUserNotificationActivationMode.background
        //stopAction.isDestructive = false
        //stopAction.isAuthenticationRequired = false

        let snoozeAction = UNNotificationAction(
                identifier: AlarmAppIdentifiers.snoozeIdentifier,
                title: "Snooze",
                options: [])
        //snoozeAction.activationMode = UIUserNotificationActivationMode.background
        //snoozeAction.isDestructive = false
        //snoozeAction.isAuthenticationRequired = false
        
        // Specify the category related to the above actions.
        var notificationActions = [UNNotificationAction]()
        if snoozeEnabled {
            notificationActions.append(snoozeAction)
        }
        notificationActions.append(stopAction)

        let alarmCategory = UNNotificationCategory(identifier: AlarmAppIdentifiers.alarmCategoryIdentifier,
                actions: notificationActions,
                intentIdentifiers: [],
                options: [.customDismissAction])

        //alarmCategory.minimalActions = notificationActions

        let notificationCategories = Set(arrayLiteral: alarmCategory)
        UNUserNotificationCenter.current().setNotificationCategories(notificationCategories)

        let options: UNAuthorizationOptions = [.alert, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
            if !granted {
                print("User denied Local Notification Authoriyation request")
                if let error = error {
                    print("Error: \(error)")
                }
            }
        }
    }

    private func correctDate(_ date: Date, onWeekdaysForNotify weekdays: [Int]) -> [Date] {

        var correctedDate: [Date] = [Date]()
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let now = Date()
        let flags: NSCalendar.Unit = [NSCalendar.Unit.weekday, NSCalendar.Unit.weekdayOrdinal, NSCalendar.Unit.day]
        let dateComponents = (calendar as NSCalendar).components(flags, from: date)
        let weekdayOfDate: Int = dateComponents.weekday!

        //no repeat
        if weekdays.isEmpty {
            //scheduling date is earlier than current date
            if date < now {
                //plus one day, otherwise the notification will be fired righton
                correctedDate.append((calendar as NSCalendar).date(
                        byAdding: NSCalendar.Unit.day,
                        value: 1,
                        to: date,
                        options: .matchStrictly)!)
            } else { //later
                correctedDate.append(date)
            }
            return correctedDate
        }
        //repeat
        else {
            let daysInWeek = 7
            correctedDate.removeAll(keepingCapacity: true)
            for currentWeekday in weekdays {

                var dateOfWeekday: Date!
                //schedule on next week
                if compare(weekday: currentWeekday, with: weekdayOfDate) == .before {
                    dateOfWeekday = (calendar as NSCalendar).date(
                            byAdding: NSCalendar.Unit.day,
                            value: currentWeekday + daysInWeek - weekdayOfDate,
                            to: date,
                            options: .matchStrictly)!
                }
                //schedule on today or next week
                else if compare(weekday: currentWeekday, with: weekdayOfDate) == .same {
                    //scheduling date is eariler than current date, then schedule on next week
                    if date.compare(now) == ComparisonResult.orderedAscending {
                        dateOfWeekday = (calendar as NSCalendar).date(
                                byAdding: NSCalendar.Unit.day,
                                value: daysInWeek,
                                to: date,
                                options: .matchStrictly)!
                    } else { //later
                        dateOfWeekday = date
                    }
                }
                //schedule on next days of this week
                else { //after
                    dateOfWeekday = (calendar as NSCalendar).date(
                            byAdding: NSCalendar.Unit.day,
                            value: currentWeekday - weekdayOfDate,
                            to: date,
                            options: .matchStrictly)!
                }

                //fix second component to 0
                dateOfWeekday = AlarmScheduler.correctSecondComponent(date: dateOfWeekday, calendar: calendar)
                correctedDate.append(dateOfWeekday)
            }
            return correctedDate
        }
    }

    public static func correctSecondComponent(
            date: Date,
            calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian)) -> Date {

        let second = calendar.component(.second, from: date)
        let correctedDate = (calendar as NSCalendar).date(
                byAdding: NSCalendar.Unit.second,
                value: -second,
                to: date,
                options: .matchStrictly)!
        return correctedDate
    }

    internal func setNotificationWithDate(_ date: Date, onWeekdaysForNotify weekdays: [Int], snoozeEnabled: Bool,
                                          onSnooze: Bool, soundName: String, index: Int) {

        let repeating: Bool = !weekdays.isEmpty

        let content = UNMutableNotificationContent()
        content.title = "A TITLE TODO Replace"
        content.body = "Wake Up!"
        // TODO: think about criticalSound
        content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName + ".mp3"))
        content.categoryIdentifier = AlarmAppIdentifiers.alarmCategoryIdentifier
        content.userInfo = ["snooze": snoozeEnabled, "index": index, "soundName": soundName, "repeating": repeating]
        
        //AlarmNotification.alertAction = "Open App"
        //AlarmNotification.timeZone = TimeZone.current
        
        //repeat weekly if repeat weekdays are selected
        //no repeat with snooze notification
        //if !weekdays.isEmpty && !onSnooze{
        //  AlarmNotification.repeatInterval = NSCalendar.Unit.weekOfYear
        //}

        let datesForNotification = correctDate(date, onWeekdaysForNotify: weekdays)

        // ???
        syncAlarmModel()

        for notificationDate in datesForNotification {
            if onSnooze {
                alarmModel.alarms[index].date = AlarmScheduler.correctSecondComponent(date: alarmModel.alarms[index].date)
            } else {
                alarmModel.alarms[index].date = notificationDate
            }

            let notificationDateComponents = Calendar.current.dateComponents(
                    in: TimeZone.current,
                    from: notificationDate)
            let notificationDateTrigger = UNCalendarNotificationTrigger(
                    dateMatching: notificationDateComponents,
                    repeats: repeating)
            let alarmNotificationRequest = UNNotificationRequest(
                    identifier: AlarmAppIdentifiers.alarmCategoryIdentifier,
                    content: content,
                    trigger: notificationDateTrigger)

            UNUserNotificationCenter.current().add(alarmNotificationRequest) { (error) in

                if let error = error {
                    print("Unable to Add Notification Request: \(error)")
                }
            }
        }
        setupNotificationSettings()
    }

    func setNotificationForSnooze(snoozeMinute: Int, soundName: String, index: Int) {
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let now = Date()
        let snoozeTime = (calendar as NSCalendar).date(
                byAdding: NSCalendar.Unit.minute,
                value: snoozeMinute,
                to: now,
                options: .matchStrictly)!

        setNotificationWithDate(snoozeTime,
                onWeekdaysForNotify: [Int](),
                snoozeEnabled: true,
                onSnooze: true,
                soundName: soundName,
                index: index)
    }

    func reSchedule() {
        //cancel all and register all is often more convenient
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        syncAlarmModel()
        for alarmIndex in 0..<alarmModel.alarmCount {
            let alarm = alarmModel.alarms[alarmIndex]
            if alarm.enabled {
                setNotificationWithDate(alarm.date as Date,
                        onWeekdaysForNotify: alarm.repeatWeekdays,
                        snoozeEnabled: alarm.snoozeEnabled,
                        onSnooze: false,
                        soundName: alarm.mediaLabel,
                        index: alarmIndex)
            }
        }
    }

    // workaround for some situation that alarm model is not setting properly (when app on background or not launched)
    func checkNotification() {
        syncAlarmModel()

        UNUserNotificationCenter.current().getPendingNotificationRequests { (pendingNotifications) in

            if pendingNotifications.isEmpty {
                for alarmIndex in 0..<self.alarmModel.alarmCount {
                    self.alarmModel.alarms[alarmIndex].enabled = false
                }
            } else {
                for (alarmIndex, alarm) in self.alarmModel.alarms.enumerated() {
                    var isOutDated = true
                    if alarm.onSnooze {
                        isOutDated = false
                    }
                    for notification in pendingNotifications {
                        if let trigger = notification.trigger as? UNCalendarNotificationTrigger {

                            if let nextFireDate = trigger.nextTriggerDate() {
                                if alarm.date >= nextFireDate {
                                    isOutDated = false
                                }
                            }
                        }

                    }
                    if isOutDated {
                        self.alarmModel.alarms[alarmIndex].enabled = false
                    }
                }
            }
        }
    }

    private func syncAlarmModel() {
        alarmModel = AlarmModel()
    }

    private enum WeekdayComparisonResult {
        case before
        case same
        case after
    }

    private func compare(weekday: Int, with otherWeekday: Int) -> WeekdayComparisonResult {
        if weekday != 1 && otherWeekday == 1 {
            return .before
        } else if weekday == otherWeekday {
            return .same
        } else {
            return .after
        }
    }

    private func minFireDateWithIndex(notificationRequests: [UNNotificationRequest]) -> (Date, Int)? {

        var minIndex = -1

        guard let firstNotification = notificationRequests.first else {
            return nil
        }

        guard let firstTrigger = firstNotification.trigger as? UNCalendarNotificationTrigger else {
            return nil
        }

        guard var minDate = firstTrigger.nextTriggerDate() else {
            return nil
        }

        for notification in notificationRequests {

            guard let trigger = notification.trigger as? UNCalendarNotificationTrigger else {
                return nil
            }

            if let index = notification.content.userInfo["index"] as? Int {

                guard let nextTriggerDate = trigger.nextTriggerDate() else {
                    return nil
                }

                if nextTriggerDate <= minDate {
                    minDate = nextTriggerDate
                    minIndex = index
                }
            }

        }
        return (minDate, minIndex)
    }
}
