import SwiftUI
import StoreKit

struct BarrageListView: View {
    @ObservedObject var viewModel: BarrageViewModel
    @State private var showAbout = false
    @Environment(\.requestReview) private var requestReview

    let onSelect: (Barrage) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            if viewModel.hasAPIError {
                errorBanner
            }
            listContent
        }
        .onAppear {
            checkAndRequestReview()
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Barajlar")
                    .font(.title2.bold())
                if let lastUpdate = viewModel.lastUpdate {
                    Text(lastUpdate.formatTurkish())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if viewModel.isLoadingFromAPI {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.trailing, 4)
            }
            Button {
                showAbout = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    // MARK: - Error Banner

    private var errorBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
            Text("Bağlantı yok · önbellek gösteriliyor")
        }
        .font(.caption)
        .foregroundColor(.orange)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - List

    @ViewBuilder
    private var listContent: some View {
        if viewModel.barrages.isEmpty {
            Spacer()
            VStack(spacing: 12) {
                ProgressView()
                Text("Veri yükleniyor...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        } else {
            List {
                ForEach(viewModel.barrages) { barrage in
                    Button {
                        onSelect(barrage)
                    } label: {
                        BarrageRowView(barrage: barrage)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    // MARK: - Review

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

// MARK: - Row

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
            Text("%\(String(format: "%.1f", barrage.dolulukOrani))")
                .font(.title3.bold())
                .foregroundColor(fillColor(for: barrage.dolulukOrani))
        }
        .padding(.vertical, 4)
    }

    private func fillColor(for percentage: Double) -> Color {
        switch percentage {
        case 70...:   return .blue
        case 40..<70: return .orange
        default:      return .red
        }
    }
}
