import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class DeeplinkHelper {
  /// Mở ứng dụng Bản đồ mặc định trên điện thoại (Google Maps / Apple Maps)
  /// Không tốn bất kỳ chi phí API nào của Google Maps Platform
  static Future<bool> launchNavigation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final destination = '$latitude,$longitude';
    final encodedLabel = Uri.encodeComponent(label ?? 'Điểm đến Đà Nẵng');

    Uri uri;

    if (!kIsWeb && Platform.isIOS) {
      // Apple Maps URL scheme
      uri = Uri.parse('maps://maps.apple.com/?daddr=$destination&q=$encodedLabel');
    } else if (!kIsWeb && Platform.isAndroid) {
      // Google Navigation Intent trên Android
      uri = Uri.parse('google.navigation:q=$destination&mode=d');
    } else {
      // Universal Web Fallback
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination');
    }

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web link
        final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination');
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching navigation deep-link: $e');
      return false;
    }
  }
}
