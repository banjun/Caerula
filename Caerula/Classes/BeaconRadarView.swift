import UIKit
import CoreLocation
import NorthLayout
import Ikemen

private let iosTealBlue = #colorLiteral(red: 0.4119389951, green: 0.8247622848, blue: 0.9853010774, alpha: 1)

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
        layout()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// start ranging beacons with UUIDs
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

    /// stop ranging beacons
    public func stopRanging() {
        regions.forEach {locationManager?.stopRangingBeacons(in: $0)}
        locationManager = nil
        stopPulseAnimation()
    }


    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard self.locationManager != nil else { return }
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            regions.forEach {manager.startRangingBeacons(in: $0)}
            startPulseAnimation()
        case .notDetermined, .restricted, .denied:
            break
        }
    }

    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        NSLog("%@", "didRangeBeacons: \(beacons.count) beacons")
    }

    // MARK: - Radar UI

    private let antenna = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24)) ※ { v in
        v.layer.cornerRadius = v.frame.width / 2
        v.layer.masksToBounds = true
        v.backgroundColor = iosTealBlue
    }

    private let pulse = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24)) ※ { v in
        v.layer.cornerRadius = v.frame.width / 2
        v.layer.masksToBounds = true
        v.backgroundColor = iosTealBlue
    }

    private func layout() {
        let autolayout = northLayoutFormat(["r": antenna.layer.cornerRadius,
                                            "rr": antenna.layer.cornerRadius * 2],
                                           ["antenna": antenna,
                                            "pulse": pulse])
        autolayout("H:[antenna(==rr)]")
        autolayout("H:[pulse(==rr)]")
        autolayout("V:[antenna(==rr)]-rr-|")
        autolayout("V:[pulse(==rr)]-rr-|")

        addConstraint(NSLayoutConstraint(item: antenna, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: pulse, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))

        bringSubview(toFront: antenna)
    }

    private func startPulseAnimation() {
        pulse.layer.add(CAAnimationGroup() ※ { g in
            g.animations = [
                CABasicAnimation(keyPath: #keyPath(CALayer.transform)) ※ { a in
                    a.fromValue = CATransform3DMakeScale(0.2, 0.2, 1)
                    a.toValue = CATransform3DMakeScale(25, 25, 1)
                },
                CABasicAnimation(keyPath: #keyPath(CALayer.opacity)) ※ { a in
                    a.fromValue = 0.75
                    a.toValue = 0
                }]
            g.duration = 2
            g.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            g.repeatCount = .greatestFiniteMagnitude
            }, forKey: "pulse")
    }

    private func stopPulseAnimation() {
        pulse.layer.removeAllAnimations()
    }
}
