import SwiftUI

struct BarrageDetailView: View {
    let barrage: Barrage
    
    @StateObject private var motionManager = MotionManager()
    @State private var waveOffset: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                waterVisualization
                
                barrageInformation
            }
            .padding()
        }
        .navigationTitle(barrage.barajAdi)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            motionManager.startMotionUpdates()
            startWaveAnimation()
        }
        .onDisappear {
            motionManager.stopMotionUpdates()
        }
    }
    
    private var waterVisualization: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(uiColor: .systemBackground))
                        )
                    
                    WaterWave(
                        fillPercentage: barrage.dolulukOrani,
                        waveOffset: waveOffset,
                        gravityX: motionManager.gravityX,
                        gravityY: motionManager.gravityY,
                        gravityZ: motionManager.gravityZ,
                        shakeIntensity: motionManager.shakeIntensity
                    )
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
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.75), value: motionManager.gravityX)
                    .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.75), value: motionManager.gravityY)
                    .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.75), value: motionManager.gravityZ)
                    
                    WaterBubbles(
                        shakeIntensity: motionManager.shakeIntensity,
                        fillPercentage: barrage.dolulukOrani,
                        containerHeight: geometry.size.height,
                        containerWidth: geometry.size.width
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    VStack {
                        Spacer()
                        Text("%\(String(format: "%.1f", barrage.dolulukOrani))")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        Spacer()
                    }
                }
            }
            .frame(height: 400)
        }
    }
    
    private var barrageInformation: some View {
        VStack(spacing: 16) {
            informationRow(title: "Baraj Adı", value: barrage.barajAdi)
            
            informationRow(
                title: "Doluluk Oranı",
                value: "%\(String(format: "%.1f", barrage.dolulukOrani))"
            )
            
            if let hacim = barrage.hacim {
                informationRow(
                    title: "Maksimum Kapasite",
                    value: "\(hacim.formatWithDots()) m³"
                )
            }
            
            if let suSeviyesi = barrage.suSeviyesi {
                informationRow(
                    title: "Su Yüksekliği",
                    value: "\(String(format: "%.2f", suSeviyesi)) m"
                )
            }
            
            if let guncellemeTarihi = barrage.guncellemeTarihi {
                informationRow(
                    title: "Güncelleme Tarihi",
                    value: guncellemeTarihi.formatDate()
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
    
    private func informationRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body.bold())
        }
    }
    
    private func startWaveAnimation() {
        withAnimation(
            .linear(duration: 3.0)
            .repeatForever(autoreverses: false)
        ) {
            waveOffset = .pi * 2
        }
    }
}


#Preview() {
    NavigationStack {
        BarrageDetailView(barrage: Barrage(
            id: 2,
            barajAdi: "Balçova Barajı",
            dolulukOrani: 45.0,
            hacim: 7759000,
            suSeviyesi: 124.02,
            guncellemeTarihi: "2026-01-31T00:00:00"
        ))
    }
}

