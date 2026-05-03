import Foundation

enum ChartRange: String, CaseIterable, Sendable {
    case week     = "1 Hafta"
    case month    = "1 Ay"
    case sixMonth = "6 Ay"

    var days: Int {
        switch self {
        case .week:     return 7
        case .month:    return 30
        case .sixMonth: return 180
        }
    }

    var xLabelFormat: Date.FormatStyle {
        let tr = Locale(identifier: "tr_TR")
        switch self {
        case .week, .month: return .dateTime.day().month(.abbreviated).locale(tr)
        case .sixMonth:     return .dateTime.month(.wide).locale(tr)
        }
    }

    var xStride: Calendar.Component {
        switch self {
        case .week, .month: return .day
        case .sixMonth:     return .month
        }
    }

    var xStrideCount: Int {
        switch self {
        case .week:     return 1
        case .month:    return 7
        case .sixMonth: return 1
        }
    }
}
