import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SidebarFeatureScreen extends StatefulWidget {
  const SidebarFeatureScreen({
    super.key,
    required this.title,
    required this.section,
  });

  final String title;
  final String section;

  @override
  State<SidebarFeatureScreen> createState() => _SidebarFeatureScreenState();
}

class _SidebarFeatureScreenState extends State<SidebarFeatureScreen> {
  final TextEditingController _noteController = TextEditingController();
  final Map<String, bool> _checkStates = <String, bool>{};

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  _FeatureBlueprint _resolveBlueprint() {
    final title = widget.title.toLowerCase();
    if (title.contains('order history')) {
      return const _FeatureBlueprint(
        summary:
            'Track completed and cancelled orders with filterable timelines.',
        checklist: [
          'Status chips behave correctly',
          'Date-range filtering works',
          'Order detail drilldown opens',
        ],
        actions: ['Filter by date', 'Export snapshot', 'Open dashboard'],
      );
    }
    if (title.contains('inventory') || title.contains('stock')) {
      return const _FeatureBlueprint(
        summary:
            'Manage stock thresholds and alert low-availability items early.',
        checklist: [
          'Low-stock markers visible',
          'Availability toggles sync',
          'Restock note captured',
        ],
        actions: ['View low stock', 'Mark restocked', 'Open menu'],
      );
    }
    if (title.contains('delivery') || title.contains('tracking')) {
      return const _FeatureBlueprint(
        summary: 'Coordinate delivery operations and monitor courier progress.',
        checklist: [
          'Active order selected',
          'Tracking status refreshed',
          'Escalation path available',
        ],
        actions: ['Start tracking', 'Escalate issue', 'Open dashboard'],
      );
    }
    if (title.contains('promotion') ||
        title.contains('campaign') ||
        title.contains('coupon') ||
        title.contains('discount')) {
      return const _FeatureBlueprint(
        summary:
            'Plan campaign goals, apply rules, and review conversion outcomes.',
        checklist: [
          'Promotion window valid',
          'Discount logic checked',
          'Success metric selected',
        ],
        actions: ['Draft campaign', 'Validate rules', 'Open analytics'],
      );
    }

    return const _FeatureBlueprint(
      summary:
          'Configure and operate this module with production-safe defaults.',
      checklist: [
        'Core configuration reviewed',
        'Validation checks passed',
        'User impact confirmed',
      ],
      actions: ['Run checks', 'Capture note', 'Return to dashboard'],
    );
  }

  void _runAction(String action) {
    final lowered = action.toLowerCase();
    if (lowered.contains('dashboard') && mounted) {
      context.go('/');
      return;
    }
    if (lowered.contains('menu') && mounted) {
      context.push('/menu');
      return;
    }
    if (lowered.contains('analytics') && mounted) {
      context.push('/analytics');
      return;
    }
    if (lowered.contains('tracking') && mounted) {
      context.push('/');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action completed for ${widget.title}.')),
    );
  }

  void _saveNote() {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved note: $note')));
    _noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final blueprint = _resolveBlueprint();
    final doneCount = blueprint.checklist
        .where((step) => _checkStates[step] ?? false)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.section,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  blueprint.summary,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Checklist progress: $doneCount/${blueprint.checklist.length}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Readiness Checklist',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...blueprint.checklist.map((step) {
            final checked = _checkStates[step] ?? false;
            return CheckboxListTile(
              value: checked,
              contentPadding: EdgeInsets.zero,
              title: Text(step),
              onChanged: (value) =>
                  setState(() => _checkStates[step] = value ?? false),
            );
          }),
          const SizedBox(height: 12),
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: blueprint.actions
                .map(
                  (action) => FilledButton(
                    onPressed: () => _runAction(action),
                    child: Text(action),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          Text(
            'Owner Notes',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Capture decision, risk, or follow-up',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _saveNote,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save note'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureBlueprint {
  const _FeatureBlueprint({
    required this.summary,
    required this.checklist,
    required this.actions,
  });

  final String summary;
  final List<String> checklist;
  final List<String> actions;
}
