import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/core/api_service.dart';

final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService(ref.watch(apiServiceProvider));
});

final staffManagementProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(staffServiceProvider).fetchManagement();
});

final staffRolesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(staffServiceProvider).fetchRoles();
});

class StaffService {
  StaffService(this._api);

  final ApiService _api;

  Future<List<dynamic>> fetchManagement() async {
    final response = await _api.get('/vendor-ops/staff/management');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['staff'] as List?)?.cast<dynamic>() ?? const [];
  }

  Future<List<dynamic>> fetchRoles() async {
    final response = await _api.get('/vendor-ops/staff/roles');
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['roles'] as List?)?.cast<dynamic>() ?? const [];
  }

  Future<Map<String, dynamic>> createStaffMember({
    required String name,
    required String roleKey,
    String status = 'active',
    String? email,
    String? phone,
  }) async {
    final response = await _api.post(
      '/vendor-ops/staff/management',
      data: {
        'name': name,
        'role_key': roleKey,
        'status': status,
        'email': email,
        'phone': phone,
      },
    );
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['staff'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateStaffMember({
    required String staffId,
    String? name,
    String? roleKey,
    String? status,
    String? email,
    String? phone,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (roleKey != null) payload['role_key'] = roleKey;
    if (status != null) payload['status'] = status;
    if (email != null) payload['email'] = email;
    if (phone != null) payload['phone'] = phone;

    final response = await _api.patch('/vendor-ops/staff/management/$staffId', data: payload);
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['staff'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  Future<void> deleteStaffMember(String staffId) async {
    await _api.delete('/vendor-ops/staff/management/$staffId');
  }

  Future<Map<String, dynamic>> inviteStaff({
    required String email,
    required String roleKey,
    int expiresInDays = 7,
  }) async {
    final response = await _api.post(
      '/vendor-ops/staff/invitations',
      data: {
        'email': email,
        'role_key': roleKey,
        'expires_in_days': expiresInDays,
      },
    );
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['invitation'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  }

  Future<List<dynamic>> updateRoles(List<Map<String, dynamic>> roles) async {
    final response = await _api.patch(
      '/vendor-ops/staff/roles',
      data: {'roles': roles},
    );
    final data = (response.data as Map).cast<String, dynamic>();
    return (data['roles'] as List?)?.cast<dynamic>() ?? const [];
  }
}
