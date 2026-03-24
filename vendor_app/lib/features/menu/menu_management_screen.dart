import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'menu_models.dart';
import 'menu_provider.dart';

typedef MenuImagePicker = Future<String?> Function(BuildContext context);

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key, this.imagePicker});

  final MenuImagePicker? imagePicker;

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(menuProvider.notifier).fetchMenus());
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Menu Management', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddCategory(context),
          ),
        ],
      ),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _EmptyState(
          title: 'Unable to load menu',
          subtitle: e.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.read(menuProvider.notifier).fetchMenus(),
        ),
        data: (snapshot) {
          final categories = snapshot.categories;
          if (categories.isEmpty) {
            return _EmptyState(
              title: 'No menu categories yet',
              subtitle: 'Create a category to start adding items.',
              actionLabel: 'Add category',
              onAction: () => _showAddCategory(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(menuProvider.notifier).fetchMenus(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ActionBar(
                  onAddCategory: () => _showAddCategory(context),
                  onAddItem: () => _showAddItem(context, categories),
                ),
                const SizedBox(height: 12),
                ...categories.map((category) => _CategoryCard(
                      category: category,
                      onEdit: () => _showEditCategory(context, category),
                      onDelete: () => _confirmDeleteCategory(context, category),
                      onAddItem: () => _showAddItem(context, categories, preselected: category),
                      onEditItem: (item) => _showEditItem(context, category, item),
                      onDeleteItem: (item) => _confirmDeleteItem(context, item),
                      onToggleAvailability: (item) => _toggleAvailability(item),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddCategory(BuildContext context) async {
    final nameController = TextEditingController();
    final sortController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Category name')),
            const SizedBox(height: 12),
            TextField(
              controller: sortController,
              decoration: const InputDecoration(labelText: 'Sort order (optional)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (result != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    await ref.read(menuProvider.notifier).createMenu({
      'category_name': name,
      if (sortController.text.trim().isNotEmpty) 'sort_order': int.tryParse(sortController.text.trim()) ?? 0,
    });
  }

  static bool _isDataImageUrl(String value) => value.toLowerCase().startsWith('data:image/');

  static bool _isValidImageUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (_isDataImageUrl(trimmed)) return trimmed.contains(';base64,');
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    if (uri.host.isEmpty) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  String _mimeFromPath(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.gif')) return 'image/gif';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<String?> _pickImageUrl(BuildContext context) async {
    if (widget.imagePicker != null) {
      return widget.imagePicker!(context);
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    final mime = image.mimeType ?? _mimeFromPath(image.name);
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  Uint8List? _decodeDataImage(String? value) {
    if (value == null || !_isDataImageUrl(value)) return null;
    final marker = ';base64,';
    final index = value.indexOf(marker);
    if (index <= 0) return null;
    try {
      return base64Decode(value.substring(index + marker.length));
    } catch (_) {
      return null;
    }
  }

  Future<void> _showEditCategory(BuildContext context, MenuCategory category) async {
    final nameController = TextEditingController(text: category.name);
    final sortController = TextEditingController(text: category.sortOrder?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Category name')),
            const SizedBox(height: 12),
            TextField(
              controller: sortController,
              decoration: const InputDecoration(labelText: 'Sort order'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Update')),
        ],
      ),
    );

    if (result != true) return;
    await ref.read(menuProvider.notifier).updateMenu(category.id, {
      'category_name': nameController.text.trim(),
      if (sortController.text.trim().isNotEmpty) 'sort_order': int.tryParse(sortController.text.trim()) ?? 0,
    });
  }

  Future<void> _confirmDeleteCategory(BuildContext context, MenuCategory category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category'),
        content: Text('Delete ${category.name} and all items inside?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(menuProvider.notifier).deleteMenu(category.id);
    }
  }

  Future<void> _showAddItem(BuildContext context, List<MenuCategory> categories, {MenuCategory? preselected}) async {
    if (categories.isEmpty) return;
    MenuCategory selected = preselected ?? categories.first;
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    String? imageUrl;
    String? imageError;
    bool isAvailable = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add menu item'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<MenuCategory>(
                  value: selected,
                  onChanged: (value) => setState(() => selected = value ?? selected),
                  items: categories
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat.name)))
                      .toList(),
                ),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item name')),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _DialogImageThumb(
                    imageUrl: imageUrl,
                    decoder: _decodeDataImage,
                  ),
                  title: const Text('Item image (optional)'),
                  subtitle: Text(
                    imageUrl == null ? 'No image selected' : 'Image selected',
                    style: TextStyle(color: imageError == null ? Colors.grey : Colors.red),
                  ),
                  trailing: OutlinedButton.icon(
                    onPressed: () async {
                      final nextImageUrl = await _pickImageUrl(context);
                      if (nextImageUrl == null) return;
                      setState(() {
                        imageUrl = nextImageUrl;
                        imageError = _isValidImageUrl(nextImageUrl) ? null : 'Invalid image URL format.';
                      });
                    },
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Upload'),
                  ),
                ),
                if (imageError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      imageError!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isAvailable,
                  onChanged: (value) => setState(() => isAvailable = value),
                  title: const Text('Available'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (result != true) return;
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? 0;
    if (name.isEmpty || price <= 0) return;
    if (imageUrl != null && !_isValidImageUrl(imageUrl!)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid image URL format.')),
      );
      return;
    }

    await ref.read(menuProvider.notifier).createMenuItem({
      'menu_id': selected.id,
      'name': name,
      'description': descController.text.trim(),
      'price': price,
      'is_available': isAvailable,
      if (imageUrl != null) 'image_url': imageUrl,
    });
  }

  Future<void> _showEditItem(BuildContext context, MenuCategory category, MenuItem item) async {
    final nameController = TextEditingController(text: item.name);
    final descController = TextEditingController(text: item.description ?? '');
    final priceController = TextEditingController(text: item.price.toStringAsFixed(0));
    String? imageUrl = item.imageUrl;
    String? imageError;
    bool isAvailable = item.isAvailable;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit menu item'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item name')),
                const SizedBox(height: 8),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _DialogImageThumb(
                    imageUrl: imageUrl,
                    decoder: _decodeDataImage,
                  ),
                  title: const Text('Item image (optional)'),
                  subtitle: Text(
                    imageUrl == null ? 'No image selected' : 'Image selected',
                    style: TextStyle(color: imageError == null ? Colors.grey : Colors.red),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final nextImageUrl = await _pickImageUrl(context);
                          if (nextImageUrl == null) return;
                          setState(() {
                            imageUrl = nextImageUrl;
                            imageError = _isValidImageUrl(nextImageUrl) ? null : 'Invalid image URL format.';
                          });
                        },
                        icon: const Icon(Icons.upload_rounded),
                        label: const Text('Upload'),
                      ),
                      if (imageUrl != null)
                        IconButton(
                          onPressed: () => setState(() {
                            imageUrl = null;
                            imageError = null;
                          }),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                    ],
                  ),
                ),
                if (imageError != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      imageError!,
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isAvailable,
                  onChanged: (value) => setState(() => isAvailable = value),
                  title: const Text('Available'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Update')),
        ],
      ),
    );

    if (result != true) return;
    if (imageUrl != null && !_isValidImageUrl(imageUrl!)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid image URL format.')),
      );
      return;
    }

    await ref.read(menuProvider.notifier).updateMenuItem(item.id, {
      'name': nameController.text.trim(),
      'description': descController.text.trim(),
      'price': double.tryParse(priceController.text.trim()) ?? item.price,
      'is_available': isAvailable,
      'image_url': imageUrl,
    });
  }

  Future<void> _confirmDeleteItem(BuildContext context, MenuItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete menu item'),
        content: Text('Delete ${item.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(menuProvider.notifier).deleteMenuItem(item.id);
    }
  }

  Future<void> _toggleAvailability(MenuItem item) async {
    await ref.read(menuProvider.notifier).updateMenuItem(item.id, {
      'is_available': !item.isAvailable,
    });
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onAddCategory, required this.onAddItem});

  final VoidCallback onAddCategory;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: onAddCategory,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Category'),
        ),
        OutlinedButton.icon(
          onPressed: onAddItem,
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('Add Item'),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onToggleAvailability,
  });

  final MenuCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddItem;
  final ValueChanged<MenuItem> onEditItem;
  final ValueChanged<MenuItem> onDeleteItem;
  final ValueChanged<MenuItem> onToggleAvailability;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(category.name, style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(onPressed: onAddItem, icon: const Icon(Icons.add_rounded)),
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
                IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
              ],
            ),
            const SizedBox(height: 6),
            if (category.items.isEmpty)
              Text('No items in this category yet.', style: Theme.of(context).textTheme.bodySmall)
            else
              ...category.items.map((item) => _ItemRow(
                    item: item,
                    onEdit: () => onEditItem(item),
                    onDelete: () => onDeleteItem(item),
                    onToggleAvailability: () => onToggleAvailability(item),
                  )),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  final MenuItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  @override
  Widget build(BuildContext context) {
    final dataBytes = _decodeDataImage(item.imageUrl);
    final hasImage = item.imageUrl != null && item.imageUrl!.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 52,
              height: 52,
              color: const Color(0xFFE2E8F0),
                child: dataBytes != null
                  ? Image.memory(dataBytes, fit: BoxFit.cover)
                  : hasImage
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
                    )
                  : const Icon(Icons.image_outlined),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Rs ${item.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),
                if ((item.description ?? '').trim().isNotEmpty)
                  Text(
                    item.description!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                Text(
                  'Item ID: ${item.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (item.updatedAt != null)
                  Text(
                    'Updated: ${item.updatedAt!.toLocal()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Switch(
            value: item.isAvailable,
            onChanged: (_) => onToggleAvailability(),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
    );
  }

  static Uint8List? _decodeDataImage(String? value) {
    if (value == null || !value.toLowerCase().startsWith('data:image/')) return null;
    final marker = ';base64,';
    final index = value.indexOf(marker);
    if (index <= 0) return null;
    try {
      return base64Decode(value.substring(index + marker.length));
    } catch (_) {
      return null;
    }
  }
}

class _DialogImageThumb extends StatelessWidget {
  const _DialogImageThumb({required this.imageUrl, required this.decoder});

  final String? imageUrl;
  final Uint8List? Function(String? value) decoder;

  @override
  Widget build(BuildContext context) {
    final bytes = decoder(imageUrl);
    final hasUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        color: const Color(0xFFE2E8F0),
        child: bytes != null
            ? Image.memory(bytes, fit: BoxFit.cover)
            : hasUrl
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined),
                  )
                : const Icon(Icons.image_outlined, size: 20),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
