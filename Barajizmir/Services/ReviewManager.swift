import Foundation

@MainActor
class ReviewManager {
    static let shared = ReviewManager()
    
    private let launchCountKey = "app_launch_count"
    private let lastReviewRequestKey = "last_review_request_date"
    private let hasRequestedReviewKey = "has_requested_review"
    private let firstLaunchDateKey = "first_launch_date"
    
    private init() {}
    
    func incrementLaunchCount() {
        if UserDefaults.standard.object(forKey: firstLaunchDateKey) == nil {
            UserDefaults.standard.set(Date(), forKey: firstLaunchDateKey)
        }
        
        let currentCount = UserDefaults.standard.integer(forKey: launchCountKey)
        let newCount = currentCount + 1
        UserDefaults.standard.set(newCount, forKey: launchCountKey)
    }
    
    func shouldRequestReview() -> Bool {
        let launchCount = UserDefaults.standard.integer(forKey: launchCountKey)
        let hasRequested = UserDefaults.standard.bool(forKey: hasRequestedReviewKey)
        
        print("🔍 Review check - Launch count: \(launchCount), Has requested: \(hasRequested)")
        
        if launchCount >= 3 && !hasRequested {
            if let firstLaunchDate = UserDefaults.standard.object(forKey: firstLaunchDateKey) as? Date {
                let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunchDate, to: Date()).day ?? 0                
                if daysSinceFirstLaunch >= 1 {
                    return true
                }
            } else {
                return true
            }
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
