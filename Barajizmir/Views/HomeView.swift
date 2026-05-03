import SwiftUI
import MapKit

struct HomeView: View {
    @StateObject private var viewModel = BarrageViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var sheetDetent: PresentationDetent = .height(240)
    @State private var isInDetail = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 38.43, longitude: 27.24),
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 2.0)
        )
    )

    var body: some View {
        ZStack {
            mapLayer.ignoresSafeArea()
        }
        .sheet(isPresented: .constant(true)) {
            NavigationStack(path: $navigationPath) {
                BarrageListView(viewModel: viewModel) { barrage in
                    navigate(to: barrage)
                }
                .navigationDestination(for: Barrage.self) { barrage in
                    BarrageDetailView(barrage: barrage)
                }
            }
            .presentationDetents(
                isInDetail ? [.height(240), .medium, .large] : [.height(240), .medium],
                selection: $sheetDetent
            )
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .interactiveDismissDisabled()
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
            .onChange(of: navigationPath) { _, path in
                if path.isEmpty {
                    isInDetail = false
                    sheetDetent = .medium
                }
            }
        }
    }

    // MARK: - Map

    // İzmir ili sınırları — bilinen tüm barajları kapsar (Kestel/Çaltıkoru dahil)
    private let minLat: Double = 37.9
    private let maxLat: Double = 39.4
    private let minLon: Double = 26.2
    private let maxLon: Double = 28.5
    private let maxSpanLat: Double = 1.0
    private let maxSpanLon: Double = 1.8

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            ForEach(viewModel.barrages) { barrage in
                if let coordinate = barrage.coordinate {
                    Annotation(barrage.barajAdi, coordinate: coordinate, anchor: .bottom) {
                        BarragePinView(barrage: barrage) {
                            navigate(to: barrage)
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .onMapCameraChange(frequency: .onEnd) { context in
            constrainCamera(to: context.region)
        }
    }

    private func constrainCamera(to region: MKCoordinateRegion) {
        var center = region.center
        var span = region.span
        var needsSnap = false

        if center.latitude > maxLat { center.latitude = maxLat; needsSnap = true }
        if center.latitude < minLat { center.latitude = minLat; needsSnap = true }
        if center.longitude > maxLon { center.longitude = maxLon; needsSnap = true }
        if center.longitude < minLon { center.longitude = minLon; needsSnap = true }
        if span.latitudeDelta > maxSpanLat { span.latitudeDelta = maxSpanLat; needsSnap = true }
        if span.longitudeDelta > maxSpanLon { span.longitudeDelta = maxSpanLon; needsSnap = true }

        if needsSnap {
            withAnimation(.easeOut(duration: 0.25)) {
                cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
            }
        }
    }

    // MARK: - Navigation

    private func navigate(to barrage: Barrage) {
        isInDetail = true
        sheetDetent = .large
        navigationPath.append(barrage)
    }
}

#Preview {
    HomeView()
}
