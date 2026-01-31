import CoreMotion
import SwiftUI
import Combine

@MainActor
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published var gravityX: Double = 0
    @Published var gravityY: Double = 0
    @Published var gravityZ: Double = 0
    @Published var shakeIntensity: Double = 0
    
    private var lastShakeTime: Date = .distantPast
    private let shakeThreshold: Double = 2.5
    private let shakeCooldown: TimeInterval = 1.0
    
    private var targetGravityX: Double = 0
    private var targetGravityY: Double = 0
    private var targetGravityZ: Double = 0
    
    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.showsDeviceMovementDisplay = false
        
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            
            let gravity = motion.gravity
            
            self.targetGravityX = gravity.x
            self.targetGravityY = gravity.y
            self.targetGravityZ = gravity.z
            
            let damping: Double = 0.85
            self.gravityX = self.gravityX * damping + self.targetGravityX * (1.0 - damping)
            self.gravityY = self.gravityY * damping + self.targetGravityY * (1.0 - damping)
            self.gravityZ = self.gravityZ * damping + self.targetGravityZ * (1.0 - damping)
            
            let acceleration = motion.userAcceleration
            let magnitude = sqrt(
                acceleration.x * acceleration.x +
                acceleration.y * acceleration.y +
                acceleration.z * acceleration.z
            )
            
            if magnitude > self.shakeThreshold {
                let now = Date()
                if now.timeIntervalSince(self.lastShakeTime) > self.shakeCooldown {
                    self.lastShakeTime = now
                    self.triggerShake()
                }
            }
            
            if self.shakeIntensity > 0 {
                self.shakeIntensity = max(0, self.shakeIntensity - 0.03)
            }
        }
    }
    
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func triggerShake() {
        shakeIntensity = 1.0
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}
