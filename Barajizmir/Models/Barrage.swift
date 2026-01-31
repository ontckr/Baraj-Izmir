import Foundation

struct Barrage: Codable, Identifiable {
    let id: Int
    let barajAdi: String
    let dolulukOrani: Double
    let hacim: Double?
    let suSeviyesi: Double?
    let guncellemeTarihi: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "BarajKuyuId"
        case barajAdi = "BarajKuyuAdi"
        case dolulukOrani = "DolulukOrani"
        case hacim = "MaksimumSuKapasitesi"
        case suSeviyesi = "SuYuksekligi"
        case guncellemeTarihi = "DurumTarihi"
    }
}
