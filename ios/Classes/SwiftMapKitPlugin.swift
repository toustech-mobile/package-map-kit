import Flutter
import UIKit

public class SwiftMapKitPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = MapViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "map_kit_view")
        
        let channel = FlutterMethodChannel(name: "map_kit", binaryMessenger: registrar.messenger())
        let instance = SwiftMapKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "createMapView":
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

class MapViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return MapView(frame: frame, viewId: viewId, messenger: messenger)
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class MapView: NSObject, FlutterPlatformView {
    private var mapViewController: MapViewController
    
    init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger) {
        mapViewController = MapViewController(messenger: messenger)
        super.init()
        mapViewController.view.frame = frame
    }
    
    func view() -> UIView {
        return mapViewController.view
    }
} 