import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    SwiftMapKitPlugin.register(with: self.registrar(forPlugin: "map_kit"))
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
} 