import Foundation

@MainActor
class ReviewManager {
    static let shared = ReviewManager()
    
    private let launchCountKey = "app_launch_count"
    private let lastReviewRequestKey = "last_review_request_date"
    private let hasRequestedReviewKey = "has_requested_review"
    
    private init() {}
    
    func incrementLaunchCount() {
        let currentCount = UserDefaults.standard.integer(forKey: launchCountKey)
        let newCount = currentCount + 1
        UserDefaults.standard.set(newCount, forKey: launchCountKey)
    }
    
    func shouldRequestReview() -> Bool {
        let launchCount = UserDefaults.standard.integer(forKey: launchCountKey)
        let hasRequested = UserDefaults.standard.bool(forKey: hasRequestedReviewKey)
        
        if launchCount == 3 && !hasRequested {
            return true
        }
        return false
    }
    
    func markReviewRequested() {
        UserDefaults.standard.set(true, forKey: hasRequestedReviewKey)
        UserDefaults.standard.set(Date(), forKey: lastReviewRequestKey)
    }
    
    func getLaunchCount() -> Int {
        return UserDefaults.standard.integer(forKey: launchCountKey)
    }
}
