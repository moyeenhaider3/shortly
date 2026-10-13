import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in a new browser tab (or the external browser on mobile).
Future<bool> openExternal(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return Future.value(false);
  return launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
}
