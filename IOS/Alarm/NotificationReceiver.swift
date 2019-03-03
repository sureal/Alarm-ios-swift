//
// Created by Matthias Neubert on 2019-02-28.
//

import Foundation
import UserNotifications
import UIKit

class NotificationReceiver: NSObject, UNUserNotificationCenterDelegate {

    let alarmScheduler: AlarmScheduler!
    var alarmModel: AlarmModelController!
    var alarmPlayer: AlarmPlayer
    var window: UIWindow?

    init(alarmScheduler: AlarmScheduler!, alarmModelController: AlarmModelController!, alarmPlayer: AlarmPlayer, window: UIWindow?) {
        self.alarmScheduler = alarmScheduler
        self.alarmModel = alarmModelController
        self.alarmPlayer = alarmPlayer
        self.window = window
        super.init()

        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                        @escaping (UNNotificationPresentationOptions) -> Void) {

        print("userNotificationCenter:willPresent:withCompletionHandler(UNNotificationPresentationOptions)")
        // for notifications that are delivered to a foreground app:

        //show an alert window
        let storageController = UIAlertController(title: "Alarm", message: nil, preferredStyle: .alert)
        let userInfoDict = notification.request.content.userInfo
        let userInfo = UserInfo(userInfo: userInfoDict)

        alarmPlayer.playSound(userInfo.soundName)
        //schedule notification for snooze
        if userInfo.isSnoozeEnabled {
            let snoozeOption = UIAlertAction(title: "Snooze", style: .default) { (_) -> Void in

                self.alarmPlayer.stopSound()

                self.alarmScheduler.setNotificationForSnooze(
                        snoozeForMinutes: 9,
                        soundName: userInfo.soundName,
                        index: userInfo.index)
            }
            storageController.addAction(snoozeOption)
        }
        let stopOption = UIAlertAction(title: "OK", style: .default) { (_) -> Void in

            self.alarmPlayer.stopSound()

            self.alarmModel.alarms[userInfo.index].onSnooze = false
            //change UI
            var mainVC = self.window?.visibleViewController as? MainAlarmViewController
            if mainVC == nil {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                mainVC = storyboard.instantiateViewController(withIdentifier: "Alarm") as? MainAlarmViewController
            }
            mainVC!.changeSwitchButtonState(index: userInfo.index)
        }

        storageController.addAction(stopOption)
        window?.visibleViewController?.navigationController?.present(storageController, animated: true, completion: nil)

        completionHandler(UNNotificationPresentationOptions.sound)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        print("userNotificationCenter:didReceive")
        // to let your app know which action was selected by the user for a given notification:

        print("Hey, I received a local notification in background due to user interaction")

        let userInfoDict = response.notification.request.content.userInfo
        let userInfo = UserInfo(userInfo: userInfoDict)

        self.alarmModel.alarms[userInfo.index].onSnooze = false
        if response.actionIdentifier == Identifier.NotificationAction.snooze {
            alarmScheduler.setNotificationForSnooze(
                    snoozeForMinutes: 9,
                    soundName: userInfo.soundName,
                    index: userInfo.index)
            self.alarmModel.alarms[userInfo.index].onSnooze = true
        }

        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        print("userNotificationCenter:openSettingsFor")
    }

}
