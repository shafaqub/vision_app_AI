import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UserPosition {
  final double x;
  final double y;
  final String location;
  final String beaconId;
  final int? rssi;
  final double confidence;

  const UserPosition({
    required this.x,
    required this.y,
    required this.location,
    required this.beaconId,
    required this.rssi,
    required this.confidence,
  });
}

class PositionService {
  // Android emulator -> Windows host
  static const String baseUrl = 'http://192.168.0.101:5000';

  static const String deviceId = 'user_001';

  Future<UserPosition?> getPosition() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/position/$deviceId'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode != 200) {
        debugPrint('Position API error: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);

      final position = data['position'];

      if (position == null) {
        return null;
      }

      return UserPosition(
        x: (position['x'] as num).toDouble(),
        y: (position['y'] as num).toDouble(),
        location: position['location'] ?? 'Unknown',
        beaconId: position['beaconId'] ?? '',
        rssi: position['rssi'] != null
            ? (position['rssi'] as num).toInt()
            : null,
        confidence: (position['confidence'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('Could not get position: $e');
      return null;
    }
  }
}
