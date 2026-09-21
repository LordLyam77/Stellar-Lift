import Foundation
import SwiftData

@Model
public final class WeeklySchedule {
    public var id: UUID = UUID()
    /// 1 = Sunday, 2 = Monday, 3 = Tuesday, 4 = Wednesday, 5 = Thursday, 6 = Friday, 7 = Saturday
    public var dayOfWeek: Int = 2
    public var reminderTimeHour: Int = 8
    public var reminderTimeMinute: Int = 0
    public var isReminderEnabled: Bool = true

    public var splitDay: SplitDay?

    public init(
        id: UUID = UUID(),
        dayOfWeek: Int,
        splitDay: SplitDay? = nil,
        reminderTimeHour: Int = 8,
        reminderTimeMinute: Int = 0,
        isReminderEnabled: Bool = true
    ) {
        self.id = id
        self.dayOfWeek = dayOfWeek
        self.splitDay = splitDay
        self.reminderTimeHour = reminderTimeHour
        self.reminderTimeMinute = reminderTimeMinute
        self.isReminderEnabled = isReminderEnabled
    }

    public var weekdayName: String {
        switch dayOfWeek {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return "Day \(dayOfWeek)"
        }
    }

    public var shortWeekdayName: String {
        switch dayOfWeek {
        case 1: return "Sun"
        case 2: return "Mon"
        case 3: return "Tue"
        case 4: return "Wed"
        case 5: return "Thu"
        case 6: return "Fri"
        case 7: return "Sat"
        default: return "D\(dayOfWeek)"
        }
    }

    /// Display order where Monday is index 0 and Sunday is index 6
    public var mondayFirstSortOrder: Int {
        return dayOfWeek == 1 ? 7 : dayOfWeek - 1
    }
}
