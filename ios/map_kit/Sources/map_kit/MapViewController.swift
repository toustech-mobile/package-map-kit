import CoreLocation
import Flutter
import MapLibre
import UIKit

private final class MapContainer: UIView {
    var onLayout: (() -> Void)?
    override func layoutSubviews() { super.layoutSubviews(); onLayout?() }
}

// All accepted calls complete once, including timeout and disposal paths.
private final class MapReply {
    private var result: FlutterResult?
    init(_ result: @escaping FlutterResult) { self.result = result }
    func complete(_ value: Any? = nil) { let callback = result; result = nil; callback?(value) }
    func fail(_ code: String, _ message: String) {
        complete(FlutterError(code: code, message: message, details: nil))
    }
}

final class MapKitNativeView: NSObject, FlutterPlatformView, MLNMapViewDelegate, UIGestureRecognizerDelegate {
    static let methods: Set<String> = ["addMarkers", "removeMarkers", "removeAllMarkers",
        "addCircles", "removeCircles", "removeAllCircles", "addPolyLines", "removePolyLines",
        "removeAllPolyLines", "setUserMarker", "moveCamera", "fitBounds", "setMapStyle", "getCamera"]

    private let container: MapContainer
    private var map: MLNMapView?
    private let sendEvent: ([String: Any]) -> Void
    private var markers: [MapMarkerSpec] = []
    private var circles: [MapCircleSpec] = []
    private var lines: [MapLineSpec] = []
    private var user: (point: MapCoordinate, accuracy: Double)?
    private var ownedAnnotations: [MLNAnnotation] = []
    private var markerSpecs: [ObjectIdentifier: MapMarkerSpec] = [:]
    private var userAnnotation: MLNPointAnnotation?
    private var shapeStyles: [ObjectIdentifier: (color: UIColor, width: CGFloat)] = [:]
    private var ready = false
    private var styleLoaded = false
    private var disposed = false
    private var failure: FlutterError?
    private var pending: [(FlutterMethodCall, MapReply)] = []
    private var styleReply: MapReply?
    private var timeout: DispatchWorkItem?
    private var dark = false

    init(frame: CGRect, arguments: Any?, sendEvent: @escaping ([String: Any]) -> Void) {
        container = MapContainer(frame: frame)
        self.sendEvent = sendEvent
        super.init()
        container.onLayout = { [weak self] in self?.becomeReady() }
        do {
            let creation = try MapPayload.object(arguments ?? [:])
            let center = try creation["initialCenter"].map { try MapPayload.coordinate(MapPayload.object($0)) }
                ?? MapCoordinate(latitude: 35.6892, longitude: 51.3890)
            let zoom = try MapPayload.number(creation, "zoom", default: 13)
            dark = try MapPayload.darkMode(["isDarkMode": creation["isDarkMode"] ?? false])
            markers = try MapPayload.objects(creation["markers"] ?? []).map(MapMarkerSpec.init)
            circles = try MapPayload.objects(creation["circles"] ?? []).map(MapCircleSpec.init)
            lines = try MapPayload.objects(creation["polyLines"] ?? []).map(MapLineSpec.init)
            try NeshanConfiguration.configure()
            let nativeMap = MLNMapView(frame: container.bounds, styleURL: Self.styleURL(dark))
            map = nativeMap
            nativeMap.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            nativeMap.delegate = self
            nativeMap.minimumZoomLevel = 2
            nativeMap.maximumZoomLevel = 18
            nativeMap.setCenter(center.native, zoomLevel: zoom, animated: false)
            container.addSubview(nativeMap)
            installGestures(nativeMap)
            startTimeout()
        } catch {
            failure = FlutterError(code: "MAP_INITIALIZATION_FAILED", message: error.localizedDescription, details: nil)
        }
    }

    private static func styleURL(_ dark: Bool) -> URL {
        URL(string: "https://static.neshan.org/sdk/maplibre/styles/\(dark ? "dark" : "light").json")!
    }

    func view() -> UIView { container }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let reply = MapReply(result)
        if disposed { reply.fail("MAP_DISPOSED", "The map has been disposed") }
        else if let failure = failure {
            if call.method == "setMapStyle", map != nil { execute(call, reply) }
            else { reply.complete(failure) }
        } else if !ready { pending.append((call, reply)) }
        else { execute(call, reply) }
    }

    private func execute(_ call: FlutterMethodCall, _ reply: MapReply) {
        guard let map = map else { reply.fail("MAP_NOT_READY", "Map is not ready"); return }
        do {
            switch call.method {
            case "getCamera":
                reply.complete(["zoom": map.zoomLevel, "latitude": map.centerCoordinate.latitude,
                                "longitude": map.centerCoordinate.longitude])
                return
            case "addMarkers": markers += try MapPayload.objects(call.arguments).map(MapMarkerSpec.init)
            case "removeMarkers":
                let points = try MapPayload.objects(call.arguments).map(MapPayload.coordinate)
                for point in points {
                    if let index = markers.firstIndex(where: { $0.point == point }) { markers.remove(at: index) }
                }
            case "removeAllMarkers": markers.removeAll()
            case "addCircles": circles += try MapPayload.objects(call.arguments).map(MapCircleSpec.init)
            case "removeCircles":
                let points = try MapPayload.objects(call.arguments).map(MapPayload.coordinate)
                for point in points {
                    if let index = circles.firstIndex(where: { $0.point == point }) { circles.remove(at: index) }
                }
            case "removeAllCircles": circles.removeAll()
            case "addPolyLines": lines += try MapPayload.objects(call.arguments).map(MapLineSpec.init)
            case "removePolyLines":
                let points = try MapPayload.objects(call.arguments).map { object -> MapCoordinate? in
                    try MapPayload.objects(object["points"]).first.map(MapPayload.coordinate)
                }
                for point in points {
                    if let index = lines.firstIndex(where: { $0.points.first == point }) { lines.remove(at: index) }
                }
            case "removeAllPolyLines": lines.removeAll()
            case "setUserMarker":
                let spec = try MapPayload.object(call.arguments)
                user = (try MapPayload.coordinate(spec), try MapPayload.nonnegative(spec, "accuracy"))
            case "moveCamera":
                let spec = try MapPayload.object(call.arguments)
                let center = try MapPayload.coordinate(spec)
                let zoom = try MapPayload.number(spec, "zoom", default: map.zoomLevel)
                map.setCenter(center.native, zoomLevel: zoom, animated: true)
                reply.complete()
                return
            case "fitBounds":
                try fitBounds(MapPayload.object(call.arguments), map: map)
                reply.complete()
                return
            case "setMapStyle":
                let newDark = try MapPayload.darkMode(MapPayload.object(call.arguments))
                if ready && newDark == dark { reply.complete() }
                else {
                    dark = newDark
                    ready = false
                    styleLoaded = false
                    failure = nil
                    styleReply = reply
                    startTimeout()
                    map.styleURL = Self.styleURL(dark)
                }
                return
            default: reply.complete(FlutterMethodNotImplemented); return
            }
            renderOverlays()
            reply.complete()
        } catch { reply.fail("INVALID_ARGUMENT", error.localizedDescription) }
    }

    private func fitBounds(_ spec: [String: Any], map: MLNMapView) throws {
        var points = try MapPayload.objects(spec["points"]).map(MapPayload.coordinate)
        let padding = try MapPayload.nonnegative(spec, "padding", default: 24)
        guard let first = points.first else { return }
        if points.allSatisfy({ $0 == first }) { map.setCenter(first.native, animated: true); return }
        // Unwrap longitudes around the first point to fit across the date line.
        points = points.map { point in
            var longitude = point.longitude
            while longitude - first.longitude > 180 { longitude -= 360 }
            while longitude - first.longitude < -180 { longitude += 360 }
            return MapCoordinate(latitude: point.latitude, longitude: longitude)
        }
        var coordinates = points.map { $0.native }
        let count = UInt(coordinates.count)
        let maximum = max(0, (min(map.bounds.width, map.bounds.height) - 1) / 2)
        let inset = min(CGFloat(padding), maximum)
        map.setVisibleCoordinates(&coordinates, count: count,
            edgePadding: UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset), animated: true)
    }

    private func startTimeout() {
        timeout?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.failStyle("Timed out loading Neshan style or waiting for map layout")
        }
        timeout = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 45, execute: work)
    }

    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        guard !disposed, failure == nil else { return }
        styleLoaded = true
        becomeReady()
    }

    func mapViewDidFailLoadingMap(_ mapView: MLNMapView, withError error: Error) {
        let nativeError = error as NSError
        NSLog("[map_kit] Neshan map loading failed: domain=%@; code=%ld; iOS bundle=%@",
              nativeError.domain, nativeError.code, Bundle.main.bundleIdentifier ?? "unknown")
        if !ready {
            failStyle("Could not load Neshan style (\(nativeError.domain), \(nativeError.code)); check package key permissions for this iOS bundle and network")
        }
    }

    private func becomeReady() {
        guard !disposed, !ready, failure == nil, styleLoaded,
              container.bounds.width > 0, container.bounds.height > 0 else { return }
        renderOverlays()
        ready = true
        timeout?.cancel()
        timeout = nil
        styleReply?.complete()
        styleReply = nil
        while ready && !pending.isEmpty {
            let (call, reply) = pending.removeFirst()
            execute(call, reply)
        }
    }

    private func failStyle(_ message: String) {
        guard !disposed else { return }
        ready = false
        failure = FlutterError(code: "STYLE_LOAD_FAILED", message: message, details: nil)
        timeout?.cancel()
        timeout = nil
        styleReply?.complete(failure)
        styleReply = nil
        let waiting = pending
        pending.removeAll()
        waiting.forEach { $0.1.complete(failure) }
    }

    private func renderOverlays() {
        guard let map = map else { return }
        map.removeAnnotations(ownedAnnotations)
        ownedAnnotations.removeAll()
        markerSpecs.removeAll()
        shapeStyles.removeAll()
        userAnnotation = nil
        for circle in circles {
            addCircle(circle.point, radius: circle.radius, fill: circle.fill, border: circle.border, width: circle.width)
        }
        for line in lines {
            addLine(line.points.map { $0.native }, color: line.outline, width: line.width + 4)
            addLine(line.points.map { $0.native }, color: line.color, width: line.width)
        }
        if let user = user {
            addCircle(user.point, radius: user.accuracy, fill: UIColor(red: 0.2, green: 0.6, blue: 1, alpha: 0.25),
                      border: UIColor(red: 0.2, green: 0.6, blue: 1, alpha: 1), width: 1)
        }
        for marker in markers {
            let annotation = MLNPointAnnotation()
            annotation.coordinate = marker.point.native
            annotation.title = marker.title ?? ""
            annotation.subtitle = marker.subtitle
            markerSpecs[ObjectIdentifier(annotation)] = marker
            ownedAnnotations.append(annotation)
        }
        if let user = user {
            let annotation = MLNPointAnnotation()
            annotation.coordinate = user.point.native
            userAnnotation = annotation
            ownedAnnotations.append(annotation)
        }
        map.addAnnotations(ownedAnnotations)
    }

    private func addLine(_ points: [CLLocationCoordinate2D], color: UIColor, width: Double) {
        var coordinates = points
        let count = UInt(coordinates.count)
        let line = MLNPolyline(coordinates: &coordinates, count: count)
        shapeStyles[ObjectIdentifier(line)] = (color, CGFloat(width))
        ownedAnnotations.append(line)
    }

    private func addCircle(_ center: MapCoordinate, radius: Double, fill: UIColor, border: UIColor, width: Double) {
        var coordinates = MapGeometry.circle(center, radius: radius)
        let count = UInt(coordinates.count)
        let polygon = MLNPolygon(coordinates: &coordinates, count: count)
        shapeStyles[ObjectIdentifier(polygon)] = (fill, 0)
        ownedAnnotations.append(polygon)
        if width > 0 { addLine(coordinates, color: border, width: width) }
    }

    func mapView(_ mapView: MLNMapView, alphaForShapeAnnotation annotation: MLNShape) -> CGFloat {
        shapeStyles[ObjectIdentifier(annotation)]?.color.cgColor.alpha ?? 1
    }

    func mapView(_ mapView: MLNMapView, strokeColorForShapeAnnotation annotation: MLNShape) -> UIColor {
        if annotation is MLNPolygon { return .clear }
        return shapeStyles[ObjectIdentifier(annotation)]?.color.withAlphaComponent(1) ?? .clear
    }

    func mapView(_ mapView: MLNMapView, fillColorForPolygonAnnotation annotation: MLNPolygon) -> UIColor {
        shapeStyles[ObjectIdentifier(annotation)]?.color.withAlphaComponent(1) ?? .clear
    }

    func mapView(_ mapView: MLNMapView, lineWidthForPolylineAnnotation annotation: MLNPolyline) -> CGFloat {
        shapeStyles[ObjectIdentifier(annotation)]?.width ?? 0
    }

    func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
        guard let point = annotation as? MLNPointAnnotation else { return nil }
        let view = MLNAnnotationView(reuseIdentifier: nil)
        view.scalesWithViewingDistance = false
        if point === userAnnotation {
            view.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
            view.backgroundColor = .systemBlue
            view.layer.cornerRadius = 9
            view.layer.borderColor = UIColor.white.cgColor
            view.layer.borderWidth = 2
            view.isEnabled = false
        } else if let marker = markerSpecs[ObjectIdentifier(point)] {
            let size = CGFloat(marker.size)
            view.frame = CGRect(x: 0, y: 0, width: size, height: size)
            view.centerOffset = CGVector(dx: 0, dy: -size / 2)
            let image = UIImageView(frame: view.bounds)
            image.contentMode = .scaleAspectFit
            image.image = marker.image ?? UIImage(named: marker.icon.replacingOccurrences(of: ".svg", with: ""))
                ?? UIImage(systemName: "mappin.circle.fill")?.withTintColor(.systemRed, renderingMode: .alwaysOriginal)
            view.addSubview(image)
            let contentCenter = CGPoint(x: size / 2, y: size * CGFloat(marker.contentCenterY))
            if let contentImage = marker.contentImage ?? UIImage(named: marker.content.replacingOccurrences(of: ".svg", with: "")) {
                let content = UIImageView(frame: view.bounds.insetBy(dx: size / 4, dy: size / 4))
                content.center = contentCenter
                content.contentMode = .scaleAspectFit
                content.image = contentImage
                view.addSubview(content)
            } else if !marker.content.isEmpty {
                let label = UILabel(frame: view.bounds.insetBy(dx: 2, dy: 2))
                label.center = contentCenter
                label.text = marker.content
                label.textAlignment = .center
                label.font = .monospacedDigitSystemFont(ofSize: size * 0.4, weight: .medium)
                label.baselineAdjustment = .alignCenters
                label.adjustsFontSizeToFitWidth = true
                view.addSubview(label)
            }
        }
        return view
    }

    func mapView(_ mapView: MLNMapView, annotationCanShowCallout annotation: MLNAnnotation) -> Bool {
        guard let marker = markerSpecs[ObjectIdentifier(annotation as AnyObject)] else { return false }
        return !(marker.title ?? "").isEmpty || !(marker.subtitle ?? "").isEmpty
    }

    func mapView(_ mapView: MLNMapView, didSelect annotation: MLNAnnotation) {
        if let marker = markerSpecs[ObjectIdentifier(annotation as AnyObject)] {
            emit("onMarkerTap", point: marker.point, data: marker.data)
            if (marker.title ?? "").isEmpty && (marker.subtitle ?? "").isEmpty {
                mapView.deselectAnnotation(annotation, animated: false)
            }
        }
    }

    private func installGestures(_ map: MLNMapView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
        tap.delegate = self
        tap.cancelsTouchesInView = false
        for recognizer in map.gestureRecognizers ?? [] {
            if let nativeTap = recognizer as? UITapGestureRecognizer, nativeTap.numberOfTapsRequired > 1 {
                tap.require(toFail: nativeTap)
            }
        }
        map.addGestureRecognizer(tap)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
        longPress.delegate = self
        longPress.cancelsTouchesInView = false
        map.addGestureRecognizer(longPress)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var target = touch.view
        while let view = target, view !== map {
            // Annotation selection owns marker taps; do not also emit a map event.
            if view is MLNAnnotationView || view is UIControl { return false }
            target = view.superview
        }
        return true
    }

    @objc private func tapped(_ gesture: UITapGestureRecognizer) {
        guard ready, let map = map, gesture.state == .ended else { return }
        let tap = gesture.location(in: map)
        let location = map.convert(tap, toCoordinateFrom: map)
        let point = MapCoordinate(latitude: location.latitude, longitude: location.longitude)
        if let circle = circles.first(where: { MapGeometry.distance($0.point, point) <= $0.radius }) {
            emit("onCircleTap", point: circle.point, data: circle.data)
        } else if let line = lines.first(where: { line in
            zip(line.points, line.points.dropFirst()).contains { from, to in
                MapGeometry.segmentDistance(tap, map.convert(from.native, toPointTo: map),
                    map.convert(to.native, toPointTo: map)) <= 30
            }
        }) { emit("onPolylineTap", point: nil, data: line.data) }
        else { emit("onMapTap", point: point) }
    }

    @objc private func longPressed(_ gesture: UILongPressGestureRecognizer) {
        guard ready, let map = map, gesture.state == .began else { return }
        let point = map.convert(gesture.location(in: map), toCoordinateFrom: map)
        emit("onMapLongPress", point: MapCoordinate(latitude: point.latitude, longitude: point.longitude))
    }

    private func emit(_ event: String, point: MapCoordinate?, data: String? = nil) {
        guard !disposed else { return }
        var payload: [String: Any] = ["latitude": point.map { $0.latitude as Any } ?? NSNull(),
                                      "longitude": point.map { $0.longitude as Any } ?? NSNull()]
        if let data = data { payload["data"] = data }
        sendEvent(["event": event, "data": payload])
    }

    func dispose() {
        guard !disposed else { return }
        disposed = true
        ready = false
        timeout?.cancel()
        timeout = nil
        styleReply?.fail("MAP_DISPOSED", "The map has been disposed")
        styleReply = nil
        let waiting = pending
        pending.removeAll()
        waiting.forEach { $0.1.fail("MAP_DISPOSED", "The map has been disposed") }
        container.onLayout = nil
        map?.delegate = nil
        map?.removeFromSuperview()
        map = nil
        ownedAnnotations.removeAll()
        markerSpecs.removeAll()
        shapeStyles.removeAll()
    }

    deinit { dispose() }
}
