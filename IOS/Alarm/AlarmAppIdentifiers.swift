//
//  AlarmAppIdentifiers.swift
//  Alarm-ios-swift
//
//  Created by natsu1211 on 2017/02/02.
//  Copyright © 2017年 LongGames. All rights reserved.
//

import Foundation

struct Identifier {

    struct Segue {
        static let add = "addSegue"
        static let edit = "editSegue"
        static let save = "saveEditSegue"
        static let sound = "soundSegue"
        static let label = "labelEditSegue"
        static let weekdays = "weekdaysSegue"
    }

    struct UnwindSegue {
        static let label = "labelUnwindSegue"
        static let sound = "soundUnwindSegue"
        static let weekdays = "weekdaysUnwindSegue"
    }

    struct TableCell {
        static let setting = "setting"
        static let music = "musicIdentifier"
        static let alarm = "alarmCell"
    }

    struct NotificationAction {
        static let stop = "Alarm.NotificationAction.stop"
        static let snooze = "Alarm.NotificationAction.snooze"
    }

    struct NotificationCategory {
        static let noSnooze = "Alarm.NotificationCategory.NoSnooze"
        static let snooze = "Alarm.NotificationCategory.Snooze"
    }
}
