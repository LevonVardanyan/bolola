import UIKit
import Flutter
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let shareChannel = FlutterMethodChannel(name: "statements/share",
                                              binaryMessenger: controller.binaryMessenger)
    shareChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in

        if (call.method == "share-file") {
            let argsMap = call.arguments as! NSDictionary
            let filepath = argsMap.value(forKey: "filePath") as? String
            let shareWithLink = argsMap.value(forKey: "shareWithLink") as? Bool
            let shareWithText = argsMap.value(forKey: "shareWithText") as? Bool

            if (filepath != nil && !filepath!.isEmpty) {
                self.shareAudioFile(url: URL(fileURLWithPath: filepath!), shareWithLink: shareWithLink ?? false, shareWithText: shareWithText ?? false);
            }
        }
    })

    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

    private func shareAudioFile(url:URL, shareWithLink: Bool, shareWithText: Bool) {


        let controller = UIApplication.shared.keyWindow!.rootViewController as! FlutterViewController
        let activityController : UIActivityViewController
        if (shareWithLink) {
            let appStoreUrl = URL(string: "https://apps.apple.com/us/app/id1523054038")
            activityController = UIActivityViewController(activityItems: [url, appStoreUrl!], applicationActivities: nil)
        } else if (shareWithText) {
            let text = URL(string: "Shared from app Bolola")
            activityController = UIActivityViewController(activityItems: [url, text!], applicationActivities: nil)
        } else {
            activityController =
            UIActivityViewController(activityItems: [url], applicationActivities: nil)
        }
         if let popoverController = activityController.popoverPresentationController {
                                popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                            popoverController.sourceView = controller.view
                                popoverController.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
                            }
        controller.present(activityController, animated: true, completion: nil)

    }
}

