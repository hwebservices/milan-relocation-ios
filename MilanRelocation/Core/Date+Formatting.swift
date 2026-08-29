import Foundation

extension Date {
    var relocationShort: String {
        formatted(.dateTime.day().month(.abbreviated))
    }

    var relocationLong: String {
        formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}

