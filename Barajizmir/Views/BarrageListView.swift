import SwiftUI

struct BarrageListView: View {
    @StateObject private var viewModel = BarrageViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.barrages.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue.opacity(0.3))
                        Text("Veri yükleniyor...")
                            .foregroundColor(.secondary)
                    }
                    .onAppear {
                        print("⏳ Empty list screen showing - barrage count: \(viewModel.barrages.count)")
                    }
                } else {
                    List {
                        Section {
                            ForEach(viewModel.barrages) { barrage in
                                NavigationLink(destination: BarrageDetailView(barrage: barrage)) {
                                    BarrageRowView(barrage: barrage)
                                }
                            }
                        } header: {
                            if let lastUpdate = viewModel.lastUpdate {
                                Text("Son Güncelleme: \(lastUpdate.formatTurkish())")
                                    .font(.caption)
                                    .textCase(nil)
                            }
                        }
                        
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gizlilik ve Kullanım")
                                    .font(.headline)
                                Text("Bu uygulama İzmir Büyükşehir Belediyesi'nin açık veri API'sini kullanmaktadır. Veriler anlık olarak güncellenmekte ve cihazınızda saklanmaktadır.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Baraj İzmir")
        }
    }
}

struct BarrageRowView: View {
    let barrage: Barrage
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(barrage.barajAdi)
                    .font(.headline)
                if let hacim = barrage.hacim {
                    Text("Hacim: \(hacim.formatWithDots()) m³")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("%\(String(format: "%.1f", barrage.dolulukOrani))")
                    .font(.title3.bold())
                    .foregroundColor(colorForPercentage(barrage.dolulukOrani))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForPercentage(_ percentage: Double) -> Color {
        switch percentage {
        case 70...:
            return .blue
        case 40..<70:
            return .orange
        default:
            return .red
        }
    }
}

#Preview("Liste Dolu") {
    BarrageListView()
}
