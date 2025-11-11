import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static Future<int> getAndroidVersion() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      return androidInfo.version.sdkInt;
    }
    return 0;
  }

  static void shareApp() {
    const String iosLink = 'https://apps.apple.com/app/id6747050806';
    const String androidLink =
        'https://play.google.com/store/apps/details?id=com.alphasoftlabs.sketch';

    final String appLink = Platform.isIOS ? iosLink : androidLink;

    Share.share('Check out this app! $appLink');
  }

  static void contactUs() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'alphasoftgames@gmail.com',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      toast("Failed to open email");
    }
  }

  static void showPrivacyPolicy() async {
    try {
      launchUrl(
        Uri.parse(
            'https://www.termsfeed.com/live/1639ceb5-4e35-431d-accf-1a9fc48dd0e4'),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      toast("Failed to open privacy policy");
    }
  }

  static void showOtherApps() async {
    const String iosUrl = 'https://apps.apple.com/developer/id1748638642';
    const String androidUrl =
        'https://play.google.com/store/apps/developer?id=AlphaSoftGames';

    final Uri rateUri = Uri.parse(
      Platform.isIOS ? iosUrl : androidUrl,
    );

    if (await canLaunchUrl(rateUri)) {
      await launchUrl(rateUri);
    } else {
      toast("Failed to open other apps");
    }
  }
}
