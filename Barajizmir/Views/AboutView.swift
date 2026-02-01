import SwiftUI
import UIKit

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    if let appIcon = appIcon {
                        Image(uiImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .cornerRadius(12)
                    } else {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Baraj İzmir")
                            .font(.headline)
                        if let version = appVersion {
                            Text("Versiyon \(version)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                
                Text("Bu uygulama İzmir Büyükşehir Belediyesi'nin Açık Veri Portalı'nı kullanmaktadır. Veriler anlık olarak güncellenmektedir.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                Link(destination: URL(string: "https://ontckr.github.io/Baraj-Izmir/privacy-policy.html")!) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        Text("Gizlilik Politikası")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .padding(.bottom, 12)
            
            Text("#suhayattır")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.5))
        }
    }
    
    // MARK: - App Version
    private var appVersion: String? {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
              else {
            return nil
        }
        return "\(version)"
    }
    
    // MARK: - App Icon
    private var appIcon: UIImage? {
        if let icon = UIImage(named: "AppIcon") {
            return icon
        }
    
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String] {
            for iconName in iconFiles.reversed() {
                if let icon = UIImage(named: iconName) {
                    return icon
                }
            }
        }
        return nil
    }
}

#Preview {
    AboutView()
        .frame(height: 200)
}
