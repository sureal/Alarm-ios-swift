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
        static let addAlarm = "addAlarmSegue"
        static let editAlarm = "editAlarmSegue"
        static let saveAddEditAlarm = "saveEditAlarmSegue"
        static let setAlarmSound = "setAlarmSoundSegue"
        static let editAlarmName = "editAlarmNameSegue"
        static let setWeekdaysRepeating = "setWeekdaysSegue"
    }

    struct UnwindSegue {
        static let saveAlarmName = "alarmNameUnwindSegue"
        static let saveAlarmSound = "setSoundUnwindSegue"
        static let saveWeekdaysRepeating = "weekdaysUnwindSegue"
        static let cancelAddAlarm = "cancelAddAlarmUnwindSegue"
        static let saveAddEditAlarm = "saveEditAlarmUnwindSegue"
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

    struct Persistence {
        static let alarmListPersistKey = "Alarm.AlarmList"
    }
}
