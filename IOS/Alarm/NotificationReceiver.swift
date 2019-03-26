//
// Created by Matthias Neubert on 2019-02-28.
//

import Foundation
import UserNotifications
import UIKit

class NotificationReceiver: NSObject, UNUserNotificationCenterDelegate, TimerElapsedDelegate {

    weak var alarmModelController: AlarmModelController!
    var alarmPlayer: AlarmPlayer
    var window: UIWindow?

    override init() {

        self.alarmPlayer = AlarmPlayer()
        if UIApplication.shared.windows.count > 0 {
            self.window = UIApplication.shared.windows[0]
        }

        super.init()

        UNUserNotificationCenter.current().delegate = self
    }

    func onAlarmTimeElapsed(forAlarm alarm: Alarm) {

        print("onAlarmTimeElapsed:forAlarm: \(alarm)")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                        @escaping (UNNotificationPresentationOptions) -> Void) {

        print("userNotificationCenter:willPresent:withCompletionHandler(UNNotificationPresentationOptions)")
        print("Received Notification in foreground: \(notification)")
        // for notifications that are delivered to a foreground app:

        //show an alert window
        /*
        let storageController = UIAlertController(title: "Alarm", message: nil, preferredStyle: .alert)
        let userInfoDict = notification.request.content.userInfo
        let userInfo = UserInfo(userInfo: userInfoDict)

        
        self.alarmPlayer.playSound(userInfo.soundName)
        //schedule notification for snooze
        if userInfo.isSnoozeEnabled {
            let snoozeOption = UIAlertAction(title: "Snooze", style: .default) { (_) -> Void in

                self.alarmPlayer.stopSound()

                self.alarmModelController.alarmScheduler.scheduleSnoozeNotification(
                        snoozeForMinutes: 9,
                        soundName: userInfo.soundName)
            }
            storageController.addAction(snoozeOption)
        }
        let stopOption = UIAlertAction(title: "OK", style: .default) { (_) -> Void in

            self.alarmPlayer.stopSound()

            if let alarm = self.alarmModelController.getAlarmAtTableIndex(index: userInfo.index) {
                alarm.onSnooze = false
            }

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

 */

        completionHandler([.alert, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {

        print("userNotificationCenter:didReceive")
        print("Received a local notification while in background due to user interaction: \(response)")

        // to let your app know which action was selected by the user for a given notification:
        let userInfoDict = response.notification.request.content.userInfo
        let userInfo = UserInfo(userInfo: userInfoDict)

        if response.actionIdentifier == AlarmIdentifier.NotificationAction.snooze {
            self.alarmModelController.alarmScheduler.scheduleSnoozeNotification(
                    snoozeForMinutes: 1,
                    soundName: userInfo.soundName)

        }

        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        if let notification = notification {
            print("userNotificationCenter:openSettingsFor: \(notification)")
        } else {
            print("userNotificationCenter:openSettingsFor: without notification")
        }
    }

}
