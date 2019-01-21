import UIKit
import NorthLayout
import Caerula

class RadarViewController: UIViewController {
    let radarView: BeaconRadarView

    init(uuids: [UUID]) {
        self.radarView = BeaconRadarView(uuids: uuids)
        super.init(nibName: nil, bundle: nil)
        self.radarView.displayNameForBeacon = { b in
            let n: Double = 2.0
            let tx1m: Double = -59 // assume 0xc5 in the iBeacon payload
            let rssi = Double(b.rssi)
            let m: Double = pow(10.0, (tx1m - rssi) / (10.0 * n))

            switch b.minor {
            case 1: return "🍎Apple" + String(b.rssi)
            case 15: return "🍓Strawberry" + String(b.rssi)
            default: return "🔹[\(b.major),\(b.minor)]\(String(format: "%1.2fm±%1.2f", m, b.accuracy))"
            }
        }
        self.radarView.didDetectBeacon = { b in
            NSLog("%@", "found beacon (\(b.major), \(b.minor))")
            if #available(iOS 10.0, *) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        self.radarView.didChangeBeaconRange = { b in
            NSLog("%@", "changed beacon range: \(b.proximity.rawValue)")
            if #available(iOS 10.0, *) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Radar"
        view.backgroundColor = .black
        radarView.labelColor = .white

        let autolayout = northLayoutFormat([:], ["radar": radarView])
        autolayout("H:|[radar]|")
        autolayout("V:|[radar]|")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        radarView.startRanging()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        radarView.stopRanging()
    }
}
