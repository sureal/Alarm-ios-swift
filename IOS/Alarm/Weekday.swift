//
// Created by Matthias Neubert on 2019-03-11.
// Copyright (c) 2019 LongGames. All rights reserved.
//

import Foundation

enum Weekday: Int, Codable {

    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}

enum WeekdayComparisonResult {
    case before
    case same
    case after
}

extension Weekday {

    func name() -> String {

        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }

    func shortName() -> String {

        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }

    func dayInWeek() -> Int {
        return self.rawValue
    }

    static func all() -> [Weekday] {
        return [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
    }

    static func repeatText(weekdays: [Weekday]) -> String {
        if weekdays.count == 7 {
            return "Every day"
        }
        
        if weekdays.isEmpty {
            return "Never"
        }
        
        var ret = String()
        let weekdaysSorted = weekdays.sorted { weekday, otherWeekday in
            return weekday.dayInWeek() < otherWeekday.dayInWeek()
        }

        for day in weekdaysSorted {            
            ret += day.shortName() + " "
        }
        return ret
    }
    
    func compare(with other: Weekday) -> WeekdayComparisonResult {
        if self.dayInWeek() < other.dayInWeek() {
            return .before
        } else if self.dayInWeek() == other.dayInWeek() {
            return .same
        } else {
            return .after
        }
    }
}
