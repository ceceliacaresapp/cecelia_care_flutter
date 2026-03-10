import Flutter
import UIKit
// 1. Import Firebase
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 2. Add this block to configure Firebase and set up the debug provider
    #if DEBUG
      let providerFactory = AppCheckDebugProviderFactory()
      AppCheck.setAppCheckProviderFactory(providerFactory)
    #endif

    FirebaseApp.configure()
    // End of new block

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}