import CoreFoundation
import CoreLocation
import Flutter
import UIKit

struct MapPayloadError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct MapCoordinate: Equatable {
    let latitude: Double
    let longitude: Double
    var native: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum MapPayload {
    static func object(_ value: Any?) throws -> [String: Any] {
        guard let value = value as? [String: Any] else {
            throw MapPayloadError(message: "Expected a map object")
        }
        return value
    }

    static func objects(_ value: Any?) throws -> [[String: Any]] {
        guard let value = value as? [Any] else {
            throw MapPayloadError(message: "Expected a list of map objects")
        }
        return try value.map { try object($0) }
    }

    static func number(_ object: [String: Any], _ key: String, default fallback: Double? = nil) throws -> Double {
        if object[key] == nil || object[key] is NSNull {
            if let fallback = fallback { return fallback }
        }
        guard let value = object[key] as? NSNumber,
              CFGetTypeID(value) != CFBooleanGetTypeID(), value.doubleValue.isFinite else {
            throw MapPayloadError(message: "\(key) must be a finite number")
        }
        return value.doubleValue
    }

    static func coordinate(_ object: [String: Any]) throws -> MapCoordinate {
        let latitude = try number(object, "latitude")
        let longitude = try number(object, "longitude")
        guard (-90...90).contains(latitude), (-180...180).contains(longitude) else {
            throw MapPayloadError(message: "Coordinates are outside latitude/longitude bounds")
        }
        return MapCoordinate(latitude: latitude, longitude: longitude)
    }

    static func nonnegative(_ object: [String: Any], _ key: String, default fallback: Double? = nil) throws -> Double {
        let value = try number(object, key, default: fallback)
        guard value >= 0 else { throw MapPayloadError(message: "\(key) must be non-negative") }
        return value
    }

    static func darkMode(_ object: [String: Any]) throws -> Bool {
        guard let value = object["isDarkMode"] as? NSNumber, CFGetTypeID(value) == CFBooleanGetTypeID() else {
            throw MapPayloadError(message: "isDarkMode must be a boolean")
        }
        return value.boolValue
    }

    static func color(_ object: [String: Any], _ key: String, default fallback: String) throws -> UIColor {
        let text = (object[key] as? String) ?? fallback
        let hex = String(text.dropFirst())
        guard text.first == "#", [6, 8].contains(hex.count),
              hex.allSatisfy({ $0.isHexDigit }), let value = UInt64(hex, radix: 16) else {
            throw MapPayloadError(message: "\(key) must be #RRGGBB or #AARRGGBB")
        }
        return UIColor(red: CGFloat((value >> 16) & 255) / 255,
                       green: CGFloat((value >> 8) & 255) / 255, blue: CGFloat(value & 255) / 255,
                       alpha: hex.count == 8 ? CGFloat((value >> 24) & 255) / 255 : 1)
    }

    static func metadata(_ object: [String: Any]) -> String {
        guard let data = object["data"], !(data is NSNull) else { return "" }
        return String(describing: data)
    }
}

struct MapMarkerSpec {
    let point: MapCoordinate
    let size: Double
    let icon: String
    let image: UIImage?
    let content: String
    let contentImage: UIImage?
    let contentCenterY: Double
    let title: String?
    let subtitle: String?
    let data: String

    init(_ object: [String: Any]) throws {
        point = try MapPayload.coordinate(object)
        size = try MapPayload.number(object, "iconSize", default: 32)
        guard size > 0, size <= 512 else { throw MapPayloadError(message: "iconSize must be between 0 and 512") }
        icon = object["icon"] as? String ?? ""
        content = object["markerContent"] as? String ?? ""
        contentCenterY = try MapPayload.number(object, "contentCenterY", default: 0.5)
        guard (0...1).contains(contentCenterY) else {
            throw MapPayloadError(message: "contentCenterY must be between 0 and 1")
        }
        image = (object["iconBytes"] as? FlutterStandardTypedData).flatMap { UIImage(data: $0.data) }
        contentImage = (object["markerContentBytes"] as? FlutterStandardTypedData).flatMap { UIImage(data: $0.data) }
        title = object["snippetTitle"] as? String
        subtitle = object["snippetDescription"] as? String
        data = MapPayload.metadata(object)
    }
}

struct MapCircleSpec {
    let point: MapCoordinate
    let radius: Double
    let width: Double
    let fill: UIColor
    let border: UIColor
    let data: String

    init(_ object: [String: Any]) throws {
        point = try MapPayload.coordinate(object)
        radius = try MapPayload.nonnegative(object, "radius")
        width = try MapPayload.nonnegative(object, "borderStroke", default: 2)
        fill = try MapPayload.color(object, "color", default: "#400000FF")
        border = try MapPayload.color(object, "borderColor", default: "#FF0000FF")
        data = MapPayload.metadata(object)
    }
}

struct MapLineSpec {
    let points: [MapCoordinate]
    let width: Double
    let color: UIColor
    let outline: UIColor
    let data: String

    init(_ object: [String: Any]) throws {
        points = try MapPayload.objects(object["points"]).map(MapPayload.coordinate)
        width = try MapPayload.number(object, "strokeWidth", default: 3)
        guard points.count >= 2, width > 0 else {
            throw MapPayloadError(message: "A polyline requires two points and a positive width")
        }
        color = try MapPayload.color(object, "color", default: "#FF0000FF")
        outline = try MapPayload.color(object, "strokeColor", default: "#640000FF")
        data = MapPayload.metadata(object)
    }
}

enum MapGeometry {
    private static let earthRadius = 6_371_000.0

    static func circle(_ center: MapCoordinate, radius: Double) -> [CLLocationCoordinate2D] {
        let latitude = center.latitude * .pi / 180
        let longitude = center.longitude * .pi / 180
        let distance = radius / earthRadius
        return (0...96).map { index in
            let bearing = Double(index % 96) * 2 * .pi / 96
            let lat = asin(max(-1, min(1, sin(latitude) * cos(distance)
                + cos(latitude) * sin(distance) * cos(bearing))))
            let lng = longitude + atan2(sin(bearing) * sin(distance) * cos(latitude), cos(distance) - sin(latitude) * sin(lat))
            return CLLocationCoordinate2D(latitude: lat * 180 / .pi,
                longitude: (lng * 180 / .pi + 540).truncatingRemainder(dividingBy: 360) - 180)
        }
    }

    static func distance(_ a: MapCoordinate, _ b: MapCoordinate) -> Double {
        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let dlat = lat2 - lat1
        let dlng = (b.longitude - a.longitude) * .pi / 180
        let value = pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlng / 2), 2)
        return 2 * earthRadius * asin(sqrt(max(0, min(1, value))))
    }

    static func segmentDistance(_ tap: CGPoint, _ from: CGPoint, _ to: CGPoint) -> CGFloat {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let length = dx * dx + dy * dy
        let t = length == 0 ? 0 : max(0, min(1, ((tap.x - from.x) * dx + (tap.y - from.y) * dy) / length))
        return hypot(tap.x - from.x - t * dx, tap.y - from.y - t * dy)
    }
}
