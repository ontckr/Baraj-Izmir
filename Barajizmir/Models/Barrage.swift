import Foundation

struct Barrage: Codable, Identifiable {
    let id: Int
    let barajAdi: String
    let dolulukOrani: Double
    let hacim: Double?
    let mevcutSuDurumu: Double?
    let suSeviyesi: Double?
    let maksimumSuYuksekligi: Double?
    let minimumSuYuksekligi: Double?
    let guncellemeTarihi: String?
    
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
    }
}
