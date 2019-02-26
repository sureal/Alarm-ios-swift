//
// Created by Matthias Neubert on 2019-02-25.
// Copyright (c) 2019 LongGames. All rights reserved.
//

import Foundation

struct Alarm: Codable {

    var date: Date = Date()
    var enabled: Bool = false
    var snoozeEnabled: Bool = false
    var repeatWeekdays: [Int] = []
    var uuid: String = ""
    var mediaID: String = ""
    var mediaLabel: String = "bell"
    var label: String = "Alarm"
    var onSnooze: Bool = false

    init() {
    }

    init(date: Date, enabled: Bool, snoozeEnabled: Bool, repeatWeekdays: [Int],
         uuid: String, mediaID: String, mediaLabel: String, label: String,
         onSnooze: Bool) {

        self.date = date
        self.enabled = enabled
        self.snoozeEnabled = snoozeEnabled
        self.repeatWeekdays = repeatWeekdays
        self.uuid = uuid
        self.mediaID = mediaID
        self.mediaLabel = mediaLabel
        self.label = label
        self.onSnooze = onSnooze
    }

    func formattedTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: self.date)
    }
}
