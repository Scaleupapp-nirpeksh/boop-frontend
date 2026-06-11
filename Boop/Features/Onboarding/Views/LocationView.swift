import SwiftUI
import CoreLocation

struct LocationView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var locationManager = LocationHelper()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                VStack(alignment: .leading, spacing: BoopSpacing.md) {
                    AccentRule()
                    EyebrowLabel(text: "Location", color: BoopColors.textMuted)
                    Text("Where are you based?")
                        .font(BoopTypography.cineTitle)
                        .foregroundStyle(BoopColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

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
                        HStack(spacing: BoopSpacing.sm) {
                            Image(systemName: "location")
                                .font(.system(size: 13, weight: .thin))
                            Text("Use my current location")
                                .font(BoopTypography.cineLabel)
                                .tracking(2)
                            Spacer()
                        }
                        .foregroundStyle(BoopColors.accentColor)
                        .padding(.vertical, BoopSpacing.sm)
                    }
                    .buttonStyle(.plain)

                    if let error = locationManager.error {
                        Text(error)
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.error)
                    }
                }

                BoopButton(
                    title: "Continue",
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.canProceedLocation
                ) {
                    viewModel.advanceStep()
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .background(BoopColors.ground.ignoresSafeArea())
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
