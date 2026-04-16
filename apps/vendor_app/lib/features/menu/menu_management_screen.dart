import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'menu_models.dart';
import 'menu_provider.dart';

typedef MenuImagePicker = Future<String?> Function(BuildContext context);
const String menuCategoryCardSemanticPrefix = 'Menu category';
const String menuItemCardSemanticPrefix = 'Menu item';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key, this.imagePicker});

  final MenuImagePicker? imagePicker;

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
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
        title: Text(
          'Menu Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Add category',
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
                ...categories.map(
                  (category) => _CategoryCard(
                    category: category,
                    onEdit: () => _showEditCategory(context, category),
                    onDelete: () => _confirmDeleteCategory(context, category),
                    onAddItem: () => _showAddItem(
                      context,
                      categories,
                      preselected: category,
                    ),
                    onEditItem: (item) =>
                        _showEditItem(context, category, item),
                    onDeleteItem: (item) => _confirmDeleteItem(context, item),
                    onToggleAvailability: (item) => _toggleAvailability(item),
                  ),
                ),
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
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Category name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sortController,
              decoration: const InputDecoration(
                labelText: 'Sort order (optional)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    await ref.read(menuProvider.notifier).createMenu({
      'category_name': name,
      if (sortController.text.trim().isNotEmpty)
        'sort_order': int.tryParse(sortController.text.trim()) ?? 0,
    });
  }

  static bool _isDataImageUrl(String value) =>
      value.toLowerCase().startsWith('data:image/');

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

  /// Pick an image from gallery and return base64-encoded bytes.
  /// Compatible with backend upload endpoint.
  ///
  /// If testable imagePicker is injected, expects it to return base64 data.
  Future<({String base64, String mimeType})> _pickImageBase64(
    BuildContext context,
  ) async {
    if (widget.imagePicker != null) {
      // For testing: injected picker returns full data URL
      final dataUrl = await widget.imagePicker!(context);
      if (dataUrl == null) throw Exception('No image selected');

      // Extract base64 and MIME type from data URL
      final marker = ';base64,';
      final mimeEnd = dataUrl.indexOf(';');
      if (mimeEnd < 6) throw Exception('Invalid data URL format');

      final mimeType = dataUrl.substring(5, mimeEnd);
      final index = dataUrl.indexOf(marker);
      if (index <= 0) throw Exception('Invalid base64 data');

      final base64 = dataUrl.substring(index + marker.length);
      return (base64: base64, mimeType: mimeType);
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (image == null) throw Exception('No image selected');

    final bytes = await image.readAsBytes();
    final mimeType = image.mimeType ?? _mimeFromPath(image.name);
    final base64 = base64Encode(bytes);

    return (base64: base64, mimeType: mimeType);
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

  /// Client-side validation for file size and MIME type (before upload).
  /// Returns error message if validation fails, null if valid.
  String? _validateImageFile(String base64Data, String mimeType) {
    // Validate MIME type
    const allowedMimes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (!allowedMimes.contains(mimeType)) {
      return 'Invalid image type. Allowed: JPEG, PNG, WebP, GIF';
    }

    // Validate file size (5 MB max)
    final bytes = base64Data.codeUnits.length;
    const maxBytes = 5 * 1024 * 1024;
    if (bytes > maxBytes) {
      final sizeMB = (bytes / (1024 * 1024)).toStringAsFixed(2);
      return 'File too large ($sizeMB MB). Maximum: 5 MB';
    }

    return null;
  }

  /// Upload image to backend storage endpoint and return HTTPS URL.
  ///
  /// This replaces client-side data URL generation with server-backed storage,
  /// which reduces payload size and enables proper caching.
  ///
  /// Returns the HTTPS URL from Supabase CDN, or null if upload fails.
  Future<String?> _uploadImageToBackend(
    String base64Data,
    String mimeType,
    BuildContext context,
  ) async {
    // Validate before uploading
    final error = _validateImageFile(base64Data, mimeType);
    if (error != null) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return null;
    }

    try {
      // Get Dio client from menu provider's HTTP service
      final menuNotifier = ref.read(menuProvider.notifier);
      final dio = menuNotifier.getDio();

      // POST to /vendor-ops/menu/upload-image
      final response = await dio.post(
        '/vendor-ops/menu/upload-image',
        data: {'imageData': base64Data, 'mimeType': mimeType},
      );

      if (response.statusCode == 201) {
        final url = response.data['url'] as String?;
        if (url != null && url.trim().isNotEmpty) {
          return url;
        }
      }
      throw Exception('Upload failed: invalid response');
    } catch (e) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: ${e is DioException ? e.message : e.toString()}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  Future<void> _showEditCategory(
    BuildContext context,
    MenuCategory category,
  ) async {
    final nameController = TextEditingController(text: category.name);
    final sortController = TextEditingController(
      text: category.sortOrder?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Category name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sortController,
              decoration: const InputDecoration(labelText: 'Sort order'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != true) return;
    await ref.read(menuProvider.notifier).updateMenu(category.id, {
      'category_name': nameController.text.trim(),
      if (sortController.text.trim().isNotEmpty)
        'sort_order': int.tryParse(sortController.text.trim()) ?? 0,
    });
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    MenuCategory category,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category'),
        content: Text('Delete ${category.name} and all items inside?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(menuProvider.notifier).deleteMenu(category.id);
    }
  }

  Future<void> _showAddItem(
    BuildContext context,
    List<MenuCategory> categories, {
    MenuCategory? preselected,
  }) async {
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
                  onChanged: (value) =>
                      setState(() => selected = value ?? selected),
                  items: categories
                      .map(
                        (cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat.name)),
                      )
                      .toList(),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item name'),
                ),
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
                    style: TextStyle(
                      color: imageError == null ? Colors.grey : Colors.red,
                    ),
                  ),
                  trailing: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final data = await _pickImageBase64(context);
                        if (!context.mounted) return;

                        // Upload to backend
                        final uploadedUrl = await _uploadImageToBackend(
                          data.base64,
                          data.mimeType,
                          context,
                        );

                        if (uploadedUrl != null) {
                          setState(() {
                            imageUrl = uploadedUrl;
                            imageError = null;
                          });
                        }
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to pick image: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
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

  Future<void> _showEditItem(
    BuildContext context,
    MenuCategory category,
    MenuItem item,
  ) async {
    final nameController = TextEditingController(text: item.name);
    final descController = TextEditingController(text: item.description ?? '');
    final priceController = TextEditingController(
      text: item.price.toStringAsFixed(0),
    );
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
                Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item name'),
                ),
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
                    style: TextStyle(
                      color: imageError == null ? Colors.grey : Colors.red,
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final data = await _pickImageBase64(context);
                            if (!context.mounted) return;

                            // Upload to backend
                            final uploadedUrl = await _uploadImageToBackend(
                              data.base64,
                              data.mimeType,
                              context,
                            );

                            if (uploadedUrl != null) {
                              setState(() {
                                imageUrl = uploadedUrl;
                                imageError = null;
                              });
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to pick image: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update'),
          ),
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
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
      child: Semantics(
        container: true,
        label: '$menuCategoryCardSemanticPrefix ${category.name}',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (category.createdAt != null ||
                            category.updatedAt != null)
                          Text(
                            [
                              if (category.createdAt != null)
                                'Created: ${category.createdAt!.toLocal()}',
                              if (category.updatedAt != null)
                                'Updated: ${category.updatedAt!.toLocal()}',
                            ].join(' | '),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add item to ${category.name}',
                    onPressed: onAddItem,
                    icon: const Icon(Icons.add_rounded),
                  ),
                  IconButton(
                    tooltip: 'Edit ${category.name}',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete ${category.name}',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (category.items.isEmpty)
                Text(
                  'No items in this category yet.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                ...category.items.map(
                  (item) => _ItemRow(
                    item: item,
                    onEdit: () => onEditItem(item),
                    onDelete: () => onDeleteItem(item),
                    onToggleAvailability: () => onToggleAvailability(item),
                  ),
                ),
            ],
          ),
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
    return Semantics(
      container: true,
      label:
          '$menuItemCardSemanticPrefix ${item.name}, Rs ${item.price.toStringAsFixed(0)}',
      child: Container(
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
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_not_supported_outlined),
                      )
                    : const Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rs ${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
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
            IconButton(
              tooltip: 'Edit ${item.name}',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete ${item.name}',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }

  static Uint8List? _decodeDataImage(String? value) {
    if (value == null || !value.toLowerCase().startsWith('data:image/')) {
      return null;
    }
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
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported_outlined),
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
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
