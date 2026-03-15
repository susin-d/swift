import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

class SessionPosture {
  const SessionPosture({
    required this.isAuthenticated,
    required this.isTrusted,
    required this.statusLabel,
    required this.detail,
    this.deviceFingerprint,
  });

  final bool isAuthenticated;
  final bool isTrusted;
  final String statusLabel;
  final String detail;
  final String? deviceFingerprint;
}

class SessionPostureService {
  static const _tokenKey = 'admin_token';
  static const _deviceTrustKey = 'admin_device_trust_id';
  static const _deviceTrustConfirmedKey = 'admin_device_trust_confirmed';

  static const _storage = FlutterSecureStorage();
  final Random _random = Random();

  Future<SessionPosture> loadPosture({required bool isAuthenticated}) async {
    if (!isAuthenticated) {
      return const SessionPosture(
        isAuthenticated: false,
        isTrusted: false,
        statusLabel: 'Session inactive',
        detail: 'Sign in to evaluate device trust posture.',
      );
    }

    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) {
      return const SessionPosture(
        isAuthenticated: false,
        isTrusted: false,
        statusLabel: 'Session inactive',
        detail: 'No active admin token found.',
      );
    }

    final trustId = await _storage.read(key: _deviceTrustKey);
    final confirmedRaw = await _storage.read(key: _deviceTrustConfirmedKey);
    final confirmed = confirmedRaw == 'true';

    if (trustId == null || trustId.isEmpty) {
      return const SessionPosture(
        isAuthenticated: true,
        isTrusted: false,
        statusLabel: 'Untrusted device',
        detail: 'Device trust id is missing. Mark this device trusted for lower-friction admin operations.',
      );
    }

    final fingerprint = trustId.length <= 8 ? trustId : trustId.substring(trustId.length - 8);

    if (!confirmed) {
      return SessionPosture(
        isAuthenticated: true,
        isTrusted: false,
        statusLabel: 'Untrusted device',
        detail: 'Device fingerprint $fingerprint is registered but not confirmed as trusted for this admin session.',
        deviceFingerprint: fingerprint,
      );
    }

    return SessionPosture(
      isAuthenticated: true,
      isTrusted: true,
      statusLabel: 'Trusted device',
      detail: 'Device fingerprint $fingerprint is trusted. Sensitive operations keep standard confirmation safeguards.',
      deviceFingerprint: fingerprint,
    );
  }

  Future<void> markCurrentDeviceTrusted() async {
    var trustId = await _storage.read(key: _deviceTrustKey);
    if (trustId == null || trustId.isEmpty) {
      trustId = _buildDeviceTrustId();
      await _storage.write(key: _deviceTrustKey, value: trustId);
    }
    await _storage.write(key: _deviceTrustConfirmedKey, value: 'true');
  }

  Future<void> markCurrentDeviceUntrusted() async {
    await _storage.write(key: _deviceTrustConfirmedKey, value: 'false');
  }

  String _buildDeviceTrustId() {
    final now = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final salt = _random.nextInt(1 << 24).toRadixString(36);
    return 'dev-$now-$salt';
  }
}

final sessionPostureServiceProvider = Provider<SessionPostureService>((_) {
  return SessionPostureService();
});

class SessionPostureController extends StateNotifier<AsyncValue<SessionPosture>> {
  SessionPostureController(this._ref, this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  final Ref _ref;
  final SessionPostureService _service;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authState = _ref.read(authProvider);
      final isAuthenticated = authState is AuthAuthenticated;
      return _service.loadPosture(isAuthenticated: isAuthenticated);
    });
  }

  Future<void> markTrusted() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.markCurrentDeviceTrusted();
      final authState = _ref.read(authProvider);
      final isAuthenticated = authState is AuthAuthenticated;
      return _service.loadPosture(isAuthenticated: isAuthenticated);
    });
  }

  Future<void> markUntrusted() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _service.markCurrentDeviceUntrusted();
      final authState = _ref.read(authProvider);
      final isAuthenticated = authState is AuthAuthenticated;
      return _service.loadPosture(isAuthenticated: isAuthenticated);
    });
  }
}

final sessionPostureProvider =
    StateNotifierProvider<SessionPostureController, AsyncValue<SessionPosture>>((ref) {
  return SessionPostureController(ref, ref.watch(sessionPostureServiceProvider));
});
