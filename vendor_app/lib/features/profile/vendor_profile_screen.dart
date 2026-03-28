import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'vendor_profile_provider.dart';
import 'vendor_profile_model.dart';

const String vendorProfileErrorTitle = 'Unable to load vendor profile';
const String vendorProfileErrorActionLabel = 'Retry';

class VendorProfileScreen extends ConsumerStatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  ConsumerState<VendorProfileScreen> createState() =>
      _VendorProfileScreenState();
}

class _VendorProfileScreenState extends ConsumerState<VendorProfileScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _imageController = TextEditingController();
  final _prepController = TextEditingController();
  final _busyMessageController = TextEditingController();
  bool _isOpen = true;
  bool _autoAcceptOrders = false;
  bool _busyModeEnabled = false;
  DateTime? _holidayUntil;
  bool _dirty = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _imageController.dispose();
    _prepController.dispose();
    _busyMessageController.dispose();
    super.dispose();
  }

  void _sync(VendorProfile profile) {
    _nameController.text = profile.name;
    _descController.text = profile.description ?? '';
    _imageController.text = profile.imageUrl ?? '';
    _isOpen = profile.isOpen;
    _autoAcceptOrders = profile.autoAcceptOrders;
    _busyModeEnabled = profile.busyModeEnabled;
    _prepController.text = profile.preparationTimeAvg.toString();
    _busyMessageController.text = profile.busyModeMessage ?? '';
    _holidayUntil = profile.holidayUntil;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(vendorProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vendor Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ProfileErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(vendorProfileProvider),
        ),
        data: (profile) {
          if (!_dirty) {
            _sync(profile);
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              SwitchListTile(
                value: _isOpen,
                onChanged: (value) => setState(() {
                  _isOpen = value;
                  _dirty = true;
                }),
                title: Text(_isOpen ? 'Store open' : 'Store closed'),
                subtitle: const Text('Toggle availability for customers'),
              ),
              SwitchListTile(
                value: _autoAcceptOrders,
                onChanged: (value) => setState(() {
                  _autoAcceptOrders = value;
                  _dirty = true;
                }),
                title: const Text('Auto accept incoming orders'),
                subtitle: const Text(
                  'New orders enter as accepted when enabled',
                ),
              ),
              SwitchListTile(
                value: _busyModeEnabled,
                onChanged: (value) => setState(() {
                  _busyModeEnabled = value;
                  _dirty = true;
                }),
                title: const Text('Busy mode'),
                subtitle: const Text('Show queue pressure state in operations'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() => _dirty = true),
                decoration: const InputDecoration(labelText: 'Store name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                onChanged: (_) => setState(() => _dirty = true),
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _imageController,
                onChanged: (_) => setState(() => _dirty = true),
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _prepController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _dirty = true),
                decoration: const InputDecoration(
                  labelText: 'Avg prep time (minutes)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _busyMessageController,
                onChanged: (_) => setState(() => _dirty = true),
                decoration: const InputDecoration(
                  labelText: 'Busy mode message (optional)',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Holiday closed until'),
                subtitle: Text(
                  _holidayUntil == null
                      ? 'Not scheduled'
                      : _holidayUntil!.toLocal().toString(),
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: 'Pick date',
                      onPressed: () async {
                        final now = DateTime.now();
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: _holidayUntil ?? now,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                        );
                        if (selectedDate == null || !mounted) return;
                        setState(() {
                          _holidayUntil = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            23,
                            59,
                          );
                          _dirty = true;
                        });
                      },
                      icon: const Icon(Icons.event_rounded),
                    ),
                    if (_holidayUntil != null)
                      IconButton(
                        tooltip: 'Clear holiday',
                        onPressed: () => setState(() {
                          _holidayUntil = null;
                          _dirty = true;
                        }),
                        icon: const Icon(Icons.clear_rounded),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _dirty ? () => _save() : null,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final imageUrl = _imageController.text.trim();
    final prepTime = int.tryParse(_prepController.text.trim()) ?? 15;
    final busyMessage = _busyMessageController.text.trim();

    await ref
        .read(vendorProfileProvider.notifier)
        .updateProfile(
          name: name,
          description: description.isEmpty ? null : description,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          isOpen: _isOpen,
          autoAcceptOrders: _autoAcceptOrders,
          preparationTimeAvg: prepTime,
          busyModeEnabled: _busyModeEnabled,
          busyModeMessage: busyMessage.isEmpty ? null : busyMessage,
          holidayUntil: _holidayUntil,
        );

    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.store_mall_directory_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 14),
            const Text(
              vendorProfileErrorTitle,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text(vendorProfileErrorActionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
