import Foundation

struct NotificationThreshold: Codable {
    let barrageId: Int
    let barajAdi: String
    var threshold: Double
    var isEnabled: Bool
}
