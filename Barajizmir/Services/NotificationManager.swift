import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let thresholdsKey = "notification_thresholds"
    private let notifiedIdsKey = "notified_barrage_ids"

    // MARK: - Thresholds

    func saveThreshold(_ threshold: NotificationThreshold) {
        var all = loadAllThresholds()
        all[threshold.barrageId] = threshold
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: thresholdsKey)
        }
    }

    func removeThreshold(for barrageId: Int) {
        var all = loadAllThresholds()
        all.removeValue(forKey: barrageId)
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: thresholdsKey)
        }
    }

    func loadThreshold(for barrageId: Int) -> NotificationThreshold? {
        loadAllThresholds()[barrageId]
    }

    private func loadAllThresholds() -> [Int: NotificationThreshold] {
        guard let data = UserDefaults.standard.data(forKey: thresholdsKey),
              let decoded = try? JSONDecoder().decode([Int: NotificationThreshold].self, from: data)
        else { return [:] }
        return decoded
    }

    // MARK: - Threshold Checking (called after each fresh API fetch)

    func checkThresholds(against barrages: [Barrage]) {
        let thresholds = loadAllThresholds()
        guard !thresholds.isEmpty else { return }

        var notifiedIds = loadNotifiedIds()
        var changed = false

        for barrage in barrages {
            guard let pref = thresholds[barrage.id], pref.isEnabled else { continue }

            let isBelow = barrage.dolulukOrani <= pref.threshold
            let alreadyNotified = notifiedIds.contains(barrage.id)

            if isBelow, !alreadyNotified {
                sendNotification(for: barrage, threshold: pref.threshold)
                notifiedIds.insert(barrage.id)
                changed = true
            } else if !isBelow, alreadyNotified {
                // Reset so next drop triggers notification again
                notifiedIds.remove(barrage.id)
                changed = true
            }
        }

        if changed { saveNotifiedIds(notifiedIds) }
    }

    // MARK: - Sending

    private func sendNotification(for barrage: Barrage, threshold: Double) {
        let content = UNMutableNotificationContent()
        content.title = barrage.barajAdi
        content.body = "Doluluk oranı %\(String(format: "%.1f", barrage.dolulukOrani))'a düştü (eşik: %\(Int(threshold)))"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "barrage_threshold_\(barrage.id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Notified ID tracking

    private func loadNotifiedIds() -> Set<Int> {
        Set(UserDefaults.standard.array(forKey: notifiedIdsKey) as? [Int] ?? [])
    }

    private func saveNotifiedIds(_ ids: Set<Int>) {
        UserDefaults.standard.set(Array(ids), forKey: notifiedIdsKey)
    }
}
