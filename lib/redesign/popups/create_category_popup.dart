import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/services/admin_upload_service.dart';

Future<Map<String, dynamic>?> showCreateCategoryPopup(BuildContext context) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const CreateCategoryPopup(),
  );
}

class CreateCategoryPopup extends StatefulWidget {
  const CreateCategoryPopup({Key? key}) : super(key: key);

  @override
  State<CreateCategoryPopup> createState() => _CreateCategoryPopupState();
}

class _CreateCategoryPopupState extends State<CreateCategoryPopup> {
  final _aliasController = TextEditingController();
  final _nameController = TextEditingController();
  final _orderingController = TextEditingController(text: '0');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _aliasController.dispose();
    _nameController.dispose();
    _orderingController.dispose();
    super.dispose();
  }

  Future<void> _createCategory() async {
    final alias = _aliasController.text.trim();
    final name = _nameController.text.trim();
    if (alias.isEmpty || name.isEmpty) {
      setState(() => _errorMessage = 'Alias and Name are required');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final service = AdminUploadService();
      final result = await service.createCategory(
        alias: alias,
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
            const Text('Create New Category', style: AppTheme.popupTitleStyle),
            const SizedBox(height: 16),
            _buildTextField(_aliasController, 'Alias (unique identifier)',
                hint: 'e.g. shows'),
            const SizedBox(height: 10),
            _buildTextField(_nameController, 'Name',
                hint: 'e.g. \u0547\u0578\u0582\u0576\u0565\u0580'),
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
                  onPressed: _isLoading ? null : _createCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: AppTheme.primaryDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create'),
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
          borderSide: const BorderSide(color: AppTheme.accentGreen),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
