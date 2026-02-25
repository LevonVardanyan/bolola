import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/pages/video/base_video_widget.dart';
import 'package:politicsstatements/redesign/resources/models/media_item.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/services/admin_upload_service.dart';
import 'package:video_player/video_player.dart';

import '../../resources/prefs.dart';
import '../../utils/utils.dart';

/// Admin video item widget specifically for web with full admin controls
class AdminVideoItemWidget extends BaseVideoWidget {
  final bool showDevTools;
  final VoidCallback? onDeleted;

  const AdminVideoItemWidget({
    Key? key,
    required AppBloc appBloc,
    required MediaItem item,
    required Future<void> Function(VideoPlayerController?) onPlay,
    required Function(VideoPlayerController?) onControllerReady,
    required VoidCallback onControllerDispose,
    bool isWebGrid = true,
    this.showDevTools = false,
    this.onDeleted,
  }) : super(
          key: key,
          appBloc: appBloc,
          item: item,
          onPlay: onPlay,
          onControllerReady: onControllerReady,
          onControllerDispose: onControllerDispose,
          isWebGrid: isWebGrid,
        );

  @override
  State<AdminVideoItemWidget> createState() => _AdminVideoItemWidgetState();
}

class _AdminVideoItemWidgetState extends BaseVideoWidgetState<AdminVideoItemWidget> {
  // Admin UI controllers
  final _nameController = TextEditingController();
  final _shareCountController = TextEditingController();
  final _keywordController = TextEditingController();
  final _relatedKeywordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shareCountController.dispose();
    _keywordController.dispose();
    _relatedKeywordController.dispose();
    super.dispose();
  }

  /// Initialize controllers with current item data
  void _initializeControllers() {
    _nameController.text = widget.item.name ?? "";
    _shareCountController.text = widget.item.shareCount.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isWebGrid) {
      return _buildWebGridLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildWebGridLayout() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.mediaCardRadius),
        border: Border.all(color: AppTheme.dividerDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.mediaCardRadius - 1),
                topRight: Radius.circular(AppTheme.mediaCardRadius - 1),
              ),
              child: buildVideoPlayer(),
            ),
          ),
          buildSeekBar(),
          Expanded(
            flex: 4,
            child: _buildAdminInterface(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.mediaCardPadding,
        vertical: 6,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(AppTheme.mediaCardRadius),
          border: Border.all(color: AppTheme.dividerDark),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.mediaCardRadius - 1),
                topRight: Radius.circular(AppTheme.mediaCardRadius - 1),
              ),
              child: buildVideoPlayer(),
            ),
            buildSeekBar(),
            _buildMobileAdminInterface(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminInterface() {
    return StreamBuilder<bool>(
      stream: updateStream,
      builder: (context, snapshot) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Share Count Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildEditField(
                        label: "Title",
                        controller: _nameController,
                        initialValue: widget.item.name ?? "",
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: _buildEditField(
                        label: "Shares",
                        controller: _shareCountController,
                        initialValue: widget.item.shareCount.toString(),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Keywords and Related Keywords Row (Editable)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildEditField(
                        label: "Keywords",
                        controller: _keywordController,
                        initialValue: (widget.item.keywords ?? []).join(', '),
                        hint: "Enter keywords separated by commas",
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildEditField(
                        label: "Related Keywords",
                        controller: _relatedKeywordController,
                        initialValue: (widget.item.relatedKeywords ?? []).join(', '),
                        hint: "Enter related keywords separated by commas",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Save & Delete Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveAllChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    if (isAdminUser) ...[
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 36,
                        width: 36,
                        child: IconButton(
                          onPressed: _confirmDeleteItem,
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          color: AppTheme.accentMagenta,
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.accentMagenta.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Action Buttons Row - Same logic as video_list_item
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildFavoriteButton(),
                    if (isAndroid()) buildDownloadButton(),
                    buildShareButton(),
                    buildHelpUsButton(),
                  ],
                ),

                // User Suggestions DevTools
                if (widget.showDevTools)
                  DevToolsWidget(widget.appBloc, widget.item, () {
                    setState(() {});
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileAdminInterface() {
    return StreamBuilder<bool>(
      stream: updateStream,
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title Section - Full width on mobile
              _buildEditField(
                label: "Title",
                controller: _nameController,
                initialValue: widget.item.name ?? "",
              ),
              const SizedBox(height: 12),

              // Share Count Section
              Row(
                children: [
                  Expanded(
                    child: _buildEditField(
                      label: "Shares",
                      controller: _shareCountController,
                      initialValue: widget.item.shareCount.toString(),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: Container()), // Spacer
                ],
              ),
              const SizedBox(height: 12),

              // Keywords Section - Editable
              _buildEditField(
                label: "Keywords",
                controller: _keywordController,
                initialValue: (widget.item.keywords ?? []).join(', '),
                hint: "Enter keywords separated by commas",
              ),
              const SizedBox(height: 12),

              // Related Keywords Section - Editable
              _buildEditField(
                label: "Related Keywords",
                controller: _relatedKeywordController,
                initialValue: (widget.item.relatedKeywords ?? []).join(', '),
                hint: "Enter related keywords separated by commas",
              ),
              const SizedBox(height: 16),

              // Save & Delete Buttons - Mobile
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveAllChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Save All Changes",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  if (isAdminUser) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      width: 48,
                      child: IconButton(
                        onPressed: _confirmDeleteItem,
                        icon: const Icon(Icons.delete_outline, size: 22),
                        color: AppTheme.accentMagenta,
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.accentMagenta.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons Row - Same logic as video_list_item
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildFavoriteButton(),
                  if (isAndroid()) buildDownloadButton(),
                  buildShareButton(),
                  buildHelpUsButton(),
                ],
              ),

              // User Suggestions DevTools
              if (widget.showDevTools)
                DevToolsWidget(widget.appBloc, widget.item, () {
                  setState(() {});
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    String? initialValue,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    // Set initial value if provided and controller is empty
    if (initialValue != null && controller.text.isEmpty) {
      controller.text = initialValue;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.mediaItemTitleStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 3),
        Container(
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.textSecondary2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: AppTheme.mediaItemTitleStyle.copyWith(fontSize: 10),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTheme.mediaItemSubtitleStyle.copyWith(fontSize: 9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Delete Item', style: AppTheme.popupTitleStyle),
        content: Text(
          'Delete "${widget.item.name}"?\nThis cannot be undone.',
          style: AppTheme.mediaItemTitleStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary2)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentMagenta,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final service = AdminUploadService();
      await service.deleteItem(widget.item.alias ?? '');
      final group = findGroupByAlias(
        widget.item.groupAlias ?? '',
        widget.item.categoryAlias ?? '',
      );
      group?.items?.removeWhere((i) => i.alias == widget.item.alias);
      widget.onDeleted?.call();
      showToast('Item deleted successfully');
    } catch (e) {
      showToast('Error deleting item: $e');
    }
  }

  void _saveAllChanges() async {
    try {
      // Save title if changed
      if (_nameController.text.isNotEmpty && _nameController.text != widget.item.name) {
        widget.item.name = _nameController.text;
      }

      // Save share count if changed
      int? newShareCount = int.tryParse(_shareCountController.text);
      if (newShareCount != null && newShareCount != widget.item.shareCount) {
        widget.item.shareCount = newShareCount;
      }

      // Parse and save keywords
      if (_keywordController.text.isNotEmpty) {
        List<String> newKeywords =
            _keywordController.text.split(',').map((keyword) => keyword.trim()).where((keyword) => keyword.isNotEmpty).toList();

        widget.item.keywords = newKeywords;

        // Also update allKeywords
        if (widget.item.allKeywords == null) widget.item.allKeywords = [];
        // Add new keywords to allKeywords if they don't exist
        for (String keyword in newKeywords) {
          if (!widget.item.allKeywords!.contains(keyword)) {
            widget.item.allKeywords!.add(keyword);
          }
        }
      } else {
        // Clear keywords if field is empty
        widget.item.keywords = [];
      }

      // Parse and save related keywords
      if (_relatedKeywordController.text.isNotEmpty) {
        List<String> newRelatedKeywords =
            _relatedKeywordController.text.split(',').map((keyword) => keyword.trim()).where((keyword) => keyword.isNotEmpty).toList();

        widget.item.relatedKeywords = newRelatedKeywords;

        // Also update allKeywords
        if (widget.item.allKeywords == null) widget.item.allKeywords = [];
        // Add new related keywords to allKeywords if they don't exist
        for (String keyword in newRelatedKeywords) {
          if (!widget.item.allKeywords!.contains(keyword)) {
            widget.item.allKeywords!.add(keyword);
          }
        }
      } else {
        // Clear related keywords if field is empty
        widget.item.relatedKeywords = [];
      }

      // Call update item endpoint to persist all changes
      widget.appBloc.updateChartItem(widget.item);
      await widget.appBloc.updateItem(widget.item);

      // Update favorites and chartList from source data to reflect changes
      updateFavoritesAndChartFromSource();

      setState(() {});
      showToast("All changes saved successfully!");
    } catch (e) {
      showToast("Error saving changes: $e");
    }
  }
}

class DevToolsWidget extends StatefulWidget {
  AppBloc appBloc;
  MediaItem item;
  Function() update;

  DevToolsWidget(this.appBloc, this.item, this.update);

  @override
  State<DevToolsWidget> createState() => _DevToolsWidgetState();
}

class _DevToolsWidgetState extends State<DevToolsWidget> {
  Map<String, bool> _editingStates = {}; // Track which suggestions are being edited
  Map<String, TextEditingController> _controllers = {}; // Controllers for each suggestion

  @override
  void dispose() {
    // Dispose all controllers
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Separate suggestions and fixes
    List<String> keywordSuggestions = widget.item.suggestedKeywords ?? [];

    if (keywordSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.actionBarColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentCyan.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppTheme.accentCyan,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                "User Suggestions",
                style: AppTheme.mediaItemTitleStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppTheme.accentCyan,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${keywordSuggestions.length}",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (keywordSuggestions.isNotEmpty) ...[
            Text(
              "Keyword Suggestions",
              style: AppTheme.mediaItemTitleStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentCyan,
              ),
            ),
            const SizedBox(height: 8),

            // Keyword suggestions
            ...keywordSuggestions
                .map((suggestion) => _buildSuggestionItem(
                      suggestion,
                      Icons.search_rounded,
                      AppTheme.accentCyan,
                      "keyword",
                    ))
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String suggestion, IconData icon, Color color, String type) {
    // Initialize controller if not exists
    if (!_controllers.containsKey(suggestion)) {
      _controllers[suggestion] = TextEditingController(text: suggestion);
    }

    bool isEditing = _editingStates[suggestion] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isEditing ? AppTheme.accentCyan : color.withValues(alpha: 0.5), width: isEditing ? 2 : 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: _controllers[suggestion],
                        style: AppTheme.mediaItemTitleStyle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: "Edit suggestion...",
                          hintStyle: AppTheme.mediaItemSubtitleStyle.copyWith(fontSize: 12),
                        ),
                        autofocus: true,
                        onSubmitted: (value) {
                          _saveEdit(suggestion);
                        },
                      )
                    : Text(
                        _controllers[suggestion]?.text ?? suggestion,
                        style: AppTheme.mediaItemTitleStyle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
              const SizedBox(width: 8),

              // Edit/Save button
              InkWell(
                onTap: () {
                  if (isEditing) {
                    _saveEdit(suggestion);
                  } else {
                    _startEdit(suggestion);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.4)),
                  ),
                  child: Icon(
                    isEditing ? Icons.check_rounded : Icons.edit_rounded,
                    color: AppTheme.accentCyan,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          if (isEditing) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Press Enter to save or click the check icon",
                    style: AppTheme.mediaItemSubtitleStyle.copyWith(fontSize: 10),
                  ),
                ),
                InkWell(
                  onTap: () => _cancelEdit(suggestion),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Remove button
              InkWell(
                onTap: () {
                  widget.appBloc.removeSuggestion(widget.item, suggestion, () {
                    // Clean up controller when removing
                    _controllers[suggestion]?.dispose();
                    _controllers.remove(suggestion);
                    _editingStates.remove(suggestion);
                    widget.update();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        color: Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Remove',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Add button (only for keyword suggestions)
              if (type == "keyword")
                InkWell(
                  onTap: () {
                    String keywordToAdd = _controllers[suggestion]?.text.trim() ?? suggestion;

                    if (keywordToAdd.isNotEmpty) {
                      widget.appBloc.addKeywordFromSuggestion(widget.item, keywordToAdd, () {
                        // Clean up controller when adding
                        _controllers[suggestion]?.dispose();
                        _controllers.remove(suggestion);
                        _editingStates.remove(suggestion);
                        widget.update();
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isEditing ? 'Add Edited' : 'Add',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _startEdit(String suggestion) {
    setState(() {
      _editingStates[suggestion] = true;
    });
  }

  void _saveEdit(String suggestion) {
    setState(() {
      _editingStates[suggestion] = false;
    });
  }

  void _cancelEdit(String suggestion) {
    setState(() {
      _editingStates[suggestion] = false;
      // Reset controller text to original suggestion
      _controllers[suggestion]?.text = suggestion;
    });
  }
}
