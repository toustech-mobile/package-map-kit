import Flutter
import MapLibre
import UIKit
import XCTest

@testable import map_kit

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testRendererIdentityWithoutAnAttachedMap() {
    let done = expectation(description: "renderer identity is available before creating a view")
    SwiftMapKitPlugin().handle(FlutterMethodCall(methodName: "getRendererInfo", arguments: nil)) { result in
      let info = result as? [String: Any]
      XCTAssertEqual(info?["renderer"] as? String, "neshan-maplibre")
      XCTAssertEqual(info?["protocolVersion"] as? Int, 1)
      XCTAssertEqual(info?["viewType"] as? String, "com.golrang.map_kit/neshan_map_view")
      done.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testPackageKeyConfiguresSDK() throws {
    try NeshanConfiguration.configure()
    // Boolean assertions keep the configured key out of failure output.
    XCTAssertTrue(MLNSettings.apiKey?.isEmpty == false)
    XCTAssertTrue(MLNSettings.apiKey == NeshanConfiguration.apiKey)
    XCTAssertTrue(MLNNetworkConfiguration.sharedManager.delegate === NeshanNetworkDelegate.shared)
    XCTAssertTrue(NeshanNetworkDelegate.shared.responds(to: NSSelectorFromString("willSendRequest:")))
    XCTAssertTrue(NeshanNetworkDelegate.shared.responds(to: NSSelectorFromString("didReceiveResponse:")))
  }

  func testNeshanRequestsUsePackageCredentialsWithoutHostPlist() {
    let request = NSMutableURLRequest(url: URL(string: "https://api.neshan.org/tile?x=1&key=old-host-key")!)
    request.setValue("existing-etag", forHTTPHeaderField: "If-None-Match")
    let authenticated = NeshanNetworkDelegate.authenticate(request, key: "package-key", bundleID: "com.example.ios")
    let items = URLComponents(url: authenticated.url!, resolvingAgainstBaseURL: false)!.queryItems!
    XCTAssertEqual(items.filter { $0.name == "key" }.count, 1)
    XCTAssertTrue(items.contains { $0.name == "key" && $0.value == "package-key" })
    XCTAssertTrue(items.contains { $0.name == "x" && $0.value == "1" })
    XCTAssertEqual(authenticated.value(forHTTPHeaderField: "bundle"), "com.example.ios")
    XCTAssertEqual(authenticated.value(forHTTPHeaderField: "If-None-Match"), "existing-etag")
  }

  func testPackageKeyIsNotSentToOtherHostsOrInsecureURLs() {
    for url in ["https://example.org/tile", "https://neshan.org.example.org/tile", "http://api.neshan.org/tile"] {
      let request = NSMutableURLRequest(url: URL(string: url)!)
      let authenticated = NeshanNetworkDelegate.authenticate(request, key: "package-key", bundleID: "com.example.ios")
      XCTAssertEqual(authenticated.url?.absoluteString, url)
      XCTAssertNil(authenticated.value(forHTTPHeaderField: "bundle"))
    }
  }

  func testGetPlatformVersion() {
    let plugin = SwiftMapKitPlugin()

    let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! String, "iOS " + UIDevice.current.systemVersion)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testCommandsBeforeViewCreationReturnAnError() {
    let plugin = SwiftMapKitPlugin()
    let done = expectation(description: "result completes")
    plugin.handle(FlutterMethodCall(methodName: "getCamera", arguments: nil)) { result in
      XCTAssertEqual((result as? FlutterError)?.code, "MAP_NOT_ATTACHED")
      done.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  func testNumericPayloadValidation() throws {
    XCTAssertEqual(try MapPayload.coordinate(["latitude": 0, "longitude": 51.5]),
                   MapCoordinate(latitude: 0, longitude: 51.5))
    let invalidValues: [Any] = [true, Double.nan, Double.infinity, "35"]
    for invalid in invalidValues {
      XCTAssertThrowsError(try MapPayload.coordinate(["latitude": invalid, "longitude": 51]))
    }
    XCTAssertThrowsError(try MapPayload.coordinate(["latitude": 91, "longitude": 0]))
    XCTAssertThrowsError(try MapPayload.nonnegative(["radius": -1], "radius"))
    XCTAssertThrowsError(try MapPayload.darkMode(["isDarkMode": 1]))
    XCTAssertTrue(try MapPayload.darkMode(["isDarkMode": true]))
  }

  func testOverlayValidation() throws {
    let circle = try MapCircleSpec(["latitude": 0, "longitude": 0, "radius": 50, "color": "#800000FF"])
    XCTAssertEqual(circle.width, 2)
    XCTAssertEqual(circle.fill.cgColor.alpha, 128.0 / 255.0, accuracy: 0.001)
    XCTAssertThrowsError(try MapCircleSpec(["latitude": 0, "longitude": 0, "radius": -1]))
    XCTAssertThrowsError(try MapMarkerSpec(["latitude": 0, "longitude": 0, "iconSize": 0]))
    XCTAssertThrowsError(try MapLineSpec(["points": [["latitude": 0, "longitude": 0]]]))
    XCTAssertThrowsError(try MapPayload.color(["color": "#ZZZZZZ"], "color", default: "#000000"))
  }

  func testGeodesicCircleAndHitTesting() {
    let center = MapCoordinate(latitude: 0, longitude: 179.999)
    let ring = MapGeometry.circle(center, radius: 1000)
    XCTAssertEqual(ring.count, 97)
    XCTAssertEqual(ring.first!.latitude, ring.last!.latitude, accuracy: 0.0000001)
    XCTAssertEqual(ring.first!.longitude, ring.last!.longitude, accuracy: 0.0000001)
    for point in ring {
      XCTAssertTrue((-180...180).contains(point.longitude))
      XCTAssertEqual(MapGeometry.distance(center, MapCoordinate(latitude: point.latitude, longitude: point.longitude)),
                     1000, accuracy: 0.01)
    }
    XCTAssertEqual(MapGeometry.segmentDistance(CGPoint(x: 5, y: 3), .zero, CGPoint(x: 10, y: 0)), 3)
    XCTAssertEqual(MapGeometry.segmentDistance(CGPoint(x: 3, y: 4), .zero, .zero), 5)
  }

  func testDisposedViewFailsCommandsWithoutCreatingAMap() {
    let view = MapKitNativeView(frame: .zero, arguments: ["zoom": "invalid"]) { _ in }
    view.dispose()
    let done = expectation(description: "disposed result completes once")
    view.handle(FlutterMethodCall(methodName: "getCamera", arguments: nil)) { result in
      XCTAssertEqual((result as? FlutterError)?.code, "MAP_DISPOSED")
      done.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

}
