/// ZEGOCLOUD configuration.
///
/// To run video calls you must provide your Zego App ID and App Sign.
///
/// - https://console.zegocloud.com/
/// - Create an app, then copy the AppID and AppSign here.
class ZegoConfig {
  /// ZEGOCLOUD App ID.
  static const int appID = 1827373674;

  /// ZEGOCLOUD App Sign.
  ///
  /// Replace with your own key.
  static const String appSign =
      "bd1548f92849128852e09f2f586b6f490deb23a46855df0a16eb6c7bade1c834";

  static bool get isConfigured =>
      appID > 0 && appSign.isNotEmpty && appSign != "<YOUR_APP_SIGN>";
}
