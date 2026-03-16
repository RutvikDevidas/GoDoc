/// ZEGOCLOUD configuration.
///
/// To run video calls you must provide your Zego App ID and App Sign.
///
/// - https://console.zegocloud.com/
/// - Create an app, then copy the AppID and AppSign here.
class ZegoConfig {
  /// ZEGOCLOUD App ID.
  ///
  /// Replace with your own. Leave as 0 to make the app compile, but calls will fail.
  static const int appID = 0;

  /// ZEGOCLOUD App Sign.
  ///
  /// Replace with your own key.
  static const String appSign = "<YOUR_APP_SIGN>";
}
