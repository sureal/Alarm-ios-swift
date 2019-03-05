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

    var alarmModelController: AlarmModelController!

    init(alarmModelController: AlarmModelController) {
        self.alarmModelController = alarmModelController

        self.setupNotificationCategories()
    }

    func setupNotificationCategories() {

        // Specify the notification actions.
        let stopAction = UNNotificationAction(
                identifier: Identifier.NotificationAction.stop,
                title: "OK",
                options: [])

        let snoozeAction = UNNotificationAction(
                identifier: Identifier.NotificationAction.snooze,
                title: "Snooze",
                options: [])

        // create categories
        let snoozeNotificationCategory = UNNotificationCategory(
                identifier: Identifier.NotificationCategory.snooze,
                actions: [stopAction, snoozeAction],
                intentIdentifiers: [],
                options: [.customDismissAction])

        let noSnoozeNotificationCategory = UNNotificationCategory(
                identifier: Identifier.NotificationCategory.noSnooze,
                actions: [stopAction, snoozeAction],
                intentIdentifiers: [],
                options: [.customDismissAction])
        //TODO: clarify alarmCategory.minimalActions = notificationActions

        UNUserNotificationCenter.current().getNotificationCategories { existingCategories in

            for existingCategory in existingCategories {
                print("Category found: \(existingCategory)")
            }

            // let the notification center know about the not. categories
            let notificationCategories: Set = [snoozeNotificationCategory, noSnoozeNotificationCategory]
            UNUserNotificationCenter.current().setNotificationCategories(notificationCategories)
        }
    }

    func requestNotificationAuthorization(authorisationGranted: @escaping (Bool) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
            if !granted {
                print("User denied Local Notification Authorization rights")
                if let error = error {
                    print("Error: \(error)")
                }

                // TODO: show alert view explaining why it sucks to have no permissions,
                // pressing OK, ask again, pressing cancel accept the result, which is
                // OK as we will ask again on next creation atempt

                authorisationGranted(false)

            } else {
                authorisationGranted(true)
            }
        }
    }

    private func correctDate(_ date: Date, onWeekdaysForNotify weekdays: [Int]) -> [Date] {

        var correctedDates: [Date] = [Date]()
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let now = Date()
        let componentsToExtract: Set<Calendar.Component> = [.weekday, .weekdayOrdinal, .day]
        let dateComponents = calendar.dateComponents(componentsToExtract, from: date)
        guard let weekdayOfDate: Int = dateComponents.weekday else {
            return correctedDates
        }

        //no repeat
        if weekdays.isEmpty {
            //scheduling date is earlier than current date
            if date < now {
                //plus one day, otherwise the notification will be fired righton
                correctedDates.append(date.toSomeDaysLaterDate(daysToAdd: 1))
            } else { //later
                correctedDates.append(date)
            }
            return correctedDates
        }
        //repeat
        else {
            let daysInWeek = 7
            correctedDates.removeAll(keepingCapacity: true)
            for currentWeekday in weekdays {

                var dateOfWeekday: Date
                //schedule on next week
                if compare(weekday: currentWeekday, with: weekdayOfDate) == .before {
                    dateOfWeekday = date.toSomeDaysLaterDate(daysToAdd: currentWeekday + daysInWeek - weekdayOfDate)
                }
                //schedule on today or next week
                else if compare(weekday: currentWeekday, with: weekdayOfDate) == .same {
                    //scheduling date is earlier than current date, then schedule on next week
                    if date.compare(now) == ComparisonResult.orderedAscending {
                        dateOfWeekday = date.toSomeDaysLaterDate(daysToAdd: daysInWeek)
                    } else { //later
                        dateOfWeekday = date
                    }
                }
                //schedule on next days of this week
                else { //after
                    dateOfWeekday = date.toSomeDaysLaterDate(daysToAdd: currentWeekday - weekdayOfDate)
                }

                //fix second component to 0
                dateOfWeekday = dateOfWeekday.toSecondsRoundedDate()
                correctedDates.append(dateOfWeekday)
            }
            return correctedDates
        }
    }

    func createNotification(forAlarm alarm: Alarm, alarmIndex: Int) {

        requestNotificationAuthorization { granted in

            if !granted {
                print("ERROR: Cannot create notification without user's permission")
                return
            }

            let content = self.createNotificationContent(alarm: alarm, alarmIndex: alarmIndex)

            //repeat weekly if repeat weekdays are selected
            //no repeat with snooze notification
            //if !weekdays.isEmpty && !onSnooze{
            //  AlarmNotification.repeatInterval = NSCalendar.Unit.weekOfYear
            //}

            let datesForNotification = self.correctDate(alarm.alertDate, onWeekdaysForNotify: alarm.repeatAtWeekdays)

            // ???
            self.alarmModelController.sync()

            var notificationRequests = [UNNotificationRequest]()

            for notificationDate in datesForNotification {
                
                let alarmNotificationRequest = self.createNotificationRequest(
                        alarm: alarm,
                        alarmIndex: alarmIndex,
                        notificationDate: notificationDate,
                        content: content)

                notificationRequests.append(alarmNotificationRequest)
            }

            for notificationRequest in notificationRequests {
                UNUserNotificationCenter.current().add(notificationRequest) { (error) in

                    if let error = error {
                        print("Unable to Add Notification Request: \(error)")
                    }
                }
            }
        }
    }

    private func createNotificationRequest(alarm: Alarm,
                                           alarmIndex: Int,
                                           notificationDate: Date,
                                           content: UNMutableNotificationContent) -> UNNotificationRequest {

        // TODO: better understand this part
        if alarm.onSnooze {
            let originalDate = alarmModelController.alarms[alarmIndex].alertDate
            alarmModelController.alarms[alarmIndex].alertDate = originalDate.toSecondsRoundedDate()
        } else {
            alarmModelController.alarms[alarmIndex].alertDate = notificationDate
        }

        let isRepeating = !alarm.repeatAtWeekdays.isEmpty
        let notificationDateTrigger = createNotificationTrigger(
            notificationDate: notificationDate,
            isRepeating: isRepeating)

        let alarmNotificationRequest = UNNotificationRequest(
                identifier: "NotificationRequest_\(notificationDate.timeIntervalSince1970)",
                content: content,
                trigger: notificationDateTrigger)

        return alarmNotificationRequest
    }

    private func createNotificationTrigger(notificationDate: Date, isRepeating: Bool) -> UNCalendarNotificationTrigger {

        let notificationDateComponents = Calendar.current.dateComponents(in: TimeZone.current, from: notificationDate)

        let notificationDateTrigger = UNCalendarNotificationTrigger(
                dateMatching: notificationDateComponents,
                repeats: isRepeating)
        return notificationDateTrigger
    }

    private func createNotificationContent(alarm: Alarm, alarmIndex: Int) -> UNMutableNotificationContent {

        let content = UNMutableNotificationContent()
        content.title = "A TITLE TODO Replace"
        content.body = "Wake Up!"
        // TODO: think about criticalSound
        content.sound = UNNotificationSound(named: UNNotificationSoundName(alarm.mediaLabel + ".mp3"))
        if alarm.snoozeEnabled {
            content.categoryIdentifier = Identifier.NotificationCategory.snooze
        } else {
            content.categoryIdentifier = Identifier.NotificationCategory.noSnooze
        }

        let userInfo = UserInfo()
        userInfo.index = alarmIndex
        userInfo.soundName = alarm.mediaLabel
        userInfo.isSnoozeEnabled = alarm.snoozeEnabled
        let repeating: Bool = !alarm.repeatAtWeekdays.isEmpty
        userInfo.repeating = repeating

        // add user info to content
        content.userInfo = userInfo.userInfoDictionary

        return content
    }

    func setNotificationForSnooze(snoozeForMinutes: Int, soundName: String, index: Int) {

        let now = Date()
        let snoozeTime = now.toSomeMinutesLaterDate(minutesToAdd: snoozeForMinutes)

        var snoozeAlarm = Alarm()
        snoozeAlarm.alertDate = snoozeTime
        snoozeAlarm.repeatAtWeekdays = [Int]()
        snoozeAlarm.snoozeEnabled = true
        snoozeAlarm.onSnooze = true
        snoozeAlarm.mediaLabel = soundName

        createNotification(forAlarm: snoozeAlarm, alarmIndex: index)
    }

    func recreateNotificationsFromDataModel() {
        //cancel all and register all is often more convenient
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        self.alarmModelController.sync()

        for alarmIndex in 0..<alarmModelController.alarmCount {
            var alarm = alarmModelController.alarms[alarmIndex]
            if alarm.enabled {
                // TODO: check what is intended here
                alarm.onSnooze = false

                createNotification(forAlarm: alarm, alarmIndex: alarmIndex)
            }
        }
    }

    // workaround for some situation that alarm model is not setting properly (when app on background or not launched)
    func checkNotification() {

        self.alarmModelController.sync()

        UNUserNotificationCenter.current().getPendingNotificationRequests { (pendingNotifications) in

            if pendingNotifications.isEmpty {
                for alarmIndex in 0..<self.alarmModelController.alarmCount {
                    self.alarmModelController.alarms[alarmIndex].enabled = false
                }
            } else {
                for (alarmIndex, alarm) in self.alarmModelController.alarms.enumerated() {
                    var isOutDated = true
                    if alarm.onSnooze {
                        isOutDated = false
                    }
                    for notification in pendingNotifications {
                        if let trigger = notification.trigger as? UNCalendarNotificationTrigger {

                            if let nextFireDate = trigger.nextTriggerDate() {
                                if alarm.alertDate >= nextFireDate {
                                    isOutDated = false
                                }
                            }
                        }

                    }
                    if isOutDated {
                        self.alarmModelController.alarms[alarmIndex].enabled = false
                    }
                }
            }
        }
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
}
