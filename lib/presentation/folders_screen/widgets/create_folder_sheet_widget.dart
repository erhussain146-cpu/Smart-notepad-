import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class CreateFolderSheetWidget extends StatefulWidget {
  final void Function(String name, String colorKey) onCreateFolder;

  const CreateFolderSheetWidget({super.key, required this.onCreateFolder});

  @override
  State<CreateFolderSheetWidget> createState() =>
      _CreateFolderSheetWidgetState();
}

class _CreateFolderSheetWidgetState extends State<CreateFolderSheetWidget> {
  final _nameController = TextEditingController();
  String _selectedColor = 'blue';
  final _formKey = GlobalKey<FormState>();

  final List<Map<String, dynamic>> _colorOptions = [
    {'key': 'blue', 'color': const Color(0xFF1565C0)},
    {'key': 'purple', 'color': const Color(0xFF6750A4)},
    {'key': 'green', 'color': const Color(0xFF2D7A4F)},
    {'key': 'yellow', 'color': const Color(0xFFB45309)},
    {'key': 'orange', 'color': const Color(0xFFE65100)},
    {'key': 'pink', 'color': const Color(0xFFC2185B)},
    {'key': 'red', 'color': const Color(0xFFB91C1C)},
    {'key': 'gray', 'color': const Color(0xFF757575)},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Create Folder',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Folder name',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CustomIconWidget(
                    iconName: 'folder_outlined',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter a folder name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Folder Color',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _colorOptions.map((opt) {
                final isSelected = _selectedColor == opt['key'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = opt['key']),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: opt['color'],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.onSurface
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onCreateFolder(
                      _nameController.text.trim(),
                      _selectedColor,
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Create Folder',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
