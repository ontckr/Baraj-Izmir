import BackgroundTasks
import Foundation

final class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()
    private init() {}

    private let taskIdentifier = "onatcakir.Barajizmir.refresh"

    func registerHandler() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            self.handleRefresh(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleNext() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // en erken 1 saat sonra
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleRefresh(task: BGAppRefreshTask) {
        scheduleNext()

        let fetchTask = Task {
            if let result = await SupabaseService.shared.fetchLatest() {
                NotificationManager.shared.checkThresholds(against: result.barrages)
            }
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            fetchTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
