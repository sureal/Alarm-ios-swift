//
// Created by Matthias Neubert on 2019-02-25.
// Copyright (c) 2019 LongGames. All rights reserved.
//

import Foundation

protocol AlarmObserver {

    func alarmChanged(alarm: Alarm)
}

class Alarm: Codable {

    var indexInTable: Int = -1 {
        didSet {
            observer?.alarmChanged(alarm: self)
        }
    }
    var alarmID: String = UUID().uuidString {
        didSet {
            observer?.alarmChanged(alarm: self)
        }
    }
    var alarmName: String = "Alarm" {
        didSet {
            observer?.alarmChanged(alarm: self)
        }
    }
    var alertDate: Date = Date() {
        didSet {
            observer?.alarmChanged(alarm: self)
        }
    }
    var enabled: Bool = true {
        didSet {
            observer?.alarmChanged(alarm: self)
        }
    }
    var snoozeEnabled: Bool = false {
        didSet {
            observer?.alarmChanged(alarm: self)
        }
    }
    var repeatAtWeekdays: [Weekday] = [] {
        didSet {
            observer?.alarmChanged(alarm: self)
        }
    }
    var mediaID: String = "" {
        didSet {
            observer?.alarmChanged(alarm: self)
        }
    }
    var mediaLabel: String = "bell" {
        didSet {
            observer?.alarmChanged(alarm: self)
        }
    }

    var observer: AlarmObserver?

    init() {
    }

    private enum CodingKeys: String, CodingKey {
        case indexInTable
        case alarmID
        case alarmName
        case alertDate
        case snoozeEnabled
        case repeatAtWeekdays
        case mediaID
        case mediaLabel
    }
    func formattedTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: self.alertDate)
    }

    func isRepeating() -> Bool {
        return !self.repeatAtWeekdays.isEmpty
    }
}
