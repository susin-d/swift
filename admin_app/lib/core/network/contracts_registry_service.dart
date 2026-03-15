import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_exception.dart';

typedef JsonMap = Map<String, dynamic>;

class ContractsRegistryService {
  ContractsRegistryService._();
  static final ContractsRegistryService instance = ContractsRegistryService._();
  static const Duration _cacheTtl = Duration(seconds: 45);

  final Map<String, _CachedJson> _cache = {};

  Dio get _dio => ApiClient.instance.dio;

  JsonMap? _readCache(String key, bool forceRefresh) {
    if (forceRefresh) {
      _cache.remove(key);
      return null;
    }

    final cached = _cache[key];
    if (cached == null) {
      return null;
    }

    if (DateTime.now().isAfter(cached.expiresAt)) {
      _cache.remove(key);
      return null;
    }

    return Map<String, dynamic>.from(cached.value);
  }

  void _writeCache(String key, JsonMap value) {
    _cache[key] = _CachedJson(
      value: Map<String, dynamic>.from(value),
      expiresAt: DateTime.now().add(_cacheTtl),
    );
  }

  Future<JsonMap> fetchRegistry({bool forceRefresh = false}) async {
    const cacheKey = 'registry';
    final cached = _readCache(cacheKey, forceRefresh);
    if (cached != null) return cached;

    try {
      final response = await _dio.get<JsonMap>('/contracts/registry');
      final data = response.data ?? <String, dynamic>{};
      _writeCache(cacheKey, data);
      return data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to load contracts registry',
      );
    }
  }

  Future<JsonMap> fetchChangelog({String? since, bool forceRefresh = false}) async {
    final cacheKey = 'changelog:${since ?? 'all'}';
    final cached = _readCache(cacheKey, forceRefresh);
    if (cached != null) return cached;

    try {
      final response = await _dio.get<JsonMap>(
        '/contracts/changelog',
        queryParameters: since == null ? null : {'since': since},
      );
      final data = response.data ?? <String, dynamic>{};
      _writeCache(cacheKey, data);
      return data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to load contracts changelog',
      );
    }
  }

  Future<JsonMap> fetchFlags({bool forceRefresh = false}) async {
    const cacheKey = 'flags';
    final cached = _readCache(cacheKey, forceRefresh);
    if (cached != null) return cached;

    try {
      final response = await _dio.get<JsonMap>('/contracts/flags');
      final data = response.data ?? <String, dynamic>{};
      _writeCache(cacheKey, data);
      return data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to load contract feature flags',
      );
    }
  }
}

class _CachedJson {
  _CachedJson({required this.value, required this.expiresAt});

  final JsonMap value;
  final DateTime expiresAt;
}
