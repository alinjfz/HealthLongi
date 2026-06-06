import Foundation

enum SleepDurationFormatting {
    /// Formats decimal hours as `7h 24m`.
    static func format(hours: Double) -> String {
        let totalMinutes = Int((hours * 60).rounded())
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }
}
