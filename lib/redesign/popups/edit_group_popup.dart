import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/resources/models/media_group.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/services/admin_upload_service.dart';

Future<Map<String, dynamic>?> showEditGroupPopup(
    BuildContext context, MediaGroup group) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (context) => EditGroupPopup(group: group),
  );
}

class EditGroupPopup extends StatefulWidget {
  final MediaGroup group;

  const EditGroupPopup({Key? key, required this.group}) : super(key: key);

  @override
  State<EditGroupPopup> createState() => _EditGroupPopupState();
}

class _EditGroupPopupState extends State<EditGroupPopup> {
  late final TextEditingController _nameController;
  late final TextEditingController _iconUrlController;
  late final TextEditingController _orderingController;
  late bool _isNewGroup;
  bool _isLoading = false;
  bool _isUploadingThumbnail = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name ?? '');
    _iconUrlController =
        TextEditingController(text: widget.group.iconUrl ?? '');
    _orderingController =
        TextEditingController(text: (widget.group.ordering ?? 0).toString());
    _isNewGroup = (widget.group.isNewGroup ?? 0) != 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconUrlController.dispose();
    _orderingController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadThumbnail() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final Uint8List? bytes = file.bytes;
    final String fileName = file.name;
    if (bytes == null || bytes.isEmpty) {
      setState(() => _errorMessage = 'Could not read file data');
      return;
    }
    setState(() {
      _isUploadingThumbnail = true;
      _errorMessage = null;
    });
    try {
      final service = AdminUploadService();
      final response = await service.uploadThumbnailFromBytes(bytes, fileName);
      final cdnUrl = response['cdnUrl'] as String? ??
          response['thumbnailUrl'] as String? ??
          '';
      setState(() {
        _iconUrlController.text = cdnUrl;
        _isUploadingThumbnail = false;
      });
    } catch (e) {
      setState(() {
        _isUploadingThumbnail = false;
        _errorMessage = 'Thumbnail upload failed: $e';
      });
    }
  }

  Future<void> _updateGroup() async {
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
      final result = await service.updateGroup(
        alias: widget.group.alias ?? '',
        name: name,
        iconUrl: _iconUrlController.text.trim(),
        ordering: int.tryParse(_orderingController.text.trim()) ?? 0,
        isNewGroup: _isNewGroup ? 1 : 0,
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
            const Text('Edit Group', style: AppTheme.popupTitleStyle),
            const SizedBox(height: 4),
            Text(
              'Alias: ${widget.group.alias}',
              style: AppTheme.mediaItemSubtitleStyle,
            ),
            const SizedBox(height: 16),
            _buildTextField(_nameController, 'Name'),
            const SizedBox(height: 10),
            _buildThumbnailPicker(),
            const SizedBox(height: 10),
            _buildTextField(_orderingController, 'Ordering',
                keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            Row(
              children: [
                Switch(
                  value: _isNewGroup,
                  onChanged: (v) => setState(() => _isNewGroup = v),
                  activeColor: AppTheme.accentCyan,
                ),
                const SizedBox(width: 8),
                const Text('Mark as New', style: AppTheme.mediaItemTitleStyle),
              ],
            ),
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
                  onPressed: (_isLoading || _isUploadingThumbnail)
                      ? null
                      : _updateGroup,
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

  Widget _buildThumbnailPicker() {
    final hasUrl = _iconUrlController.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thumbnail', style: AppTheme.textFieldLabelStyle),
        const SizedBox(height: 6),
        Row(
          children: [
            if (hasUrl && !_isUploadingThumbnail)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  _iconUrlController.text,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: AppTheme.textSecondary2,
                    size: 48,
                  ),
                ),
              ),
            if (hasUrl) const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _isUploadingThumbnail ? null : _pickAndUploadThumbnail,
              icon: _isUploadingThumbnail
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.image_outlined, size: 18),
              label: Text(_isUploadingThumbnail
                  ? 'Uploading...'
                  : hasUrl
                      ? 'Change JPG'
                      : 'Choose JPG'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceDark,
                foregroundColor: AppTheme.accentCyan,
                side: const BorderSide(color: AppTheme.dividerDark),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        if (hasUrl) ...[
          const SizedBox(height: 4),
          Text(
            _iconUrlController.text,
            style: AppTheme.mediaItemSubtitleStyle.copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
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
