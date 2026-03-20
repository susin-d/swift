import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/campus_building.dart';
import '../models/delivery_zone.dart';

class CampusService {
  CampusService._();
  static final CampusService instance = CampusService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<CampusBuilding>> fetchBuildings() async {
    try {
      final response = await _dio.get<List<dynamic>>('/admin/campus/buildings');
      final data = response.data ?? [];
      return data.map((e) => CampusBuilding.fromJson((e as Map).cast<String, dynamic>())).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to load campus buildings',
      );
    }
  }

  Future<CampusBuilding> createBuilding({
    required String name,
    String? code,
    String? address,
    double? latitude,
    double? longitude,
    String? deliveryNotes,
    bool isActive = true,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/admin/campus/buildings', data: {
        'name': name,
        'code': code,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'delivery_notes': deliveryNotes,
        'is_active': isActive,
      });
      return CampusBuilding.fromJson((response.data ?? const <String, dynamic>{}).cast<String, dynamic>());
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to create building',
      );
    }
  }

  Future<CampusBuilding> updateBuilding(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>('/admin/campus/buildings/$id', data: updates);
      return CampusBuilding.fromJson((response.data ?? const <String, dynamic>{}).cast<String, dynamic>());
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to update building',
      );
    }
  }

  Future<List<DeliveryZone>> fetchZones() async {
    try {
      final response = await _dio.get<List<dynamic>>('/admin/campus/zones');
      final data = response.data ?? [];
      return data.map((e) => DeliveryZone.fromJson((e as Map).cast<String, dynamic>())).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to load delivery zones',
      );
    }
  }

  Future<DeliveryZone> createZone({
    required String name,
    String? buildingId,
    Map<String, dynamic>? geojson,
    bool isActive = true,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/admin/campus/zones', data: {
        'name': name,
        'building_id': buildingId,
        'geojson': geojson,
        'is_active': isActive,
      });
      return DeliveryZone.fromJson((response.data ?? const <String, dynamic>{}).cast<String, dynamic>());
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to create delivery zone',
      );
    }
  }

  Future<DeliveryZone> updateZone(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>('/admin/campus/zones/$id', data: updates);
      return DeliveryZone.fromJson((response.data ?? const <String, dynamic>{}).cast<String, dynamic>());
    } on DioException catch (e) {
      throw ApiException.fromDioException(
        e,
        fallbackMessage: 'Failed to update delivery zone',
      );
    }
  }
}
