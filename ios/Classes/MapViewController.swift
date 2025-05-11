import UIKit
import MapKit
import Flutter

class MapViewController: UIViewController {
    private var mapView: MKMapView!
    private var messenger: FlutterBinaryMessenger
    private var button: UIButton!
    private var channel: FlutterMethodChannel!

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init(nibName: nil, bundle: nil)
        setupChannel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupChannel() {
        channel = FlutterMethodChannel(name: "map_kit_view", binaryMessenger: messenger)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupButton()
    }

    private func setupMapView() {
        mapView = MKMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)

            // Set initial map region
        let initialLocation = CLLocation(latitude: 37.7749, longitude: -122.4194) // San Francisco
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegion(
            center: initialLocation.coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius)
            mapView.setRegion(coordinateRegion, animated: true)


//         mapview = NTMapView();
//               let neshan = NTNeshanServices.createBaseMap(NTNeshanMapStyle.NESHAN)
//               mapview?.getLayers().add(neshan)
//
//               let neshan2 = NTNeshanServices.createTrafficLayer()
//               mapview?.getLayers().add(neshan2)
//
//               let neshan3 = NTNeshanServices.createPOILayer(false)
//               mapview?.getLayers().add(neshan3)
//
//               mapview?.setFocalPointPosition(NTLngLat(x:59.2,y:36.5), durationSeconds: 0.4)
//               mapview?.setZoom(13, durationSeconds: 0.4)
//               view=mapview
    }

    private func setupButton() {
        button = UIButton(type: .system)
        button.setTitle("Tap Me!", for: .normal)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            button.widthAnchor.constraint(equalToConstant: 120),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])

        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @objc private func buttonTapped() {
        channel.invokeMethod("onButtonTapped", arguments: nil)
    }
}