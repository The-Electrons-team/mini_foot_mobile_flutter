// Chargé uniquement quand `dart.library.js` est dispo (web). Les lints
// "avoid_web_libraries_in_flutter" et "deprecated_member_use" (dart:js) sont
// inapplicables ici : c'est la branche web du conditional import.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

void showBrowserNotification(String? title, String? body) {
  js.context.callMethod('showBrowserNotification', [title, body]);
}
