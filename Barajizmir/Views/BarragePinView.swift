import SwiftUI

struct BarragePinView: View {
    let barrage: Barrage
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(fillColor)
                        .frame(width: 48, height: 48)
                        .shadow(color: fillColor.opacity(0.45), radius: 5, x: 0, y: 3)
                    VStack(spacing: 0) {
                        Text(String(format: "%.0f", barrage.dolulukOrani))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("%")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                PinPointer()
                    .fill(fillColor)
                    .frame(width: 12, height: 7)
            }
        }
        .buttonStyle(.plain)
    }

    private var fillColor: Color {
        switch barrage.dolulukOrani {
        case 0..<30:  return .red
        case 30..<60: return .orange
        case 60..<80: return Color(red: 0.85, green: 0.65, blue: 0.0)
        default:      return Color(red: 0.2, green: 0.7, blue: 0.3)
        }
    }
}

/// Downward-pointing triangle that acts as the pin tip.
private struct PinPointer: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        BarragePinView(barrage: Barrage(
            id: 1, barajAdi: "Tahtalı", dolulukOrani: 82,
            hacim: nil, mevcutSuDurumu: nil, suSeviyesi: nil,
            maksimumSuYuksekligi: nil, minimumSuYuksekligi: nil, guncellemeTarihi: nil,
            enlem: nil, boylam: nil
        ), onTap: {})
        BarragePinView(barrage: Barrage(
            id: 2, barajAdi: "Balçova", dolulukOrani: 45,
            hacim: nil, mevcutSuDurumu: nil, suSeviyesi: nil,
            maksimumSuYuksekligi: nil, minimumSuYuksekligi: nil, guncellemeTarihi: nil,
            enlem: nil, boylam: nil
        ), onTap: {})
        BarragePinView(barrage: Barrage(
            id: 3, barajAdi: "Gördes", dolulukOrani: 22,
            hacim: nil, mevcutSuDurumu: nil, suSeviyesi: nil,
            maksimumSuYuksekligi: nil, minimumSuYuksekligi: nil, guncellemeTarihi: nil,
            enlem: nil, boylam: nil
        ), onTap: {})
    }
    .padding()
}
