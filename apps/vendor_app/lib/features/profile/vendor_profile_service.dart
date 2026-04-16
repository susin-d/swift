import 'package:vendor_app/core/api_service.dart';
import 'vendor_profile_model.dart';

class VendorProfileService {
  VendorProfileService(this._api);
  final ApiService _api;

  Future<VendorProfile> fetchProfile() async {
    final profileResponse = await _api.get('/vendor-ops/profile');
    final controlsResponse = await _api.get('/vendor-ops/store-controls');

    final profileData = (profileResponse.data as Map).cast<String, dynamic>();
    final controlsData = (controlsResponse.data as Map).cast<String, dynamic>();
    final vendor = (profileData['vendor'] as Map).cast<String, dynamic>();
    final controls = (controlsData['controls'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    return VendorProfile.fromJson({...vendor, 'controls': controls});
  }

  Future<VendorProfile> updateProfile({
    required String name,
    String? description,
    String? imageUrl,
    required bool isOpen,
    bool? autoAcceptOrders,
    int? preparationTimeAvg,
    bool? busyModeEnabled,
    String? busyModeMessage,
    DateTime? holidayUntil,
  }) async {
    final response = await _api.patch('/vendor-ops/profile', data: {
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'is_open': isOpen,
    });

    await _api.patch('/vendor-ops/store-controls', data: {
      'is_open': isOpen,
      'auto_accept_orders': autoAcceptOrders,
      'preparation_time_avg': preparationTimeAvg,
      'busy_mode_enabled': busyModeEnabled,
      'busy_mode_message': busyModeMessage,
      'holiday_until': holidayUntil?.toUtc().toIso8601String(),
    });

    final data = (response.data as Map).cast<String, dynamic>();
    final profile = (data['vendor'] as Map).cast<String, dynamic>();
    final controlsResponse = await _api.get('/vendor-ops/store-controls');
    final controlsData = (controlsResponse.data as Map).cast<String, dynamic>();
    final controls = (controlsData['controls'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    return VendorProfile.fromJson({...profile, 'controls': controls});
  }
}
