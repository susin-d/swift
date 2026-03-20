import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/campus_building.dart';
import '../../data/models/delivery_zone.dart';
import '../../data/services/campus_service.dart';

class CampusBuildingsNotifier extends AsyncNotifier<List<CampusBuilding>> {
  @override
  Future<List<CampusBuilding>> build() async {
    return CampusService.instance.fetchBuildings();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => CampusService.instance.fetchBuildings());
  }

  Future<String?> createBuilding({
    required String name,
    String? code,
    String? address,
    double? latitude,
    double? longitude,
    String? deliveryNotes,
    bool isActive = true,
  }) async {
    try {
      await CampusService.instance.createBuilding(
        name: name,
        code: code,
        address: address,
        latitude: latitude,
        longitude: longitude,
        deliveryNotes: deliveryNotes,
        isActive: isActive,
      );
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateBuilding(CampusBuilding building, Map<String, dynamic> updates) async {
    try {
      await CampusService.instance.updateBuilding(building.id, updates);
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

class CampusZonesNotifier extends AsyncNotifier<List<DeliveryZone>> {
  @override
  Future<List<DeliveryZone>> build() async {
    return CampusService.instance.fetchZones();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => CampusService.instance.fetchZones());
  }

  Future<String?> createZone({
    required String name,
    String? buildingId,
    Map<String, dynamic>? geojson,
    bool isActive = true,
  }) async {
    try {
      await CampusService.instance.createZone(
        name: name,
        buildingId: buildingId,
        geojson: geojson,
        isActive: isActive,
      );
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateZone(DeliveryZone zone, Map<String, dynamic> updates) async {
    try {
      await CampusService.instance.updateZone(zone.id, updates);
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final campusBuildingsProvider = AsyncNotifierProvider<CampusBuildingsNotifier, List<CampusBuilding>>(
  CampusBuildingsNotifier.new,
);

final campusZonesProvider = AsyncNotifierProvider<CampusZonesNotifier, List<DeliveryZone>>(
  CampusZonesNotifier.new,
);
