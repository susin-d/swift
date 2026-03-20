import 'package:vendor_app/core/api_service.dart';
import 'vendor_profile_model.dart';

class VendorProfileService {
  VendorProfileService(this._api);
  final ApiService _api;

  Future<VendorProfile> fetchProfile() async {
    final response = await _api.get('/vendor-ops/profile');
    final data = (response.data as Map).cast<String, dynamic>();
    return VendorProfile.fromJson((data['vendor'] as Map).cast<String, dynamic>());
  }

  Future<VendorProfile> updateProfile({
    required String name,
    String? description,
    String? imageUrl,
    required bool isOpen,
  }) async {
    final response = await _api.patch('/vendor-ops/profile', data: {
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'is_open': isOpen,
    });
    final data = (response.data as Map).cast<String, dynamic>();
    return VendorProfile.fromJson((data['vendor'] as Map).cast<String, dynamic>());
  }
}
