import 'api_service.dart';

class ContractsRegistryService {
  final ApiService _api = ApiService();
  static const Duration _cacheTtl = Duration(seconds: 45);
  static final Map<String, _CachedJson> _cache = {};

  Map<String, dynamic>? _readCache(String key, bool forceRefresh) {
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

  void _writeCache(String key, Map<String, dynamic> value) {
    _cache[key] = _CachedJson(
      value: Map<String, dynamic>.from(value),
      expiresAt: DateTime.now().add(_cacheTtl),
    );
  }

  Future<Map<String, dynamic>> fetchRegistry({bool forceRefresh = false}) async {
    const cacheKey = 'registry';
    final cached = _readCache(cacheKey, forceRefresh);
    if (cached != null) return cached;

    final response = await _api.get('/contracts/registry');
    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    _writeCache(cacheKey, data);
    return data;
  }

  Future<Map<String, dynamic>> fetchChangelog({String? since, bool forceRefresh = false}) async {
    final cacheKey = 'changelog:${since ?? 'all'}';
    final cached = _readCache(cacheKey, forceRefresh);
    if (cached != null) return cached;

    final response = await _api.get(
      '/contracts/changelog',
      queryParameters: since == null ? null : {'since': since},
    );
    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    _writeCache(cacheKey, data);
    return data;
  }

  Future<Map<String, dynamic>> fetchFlags({bool forceRefresh = false}) async {
    const cacheKey = 'flags';
    final cached = _readCache(cacheKey, forceRefresh);
    if (cached != null) return cached;

    final response = await _api.get('/contracts/flags');
    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    _writeCache(cacheKey, data);
    return data;
  }
}

class _CachedJson {
  _CachedJson({required this.value, required this.expiresAt});

  final Map<String, dynamic> value;
  final DateTime expiresAt;
}
