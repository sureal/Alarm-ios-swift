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


protocol TimerElapsedDelegate {
    func onAlarmTimeElapsed(forAlarm alarm: Alarm)
}

class AlarmScheduler {

    weak var alarmModelController: AlarmModelController!

    var notificationRequestIds = [String]()

    var backgroundTimers = [Timer]()

    var timerElapsedDelegate: TimerElapsedDelegate?

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
                actions: [stopAction],
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
        if !alarm.isRepeating() {
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
            guard let weekdayOfAlertDate: Int = dateComponents.weekday else {
                return notificationDates
            }

            let daysInWeek = 7
            notificationDates.removeAll(keepingCapacity: true)
            for repetitionWeekday in alarm.repeatAtWeekdays {

                var dateOfWeekday: Date
                //schedule on next week
                if compare(weekday: repetitionWeekday, with: weekdayOfAlertDate) == .before {
                    dateOfWeekday = alarm.alertDate.toSomeDaysLaterDate(daysToAdd: repetitionWeekday + daysInWeek - weekdayOfAlertDate)
                }
                //schedule on today or next week
                else if compare(weekday: repetitionWeekday, with: weekdayOfAlertDate) == .same {
                    //scheduling date is earlier than current date, then schedule on next week
                    if alarm.alertDate.compare(now) == ComparisonResult.orderedAscending {
                        dateOfWeekday = alarm.alertDate.toSomeDaysLaterDate(daysToAdd: daysInWeek)
                    } else { //later
                        dateOfWeekday = alarm.alertDate
                    }
                }
                //schedule on next days of this week
                else { //after
                    dateOfWeekday = alarm.alertDate.toSomeDaysLaterDate(daysToAdd: repetitionWeekday - weekdayOfAlertDate)
                }

                //fix second component to 0
                dateOfWeekday = dateOfWeekday.toMinutesRoundedDate()
                notificationDates.append(dateOfWeekday)
            }
            return notificationDates
        }
    }

    private func addNotification(forAlarm alarm: Alarm) {

        let datesForNotification = self.createNotificationDates(forAlarm: alarm)

        addBackgroundTimer(alarm: alarm)

        requestNotificationAuthorization { granted in

            if !granted {
                print("ERROR: Cannot create notification without user's permission")
                return
            }

            let content = self.createNotificationContent(forAlarm: alarm)



            var notificationRequests = [UNNotificationRequest]()

            for notificationDate in datesForNotification {
                
                let alarmNotificationRequest = self.createNotificationRequest(
                        notificationDate: notificationDate,
                        isRepeating: alarm.isRepeating(),
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

    private func addBackgroundTimer(alarm: Alarm) {

        if !alarm.isRepeating() {
            let timeUntilFirstAlarm = alarm.alertDate.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate

            let timer = Timer.scheduledTimer(withTimeInterval: timeUntilFirstAlarm, repeats: false) { timer in
                print("Time elapsed of alarm \(alarm.alarmName)")
                self.timerElapsedDelegate?.onAlarmTimeElapsed(forAlarm: alarm)
            }
            self.backgroundTimers.append(timer)
        } else {

            let oneWeekInSeconds = 7 * 24 * 60 * 60.0
            let notificationDates = self.createNotificationDates(forAlarm: alarm)
            for notificationDate in notificationDates {

                let timer = Timer(fire: notificationDate, interval: oneWeekInSeconds, repeats: true) { timer in
                    print("Time elapsed of alarm \(alarm.alarmName)")
                    self.timerElapsedDelegate?.onAlarmTimeElapsed(forAlarm: alarm)
                }
                self.backgroundTimers.append(timer)
            }
        }

        self.backgroundTimers.forEach { timer in
            print("Created timer: Fires next:  \(timer.fireDate) in interval of \(timer.timeInterval/60/60) hours")
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
        userInfo.repeating = alarm.isRepeating()

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
        snoozeAlarm.mediaLabel = soundName

        addNotification(forAlarm: snoozeAlarm)
    }

    func recreateNotificationsFromDataModel() {

        //printNotificationSettings()

        removeExistingNotifications()

        for alarmIndex in 0..<self.alarmModelController.alarmCount {
            if let alarm = self.alarmModelController.getAlarmAtTableIndex(index: alarmIndex) {

                if alarm.enabled {
                    self.addNotification(forAlarm: alarm)
                }
            }
        }

        printPendingNotificationRequests(context: "After adding ")
    }

    private func removeExistingNotifications() {

        printPendingNotificationRequests(context: "Before removal")

        //cancel all and register all is often more convenient
        //UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: self.notificationRequestIds)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        //UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: self.notificationRequestIds)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        self.notificationRequestIds.removeAll()

        // remove all timers
        self.backgroundTimers.forEach { timer in
            timer.invalidate()
        }
        self.backgroundTimers.removeAll()

        printPendingNotificationRequests(context: "After removal")
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
        if weekday < otherWeekday /*weekday != 1 && otherWeekday == 1*/ {
            return .before
        } else if weekday == otherWeekday {
            return .same
        } else {
            return .after
        }
    }
}
