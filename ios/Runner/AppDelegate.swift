import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Icon id (as used from Dart) -> alternate icon set name; nil = primary AppIcon.
  private let alternateIcons: [String: String?] = [
    "halloween": nil,
    "christmas": "AppIcon-Christmas",
  ]

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "SpookyAppIcon") {
      registerAppIconChannel(registrar.messenger())
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerAppIconChannel(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "spookyai/app_icon", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      let app = UIApplication.shared
      switch call.method {
      case "isSupported":
        result(app.supportsAlternateIcons)
      case "getIcon":
        let current = app.alternateIconName
        let id = self.alternateIcons.first(where: { $0.value == current })?.key ?? "halloween"
        result(id)
      case "setIcon":
        let args = call.arguments as? [String: Any]
        let id = args?["icon"] as? String ?? "halloween"
        guard app.supportsAlternateIcons, let name = self.alternateIcons[id] else {
          result(FlutterError(code: "unsupported", message: "Cannot set icon \(id)", details: nil))
          return
        }
        if app.alternateIconName == name {
          result(nil)
          return
        }
        app.setAlternateIconName(name) { error in
          if let error = error {
            result(FlutterError(code: "failed", message: error.localizedDescription, details: nil))
          } else {
            result(nil)
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
