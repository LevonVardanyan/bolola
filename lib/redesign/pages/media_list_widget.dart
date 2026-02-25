import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/pages/audio/audios_list_widget.dart';
import 'package:politicsstatements/redesign/pages/sheets/sorting_type_sheet.dart';
import 'package:politicsstatements/redesign/pages/video/video_list_widget.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/utils/constants.dart';
import 'package:politicsstatements/redesign/utils/popup_utils.dart';
import 'package:politicsstatements/redesign/utils/utils.dart';
import 'package:politicsstatements/redesign/widgets/commong_widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:swipe_refresh/swipe_refresh.dart';

import '../resources/models/media_item.dart';

// Constants for better maintainability
class _MediaListConstants {
  static const double mobileStatusBarHeight = 48.0;
  static const double webStatusBarTopMargin = 12.0;
  static const double actionBarHeight = 56.0;
  static const double searchBarHeight = 36.0;
  static const double autoPlayBarHeight = 40.0;
  static const double tabBarHeight = 48.0;
  static const double blurSigma = 7.5;
  static const int searchDebounceMs = 100;
  static const int pageAnimationDurationMs = 300;

  // Padding constants
  static const double horizontalPadding = 12.0;
  static const double autoPlayTopPadding = 8.0;
  static const double autoPlayRightPadding = 16.0;
  static const double autoPlayBarHeightActual = 32.0;

  // Icon sizes
  static const double backIconSize = 36.0;
}

class MediaListView extends StatefulWidget {
  List<MediaItem> items;
  List<String>? groupSortingTypes;
  AppBloc appBloc;
  bool showActionBar = false;
  bool showSearch = true;
  bool? isAutoPlayDefault;
  bool showSortAndShuffle = true;

  bool focusOnSearch = false;
  bool showAd = true;
  String actionBarTitle = "";
  String searchText = "Որոնում այս խմբում";
  String textWhenEmpty = "";
  Function(int)? tabChanged;
  Function()? backClicked;
  _MediaListViewState state = _MediaListViewState();

  MediaListView(this.appBloc, this.items,
      {this.groupSortingTypes,
      this.showSearch = true,
      this.showAd = true,
      this.showActionBar = false,
      this.textWhenEmpty = "",
      this.searchText = "Որոնում այս խմբում",
      this.actionBarTitle = "",
      this.focusOnSearch = false,
      this.isAutoPlayDefault,
      this.showSortAndShuffle = true,
      this.tabChanged,
      this.backClicked});

  setItems(List<MediaItem> items) {
    this.items = items;
    state.itemsUpdated();
  }

  @override
  State<StatefulWidget> createState() {
    return this.state = _MediaListViewState();
  }

  bool isEmpty() {
    return items.isEmpty;
  }
}

class _MediaListViewState extends State<MediaListView> with TickerProviderStateMixin {
  late TabController tabController;
  late PageController pageController;

  List<String> searchSortingTypes = [SEARCH_SORT_TYPE_ORDER, SEARCH_SORT_TYPE_POPULAR];
  String groupSortingType = SORT_TYPE_MIXED.toString();
  String searchSortingType = SEARCH_SORT_TYPE_ORDER.toString();
  bool isAudio = false;
  bool? isAutoPlay;

  Timer? searchTimer;
  bool isSearching = false;
  String previousQuery = "";
  List<MediaItem> searchedItems = [];
  FocusNode searchFocusNode = FocusNode();

  TextEditingController searchController = TextEditingController();

  AudioListView? audioListView;
  VideoListWidget? videoListView;

  // Computed properties for better readability
  bool get shouldShowAutoPlayBar => isAutoPlay != null && !kIsWeb;
  
  bool get shouldShowControlPanel => shouldShowAutoPlayBar || (_shouldShowShuffleButton() || _shouldShowSortingWidget());

  bool get hasEmptySearchResults => isSearching && searchedItems.isEmpty;

  bool get hasEmptyItems => widget.items.isEmpty && !isSearching;

  /// Calculate the top offset for the content based on various UI elements
  double _calculateTopOffset() {
    double offset = 0;

    // Status bar height (mobile only)
    if (!kIsWeb) {
      offset += _MediaListConstants.mobileStatusBarHeight;
    } else {
      offset += _MediaListConstants.webStatusBarTopMargin;
    }

    // Action bar height
    if (widget.showActionBar) {
      offset += _MediaListConstants.actionBarHeight;
    }

    // Search bar height
    if (widget.showSearch) {
      offset += _MediaListConstants.searchBarHeight;
    }

    // Control panel height (autoplay bar or shuffle/sort controls)
    if (shouldShowControlPanel) {
      offset += _MediaListConstants.autoPlayBarHeight;
    }

    // Tab bar height
    offset += _MediaListConstants.tabBarHeight;

    return offset;
  }

  itemsUpdated() {
    audioListView?.setItems(widget.items);
    videoListView?.updateItems(widget.items);
  }

  cancelSearch() {
    if (isSearching) {
      isSearching = false;
      widget.appBloc.isSearching = false;
      previousQuery = "";
      searchedItems.clear();
      searchController.text = "";
      audioListView?.setItems(widget.items);
      videoListView?.updateItems(widget.items);
      setState(() {});
    }
  }

  search(String query, bool searchInAll) async {
    if (searchTimer?.isActive == true) searchTimer?.cancel();
    searchTimer = Timer(Duration(milliseconds: _MediaListConstants.searchDebounceMs), () async {
      if (!isAudio) videoListView?.stopAll();
      if (isAudio) audioListView?.stopAll();

      isSearching = true;
      widget.appBloc.isSearching = true;
      String lowerCase = query.toLowerCase();
      sendEvent("search", {"query": lowerCase});
      if (lowerCase.isEmpty) {
        cancelSearch();
        return;
      }
      List<MediaItem> foundItems = [];
      if (widget.items.isEmpty) {
        // if (searchInAll) {
        foundItems.addAll(searchInMediaList(lowerCase, searchSortingType, allItems.toList()));
        // } else {
        //   foundItems.addAll(searchInMediaList(lowerCase, searchSortingType, searchedItems));
        // }
      } else {
        foundItems.addAll(searchInMediaList(lowerCase, searchSortingType, widget.items));
      }
      if (foundItems.isEmpty) {
        searchedItems.clear();
      }
      searchedItems = foundItems;
      if (mounted) {
        audioListView?.setItems(searchedItems);
        videoListView?.updateItems(searchedItems);
      }
      previousQuery = query;
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      initialIndex: 0,
      length: 2,
      vsync: this,
    );
    pageController = PageController(initialPage: 0);
    pageController.addListener(() {
      isAudio = pageController.page == 1;
      widget.tabChanged?.call(pageController.page!.toInt());
      tabController.index = pageController.page!.toInt();
    });
    tabController.addListener(() {
      isAudio = tabController.index == 1;
      widget.tabChanged?.call(tabController.index);
    });
    isAutoPlay = widget.isAutoPlayDefault;

    double topOffest = _calculateTopOffset();
    audioListView = AudioListView(
      widget.appBloc,
      widget.items,
      isAutoPlay: widget.isAutoPlayDefault == true,
      topOffset: topOffest,
    );
    videoListView = VideoListWidget(
      appBloc: widget.appBloc,
      initialItems: widget.items,
      isAutoPlay: widget.isAutoPlayDefault == true,
      topOffset: topOffest,
    );
    //
    if (widget.focusOnSearch) {
      searchFocusNode.requestFocus();
    }
  }

  changeAutoPlay() {
    setState(() {
      isAutoPlay = !isAutoPlay!;
      videoListView?.setAutoPlay(isAutoPlay!);
      audioListView?.setIsAutoPlay(isAutoPlay!);
      saveIsAutoPlay(isAutoPlay!);
    });
  }

  @override
  Widget build(BuildContext context) {
    double topOffest = _calculateTopOffset();
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            color: Colors.transparent,
            child: Stack(
              children: [
                Container(
                  child: hasEmptySearchResults
                      ? Center(
                          child: Text(
                            "Փորձեք այլ կերպ",
                            style: AppTheme.mediaItemSubtitleStyle,
                          ),
                        )
                      : hasEmptyItems
                          ? Center(
                              child: Text(
                                widget.textWhenEmpty,
                                textAlign: TextAlign.center,
                                style: AppTheme.mediaItemSubtitleStyle,
                              ),
                            )
                          : PageView(
                              controller: pageController,
                              scrollBehavior: CupertinoScrollBehavior(),
                              children: [videoListView!, audioListView!],
                            ),
                ),
                Container(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: _MediaListConstants.blurSigma, sigmaY: _MediaListConstants.blurSigma),
                      child: Container(
                        height: topOffest,
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: Image.asset("assets/transparent.png"),
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: kIsWeb ? _MediaListConstants.webStatusBarTopMargin : _MediaListConstants.mobileStatusBarHeight,
                    ),
                    !widget.showActionBar
                        ? Container()
                        : Container(
                            height: _MediaListConstants.actionBarHeight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: _MediaListConstants.horizontalPadding,
                              ),
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceDark,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppTheme.dividerDark),
                                      ),
                                      child: Icon(
                                        Icons.keyboard_arrow_left_rounded,
                                        size: _MediaListConstants.backIconSize,
                                        color: AppTheme.accentCyan,
                                      ),
                                    ),
                                  ),
                                  Center(
                                      child: Text(
                                    widget.actionBarTitle,
                                    style: AppTheme.headingSStyle,
                                  )),
                                ],
                              ),
                            ),
                          ),
                    widget.showSearch
                        ? SearchWidget(widget.searchText, searchController, searchFocusNode, (query) {
                            search(query, query.length < previousQuery.length || previousQuery.isEmpty);
                            setState(() {});
                          }, () {
                            cancelSearch();
                          }, backClick: widget.backClicked)
                        : Container(),
                    shouldShowControlPanel
                        ? Padding(
                            padding: const EdgeInsets.only(
                              top: _MediaListConstants.autoPlayTopPadding,
                              right: _MediaListConstants.autoPlayRightPadding,
                            ),
                            child: Container(
                              height: _MediaListConstants.autoPlayBarHeightActual,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Only show autoplay controls on non-web platforms
                                  if (shouldShowAutoPlayBar) ...[
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 28,
                                          child: Switch(
                                            value: isAutoPlay ?? false,
                                            activeColor: AppTheme.accentCyan,
                                            activeTrackColor: AppTheme.accentCyan.withValues(alpha: 0.3),
                                            inactiveThumbColor: AppTheme.textSecondary2,
                                            inactiveTrackColor: AppTheme.dividerDark,
                                            trackOutlineColor: WidgetStateProperty.all(AppTheme.transparent),
                                            onChanged: (bool value) {
                                              changeAutoPlay();
                                            },
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            changeAutoPlay();
                                          },
                                          child: Text(
                                            "Auto Play",
                                            style: AppTheme.mediaControlLabelStyle,
                                          ),
                                        )
                                      ],
                                    ),
                                    Expanded(child: Container()),
                                  ],
                                  // Show shuffle and sort buttons when either autoplay is available or on web
                                  if (!shouldShowAutoPlayBar) Expanded(child: Container()),
                                  if (_shouldShowShuffleButton()) ...[
                                    _buildShuffleButton(),
                                    if (_shouldShowSortingWidget()) SizedBox(width: 12),
                                  ],
                                  if (_shouldShowSortingWidget()) _buildSortingWidget()
                                ],
                              ),
                            ),
                          )
                        : Container(),
                    Container(
                      height: _MediaListConstants.tabBarHeight,
                      child: Stack(
                        children: [
                          TabBar(
                            controller: tabController,
                            tabs: [
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.videocam_rounded, size: 18),
                                    SizedBox(width: 6),
                                    Text("Վիդեո"),
                                  ],
                                ),
                              ),
                              Tab(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.headphones_rounded, size: 18),
                                    SizedBox(width: 6),
                                    Text("Աուդիո"),
                                  ],
                                ),
                              ),
                            ],
                            labelStyle: AppTheme.mediaTabLabelStyle,
                            labelColor: AppTheme.textPrimary,
                            dividerColor: AppTheme.dividerDark,
                            indicatorSize: TabBarIndicatorSize.tab,
                            unselectedLabelStyle: AppTheme.mediaTabLabelInactiveStyle,
                            unselectedLabelColor: AppTheme.textSecondary2,
                            indicatorColor: AppTheme.accentCyan,
                            indicatorWeight: 3,
                            onTap: (page) {
                              if (page == 1) {
                                videoListView?.stopAll();
                              } else {
                                audioListView?.stopAll();
                              }
                              pageController.animateToPage(page,
                                  duration: Duration(milliseconds: _MediaListConstants.pageAnimationDurationMs), curve: Curves.linear);
                            },
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  bool _shouldShowSortingWidget() {
    // Don't show if disabled by widget parameter
    if (!widget.showSortAndShuffle) return false;
    
    // Always show sorting when searching
    if (isSearching) return true;
    
    // Show sorting for non-searching state when we have sorting types
    // or provide default sorting options
    return widget.groupSortingTypes?.isNotEmpty == true || !isSearching;
  }

  Widget _buildSortingWidget() {
    if (!_shouldShowSortingWidget()) return Container();
    
    // Default sorting types for non-searching state
    List<String> defaultGroupSortingTypes = [SORT_TYPE_ORDER, SORT_TYPE_POPULAR, SORT_TYPE_MIXED];
    
    return InkWell(
      onTap: () {
        List<String> sortingTypes;
        String currentSortType;
        
        if (isSearching) {
          sortingTypes = searchSortingTypes;
          currentSortType = searchSortingType;
        } else {
          sortingTypes = widget.groupSortingTypes?.isNotEmpty == true 
              ? widget.groupSortingTypes! 
              : defaultGroupSortingTypes;
          currentSortType = groupSortingType;
        }
        
        showModal(
            context,
            ChooseSortTypeModal(sortingTypes, currentSortType, (selectedSortType) {
              if (isSearching) {
                this.searchSortingType = selectedSortType;
                reOrderItemsBySortType(searchedItems, searchSortingType);
                audioListView?.setItems(searchedItems);
                videoListView?.updateItems(searchedItems);
              } else {
                this.groupSortingType = selectedSortType;
                reOrderItemsBySortType(widget.items, groupSortingType);
                itemsUpdated();
              }
              setState(() {});
            }));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.dividerDark),
          color: AppTheme.cardDark,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.sort_rounded, size: 16, color: AppTheme.accentCyan),
            const SizedBox(width: 4),
            Text("Դասավորել", style: AppTheme.mediaControlLabelStyle)
          ],
        ),
      ),
    );
  }

  bool _shouldShowShuffleButton() {
    return widget.showSortAndShuffle;
  }

  Widget _buildShuffleButton() {
    if (!_shouldShowShuffleButton()) return Container();
    
    return InkWell(
      onTap: () {
        _shuffleItems();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.dividerDark),
          color: AppTheme.cardDark,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.shuffle_rounded, size: 16, color: AppTheme.accentCyan),
            const SizedBox(width: 4),
            Text("Խառնել", style: AppTheme.mediaControlLabelStyle)
          ],
        ),
      ),
    );
  }

  void _shuffleItems() {
    if (isSearching) {
      searchedItems.shuffle();
      audioListView?.setItems(searchedItems);
      videoListView?.updateItems(searchedItems);
    } else {
      widget.items.shuffle();
      itemsUpdated();
    }
    setState(() {});
  }

  void reOrderItemsBySortType(List<MediaItem> items, String sortingType) {
    switch (sortingType) {
      case SEARCH_SORT_TYPE_ORDER:
        items.sort((a, b) => a.name!.length - b.name!.length);
        break;
      case SEARCH_SORT_TYPE_POPULAR:
      case SORT_TYPE_POPULAR:
        items.sort((a, b) => b.shareCount! - a.shareCount!);
        break;
      case SORT_TYPE_ORDER:
        items.sort((a, b) => a.ordering! - b.ordering!);
        break;
      default:
        items.shuffle();
        break;
    }
  }
}
