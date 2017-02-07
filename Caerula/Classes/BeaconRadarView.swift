import UIKit
import CoreLocation

public class BeaconRadarView: UIView, CLLocationManagerDelegate {
    public var uuids: [UUID] {
        didSet {
            // TODO: restart ranging with new uuids
            regions = uuids.map {CLBeaconRegion(proximityUUID: $0, identifier: $0.uuidString)}
        }
    }
    private var regions: [CLBeaconRegion]
    private var locationManager: CLLocationManager?

    public init(uuids: [UUID]) {
        self.uuids = uuids
        self.regions = uuids.map {CLBeaconRegion(proximityUUID: $0, identifier: $0.uuidString)}
        super.init(frame: .zero)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func startRanging() {
        guard CLLocationManager.isRangingAvailable() else {
            NSLog("%@", "cancelling ranging beacons becauase CLLocationManager.isRangingAvailable() = false")
            return
        }

        let locationManager = CLLocationManager()
        self.locationManager = locationManager
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    public func stopRanging() {
        regions.forEach {locationManager?.stopRangingBeacons(in: $0)}
        locationManager = nil
    }


    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard self.locationManager != nil else { return }
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            regions.forEach {manager.startRangingBeacons(in: $0)}
        case .notDetermined, .restricted, .denied:
            break
        }
    }

    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        NSLog("%@", "didRangeBeacons: \(beacons.count) beacons")
    }
}
