import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'vendor_profile_provider.dart';
import 'vendor_profile_model.dart';

class VendorProfileScreen extends ConsumerStatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  ConsumerState<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends ConsumerState<VendorProfileScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _imageController = TextEditingController();
  bool _isOpen = true;
  bool _dirty = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _sync(VendorProfile profile) {
    _nameController.text = profile.name;
    _descController.text = profile.description ?? '';
    _imageController.text = profile.imageUrl ?? '';
    _isOpen = profile.isOpen;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(vendorProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Vendor Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
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

    await ref.read(vendorProfileProvider.notifier).updateProfile(
          name: name,
          description: description.isEmpty ? null : description,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          isOpen: _isOpen,
        );

    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }
}
