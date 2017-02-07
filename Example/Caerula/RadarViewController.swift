import UIKit
import NorthLayout
import Caerula

class RadarViewController: UIViewController {
    let radarView: BeaconRadarView

    init(uuids: [UUID]) {
        self.radarView = BeaconRadarView(uuids: uuids)
        super.init(nibName: nil, bundle: nil)
        self.radarView.displayNameForBeacon = { b in
            switch b.minor {
            case 1: return "🍎Apple"
            case 20: return "🍓Strawberry"
            default: return "🔹Other"
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
