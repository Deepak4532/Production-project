import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {

  private var methodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)

    // Set ourselves as the notification delegate explicitly
    UNUserNotificationCenter.current().delegate = self

    // Set up the MethodChannel to send notification payloads to Flutter
    if let controller = window?.rootViewController as? FlutterViewController {
      methodChannel = FlutterMethodChannel(
        name: "com.medication.app/notification",
        binaryMessenger: controller.binaryMessenger
      )
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Called when user taps a notification (foreground OR background)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    // flutter_local_notifications stores payload under this key
    let payload = userInfo["payload"] as? String ?? response.notification.request.identifier

    NSLog("[AppDelegate] Notification tapped, payload: %@", payload)

    // Give Flutter time to fully resume before invoking the channel
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      self?.methodChannel?.invokeMethod("onNotificationTap", arguments: payload)
      NSLog("[AppDelegate] MethodChannel invoked with payload: %@", payload)
    }

    // Also call super so flutter_local_notifications can do its own handling
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  // Show notification banner even when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    NSLog("[AppDelegate] Notification will present in foreground")
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .badge, .sound])
    } else {
      completionHandler([.alert, .badge, .sound])
    }
  }

  // Handle Google Sign-In URL redirect
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
  }
}
