import CoreLocation

/// الموقع (لمواقيت الصلاة) والاتجاه (لبوصلة القبلة)
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var onLocation: ((Double, Double) -> Void)?
    var onHeading: ((Double) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.headingFilter = 2
    }

    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
        default: break
        }
    }

    func setHeading(_ on: Bool) {
        if on { manager.startUpdatingHeading() } else { manager.stopUpdatingHeading() }
    }

    func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        if m.authorizationStatus == .authorizedWhenInUse || m.authorizationStatus == .authorizedAlways {
            m.requestLocation()
        }
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let c = locations.last?.coordinate else { return }
        onLocation?(c.latitude, c.longitude)
    }

    func locationManager(_ m: CLLocationManager, didUpdateHeading h: CLHeading) {
        onHeading?(h.trueHeading >= 0 ? h.trueHeading : h.magneticHeading)
    }

    func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {}
}
