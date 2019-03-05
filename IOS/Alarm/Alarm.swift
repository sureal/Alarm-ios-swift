//
// Created by Matthias Neubert on 2019-02-25.
// Copyright (c) 2019 LongGames. All rights reserved.
//

import Foundation

struct Alarm: Codable {

    var alarmID: String = ""
    var alarmName: String = "Alarm"
    var alertDate: Date = Date()
    var enabled: Bool = false
    var snoozeEnabled: Bool = false
    var repeatAtWeekdays: [Int] = []

    var mediaID: String = ""
    var mediaLabel: String = "bell"

    var onSnooze: Bool = false

    init() {
    }

    func formattedTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: self.alertDate)
    }
}
