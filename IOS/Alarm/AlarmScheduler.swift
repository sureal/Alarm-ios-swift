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

    weak var alarmModelController: AlarmModelController!

    var notificationRequestIds = [String]()

    init() {

        self.requestNotificationAuthorization { granted in
            self.setupNotificationCategories()
        }
    }

    private func setupNotificationCategories() {

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
                print("Existing Notification Category: \(existingCategory)")
            }
            // let the notification center know about the not. categories
            let notificationCategories: Set = [snoozeNotificationCategory, noSnoozeNotificationCategory]
            UNUserNotificationCenter.current().setNotificationCategories(notificationCategories)
        }
    }

    private func requestNotificationAuthorization(authorisationGranted: @escaping (Bool) -> Void) {

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
                print("Notification authorization granted by user")
                authorisationGranted(true)
            }
        }
    }

    private func createNotificationDates(forAlarm alarm: Alarm) -> [Date] {

        var notificationDates: [Date] = [Date]()
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let now = Date()


        //no repeat
        if alarm.repeatAtWeekdays.isEmpty {
            //scheduling date is earlier than current date
            if alarm.alertDate < now {
                //plus one day, otherwise the notification will be fired righton
                notificationDates.append(alarm.alertDate.toSomeDaysLaterDate(daysToAdd: 1))
            } else { //later
                notificationDates.append(alarm.alertDate)
            }
            return notificationDates
        }
        //repeat
        else {

            let componentsToExtract: Set<Calendar.Component> = [.weekday, .weekdayOrdinal, .day]
            let dateComponents = calendar.dateComponents(componentsToExtract, from: alarm.alertDate)
            guard let weekdayOfDate: Int = dateComponents.weekday else {
                return notificationDates
            }

            let daysInWeek = 7
            notificationDates.removeAll(keepingCapacity: true)
            for currentWeekday in alarm.repeatAtWeekdays {

                var dateOfWeekday: Date
                //schedule on next week
                if compare(weekday: currentWeekday, with: weekdayOfDate) == .before {
                    dateOfWeekday = alarm.alertDate.toSomeDaysLaterDate(daysToAdd: currentWeekday + daysInWeek - weekdayOfDate)
                }
                //schedule on today or next week
                else if compare(weekday: currentWeekday, with: weekdayOfDate) == .same {
                    //scheduling date is earlier than current date, then schedule on next week
                    if alarm.alertDate.compare(now) == ComparisonResult.orderedAscending {
                        dateOfWeekday = alarm.alertDate.toSomeDaysLaterDate(daysToAdd: daysInWeek)
                    } else { //later
                        dateOfWeekday = alarm.alertDate
                    }
                }
                //schedule on next days of this week
                else { //after
                    dateOfWeekday = alarm.alertDate.toSomeDaysLaterDate(daysToAdd: currentWeekday - weekdayOfDate)
                }

                //fix second component to 0
                dateOfWeekday = dateOfWeekday.toMinutesRoundedDate()
                notificationDates.append(dateOfWeekday)
            }
            return notificationDates
        }
    }

    private func addNotification(forAlarm alarm: Alarm) {

        requestNotificationAuthorization { granted in

            if !granted {
                print("ERROR: Cannot create notification without user's permission")
                return
            }

            let content = self.createNotificationContent(forAlarm: alarm)

            let datesForNotification = self.createNotificationDates(forAlarm: alarm)

            var notificationRequests = [UNNotificationRequest]()

            for notificationDate in datesForNotification {
                
                let alarmNotificationRequest = self.createNotificationRequest(
                        notificationDate: notificationDate,
                        isRepeating: !alarm.repeatAtWeekdays.isEmpty,
                        content: content)

                notificationRequests.append(alarmNotificationRequest)
            }

            for notificationRequest in notificationRequests {
                UNUserNotificationCenter.current().add(notificationRequest) { (error) in

                    if let error = error {
                        print("Unable to Add Notification Request: \(error)")
                    } else {
                        print("Created Notification Request: \(notificationRequest)")
                    }
                }
            }
        }
    }

    private func createNotificationRequest(notificationDate: Date,
                                           isRepeating: Bool,
                                           content: UNMutableNotificationContent) -> UNNotificationRequest {


        let notificationDateTrigger = createNotificationTrigger(
                notificationDate: notificationDate.toMinutesRoundedDate(),
                isRepeating: isRepeating)

        // Make them unique
        let identifier = "AlarmNotificationRequest_\(UUID().uuidString)"
        self.notificationRequestIds.append(identifier)
        let alarmNotificationRequest = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: notificationDateTrigger)

        return alarmNotificationRequest
    }

    private func createNotificationTrigger(notificationDate: Date, isRepeating: Bool) -> UNNotificationTrigger {

        //let testtrigger = UNTimeIntervalNotificationTrigger(timeInterval: 20, repeats: false)
        //return testtrigger
        var notificationDateComponents: DateComponents
        if !isRepeating {
            notificationDateComponents = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,], from: notificationDate)
        } else {
            notificationDateComponents = Calendar.current.dateComponents([.weekday, .hour, .minute, .second], from: notificationDate)
        }

        let notificationDateTrigger = UNCalendarNotificationTrigger(
                dateMatching: notificationDateComponents,
                repeats: isRepeating)
        return notificationDateTrigger
    }

    private func createNotificationContent(forAlarm alarm: Alarm) -> UNMutableNotificationContent {

        let content = UNMutableNotificationContent()
        content.title = "Alarm: \(alarm.alarmName)"
        content.body = "Wake Up!"
        // TODO: think about criticalSound
        content.sound = UNNotificationSound(named: UNNotificationSoundName(alarm.mediaLabel + ".mp3"))
        if alarm.snoozeEnabled {
            content.categoryIdentifier = Identifier.NotificationCategory.snooze
        } else {
            content.categoryIdentifier = Identifier.NotificationCategory.noSnooze
        }

        let userInfo = UserInfo()
        userInfo.index = alarm.indexInTable
        userInfo.soundName = alarm.mediaLabel
        userInfo.isSnoozeEnabled = alarm.snoozeEnabled
        let repeating: Bool = !alarm.repeatAtWeekdays.isEmpty
        userInfo.repeating = repeating

        // add user info to content
        content.userInfo = userInfo.userInfoDictionary

        return content
    }

    func scheduleSnoozeNotification(snoozeForMinutes: Int, soundName: String) {

        let now = Date()
        let snoozeTime = now.toSomeMinutesLaterDate(minutesToAdd: snoozeForMinutes).toMinutesRoundedDate()

        let snoozeAlarm = Alarm()
        snoozeAlarm.alertDate = snoozeTime
        snoozeAlarm.repeatAtWeekdays = [Int]()
        snoozeAlarm.snoozeEnabled = true
        snoozeAlarm.onSnooze = true
        snoozeAlarm.mediaLabel = soundName

        addNotification(forAlarm: snoozeAlarm)
    }

    func recreateNotificationsFromDataModel() {

        printNotificationSettings()

        printPendingNotificationRequests(context: "Before")

        //cancel all and register all is often more convenient
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: self.notificationRequestIds)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: self.notificationRequestIds)
        self.notificationRequestIds.removeAll()

        for alarmIndex in 0..<self.alarmModelController.alarmCount {
            if let alarm = self.alarmModelController.getAlarmAtTableIndex(index: alarmIndex) {

                if alarm.enabled {

                    alarm.onSnooze = false
                    self.addNotification(forAlarm: alarm)
                }
            }
        }

        printPendingNotificationRequests(context: "After")
    }

    private func printPendingNotificationRequests(context: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in

            let count = notificationRequests.count
            print("\(context) Existing Pending Notification Requests: \(count)")
            notificationRequests.forEach({ (request) in

                print("\(context) Pending: Notification Request: \(request)")
            })
        }
    }

    private func printNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification Settings: \(settings)")
        }
    }

    // workaround for some situation that alarm model is not setting properly (when app on background or not launched)
    func disableAlarmsIfOutdated() {

        UNUserNotificationCenter.current().getPendingNotificationRequests { (pendingNotifications) in

            let count = pendingNotifications.count

            if count == 0 {

                self.alarmModelController.disableAllAlarms()

            } else {

                for alarmIndex in 0..<self.alarmModelController.alarmCount {

                    if let alarm = self.alarmModelController.getAlarmAtTableIndex(index: alarmIndex) {

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
                            alarm.enabled = false
                        }
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
