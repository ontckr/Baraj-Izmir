import SwiftUI

struct WaterWave: Shape {
    var fillPercentage: Double
    var waveOffset: Double
    var gravityX: Double
    var gravityY: Double
    var gravityZ: Double
    var shakeIntensity: Double
    
    var animatableData: AnimatablePair<Double, AnimatablePair<Double, AnimatablePair<Double, AnimatablePair<Double, AnimatablePair<Double, Double>>>>> {
        get {
            AnimatablePair(fillPercentage, AnimatablePair(waveOffset, AnimatablePair(gravityX, AnimatablePair(gravityY, AnimatablePair(gravityZ, shakeIntensity)))))
        }
        set {
            fillPercentage = newValue.first
            waveOffset = newValue.second.first
            gravityX = newValue.second.second.first
            gravityY = newValue.second.second.second.first
            gravityZ = newValue.second.second.second.second.first
            shakeIntensity = newValue.second.second.second.second.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // If fill percentage is 0 or less, return empty path
        guard fillPercentage > 0 else {
            return path
        }
        
        let baseAmplitude = 3.0 + (shakeIntensity * 12.0)
        let wavelength = rect.width / 2.0
        let frequency = 2.0 * .pi / wavelength
        
        let maxTilt = rect.height * 0.35
        
        let baseY = rect.height * (1.0 - fillPercentage / 100.0)
        
        let gravityOffsetX = gravityX
        let gravityOffsetY = gravityY + 1.0
        
        path.move(to: CGPoint(x: 0, y: rect.height))
        
        for x in stride(from: 0, through: rect.width, by: 2) {
            let normalizedX = (x / rect.width - 0.5) * 2.0
            
            let horizontalTilt = normalizedX * gravityOffsetX * maxTilt
            let verticalTilt = normalizedX * gravityOffsetY * maxTilt * 0.3
            
            let tiltEffect = horizontalTilt + verticalTilt
            
            let sineWave = sin(frequency * x + waveOffset) * baseAmplitude
            let y = baseY + tiltEffect + sineWave
            
            let clampedY = min(max(y, 0), rect.height)
            path.addLine(to: CGPoint(x: x, y: clampedY))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

#Preview("Yüksek Su Seviyesi - %80") {
    WaterWave(fillPercentage: 80, waveOffset: 0, gravityX: 0, gravityY: -1, gravityZ: 0, shakeIntensity: 0)
        .fill(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.7, blue: 0.9),
                    Color(red: 0.2, green: 0.5, blue: 0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(width: 300, height: 400)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
}
