//
// Created by Matthias Neubert on 2019-02-26.
// Copyright (c) 2019 LongGames. All rights reserved.
//

import Foundation

extension Date {

    public func toMinutesRoundedDate(calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian)) -> Date {

        let secondComponent = calendar.component(.second, from: self)

        if let roundedDate = calendar.date(byAdding: .second, value: -secondComponent, to: self) {
            return roundedDate
        }

        return self
    }

    public func toSomeDaysLaterDate(
            calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian),
            daysToAdd: Int) -> Date {

        if let daysLaterDate = calendar.date(byAdding: .day, value: daysToAdd, to: self) {
            return daysLaterDate
        }

        return self
    }

    public func toSomeMinutesLaterDate(
            calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian),
            minutesToAdd: Int) -> Date {

        if let minutesLaterDate = calendar.date(byAdding: .minute, value: minutesToAdd, to: self) {
            return minutesLaterDate
        }

        return self
    }

}
