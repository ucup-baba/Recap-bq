import 'package:url_launcher/url_launcher.dart';

/// Open URL in new tab/window, works on all platforms
Future<void> openUrlInNewTab(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
