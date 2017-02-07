import Foundation
import UIKit
import CoreLocation
import NorthLayout
import Ikemen

private let iosTealBlue = #colorLiteral(red: 0.4119389951, green: 0.8247622848, blue: 0.9853010774, alpha: 1)
private let maxLabels = 20 // all labels are prepared on initialize. overflowed beacons are not displayed on labels.
private let beaconTimeout: TimeInterval = 20 // disappear after this secs with invisible state

public class BeaconRadarView: UIView, CLLocationManagerDelegate {
    public var uuids: [UUID] {
        didSet {
            // TODO: restart ranging with new uuids
            regions = uuids.map {CLBeaconRegion(proximityUUID: $0, identifier: $0.uuidString)}
        }
    }

    /// callback for beacon display name customization. return nil to use default name
    public var displayNameForBeacon: (CLBeacon) -> String? = {_ in nil}
    public let defaultDisplayNameForBeacon: (CLBeacon) -> String = {b in "🔹(\(b.major), \(b.minor))"}

    public struct ScannedBeacon {
        var lastFound: Date
        var beacon: CLBeacon
        fileprivate var label: UILabel?
        fileprivate var behavior: UIAttachmentBehavior?

        init(lastFound: Date, beacon: CLBeacon) {
            self.lastFound = lastFound
            self.beacon = beacon
        }
    }
    public private(set) var visibleBeacons: [ScannedBeacon] = []

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
        // beacons is sorted by distance (nearest first). (documented)
        // called every 1 sec even nothing happened.
        // notified visible beacons on that time (or within 10 secs from last seen)
        // NSLog("%@", "didRangeBeacons: \(beacons.count) beacons")
        let now = Date()

        beacons.forEach { b in
            if let i = (visibleBeacons.index {$0.beacon.proximityUUID == b.proximityUUID && $0.beacon.major == b.major && $0.beacon.minor == b.minor}) {
                visibleBeacons[i].lastFound = now
                visibleBeacons[i].beacon = b
            } else {
                visibleBeacons.append(ScannedBeacon(lastFound: now, beacon: b))
            }
        }
        visibleBeacons = visibleBeacons.filter {now.timeIntervalSince($0.lastFound) < beaconTimeout}.sorted {$0.lastFound < $1.lastFound}
        updateBeaconLabels()
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

    private lazy var dynamicAnimator: UIDynamicAnimator = UIDynamicAnimator(referenceView: self) ※ { a in
        self.preparedLabels.forEach {
            self.itemBehavior.addItem($0)
            self.boundaryBehavior.addItem($0)
            self.collisionBehavior.addItem($0)
        }
        a.addBehavior(self.itemBehavior)
        a.addBehavior(self.boundaryBehavior)
        a.addBehavior(self.collisionBehavior)
    }

    private let itemBehavior = UIDynamicItemBehavior() ※ { b in
        b.density = 1
        b.elasticity = 0
        b.resistance = 1
        b.angularResistance = .greatestFiniteMagnitude
        b.allowsRotation = false
    }

    private let boundaryBehavior = UICollisionBehavior(items: []) ※ { b in
        // collision detection on view bounds is always enabled.
        b.translatesReferenceBoundsIntoBoundary = true
        b.collisionMode = .boundaries
    }

    private let collisionBehavior = UICollisionBehavior(items: []) ※ { b in
        // collision detection on some items will be disabled on move.
        // separate view bounds detection to boundaryBehavior.
        b.translatesReferenceBoundsIntoBoundary = true
        b.collisionMode = .everything
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

    private lazy var preparedLabels: [UILabel] = (0..<maxLabels).map {_ in
        let l = UILabel()
        l.font = .boldSystemFont(ofSize: 16)
        l.textColor = .white
        l.isHidden = true
        l.text = "." // non-zero for UIDynamics
        l.sizeToFit()
        self.addSubview(l)
        return l
    }
    /// customizable label color
    public var labelColor: UIColor {
        get {return preparedLabels.first!.textColor}
        set {preparedLabels.forEach {$0.textColor = newValue}}
    }

    private func updateBeaconLabels() {
        for i in 0..<self.visibleBeacons.count {
            let b = self.visibleBeacons[i].beacon

            if self.visibleBeacons[i].label == nil {
                guard let usableLabel = (self.preparedLabels.first {l in !self.visibleBeacons.contains {$0.label == l}}) else { continue }
                usableLabel.text = self.displayNameForBeacon(b) ?? self.defaultDisplayNameForBeacon(b)
                usableLabel.sizeToFit() // for dynamicAnimator
                usableLabel.center.x = CGFloat(arc4random() % 100) * self.bounds.width / 100
                self.updateDynamicItemSizes()
                self.visibleBeacons[i].label = usableLabel
            }
            guard let l = self.visibleBeacons[i].label else { continue }

            let behavior = self.visibleBeacons[i].behavior ?? (UIAttachmentBehavior(item: l, attachedToAnchor: self.antenna.center) ※ {
                $0.frequency = 2
                $0.damping = 1
                $0.frictionTorque = 1
                self.dynamicAnimator.addBehavior($0)
                })
            self.visibleBeacons[i].behavior = behavior
            behavior.anchorPoint = self.antenna.center

            if !bounds.contains(l.center) {
                // re-position: out-of-bounds may be caused by screen orientation change
                l.center.x = CGFloat(arc4random() % 100) * bounds.width / 100
                l.center.y = bounds.height / 2
                dynamicAnimator.updateItem(usingCurrentState: l)
            }

            func moveToDistance(_ distance: CGFloat) {
                // NSLog("%@", "move \(b.minor): \(behavior.length) -> \(distance)")
                // disable collision detection for the moving item (make flyable over other items)
                self.collisionBehavior.removeItem(l)
                behavior.length = distance

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.collisionBehavior.addItem(l)
                    self.updateDynamicItemSizes()
                }
            }

            func changeAlpha(_ alpha: CGFloat) {
                UIView.animate(withDuration: 0.5) {
                    l.alpha = alpha
                }
            }

            switch b.proximity {
            case .immediate:
                changeAlpha(1)
                moveToDistance(self.bounds.height * 0.2)
            case .near:
                changeAlpha(1)
                moveToDistance(self.bounds.height * 0.4)
            case .far:
                changeAlpha(1)
                moveToDistance(self.bounds.height * 0.8)
            case .unknown:
                changeAlpha(0.5)
            }
        }

        self.preparedLabels.forEach {l in l.isHidden = !self.visibleBeacons.contains {$0.label == l}}
    }

    private func updateDynamicItemSizes() {
        // As UICollisionBehavior behave as its initial items sizes,
        // Reloading is required after resizing items.
        // The method is not available in the API.
        // The only way we can do that is to removeAllBehaviors and add again
        let allBehaviors = dynamicAnimator.behaviors
        dynamicAnimator.removeAllBehaviors()
        allBehaviors.forEach {dynamicAnimator.addBehavior($0)}
    }
}
