import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/campus_building.dart';
import '../../data/models/delivery_zone.dart';
import '../providers/campus_provider.dart';

class CampusScreen extends ConsumerWidget {
  const CampusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              isScrollable: true,
              labelColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'Buildings'),
                Tab(text: 'Delivery Zones'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: TabBarView(children: [_BuildingsTab(), _ZonesTab()])),
        ],
      ),
    );
  }
}

class _BuildingsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildingsAsync = ref.watch(campusBuildingsProvider);

    return buildingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _CampusError(
        message: error.toString(),
        onRetry: () => ref.read(campusBuildingsProvider.notifier).refresh(),
      ),
      data: (buildings) {
        return RefreshIndicator(
          onRefresh: () => ref.read(campusBuildingsProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Campus buildings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  FilledButton.icon(
                    onPressed: () => _showBuildingDialog(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add building'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (buildings.isEmpty)
                const _EmptyState(
                  title: 'No buildings yet',
                  subtitle: 'Add a building to enable class delivery routing.',
                )
              else
                ...buildings.map(
                  (building) => _BuildingCard(building: building),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBuildingDialog(
    BuildContext context,
    WidgetRef ref, {
    CampusBuilding? building,
  }) async {
    final nameController = TextEditingController(text: building?.name ?? '');
    final codeController = TextEditingController(text: building?.code ?? '');
    final addressController = TextEditingController(
      text: building?.address ?? '',
    );
    final latController = TextEditingController(
      text: building?.latitude?.toString() ?? '',
    );
    final lngController = TextEditingController(
      text: building?.longitude?.toString() ?? '',
    );
    final notesController = TextEditingController(
      text: building?.deliveryNotes ?? '',
    );
    bool isActive = building?.isActive ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(building == null ? 'Add building' : 'Edit building'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'Code (optional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address (optional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: latController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Latitude (optional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: lngController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Longitude (optional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Delivery notes (optional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (value) => setState(() => isActive = value),
                      title: const Text('Active'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;
    if (result != true) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showSnack(context, 'Name is required', isError: true);
      return;
    }

    final latitude = latController.text.trim().isEmpty
        ? null
        : double.tryParse(latController.text.trim());
    final longitude = lngController.text.trim().isEmpty
        ? null
        : double.tryParse(lngController.text.trim());

    String? error;
    if (building == null) {
      error = await ref
          .read(campusBuildingsProvider.notifier)
          .createBuilding(
            name: name,
            code: codeController.text.trim().isEmpty
                ? null
                : codeController.text.trim(),
            address: addressController.text.trim().isEmpty
                ? null
                : addressController.text.trim(),
            latitude: latitude,
            longitude: longitude,
            deliveryNotes: notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
            isActive: isActive,
          );
    } else {
      error = await ref
          .read(campusBuildingsProvider.notifier)
          .updateBuilding(building, {
            'name': name,
            'code': codeController.text.trim().isEmpty
                ? null
                : codeController.text.trim(),
            'address': addressController.text.trim().isEmpty
                ? null
                : addressController.text.trim(),
            'latitude': latitude,
            'longitude': longitude,
            'delivery_notes': notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
            'is_active': isActive,
          });
    }

    if (!context.mounted) return;
    _showSnack(context, error ?? 'Building saved');
  }

  void _showSnack(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFB91C1C) : null,
      ),
    );
  }
}

class _BuildingCard extends ConsumerWidget {
  const _BuildingCard({required this.building});

  final CampusBuilding building;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          building.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (building.code != null && building.code!.isNotEmpty)
              Text('Code: ${building.code}'),
            if (building.address != null && building.address!.isNotEmpty)
              Text(building.address!),
            if (building.deliveryNotes != null &&
                building.deliveryNotes!.isNotEmpty)
              Text('Notes: ${building.deliveryNotes}'),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _BuildingsTab()._showBuildingDialog(
                context,
                ref,
                building: building,
              ),
            ),
            Switch(
              value: building.isActive,
              onChanged: (value) async {
                final error = await ref
                    .read(campusBuildingsProvider.notifier)
                    .updateBuilding(building, {'is_active': value});
                if (!context.mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: const Color(0xFFB91C1C),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(campusZonesProvider);
    final buildingsAsync = ref.watch(campusBuildingsProvider);

    return zonesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _CampusError(
        message: error.toString(),
        onRetry: () => ref.read(campusZonesProvider.notifier).refresh(),
      ),
      data: (zones) {
        final buildingMap = <String, CampusBuilding>{
          for (final b in buildingsAsync.value ?? const <CampusBuilding>[])
            b.id: b,
        };

        return RefreshIndicator(
          onRefresh: () => ref.read(campusZonesProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Delivery zones',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  FilledButton.icon(
                    onPressed: () => _showZoneDialog(
                      context,
                      ref,
                      buildings: buildingMap.values.toList(),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add zone'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (zones.isEmpty)
                const _EmptyState(
                  title: 'No zones yet',
                  subtitle: 'Add zones to enable geofence validation.',
                )
              else
                ...zones.map(
                  (zone) => _ZoneCard(zone: zone, buildingMap: buildingMap),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showZoneDialog(
    BuildContext context,
    WidgetRef ref, {
    DeliveryZone? zone,
    required List<CampusBuilding> buildings,
  }) async {
    final nameController = TextEditingController(text: zone?.name ?? '');
    final geoController = TextEditingController(
      text: zone?.geojson == null
          ? ''
          : const JsonEncoder.withIndent('  ').convert(zone!.geojson),
    );
    String? selectedBuilding =
        zone?.buildingId ?? (buildings.isNotEmpty ? buildings.first.id : null);
    bool isActive = zone?.isActive ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            zone == null ? 'Add delivery zone' : 'Edit delivery zone',
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Zone name'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedBuilding,
                      decoration: const InputDecoration(
                        labelText: 'Building (optional)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No building'),
                        ),
                        ...buildings.map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(b.name),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => selectedBuilding = value),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: geoController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'GeoJSON (optional)',
                        hintText: '{"type":"Polygon","coordinates":[...]}',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: isActive,
                      onChanged: (value) => setState(() => isActive = value),
                      title: const Text('Active'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;
    if (result != true) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showSnack(context, 'Zone name is required', isError: true);
      return;
    }

    Map<String, dynamic>? geojson;
    if (geoController.text.trim().isNotEmpty) {
      try {
        geojson = jsonDecode(geoController.text.trim()) as Map<String, dynamic>;
      } catch (_) {
        _showSnack(context, 'GeoJSON is not valid JSON', isError: true);
        return;
      }
    }

    String? error;
    if (zone == null) {
      error = await ref
          .read(campusZonesProvider.notifier)
          .createZone(
            name: name,
            buildingId: selectedBuilding,
            geojson: geojson,
            isActive: isActive,
          );
    } else {
      error = await ref.read(campusZonesProvider.notifier).updateZone(zone, {
        'name': name,
        'building_id': selectedBuilding,
        'geojson': geojson,
        'is_active': isActive,
      });
    }

    if (!context.mounted) return;
    _showSnack(context, error ?? 'Delivery zone saved');
  }

  void _showSnack(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFB91C1C) : null,
      ),
    );
  }
}

class _ZoneCard extends ConsumerWidget {
  const _ZoneCard({required this.zone, required this.buildingMap});

  final DeliveryZone zone;
  final Map<String, CampusBuilding> buildingMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildingName = zone.buildingId == null
        ? null
        : buildingMap[zone.buildingId]?.name;
    final geojsonLabel = zone.geojson == null ? 'No geojson' : 'GeoJSON set';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          zone.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (buildingName != null) Text('Building: $buildingName'),
            Text(geojsonLabel),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _ZonesTab()._showZoneDialog(
                context,
                ref,
                zone: zone,
                buildings: buildingMap.values.toList(),
              ),
            ),
            Switch(
              value: zone.isActive,
              onChanged: (value) async {
                final error = await ref
                    .read(campusZonesProvider.notifier)
                    .updateZone(zone, {'is_active': value});
                if (!context.mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: const Color(0xFFB91C1C),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.location_city_outlined,
              size: 36,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CampusError extends StatelessWidget {
  const _CampusError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Color(0xFFB91C1C),
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load campus data',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
