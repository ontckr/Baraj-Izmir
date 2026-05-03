import SwiftUI
import UserNotifications

struct BarrageNotificationSection: View {
    let barrage: Barrage

    @State private var isEnabled = false
    @State private var threshold: Double = 40
    @State private var showSettingsAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            toggleRow
            if isEnabled {
                Divider()
                sliderRow
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .onAppear(perform: loadSavedPreference)
        .alert("Bildirim İzni Gerekli", isPresented: $showSettingsAlert) {
            Button("Ayarları Aç") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("İptal", role: .cancel) {
                isEnabled = false
            }
        } message: {
            Text("Bildirim alabilmek için Ayarlar > Baraj İzmir > Bildirimler bölümünden izin vermeniz gerekiyor.")
        }
    }

    // MARK: - Toggle Row

    private var toggleRow: some View {
        HStack {
            Label("Doluluk Bildirimi", systemImage: "bell.fill")
                .font(.headline)
            Spacer()
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .onChange(of: isEnabled) { _, enabled in
                    handleToggleChange(enabled)
                }
        }
    }

    // MARK: - Slider Row

    private var sliderRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Eşik Değeri")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("%\(Int(threshold))")
                    .font(.title3.bold())
                    .foregroundColor(thresholdColor)
            }

            Slider(value: $threshold, in: 10...90, step: 1)
                .tint(thresholdColor)
                .onChange(of: threshold) {
                    savePreference()
                }

            Text(thresholdDescription)
                .font(.caption)
                .foregroundColor(barrage.dolulukOrani <= threshold ? .orange : .secondary)
        }
    }

    // MARK: - Helpers

    private var thresholdColor: Color {
        switch threshold {
        case 0..<30:  return .red
        case 30..<60: return .orange
        default:      return .green
        }
    }

    private var thresholdDescription: String {
        if barrage.dolulukOrani <= threshold {
            return "Baraj şu an zaten %\(Int(threshold)) eşiğinin altında (%\(String(format: "%.1f", barrage.dolulukOrani))). Doluluk yükselip tekrar düşünce bildirim alırsın."
        }
        return "Doluluk %\(Int(threshold))'in altına düşünce bildirim alırsın."
    }

    private func loadSavedPreference() {
        guard let saved = NotificationManager.shared.loadThreshold(for: barrage.id) else { return }
        isEnabled = saved.isEnabled
        threshold = saved.threshold
    }

    private func savePreference() {
        NotificationManager.shared.saveThreshold(NotificationThreshold(
            barrageId: barrage.id,
            barajAdi: barrage.barajAdi,
            threshold: threshold,
            isEnabled: isEnabled
        ))
    }

    private func handleToggleChange(_ enabled: Bool) {
        guard enabled else {
            NotificationManager.shared.removeThreshold(for: barrage.id)
            return
        }

        Task { @MainActor in
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                savePreference()
            case .notDetermined:
                let granted = (try? await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound])) ?? false
                if granted {
                    savePreference()
                } else {
                    isEnabled = false
                }
            case .denied:
                showSettingsAlert = true
            @unknown default:
                isEnabled = false
            }
        }
    }
}

#Preview {
    BarrageNotificationSection(barrage: Barrage(
        id: 1,
        barajAdi: "Tahtalı Barajı",
        dolulukOrani: 45.0,
        hacim: nil, mevcutSuDurumu: nil, suSeviyesi: nil,
        maksimumSuYuksekligi: nil, minimumSuYuksekligi: nil,
        guncellemeTarihi: nil, enlem: nil, boylam: nil
    ))
    .padding()
}
