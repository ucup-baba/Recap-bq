// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Open URL in new tab for web platform
Future<void> openUrlInNewTab(String url) async {
  html.window.open(url, '_blank');
}
