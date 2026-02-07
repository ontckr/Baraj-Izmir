import SwiftUI

struct WaterBubbles: View {
    let shakeIntensity: Double
    let fillPercentage: Double
    let containerHeight: CGFloat
    let containerWidth: CGFloat
    
    @State private var bubbleKeys: [UUID] = []
    @State private var burstBubbleKeys: Set<UUID> = []
    
    var body: some View {
        ZStack {
            if fillPercentage > 0 {
                ForEach(bubbleKeys, id: \.self) { key in
                    BubbleView(
                        key: key,
                        fillPercentage: fillPercentage,
                        containerHeight: containerHeight,
                        containerWidth: containerWidth,
                        isBurst: burstBubbleKeys.contains(key)
                    )
                }
            }
        }
        .onAppear {
            if fillPercentage > 0 {
                startContinuousBubbles()
            }
        }
        .onChange(of: shakeIntensity) { oldValue, newValue in
            if fillPercentage > 0 && newValue > 0.2 {
                createBurstBubbles(intensity: newValue)
            }
        }
    }
    
    private func startContinuousBubbles() {
        let baseCount = min(max(4, Int(fillPercentage / 10.0)), 12)
        bubbleKeys = (0..<baseCount).map { _ in UUID() }
    }
    
    private func createBurstBubbles(intensity: Double) {
        let bubbleCount = min(Int(intensity * 12), 15)
        let newKeys = (0..<bubbleCount).map { _ in UUID() }
        bubbleKeys.append(contentsOf: newKeys)
        burstBubbleKeys.formUnion(newKeys)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            bubbleKeys.removeAll { key in
                newKeys.contains(key)
            }
            burstBubbleKeys.subtract(newKeys)
        }
    }
}

struct BubbleView: View {
    let key: UUID
    let fillPercentage: Double
    let containerHeight: CGFloat
    let containerWidth: CGFloat
    let isBurst: Bool
    
    @State private var y: CGFloat = 0
    @State private var x: CGFloat = 0
    @State private var size: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(opacity),
                        Color.white.opacity(opacity * 0.2)
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .position(x: x, y: y)
            .onAppear {
                setupBubble()
                animateBubble()
            }
    }
    
    private func setupBubble() {
        let waterTop = containerHeight * (1.0 - fillPercentage / 100.0)
        let waterBottom = containerHeight
        
        let margin: CGFloat = 8
        x = CGFloat.random(in: margin...(containerWidth - margin))
        y = CGFloat.random(in: waterTop...waterBottom)
        
        if isBurst {
            size = CGFloat.random(in: 5...12)
            opacity = Double.random(in: 0.6...0.9)
        } else {
            size = CGFloat.random(in: 2...5)
            opacity = Double.random(in: 0.2...0.5)
        }
    }
    
    private func animateBubble() {
        let waterTop = containerHeight * (1.0 - fillPercentage / 100.0)
        let targetY = waterTop - CGFloat.random(in: 15...40)
        let duration = Double.random(in: 2.5...4.5)
        
        withAnimation(.linear(duration: duration)) {
            y = targetY
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            let waterTop = containerHeight * (1.0 - fillPercentage / 100.0)
            let waterBottom = containerHeight
            
            let margin: CGFloat = 8
            y = CGFloat.random(in: waterTop...waterBottom)
            x = CGFloat.random(in: margin...(containerWidth - margin))
            size = CGFloat.random(in: 2...5)
            opacity = Double.random(in: 0.2...0.5)
            
            animateBubble()
        }
    }
}
