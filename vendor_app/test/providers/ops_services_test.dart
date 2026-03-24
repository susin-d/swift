import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vendor_app/core/api_service.dart';
import 'package:vendor_app/features/preferences/preferences_providers.dart';
import 'package:vendor_app/features/staff/staff_providers.dart';

class _FakeApiService extends ApiService {
  final List<Map<String, dynamic>> patchCalls = [];
  final List<Map<String, dynamic>> postCalls = [];
  final List<Map<String, dynamic>> deleteCalls = [];

  @override
  Future<Response<dynamic>> patch(String path, {dynamic data, String? cancelKey}) async {
    patchCalls.add({'path': path, 'data': data, 'cancelKey': cancelKey});
    return Response<dynamic>(
      data: {
        'language': {'current': 'Hindi', 'options': ['English', 'Hindi']},
        'theme': {'dark_mode': true, 'high_contrast': false},
        'app_settings': {
          'compact_cards': true,
          'silent_alerts': false,
          'notification_enabled': true,
          'auto_print_receipts': true,
        },
        'roles': [
          {'key': 'manager', 'permissions': ['orders.manage']}
        ],
      },
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<dynamic>> post(String path, {dynamic data, String? cancelKey}) async {
    postCalls.add({'path': path, 'data': data, 'cancelKey': cancelKey});
    return Response<dynamic>(
      data: {
        'staff': {'id': 'staff-1', 'name': 'Chef', 'role_key': 'kitchen'},
        'invitation': {'id': 'inv-1', 'email': 'staff@campus.edu', 'role_key': 'cashier'}
      },
      statusCode: 201,
      requestOptions: RequestOptions(path: path),
    );
  }

  @override
  Future<Response<dynamic>> delete(String path, {String? cancelKey}) async {
    deleteCalls.add({'path': path, 'cancelKey': cancelKey});
    return Response<dynamic>(
      data: {'success': true},
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

void main() {
  group('PreferencesService mutations', () {
    test('updateLanguage calls correct endpoint and payload', () async {
      final api = _FakeApiService();
      final container = ProviderContainer(
        overrides: [apiServiceProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final service = container.read(preferencesServiceProvider);
      final response = await service.updateLanguage('Hindi');

      expect(api.patchCalls, hasLength(1));
      expect(api.patchCalls.first['path'], '/vendor-ops/preferences/language');
      expect(api.patchCalls.first['data'], {'current': 'Hindi'});
      expect(response['current'], 'Hindi');
    });

    test('updateTheme calls correct endpoint', () async {
      final api = _FakeApiService();
      final container = ProviderContainer(
        overrides: [apiServiceProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final service = container.read(preferencesServiceProvider);
      await service.updateTheme(darkMode: true, highContrast: false);

      expect(api.patchCalls, hasLength(1));
      expect(api.patchCalls.first['path'], '/vendor-ops/preferences/theme');
      expect(api.patchCalls.first['data'], {'dark_mode': true, 'high_contrast': false});
    });

    test('updateAppSettings calls correct endpoint', () async {
      final api = _FakeApiService();
      final container = ProviderContainer(
        overrides: [apiServiceProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final service = container.read(preferencesServiceProvider);
      await service.updateAppSettings(
        compactCards: true,
        silentAlerts: false,
        notificationEnabled: true,
        autoPrintReceipts: true,
      );

      expect(api.patchCalls, hasLength(1));
      expect(api.patchCalls.first['path'], '/vendor-ops/preferences/app');
      expect(
        api.patchCalls.first['data'],
        {
          'compact_cards': true,
          'silent_alerts': false,
          'notification_enabled': true,
          'auto_print_receipts': true,
        },
      );
    });
  });

  group('StaffService mutations', () {
    test('createStaffMember posts to management endpoint', () async {
      final api = _FakeApiService();
      final container = ProviderContainer(
        overrides: [apiServiceProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final service = container.read(staffServiceProvider);
      final staff = await service.createStaffMember(
        name: 'Chef',
        roleKey: 'kitchen',
        email: 'chef@campus.edu',
      );

      expect(api.postCalls, hasLength(1));
      expect(api.postCalls.first['path'], '/vendor-ops/staff/management');
      expect((api.postCalls.first['data'] as Map)['name'], 'Chef');
      expect(staff['id'], 'staff-1');
    });

    test('inviteStaff posts to invitations endpoint', () async {
      final api = _FakeApiService();
      final container = ProviderContainer(
        overrides: [apiServiceProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final service = container.read(staffServiceProvider);
      final invitation = await service.inviteStaff(
        email: 'staff@campus.edu',
        roleKey: 'cashier',
        expiresInDays: 10,
      );

      expect(api.postCalls, hasLength(1));
      expect(api.postCalls.first['path'], '/vendor-ops/staff/invitations');
      expect((api.postCalls.first['data'] as Map)['expires_in_days'], 10);
      expect(invitation['id'], 'inv-1');
    });

    test('updateRoles patches role definitions', () async {
      final api = _FakeApiService();
      final container = ProviderContainer(
        overrides: [apiServiceProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final service = container.read(staffServiceProvider);
      final roles = await service.updateRoles([
        {'key': 'manager', 'permissions': ['orders.manage']}
      ]);

      expect(api.patchCalls, hasLength(1));
      expect(api.patchCalls.first['path'], '/vendor-ops/staff/roles');
      expect(roles, isNotEmpty);
    });

    test('deleteStaffMember calls delete endpoint', () async {
      final api = _FakeApiService();
      final container = ProviderContainer(
        overrides: [apiServiceProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final service = container.read(staffServiceProvider);
      await service.deleteStaffMember('staff-1');

      expect(api.deleteCalls, hasLength(1));
      expect(api.deleteCalls.first['path'], '/vendor-ops/staff/management/staff-1');
    });
  });
}
