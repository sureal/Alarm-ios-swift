//
//  AppDelegate.swift
//
//  Created by longyutao on 15-2-28.
//  Copyright (c) 2015年 LongGames. All rights reserved.
//

import UIKit
import Foundation
import AudioToolbox
import AVFoundation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var alarmScheduler: AlarmScheduler!
    var notificationReceiver: NotificationReceiver!

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {


        // Create Dependencies
        let alarmModelController = AlarmModelController()
        self.alarmScheduler = AlarmScheduler(alarmModelController: alarmModelController)

        guard let rootNavController = window?.rootViewController as? UINavigationController else {
            return false
        }
        // inject into main view controller
        guard let mainAlarmViewController = rootNavController.topViewController as? MainAlarmViewController else {
            return false
        }
        mainAlarmViewController.alarmModelController = alarmModelController
        mainAlarmViewController.alarmScheduler = alarmScheduler

        let alarmPlayer = AlarmPlayer()
        self.notificationReceiver = NotificationReceiver(
                alarmScheduler: alarmScheduler,
                alarmModelController: alarmModelController,
                alarmPlayer: alarmPlayer,
                window: window)

        window?.tintColor = UIColor.red

        return true
    }

    //UIApplicationDelegate protocol
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain
        // types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits
        // the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games
        // should use this method to pause the game.
//        audioPlayer?.pause()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough
        // application state information to restore your application to its current state in case it is
        // terminated later.
        // If your application supports background execution, this method is called instead of
        // applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of
        // the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the
        // application was previously in the background, optionally refresh the user interface.
//        audioPlayer?.play()
        alarmScheduler.checkNotification()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate.
        // See also applicationDidEnterBackground:.
    }

}
