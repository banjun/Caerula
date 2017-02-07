import UIKit
import NorthLayout
import Ikemen

class ViewController: UIViewController {
    private var defaultsUUIDs: [String] {
        get {return UserDefaults.standard.array(forKey: "uuids") as? [String] ?? []}
        set {UserDefaults.standard.set(newValue, forKey: "uuids")}
    }

    private lazy var uuid1Field: UITextField = UITextField() ※ {
        $0.placeholder = "UUID to monitor"
        $0.text = self.defaultsUUIDs.count > 0 ? self.defaultsUUIDs[0] : nil
        $0.borderStyle = .roundedRect
    }
    private lazy var uuid2Field: UITextField = UITextField() ※ {
        $0.placeholder = "UUID to monitor"
        $0.text = self.defaultsUUIDs.count > 1 ? self.defaultsUUIDs[1] : nil
        $0.borderStyle = .roundedRect
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {fatalError()}

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Caerula"
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Radar", style: .plain, target: self, action: #selector(showRadar))
        let autolayout = northLayoutFormat(["p": 8], [
            "uuid1": uuid1Field,
            "uuid2": uuid2Field,
            ])
        autolayout("H:|-p-[uuid1]-p-|")
        autolayout("H:|-p-[uuid2]-p-|")
        autolayout("V:|-p-[uuid1]-[uuid2]")
    }

    @objc private func showRadar() {
        let uuids = [uuid1Field, uuid2Field].flatMap {$0.text}.flatMap {UUID(uuidString: $0)}
        func showVC() {
            show(RadarViewController(uuids: uuids), sender: nil)
        }
        defaultsUUIDs = uuids.map {$0.uuidString}

        if uuids.isEmpty {
            let ac = UIAlertController(title: nil, message: "No UUIDs monitored", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Proceed", style: .default) {_ in showVC()})
            present(ac, animated: true, completion: nil)
        } else {
            showVC()
        }
    }
}

