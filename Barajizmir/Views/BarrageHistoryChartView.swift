import SwiftUI
import Charts


struct BarrageHistoryChartView: View {
    let barrage: Barrage

    @State private var selectedRange: ChartRange = .month
    @State private var data: [BarrageHistoryPoint] = []
    @State private var isLoading = false
    @State private var selectedDate: Date?

    private var selectedPoint: BarrageHistoryPoint? {
        guard let selectedDate else { return nil }
        return data.min(by: {
            abs($0.capturedAt.timeIntervalSince(selectedDate)) <
            abs($1.capturedAt.timeIntervalSince(selectedDate))
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            rangePicker
            if isLoading {
                loadingState
            } else if data.isEmpty {
                emptyState
            } else {
                chart
                footer
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .task(id: selectedRange) {
            await loadData()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Label("Doluluk Geçmişi", systemImage: "chart.xyaxis.line")
                .font(.headline)
            Spacer()
            if let first = data.first, let last = data.last {
                let diff = last.dolulukOrani - first.dolulukOrani
                Label(
                    String(format: "%+.1f%%", diff),
                    systemImage: diff >= 0 ? "arrow.up.right" : "arrow.down.right"
                )
                .font(.caption.bold())
                .foregroundColor(diff >= 0 ? .green : .red)
            }
        }
    }

    // MARK: - Range Picker

    private var rangePicker: some View {
        Picker("Aralık", selection: $selectedRange) {
            ForEach(ChartRange.allCases, id: \.self) {
                Text($0.rawValue).tag($0)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            ForEach(data) { point in
                AreaMark(
                    x: .value("Tarih", point.capturedAt, unit: .day),
                    yStart: .value("", max(yMin, 0)),
                    yEnd: .value("Doluluk", point.dolulukOrani)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [fillColor.opacity(0.35), fillColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Tarih", point.capturedAt, unit: .day),
                    y: .value("Doluluk", point.dolulukOrani)
                )
                .foregroundStyle(fillColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }

            if let last = data.last {
                PointMark(
                    x: .value("Tarih", last.capturedAt, unit: .day),
                    y: .value("Doluluk", last.dolulukOrani)
                )
                .foregroundStyle(fillColor)
                .symbolSize(55)

                PointMark(
                    x: .value("Tarih", last.capturedAt, unit: .day),
                    y: .value("Doluluk", last.dolulukOrani)
                )
                .foregroundStyle(.white)
                .symbolSize(18)
            }

            if let selected = selectedPoint {
                RuleMark(x: .value("Seçili", selected.capturedAt, unit: .day))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                    .annotation(position: .top, alignment: .center, spacing: 6) {
                        VStack(spacing: 2) {
                            Text(selected.capturedAt.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "tr_TR"))))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%%%.1f", selected.dolulukOrani))
                                .font(.subheadline.bold())
                                .foregroundStyle(fillColor)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(uiColor: .systemBackground))
                                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                        )
                    }
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartYScale(domain: max(yMin, 0)...min(yMax, 100))
        .chartXAxis {
            AxisMarks(
                values: .stride(by: selectedRange.xStride, count: selectedRange.xStrideCount)
            ) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                AxisValueLabel(format: selectedRange.xLabelFormat, centered: true)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: 20)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.secondary.opacity(0.3))
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("%\(Int(v))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(height: 180)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            statItem(label: "En Düşük",  value: data.map(\.dolulukOrani).min() ?? 0)
            Spacer()
            statItem(label: "Ortalama",  value: data.map(\.dolulukOrani).reduce(0, +) / Double(data.count))
            Spacer()
            statItem(label: "En Yüksek", value: data.map(\.dolulukOrani).max() ?? 0)
        }
        .padding(.top, 4)
    }

    private func statItem(label: String, value: Double) -> some View {
        VStack(spacing: 2) {
            Text(String(format: "%%%.1f", value))
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - States

    private var loadingState: some View {
        HStack {
            Spacer()
            ProgressView().padding(.vertical, 40)
            Spacer()
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Henüz yeterli veri yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 32)
            Spacer()
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        data = await SupabaseService.shared.fetchHistory(barrageId: barrage.id, range: selectedRange)
        isLoading = false
    }

    // MARK: - Helpers

    private var yMin: Double { (data.map(\.dolulukOrani).min() ?? 0) - 5 }
    private var yMax: Double { (data.map(\.dolulukOrani).max() ?? 100) + 5 }

    private var fillColor: Color {
        switch barrage.dolulukOrani {
        case 0..<30:  return .red
        case 30..<60: return .orange
        case 60..<80: return Color(red: 0.85, green: 0.65, blue: 0.0)
        default:      return Color(red: 0.2, green: 0.7, blue: 0.3)
        }
    }
}

#Preview {
    let barrage = Barrage(
        id: 235,
        barajAdi: "Gördes Barajı",
        dolulukOrani: 41.56,
        hacim: nil, mevcutSuDurumu: nil, suSeviyesi: nil,
        maksimumSuYuksekligi: nil, minimumSuYuksekligi: nil,
        guncellemeTarihi: nil, enlem: nil, boylam: nil
    )
    BarrageHistoryChartView(barrage: barrage)
        .padding()
}
