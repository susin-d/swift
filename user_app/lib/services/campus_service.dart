import '../models/campus_building.dart';
import '../models/delivery_zone.dart';
import 'api_service.dart';

class CampusService {
  final ApiService _api = ApiService();

  Future<List<CampusBuilding>> getBuildings() async {
    final response = await _api.get('/public/buildings');
    final data = response.data as List? ?? [];
    return data.map((json) => CampusBuilding.fromJson(json)).toList();
  }

  Future<List<DeliveryZone>> getZones({String? buildingId}) async {
    final response = await _api.get('/public/zones', queryParameters: {
      if (buildingId != null) 'building_id': buildingId,
    });
    final data = response.data as List? ?? [];
    return data.map((json) => DeliveryZone.fromJson(json)).toList();
  }
}
