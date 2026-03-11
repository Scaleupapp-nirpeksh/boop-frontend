import SwiftUI
import CoreLocation

struct LocationView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var locationManager = LocationHelper()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                BoopSectionIntro(
                    title: "Your city",
                    eyebrow: "Location"
                )

                BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
                    VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                        BoopTextField(
                            label: "City",
                            text: $viewModel.city,
                            placeholder: "Mumbai, Delhi, Bangalore..."
                        )

                        Button {
                            locationManager.requestLocation { city, coords in
                                viewModel.city = city
                                viewModel.coordinates = coords
                            }
                        } label: {
                            HStack(spacing: BoopSpacing.xs) {
                                Image(systemName: "location.fill")
                                    .foregroundStyle(BoopColors.secondary)
                                Text("Use my current location")
                                    .font(BoopTypography.callout)
                                    .foregroundStyle(BoopColors.secondary)
                            }
                            .padding(.vertical, BoopSpacing.sm)
                            .padding(.horizontal, BoopSpacing.md)
                            .background(BoopColors.secondary.opacity(0.1))
                            .clipShape(Capsule())
                        }

                        if let error = locationManager.error {
                            Text(error)
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.error)
                        }

                        BoopButton(
                            title: "Continue",
                            isLoading: viewModel.isLoading,
                            isDisabled: !viewModel.canProceedLocation
                        ) {
                            viewModel.advanceStep()
                        }
                    }
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .onTapGesture { hideKeyboard() }
    }
}

// MARK: - Location Helper

@Observable
class LocationHelper: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var error: String?
    private var completion: ((String, [Double]?) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocation(completion: @escaping (String, [Double]?) -> Void) {
        self.completion = completion
        error = nil
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        let coords = [location.coordinate.longitude, location.coordinate.latitude]

        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                let city = placemarks?.first?.locality ?? "Unknown"
                self?.completion?(city, coords)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = "Could not determine your location"
    }
}
