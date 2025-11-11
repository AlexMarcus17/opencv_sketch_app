import 'package:flutter/cupertino.dart';
import '../../application/utils.dart';

class SettingsScreen {
  static void showSettingsSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text(
            'Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Utils.shareApp();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.share,
                    color: CupertinoColors.systemBlue,
                  ),
                  SizedBox(width: 12),
                  Text('Share App'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Utils.contactUs();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.mail,
                    color: CupertinoColors.systemBlue,
                  ),
                  SizedBox(width: 12),
                  Text('Contact Us'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Utils.showPrivacyPolicy();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.doc_text,
                    color: CupertinoColors.systemBlue,
                  ),
                  SizedBox(width: 12),
                  Text('Privacy Policy'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                Utils.showOtherApps();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.app_badge,
                    color: CupertinoColors.systemBlue,
                  ),
                  SizedBox(width: 12),
                  Text('Other Apps'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }
}
