import BackgroundTasks
import Foundation

final class BackgroundRefreshManager: @unchecked Sendable {
    static let shared = BackgroundRefreshManager()
    private init() {}

    private let taskIdentifier = "onatcakir.Barajizmir.refresh"

    func registerHandler() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { [weak self] task in
            guard let self, let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleRefresh(task: refreshTask)
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
