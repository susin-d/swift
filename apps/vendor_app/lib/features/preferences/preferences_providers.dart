import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/core/api_service.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService(ref.watch(apiServiceProvider));
});

final preferencesLanguageProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(preferencesServiceProvider).fetchLanguage();
});

final preferencesThemeProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(preferencesServiceProvider).fetchTheme();
});

final preferencesAppProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(preferencesServiceProvider).fetchAppSettings();
});

class PreferencesService {
  PreferencesService(this._api);

  final ApiService _api;

  Future<Map<String, dynamic>> fetchLanguage() async {
    final response = await _api.get('/vendor-ops/preferences/language');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['language'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchTheme() async {
    final response = await _api.get('/vendor-ops/preferences/theme');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['theme'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchAppSettings() async {
    final response = await _api.get('/vendor-ops/preferences/app');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['app_settings'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateLanguage(String current) async {
    final response = await _api.patch(
      '/vendor-ops/preferences/language',
      data: {'current': current},
    );
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['language'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateTheme({
    bool? darkMode,
    bool? highContrast,
  }) async {
    final payload = <String, dynamic>{};
    if (darkMode != null) payload['dark_mode'] = darkMode;
    if (highContrast != null) payload['high_contrast'] = highContrast;

    final response = await _api.patch('/vendor-ops/preferences/theme', data: payload);
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['theme'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateAppSettings({
    bool? compactCards,
    bool? silentAlerts,
    bool? notificationEnabled,
    bool? autoPrintReceipts,
  }) async {
    final payload = <String, dynamic>{};
    if (compactCards != null) payload['compact_cards'] = compactCards;
    if (silentAlerts != null) payload['silent_alerts'] = silentAlerts;
    if (notificationEnabled != null) payload['notification_enabled'] = notificationEnabled;
    if (autoPrintReceipts != null) payload['auto_print_receipts'] = autoPrintReceipts;

    final response = await _api.patch('/vendor-ops/preferences/app', data: payload);
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['app_settings'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }
}
