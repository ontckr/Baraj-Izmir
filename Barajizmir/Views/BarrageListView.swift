import SwiftUI
import StoreKit

struct BarrageListView: View {
    @StateObject private var viewModel = BarrageViewModel()
    @State private var showAboutSheet = false
    @Environment(\.requestReview) private var requestReview
    
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
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                    .onAppear {
                        checkAndRequestReview()
                    }
                }
            }
            .navigationTitle("Baraj İzmir")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAboutSheet = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showAboutSheet) {
                AboutView()
                    .presentationDetents([.height(200)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func checkAndRequestReview() {
        Task { @MainActor in
            if ReviewManager.shared.shouldRequestReview() {
                try? await Task.sleep(for: .seconds(1.5))
                requestReview()
                ReviewManager.shared.markReviewRequested()
            }
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
