import Flutter
import UIKit
import flutter_unity_widget
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      InitUnityIntegrationWithOptions(argc: CommandLine.argc, argv: CommandLine.unsafeArgv, launchOptions)
    
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
            // キーの末尾だけ表示（流出防止）
            let tail = String(apiKey.suffix(6))
            print("[GMS] GMSApiKey present. len=\(apiKey.count), k=\(tail)")
            GMSServices.provideAPIKey(apiKey)
        } else {
            fatalError("GMSApiKey not found in Info.plist")
        }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
