# Baraj İzmir 💧

iOS app for monitoring İzmir's dam water levels with realistic water visualization and motion effects.

## 📱 Features

- **Home Screen**: Real-time barrage list sorted by fill percentage with color-coded indicators
- **Detail Screen**: Animated water visualization with device tilt and shake detection
- **Offline Support**: Automatic caching with silent fallback

## 🎨 Water Visualization

- Dynamic fill level based on actual percentage
- Continuous sine wave animation
- Device tilt response using CoreMotion
- Natural blue gradient
- 60 FPS motion updates

## 🏗️ Architecture

**MVVM Pattern** with SwiftUI:
- **Model**: `Barrage` (Codable struct)
- **ViewModel**: `BarrageViewModel` (state management)
- **View**: `BarrageListView`, `BarrageDetailView`
- **Service**: `BarrageService` (actor-based networking)

**Tech Stack**: Swift, SwiftUI, URLSession, CoreMotion, async/await

## 📁 Project Structure

```
Barajizmir/
├── Models/Barrage.swift
├── Services/
│   ├── BarrageService.swift
│   └── MotionManager.swift
├── ViewModels/BarrageViewModel.swift
├── Views/
│   ├── BarrageListView.swift
│   ├── BarrageDetailView.swift
│   └── WaterWave.swift
└── Extensions/NumberFormatter+Extensions.swift
```

## 🌐 API

**Endpoint**: `https://openapi.izmir.bel.tr/api/izsu/barajdurum`

Public API, no authentication required. Returns JSON array of barrage data.

## 🚀 Getting Started

### Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### Installation
1. Clone repository
2. Open `Barajizmir.xcodeproj`
3. Build and run (⌘R)

## 📄 License

Built for İzmir residents. Data provided by [İzmir Büyükşehir Belediyesi Open Data API](https://openapi.izmir.bel.tr).

---

**Made with 💙 for İzmir**
