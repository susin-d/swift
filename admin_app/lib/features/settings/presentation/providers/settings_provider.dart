import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_settings.dart';
import '../../data/services/settings_service.dart';

class SettingsNotifier extends AsyncNotifier<AdminSettings> {
  @override
  Future<AdminSettings> build() async {
    return SettingsService.instance.fetchSettings();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => SettingsService.instance.fetchSettings());
  }

  Future<String?> save(double commissionRate, double deliveryFee) async {
    try {
      final next = await SettingsService.instance.updateSettings(
        AdminSettings(commissionRate: commissionRate, deliveryFee: deliveryFee),
      );
      state = AsyncData(next);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AdminSettings>(
  SettingsNotifier.new,
);
