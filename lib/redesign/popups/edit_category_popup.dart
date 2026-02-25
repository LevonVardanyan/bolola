import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/resources/models/media_category.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/services/admin_upload_service.dart';

Future<Map<String, dynamic>?> showEditCategoryPopup(
    BuildContext context, MediaCategory category) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => EditCategoryPopup(category: category),
  );
}

class EditCategoryPopup extends StatefulWidget {
  final MediaCategory category;

  const EditCategoryPopup({Key? key, required this.category}) : super(key: key);

  @override
  State<EditCategoryPopup> createState() => _EditCategoryPopupState();
}

class _EditCategoryPopupState extends State<EditCategoryPopup> {
  late final TextEditingController _nameController;
  late final TextEditingController _orderingController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name ?? '');
    _orderingController =
        TextEditingController(text: (widget.category.ordering ?? 0).toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orderingController.dispose();
    super.dispose();
  }

  Future<void> _updateCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Name is required');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final service = AdminUploadService();
      final result = await service.updateCategory(
        alias: widget.category.alias ?? '',
        name: name,
        ordering: int.tryParse(_orderingController.text.trim()) ?? 0,
      );
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.mediaCardRadius)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Category', style: AppTheme.popupTitleStyle),
            const SizedBox(height: 4),
            Text(
              'Alias: ${widget.category.alias}',
              style: AppTheme.mediaItemSubtitleStyle,
            ),
            const SizedBox(height: 16),
            _buildTextField(_nameController, 'Name'),
            const SizedBox(height: 10),
            _buildTextField(_orderingController, 'Ordering',
                keyboardType: TextInputType.number),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!,
                  style: const TextStyle(
                      color: AppTheme.accentMagenta, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.textSecondary2)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentCyan,
                    foregroundColor: AppTheme.primaryDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTheme.mediaItemTitleStyle,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.textFieldLabelStyle,
        hintText: hint,
        hintStyle: AppTheme.textFieldHintStyle,
        filled: true,
        fillColor: AppTheme.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.accentCyan),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
