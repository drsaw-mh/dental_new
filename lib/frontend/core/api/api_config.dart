import 'package:flutter/foundation.dart';

const configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl {
  if (configuredApiBaseUrl.isNotEmpty) {
    return configuredApiBaseUrl;
  }

  if (kIsWeb) {
    return 'http://127.0.0.1:4000';
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:4000';
  }

  return 'http://127.0.0.1:4000';
}
