import AppIntents

/// App Shortcuts provider to make intents discoverable by Siri
@available(iOS 17.0, *)
struct BarajizmirAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: BarrageFillRateIntent(),
            phrases:[
                "\(.applicationName) barajların doluluk oranlarını söyle",
                "\(.applicationName) barajların doluluk oranlarını listele",
                "\(.applicationName) tüm barajların doluluk oranını söyle",
                "\(.applicationName) baraj doluluklarını göster",
                "\(.applicationName) baraj doluluklarını listele",
                "\(.applicationName) barajlar yüzde kaç dolu",
                "\(.applicationName) barajlar ne durumda",
                "\(.applicationName) İzmir barajlarının doluluk durumu nedir",
                "\(.applicationName) baraj doluluk bilgisi",
                "\(.applicationName) barajlar dolu mu",
                "\(.applicationName) barajlarda su var mı",
                "\(.applicationName) bana barajların doluluk oranlarını söyler misin",
                "\(.applicationName) baraj doluluk",
                "\(.applicationName) baraj doluluk oranı",
                "\(.applicationName) baraj dolulukları",
                "\(.applicationName) baraj durumu",
                "\(.applicationName) barajlar",
                "\(.applicationName) doluluk oranları",
                "\(.applicationName) İzmir baraj",
                "\(.applicationName) baraj doluluk durumu",
                "\(.applicationName) izmir baraj doluluk",
                "\(.applicationName) baraj su durumu",
                "\(.applicationName) baraj oranları",
                "\(.applicationName) barajlardaki su durumu",
                "\(.applicationName) barajlar kaç dolu",
                "\(.applicationName) barajlar yüzde kaç",
                "\(.applicationName) izmir barajlar dolu mu",
                "\(.applicationName) baraj su",
                "\(.applicationName) su durumu",
                "\(.applicationName) baraj su var mı",
                "\(.applicationName) barajlarda ne kadar su var",
                "barajların doluluk oranlarını \(.applicationName) ile söyle",
                "İzmir barajlarının doluluk durumunu \(.applicationName) ile öğren",
                "baraj doluluk oranları \(.applicationName)",
                "baraj doluluk durumu \(.applicationName)",
                "izmir baraj doluluk \(.applicationName)",
                "\(.applicationName) barajlar hakkında bilgi ver",
                "\(.applicationName) barajların son durumu",
                "\(.applicationName) barajların güncel doluluk durumu",
                "\(.applicationName) izmirde barajlar ne durumda",
                "\(.applicationName) izmirdeki barajlar dolu mu"
            ],
            shortTitle: "Baraj Doluluk Oranı",
            systemImageName: "drop.fill"
        )
    }

    static var shortcutTileColor: ShortcutTileColor {
        .blue
    }
}
