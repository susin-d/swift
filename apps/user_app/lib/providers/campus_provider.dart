import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/campus_building.dart';
import '../models/delivery_zone.dart';
import '../services/campus_service.dart';

final campusServiceProvider = Provider((ref) => CampusService());

final campusBuildingsProvider = FutureProvider<List<CampusBuilding>>((ref) async {
  return ref.watch(campusServiceProvider).getBuildings();
});

final campusZonesProvider = FutureProvider.family<List<DeliveryZone>, String?>((ref, buildingId) async {
  return ref.watch(campusServiceProvider).getZones(buildingId: buildingId);
});
