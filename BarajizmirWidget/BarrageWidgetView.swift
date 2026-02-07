import WidgetKit
import SwiftUI

struct BarrageWidgetView: View {
    var entry: BarrageWidgetTimeline.Entry
    
    var body: some View {
        switch entry.state {
        case .loaded:
            if let barrage = entry.barrage {
                loadedView(barrage: barrage)
            } else {
                errorView
            }
        case .loading:
            loadingView
        case .error:
            errorView
        case .noSelection:
            noSelectionView
        }
    }
    
    // MARK: - Loaded State
    
    @ViewBuilder
    private func loadedView(barrage: Barrage) -> some View {
        VStack(alignment: .leading) {
            Text(barrage.barajAdi)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(barrage.dolulukOrani, format: .number.precision(.fractionLength(1)).locale(Locale(identifier: "tr_TR")))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("%")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(fillColor(for: barrage.dolulukOrani))
                            .frame(width: geometry.size.width * CGFloat(barrage.dolulukOrani / 100.0))
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    // MARK: - Loading State
    
    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .tint(.blue)
            Text("Yükleniyor...")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    // MARK: - Error State
    
    private var errorView: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(.orange)
            Text("Veri yüklenemedi")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    // MARK: - No Selection State
    
    private var noSelectionView: some View {
        VStack(spacing: 8) {
            Image(systemName: "drop.circle")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            Text("Baraj seçin")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    
    // MARK: - Helpers
    
    private func fillColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<30:
            return .red
        case 30..<60:
            return .orange
        case 60..<80:
            return .yellow
        default:
            return .green
        }
    }
}

// MARK: - Preview

#Preview("Yüklü Durum", as: .systemSmall) {
    BarrageWidget()
} timeline: {
    BarrageWidgetEntry(
        date: Date(),
        barrage: Barrage(
            id: 1,
            barajAdi: "Alaçatı Kutlu Aktaş Barajı",
            dolulukOrani: 44.2,
            hacim: nil,
            mevcutSuDurumu: nil,
            suSeviyesi: nil,
            maksimumSuYuksekligi: nil,
            minimumSuYuksekligi: nil,
            guncellemeTarihi: nil
        ),
        lastUpdate: Date(),
        state: .loaded
    )
}

#Preview("Hata Durumu", as: .systemSmall) {
    BarrageWidget()
} timeline: {
    BarrageWidgetEntry(
        date: Date(),
        barrage: nil,
        lastUpdate: nil,
        state: .error
    )
}

#Preview("Seçim Yok", as: .systemSmall) {
    BarrageWidget()
} timeline: {
    BarrageWidgetEntry(
        date: Date(),
        barrage: nil,
        lastUpdate: Date(),
        state: .noSelection
    )
}
