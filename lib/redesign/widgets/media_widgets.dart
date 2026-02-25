import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/popups/edit_group_popup.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/services/admin_upload_service.dart';
import '../resources/models/media_group.dart';
import '../resources/models/media_item.dart';

class MediaGroupWidget extends StatelessWidget {
  final String groupAlias;
  final String categoryAlias;
  final AppBloc appBloc;
  final Function() onClick;
  final VoidCallback? onDeleted;
  final VoidCallback? onEdited;

  const MediaGroupWidget(this.appBloc, this.groupAlias, this.categoryAlias, this.onClick, {Key? key, this.onDeleted, this.onEdited}) : super(key: key);

  Future<void> _confirmDeleteGroup(BuildContext context, MediaGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Delete Group', style: AppTheme.popupTitleStyle),
        content: Text(
          'Delete "${group.name}" and all its ${group.items?.length ?? 0} items?\nThis cannot be undone.',
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
      await service.deleteGroup(group.alias ?? '');
      for (var category in medias?.categories ?? []) {
        category.groups?.removeWhere((g) => g.alias == group.alias);
      }
      onDeleted?.call();
    } catch (e) {
      if (kDebugMode) print('Error deleting group: $e');
    }
  }

  Future<void> _handleEditGroup(BuildContext context, MediaGroup group) async {
    final result = await showEditGroupPopup(context, group);
    if (result != null) {
      final groupData = result['group'] as Map<String, dynamic>?;
      if (groupData != null) {
        group.name = groupData['name'] as String? ?? group.name;
        group.iconUrl = groupData['iconUrl'] as String? ?? group.iconUrl;
        group.ordering = groupData['ordering'] as int? ?? group.ordering;
        group.isNewGroup = groupData['isNewGroup'] as int? ?? group.isNewGroup;
        onEdited?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const size = 160.0;
    MediaGroup? group = findGroupByAlias(groupAlias, categoryAlias);
    bool isGroupEmpty = medias?.isGroupEmpty(group) == true;
    return InkWell(
      onTap: onClick,
      child: Container(
        height: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                group?.iconUrl?.isEmpty == true || group == null
                    ? Container(
                        color: AppTheme.cardDark,
                        width: size,
                        height: size,
                        child: Center(
                          child: CupertinoActivityIndicator(
                            color: AppTheme.blue900,
                          ),
                        ))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Container(
                          width: size,
                          height: size,
                          child: CachedNetworkImage(
                            imageUrl: group?.iconUrl ?? "",
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.cardDark,
                              child: Center(
                                child: CupertinoActivityIndicator(
                                  color: AppTheme.accentCyan,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.cardDark,
                              child: Center(
                                child: Icon(
                                  Icons.error_outline,
                                  color: AppTheme.textSecondary2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                if (isGroupEmpty && group?.items == null)
                  Container(
                    color: Colors.black45,
                    width: size,
                    height: size,
                    child: CupertinoActivityIndicator(
                      color: AppTheme.white,
                    ),
                  ),
                if (group != null && (group.isNewGroup ?? 0) == 1)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF6B9D),
                            Color(0xFFC239B3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B9D).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.fiber_new,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isAdminUser && group != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _handleEditGroup(context, group),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.edit_outlined, color: AppTheme.accentCyan, size: 18),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _confirmDeleteGroup(context, group),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.delete_outline, color: AppTheme.accentMagenta, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(
              height: 2,
            ),
            SizedBox(
              width: size,
              child: Text(
                (group?.name ?? "") + " (${group?.items?.length ?? 0})",
                style: AppTheme.groupNameStyle,
              ),
            )
          ],
        ),
      ),
    );
  }
}

