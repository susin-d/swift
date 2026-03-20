import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/core/api_service.dart';

import 'vendor_profile_model.dart';
import 'vendor_profile_service.dart';

final vendorProfileServiceProvider = Provider<VendorProfileService>((ref) {
  return VendorProfileService(ref.watch(apiServiceProvider));
});

final vendorProfileProvider = StateNotifierProvider<VendorProfileNotifier, AsyncValue<VendorProfile>>((ref) {
  return VendorProfileNotifier(ref.watch(vendorProfileServiceProvider));
});

class VendorProfileNotifier extends StateNotifier<AsyncValue<VendorProfile>> {
  VendorProfileNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  final VendorProfileService _service;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _service.fetchProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    required String name,
    String? description,
    String? imageUrl,
    required bool isOpen,
  }) async {
    try {
      final updated = await _service.updateProfile(
        name: name,
        description: description,
        imageUrl: imageUrl,
        isOpen: isOpen,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
