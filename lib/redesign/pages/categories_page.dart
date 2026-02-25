import 'dart:io';
import 'dart:ui';

import 'package:blur/blur.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/pages/media_group_page.dart';
import 'package:politicsstatements/redesign/pages/media_list_widget.dart';
import 'package:politicsstatements/redesign/pages/media_top_chart_page.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/resources/rest_client.dart';
import 'package:politicsstatements/redesign/utils/popup_utils.dart';
import 'package:politicsstatements/redesign/widgets/media_widgets.dart';

import '../resources/models/media_category.dart';
import '../resources/models/media_group.dart';
import '../resources/models/medias.dart';
import '../popups/create_group_popup.dart';
import '../popups/create_category_popup.dart';
import '../popups/edit_category_popup.dart';
import '../popups/edit_group_popup.dart';
import '../services/admin_upload_service.dart';

class CategoriesPage extends StatefulWidget {
  AppBloc appBloc;
  _CategoriesPageState state = _CategoriesPageState();

  CategoriesPage(this.appBloc);

  @override
  State<StatefulWidget> createState() {
    return this.state = _CategoriesPageState();
  }
}

class _CategoriesPageState extends State<CategoriesPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  late MediaListView mediaListView;
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
        stream: widget.appBloc.dataLoadingStream,
        initialData: false,
        builder: (context, dataLoadingSnapshot) {
          return dataLoadingSnapshot.data == true
              ? WelcomeLoadingWidget()
              : Container(
                  child: Stack(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          medias == null
                              ? Container()
                              : Expanded(
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: (medias?.categories?.length ?? 0) + (isAdminUser ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      final categoryCount = medias?.categories?.length ?? 0;
                                      if (index == categoryCount && isAdminUser) {
                                        return _buildCreateCategoryButton();
                                      }
                                      return Padding(
                                        padding: EdgeInsets.only(top: index == 0 ? 150.0 : 0),
                                        child: MediaCategoryWidget(
                                          widget.appBloc,
                                          medias!.categories![index],
                                          onDeleted: () => setState(() {}),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                      Stack(
                        children: [
                          Container(
                            child: Stack(
                              children: [
                                ClipRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 7.5, sigmaY: 7.5),
                                    child: Container(
                                      height: 140,
                                      width: double.infinity,
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        child: Image.asset("assets/transparent.png"),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: kIsWeb ? 0 : 36.0,
                                    left: 16,
                                  ),
                                  child: Container(
                                    height: 56,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                Scaffold.of(context).openDrawer();
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.surfaceDark,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: AppTheme.dividerDark),
                                                ),
                                                child: const Icon(
                                                  Icons.menu_rounded,
                                                  color: AppTheme.textSecondary2,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                            Expanded(child: Container()),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Bolola',
                                                  style: AppTheme.headingSStyle,
                                                ),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (!isProductionEnvironment)
                                                      Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                        color: AppTheme.accentOrange.withValues(alpha: 0.2),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: AppTheme.accentOrange),
                                                      ),
                                                      child: Text(
                                                        "STAGING v${appVersion}",
                                                        style: const TextStyle(
                                                          color: AppTheme.accentOrange,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Expanded(child: Container()),
                                            InkWell(
                                              onTap: () async {
                                                final messageSent = await showSendMessagePopup(context, widget.appBloc);
                                                if (messageSent == true) {
                                                  // Message was sent successfully
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                margin: const EdgeInsets.only(right: 16.0),
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.surfaceDark,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: AppTheme.dividerDark),
                                                ),
                                                child: const Icon(
                                                  Icons.message_rounded,
                                                  color: AppTheme.textSecondary2,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 88.0),
                                  child: Container(
                                    height: 36,
                                    width: double.infinity,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        right: 16,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          widget.appBloc.openCategoriesSearch();
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(AppTheme.mediaCardRadius), border: Border.all(color: AppTheme.dividerDark)),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 8,
                                              ),
                                              Icon(
                                                Icons.search,
                                                color: AppTheme.textSecondary2,
                                              ),
                                              SizedBox(
                                                width: 8,
                                              ),
                                              Text(
                                                "Որոնում հայատառ և լատինատառ",
                                                style: AppTheme.textFieldHintStyle,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
        });
  }

  Widget _buildCreateCategoryButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () async {
          final result = await showCreateCategoryPopup(context);
          if (result != null) {
            final catData = result['category'] as Map<String, dynamic>?;
            if (catData != null) {
              final newCategory = MediaCategory(
                alias: catData['alias'],
                name: catData['name'],
                ordering: catData['ordering'] ?? 0,
                groups: [],
                groupNames: [],
              );
              setState(() {
                medias?.categories?.add(newCategory);
              });
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.accentGreen.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline,
                  color: AppTheme.accentGreen, size: 22),
              const SizedBox(width: 8),
              Text(
                'Create New Category',
                style: TextStyle(
                  color: AppTheme.accentGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MediaCategoryWidget extends StatefulWidget {
  final MediaCategory category;
  final AppBloc appBloc;
  final VoidCallback? onDeleted;

  const MediaCategoryWidget(this.appBloc, this.category, {Key? key, this.onDeleted}) : super(key: key);

  @override
  State<MediaCategoryWidget> createState() => _MediaCategoryWidgetState();
}

class _MediaCategoryWidgetState extends State<MediaCategoryWidget> {
  Future<void> _handleCreateGroup() async {
    final result = await showCreateGroupPopup(context, widget.category.alias ?? '');
    if (result != null) {
      final groupData = result['group'] as Map<String, dynamic>?;
      if (groupData != null) {
        final newGroup = MediaGroup(
          alias: groupData['alias'],
          name: groupData['name'],
          categoryAlias: groupData['categoryAlias'],
          iconUrl: groupData['iconUrl'] ?? '',
          count: groupData['count'] ?? 0,
          ordering: groupData['ordering'] ?? 0,
          isNewGroup: groupData['isNewGroup'] ?? 0,
          items: [],
        );
        setState(() {
          widget.category.groups?.add(newGroup);
        });
      }
    }
  }

  Future<void> _confirmDeleteCategory() async {
    final groupCount = widget.category.groups?.length ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Delete Category', style: AppTheme.popupTitleStyle),
        content: Text(
          'Delete "${widget.category.name}" and all its $groupCount groups?\nThis cannot be undone.',
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
      await service.deleteCategory(widget.category.alias ?? '');
      medias?.categories?.removeWhere((c) => c.alias == widget.category.alias);
      widget.onDeleted?.call();
    } catch (e) {
      if (kDebugMode) print('Error deleting category: $e');
    }
  }

  Future<void> _handleEditCategory() async {
    final result = await showEditCategoryPopup(context, widget.category);
    if (result != null) {
      final catData = result['category'] as Map<String, dynamic>?;
      if (catData != null) {
        setState(() {
          widget.category.name = catData['name'] as String? ?? widget.category.name;
          widget.category.ordering = catData['ordering'] as int? ?? widget.category.ordering;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int groupCount = widget.category.groups?.length ?? 0;
    final int extraItems = isAdminUser ? 1 : 0;

    return Container(
      color: AppTheme.primaryDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8, top: 4, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    (widget.category.name ?? "") + " ($groupCount)",
                    style: AppTheme.strongStyleBold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isAdminUser) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _handleEditCategory,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.edit_outlined, color: AppTheme.accentCyan, size: 18),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _confirmDeleteCategory,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentMagenta.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.delete_outline, color: AppTheme.accentMagenta, size: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            height: 220,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              scrollDirection: Axis.horizontal,
              itemCount: groupCount + extraItems,
              itemBuilder: (context, i) {
                if (isAdminUser && i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: _buildCreateGroupButton(),
                  );
                }
                final groupIndex = isAdminUser ? i - 1 : i;
                return groupIndex < groupCount
                    ? Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: MediaGroupWidget(
                          widget.appBloc,
                          widget.category.groups![groupIndex].alias ?? "",
                          widget.category.alias!,
                          () {
                            if (isAdminUser || widget.category.groups![groupIndex].items?.isNotEmpty == true)
                              Navigator.push(context, MaterialPageRoute(builder: (_) => MediaGroupRoute(widget.appBloc, widget.category.groups![groupIndex])));
                          },
                          onDeleted: () => setState(() {}),
                          onEdited: () => setState(() {}),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 48),
                        child: InkWell(
                          onTap: () async {
                            final messageSent = await showSendMessagePopup(context, widget.appBloc);
                            if (messageSent == true) {
                              // Message was sent successfully
                            }
                          },
                          child: Container(
                            width: 160,
                            height: 160,
                            child: Center(
                              child: Text(
                                "Ուզու՞մ եք ավելին\nՍեղմեք այստեղ\nև օգնեք մեզ",
                                textAlign: TextAlign.center,
                                style: AppTheme.groupNameStyle,
                              ),
                            ),
                          ),
                        ),
                      );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCreateGroupButton() {
    const size = 160.0;
    return Container(
      height: 220,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _handleCreateGroup,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentCyan.withValues(alpha: 0.4),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: AppTheme.accentCyan, size: 28),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create\nNew Group',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.accentCyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeLoadingWidget extends StatelessWidget {
  bool dataLoaded = false;

  WelcomeLoadingWidget({Key? key, this.dataLoaded = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
            child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Տվյալները բեռնվում են...\nԽնդրում ենք սպասել, թե չէ\nԲոլոլայա լինելու ու ահավոր բազար",
                textAlign: TextAlign.center,
                style: AppTheme.strongStyle,
              ),
              SizedBox(
                height: 12,
              ),
              CupertinoActivityIndicator(
                color: AppTheme.accentCyan,
                radius: 18,
              )
            ],
          ),
        )),
      ),
    );
  }
}
