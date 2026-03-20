import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/class_session_provider.dart';
import '../../providers/campus_provider.dart';
import '../../models/campus_building.dart';

class ClassScheduleScreen extends ConsumerWidget {
  const ClassScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(classSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Class Schedule')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load classes: $e')),
        data: (sessions) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saved classes', style: TextStyle(fontWeight: FontWeight.w800)),
                  ElevatedButton.icon(
                    onPressed: () => _openCreate(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (sessions.isEmpty)
                const Center(child: Text('No classes saved yet.'))
              else
                ...sessions.map((s) => _SessionCard(session: s)).toList(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final buildingsAsync = await ref.read(campusBuildingsProvider.future);
    if (!context.mounted) return;

    final buildingController = ValueNotifier<CampusBuilding>(buildingsAsync.first);
    final roomController = TextEditingController();
    final courseController = TextEditingController();
    final startsController = TextEditingController();
    final endsController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add class'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                ValueListenableBuilder<CampusBuilding>(
                  valueListenable: buildingController,
                  builder: (context, selected, _) {
                    return DropdownButtonFormField<String>(
                      value: selected.id,
                      decoration: const InputDecoration(labelText: 'Building'),
                      items: buildingsAsync
                          .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                          .toList(),
                      onChanged: (value) {
                        final next = buildingsAsync.firstWhere((b) => b.id == value);
                        buildingController.value = next;
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: 'Room'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: courseController,
                  decoration: const InputDecoration(labelText: 'Course label (optional)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: startsController,
                  decoration: const InputDecoration(labelText: 'Start time (YYYY-MM-DD HH:MM)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: endsController,
                  decoration: const InputDecoration(labelText: 'End time (YYYY-MM-DD HH:MM)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Save')),
          ],
        );
      },
    );

    if (result != true) return;

    DateTime? parse(String value) {
      if (value.trim().isEmpty) return null;
      return DateTime.tryParse(value.replaceFirst(' ', 'T'));
    }

    final startsAt = parse(startsController.text);
    final endsAt = parse(endsController.text);

    final service = ref.read(classSessionServiceProvider);
    await service.createSession(
      buildingId: buildingController.value.id,
      room: roomController.text.trim(),
      courseLabel: courseController.text.trim().isEmpty ? null : courseController.text.trim(),
      startsAt: startsAt,
      endsAt: endsAt,
    );
    ref.invalidate(classSessionsProvider);
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard({required this.session});

  final dynamic session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = session.startsAt == null ? 'Anytime' : DateFormat('MMM dd, hh:mm a').format(session.startsAt);
    final end = session.endsAt == null ? '' : ' - ${DateFormat('hh:mm a').format(session.endsAt)}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('${session.buildingName ?? 'Building'} • ${session.room}'),
        subtitle: Text('$start$end${session.courseLabel == null ? '' : ' • ${session.courseLabel}'}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await ref.read(classSessionServiceProvider).deleteSession(session.id);
            ref.invalidate(classSessionsProvider);
          },
        ),
      ),
    );
  }
}
