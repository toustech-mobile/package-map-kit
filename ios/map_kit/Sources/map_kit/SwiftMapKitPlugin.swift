import Flutter
import UIKit

public final class SwiftMapKitPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var eventChannel: FlutterEventChannel?
    private var methodChannels: [FlutterMethodChannel] = []
    // Flutter owns platform views. Strong references here would prevent disposal.
    private var views: [WeakMapView] = []

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftMapKitPlugin()
        registrar.register(MapViewFactory(plugin: instance), withId: "map_kit_view")
        for name in ["com.example.example/method_channel", "map_kit"] {
            let channel = FlutterMethodChannel(name: name, binaryMessenger: registrar.messenger())
            registrar.addMethodCallDelegate(instance, channel: channel)
            instance.methodChannels.append(channel)
        }
        let events = FlutterEventChannel(name: "com.yourapp/event_channel", binaryMessenger: registrar.messenger())
        events.setStreamHandler(instance)
        instance.eventChannel = events
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion": result("iOS " + UIDevice.current.systemVersion)
        case "createMapView": result(nil) // Compatibility with the former MapKit.initialize API.
        default:
            guard MapKitNativeView.methods.contains(call.method) else { result(FlutterMethodNotImplemented); return }
            views.removeAll { $0.value == nil }
            guard let view = views.last?.value else {
                result(FlutterError(code: "MAP_NOT_ATTACHED", message: "No Neshan map is attached", details: nil))
                return
            }
            view.handle(call, result: result)
        }
    }

    fileprivate func attach(_ view: MapKitNativeView) {
        views.removeAll { $0.value == nil }
        views.append(WeakMapView(view))
    }

    fileprivate func emit(_ event: [String: Any]) { eventSink?(event) }

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        views.compactMap { $0.value }.forEach { $0.dispose() }
        views.removeAll()
        eventSink = nil
        eventChannel?.setStreamHandler(nil)
        eventChannel = nil
        methodChannels.forEach { $0.setMethodCallHandler(nil) }
        methodChannels.removeAll()
    }
}

private final class WeakMapView {
    weak var value: MapKitNativeView?
    init(_ value: MapKitNativeView) { self.value = value }
}

private final class MapViewFactory: NSObject, FlutterPlatformViewFactory {
    private weak var plugin: SwiftMapKitPlugin?
    init(plugin: SwiftMapKitPlugin) {
        self.plugin = plugin
        super.init()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let view = MapKitNativeView(frame: frame, arguments: args) { [weak plugin = self.plugin] event in
            plugin?.emit(event)
        }
        plugin?.attach(view)
        return view
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol { FlutterStandardMessageCodec.sharedInstance() }
}
