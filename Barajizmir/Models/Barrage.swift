import Foundation
import CoreLocation

struct Barrage: Codable, Identifiable, Hashable {
    let id: Int
    let barajAdi: String
    let dolulukOrani: Double
    let hacim: Double?
    let mevcutSuDurumu: Double?
    let suSeviyesi: Double?
    let maksimumSuYuksekligi: Double?
    let minimumSuYuksekligi: Double?
    let guncellemeTarihi: String?
    let enlem: String?
    let boylam: String?

    enum CodingKeys: String, CodingKey {
        case id = "BarajKuyuId"
        case barajAdi = "BarajKuyuAdi"
        case dolulukOrani = "DolulukOrani"
        case hacim = "MaksimumSuKapasitesi"
        case mevcutSuDurumu = "SuDurumu"
        case suSeviyesi = "SuYuksekligi"
        case maksimumSuYuksekligi = "MaksimumSuYuksekligi"
        case minimumSuYuksekligi = "MinimumSuYuksekligi"
        case guncellemeTarihi = "DurumTarihi"
        case enlem = "Enlem"
        case boylam = "Boylam"
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latStr = enlem, let lonStr = boylam,
              let lat = Double(latStr), let lon = Double(lonStr) else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
