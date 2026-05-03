# Baraj İzmir

İzmir'deki barajların doluluk oranlarını gerçek zamanlı olarak takip eden iOS uygulaması.

## Özellikler

**Harita Görünümü** — Tüm barajlar İzmir haritasında renkli pinlerle gösterilir. Pine dokunarak baraj detayına ulaşılır.

**Doluluk Animasyonu** — Detay ekranında gerçek doluluk oranına göre animasyonlu su görseli. Telefonu eğilterek su hareket eder, sallayınca baloncuklar çıkar.

**Eşik Bildirimleri** — Her baraj için özelleştirilebilir doluluk eşiği. Oran belirlenen değerin altına düşünce bildirim gelir.

**Widget** — Ana ekrana eklenebilen widget ile tek bakışta doluluk durumu.

**Siri Entegrasyonu** — "Barajların doluluk oranı ne?" gibi komutlarla sesli bilgi alınabilir.

## Teknik Altyapı

Veriler saatte bir GitHub Actions aracılığıyla İzmir Büyükşehir Belediyesi Open API'ından çekilerek Supabase veritabanında saklanır. iOS uygulaması doğrudan Supabase'den beslenir.

```
GitHub Actions (saatlik)
  → İzmir Open API
  → Supabase

iOS Uygulaması
  → Supabase → Ekran
  → App Group cache → Widget & Siri
```

**Kullanılan Teknolojiler:** Swift, SwiftUI, MapKit, WidgetKit, App Intents, CoreMotion, UserNotifications, BackgroundTasks, Supabase

## Gereksinimler

- iOS 17.0+
- Xcode 15.0+

## Kurulum

1. Repoyu klonla
2. `Barajizmir.xcodeproj` dosyasını aç
3. `SupabaseService.swift` içindeki `projectURL` ve `anonKey` değerlerini gir
4. Build al ve çalıştır (⌘R)

## Veri Kaynağı

[İzmir Büyükşehir Belediyesi Açık Veri Platformu](https://openapi.izmir.bel.tr)

---

Made with ♥ for İzmir
