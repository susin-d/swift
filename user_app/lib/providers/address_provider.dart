import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/address_model.dart';
import '../services/address_service.dart';

final addressServiceProvider = Provider((ref) => AddressService());

final addressesProvider = StateNotifierProvider<AddressesNotifier, AsyncValue<List<AddressModel>>>((ref) {
  return AddressesNotifier(ref.watch(addressServiceProvider));
});

class AddressesNotifier extends StateNotifier<AsyncValue<List<AddressModel>>> {
  AddressesNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  final AddressService _service;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = await _service.getAddresses();
      final addresses = data.map((json) => AddressModel.fromJson((json as Map).cast<String, dynamic>())).toList();
      state = AsyncValue.data(addresses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAddress({
    required String label,
    required String addressLine,
    bool isDefault = false,
  }) async {
    try {
      await _service.addAddress(label: label, addressLine: addressLine, isDefault: isDefault);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _service.deleteAddress(id);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setDefault(String id) async {
    try {
      await _service.setDefault(id);
      await refresh();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
