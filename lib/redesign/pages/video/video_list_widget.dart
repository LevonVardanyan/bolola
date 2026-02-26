import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/pages/sheets/help_us_sheet.dart';
import 'package:politicsstatements/redesign/pages/video/admin_video_list_item_widget.dart';
import 'package:politicsstatements/redesign/pages/video/video_list_item_widget.dart';
import 'package:politicsstatements/redesign/resources/models/media_item.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/utils/constants.dart';
import 'package:politicsstatements/redesign/utils/popup_utils.dart';
import 'package:politicsstatements/redesign/utils/utils.dart';
import 'package:politicsstatements/redesign/widgets/media_widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:swipe_refresh/swipe_refresh.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Enhanced video list widget with improved memory management and cleaner architecture
class VideoListWidget extends StatefulWidget {
  final AppBloc appBloc;
  final List<MediaItem> initialItems;
  final double marginTop;
  final bool isAutoPlay;
  final double topOffset;
  final double scrollableTopOffset;
  final bool showDevTools;

  _VideoListWidgetState state = _VideoListWidgetState();

  VideoListWidget({
    required this.appBloc,
    required this.initialItems,
    this.marginTop = 0.0,
    this.isAutoPlay = false,
    this.topOffset = 0,
    this.scrollableTopOffset = 0,
    this.showDevTools = false,
  });

  /// Update the list of items and refresh UI
  void updateItems(List<MediaItem> newItems) {
    state.updateItems(newItems);
  }

  /// Set autoplay mode
  void setAutoPlay(bool autoPlay) {
    state.setAutoPlay(autoPlay);
  }

  /// Stop all video playback
  Future<void> stopAll() async {
    await state.stopAll();
  }

  @override
  State<VideoListWidget> createState() {
    return this.state = _VideoListWidgetState();
  }
}

class _VideoListWidgetState extends State<VideoListWidget> {
  // Video controller management
  final VideoControllerManager _controllerManager = VideoControllerManager();

  // UI state
  List<MediaItem> _items = [];
  bool _isAutoPlay = false;
  var isMobileBrowser = kIsWeb && screenWidth <= 768;

  // Refresh controller
  final _refreshController = StreamController<SwipeRefreshState>.broadcast();

  // Autoplay management
  Timer? _autoplayDebounce;
  final Map<String, double> _visibilityMap = {};
  
  // Dynamic aspect ratio based on first item
  double? _firstItemAspectRatio;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
    // Disable autoplay on web
    _isAutoPlay = kIsWeb ? false : widget.isAutoPlay;

    // Fetch first item's aspect ratio for dynamic card sizing
    if (kIsWeb) {
      _fetchFirstItemAspectRatio();
    }

    // Add a small delay to ensure proper initialization on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Trigger a rebuild to ensure proper initialization
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controllerManager.dispose();
    _refreshController.close();
    _autoplayDebounce?.cancel();
    super.dispose();
  }

  /// Update the list of items and refresh UI
  void updateItems(List<MediaItem> newItems) {
    if (!mounted) return;

    // Stop current playback
    _controllerManager.stopCurrentPlayback();

    // Clear visibility tracking
    _visibilityMap.clear();

    // Update items
    setState(() {
      _items = List.from(newItems);
      _firstItemAspectRatio = null; // Reset aspect ratio
    });
    
    // Fetch new first item's aspect ratio for dynamic card sizing
    if (kIsWeb) {
      _fetchFirstItemAspectRatio();
    }
  }

  /// Set autoplay mode
  void setAutoPlay(bool autoPlay) {
    if (!mounted) return;
    setState(() {
      // Disable autoplay on web
      _isAutoPlay = kIsWeb ? false : autoPlay;
    });
  }

  /// Stop all video playback
  Future<void> stopAll() async {
    await _controllerManager.stopCurrentPlayback();
  }

  /// Handle visibility changes for autoplay
  void _onVisibilityChanged(String alias, VisibilityInfo visibilityInfo) async {
    // Skip autoplay logic on web
    if (!_isAutoPlay || !mounted || kIsWeb) return;

    final visiblePercentage = visibilityInfo.visibleFraction * 100;
    final itemRect = visibilityInfo.visibleBounds;
    final screenHeight = MediaQuery.of(context).size.height;
    final scrollableTop = widget.scrollableTopOffset;
    final scrollableBottom = screenHeight;

    final isInScrollableArea = itemRect.top < scrollableBottom && itemRect.bottom > scrollableTop && (itemRect.bottom - itemRect.top) > 0;

    if (!isInScrollableArea) {
      _visibilityMap.remove(alias);
      // Only schedule autoplay if this was the currently playing video
      if (_controllerManager.currentAlias == alias) {
        _scheduleAutoplay();
      }
      return;
    }

    final previousPercentage = _visibilityMap[alias] ?? 0;
    _visibilityMap[alias] = visiblePercentage;

    // Only schedule autoplay if visibility changed significantly (more than 10%)
    if ((visiblePercentage - previousPercentage).abs() > 10) {
      _scheduleAutoplay();
    }
  }

  /// Schedule autoplay with debouncing
  void _scheduleAutoplay() {
    // Skip autoplay logic on web
    if (kIsWeb) return;

    _autoplayDebounce?.cancel();
    _autoplayDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;

      // Find the most visible video
      String? bestAlias;
      double bestFraction = 0;

      _visibilityMap.forEach((alias, fraction) {
        if (fraction > bestFraction) {
          bestFraction = fraction;
          bestAlias = alias;
        }
      });

      // Only play if we found a good candidate and it's not already playing
      if (bestAlias != null && bestFraction > 50.0 && _controllerManager.currentAlias != bestAlias) {
        await _controllerManager.playVideo(bestAlias!);
      }
    });
  }

  /// Fetch the first item's aspect ratio for dynamic card sizing
  Future<void> _fetchFirstItemAspectRatio() async {
    if (_items.isEmpty || _items[0].imageUrl == null || _items[0].imageUrl!.isEmpty) {
      return;
    }

    try {
      final image = Image.network(_items[0].imageUrl!);
      final completer = Completer<void>();

      image.image.resolve(const ImageConfiguration()).addListener(
            ImageStreamListener((ImageInfo info, bool _) {
              if (mounted) {
                setState(() {
                  _firstItemAspectRatio = info.image.width / info.image.height;
                });
              }
              completer.complete();
            }, onError: (exception, stackTrace) {
              print('Error loading first item image for aspect ratio: $exception');
              completer.complete();
            }),
          );

      await completer.future;
    } catch (e) {
      print('Error fetching first item aspect ratio: $e');
    }
  }

  /// Get the number of columns based on screen width for web
  int _getWebColumnCount(double screenWidth) {
    if (screenWidth > 1200) {
      return 5;
    } else if (screenWidth > 800) {
      return 3;
    } else {
      return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Check if it's a mobile browser (web platform with mobile screen size)

    return Container(
      color: AppTheme.primaryDark,
      height: screenHeight,
      child: (kIsWeb) ? _buildWebGridView(screenWidth) : _buildMobileListView(),
    );
  }

  /// Build web grid view
  Widget _buildWebGridView(double screenWidth) {
    final columnCount = _getWebColumnCount(screenWidth);

    // Calculate aspect ratio based on content needs
    double calculateAspectRatio() {
      if (isAdminUser) {
        return 0.65; // Static ratio for admin interface (was working well)
      } else {
        // If we have the first item's aspect ratio, calculate dynamic card size
        if (_firstItemAspectRatio != null) {
          // Calculate actual card width based on screen width and columns
          final horizontalPadding = 16.0 * 2; // left + right padding
          final crossAxisSpacing = 12.0 * (columnCount - 1); // spacing between columns
          final availableWidth = screenWidth - horizontalPadding - crossAxisSpacing;
          final cardWidth = availableWidth / columnCount;
          
          // Video aspect ratio (width/height) from thumbnail
          final videoAspectRatio = _firstItemAspectRatio!;
          
          // Calculate video height based on card width
          final videoHeight = cardWidth / videoAspectRatio;
          
          // Fixed pixel heights for seek bar + info section
          // Seek bar: ~40px, Info: ~100px = ~140px total
          final fixedHeightsPixels = 140.0;
          
          // Total card height in pixels (with 25% extra - was 15%)
          // This ensures title and actions are always visible
          final totalCardHeight = videoHeight + (fixedHeightsPixels * 1.25);
          
          // Card aspect ratio = width / height
          return cardWidth / totalCardHeight;
        }
        
        // Fallback to default ratio while aspect ratio is loading
        return 0.70; // Width:Height ratio - taller cards for better title visibility
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: isMobileBrowser ? 0 : 16.0,
        top:  16.0 + widget.topOffset, // Add topOffset to the top padding
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          crossAxisSpacing: 12, // Increased spacing between columns
          mainAxisSpacing: 16, // Increased spacing between rows
          childAspectRatio: calculateAspectRatio(),
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) => _buildVideoItem(index, true),
      ),
    );
  }

  /// Build mobile list view
  Widget _buildMobileListView() {
    return ListView.builder(
      itemCount: _items.length,
      padding: EdgeInsets.zero,
      addAutomaticKeepAlives: false,
      itemBuilder: (context, index) => _buildVideoItem(index, false),
    );
  }

  Widget _buildVideoItem(int index, bool isWeb) {
    if (index >= _items.length) return const SizedBox.shrink();
    isMobileBrowser = kIsWeb && screenWidth <= 768;
    final item = _items[index];
    final alias = item.alias ?? 'unknown_$index';

    return VisibilityDetector(
      key: Key(alias),
      onVisibilityChanged: (info) => _onVisibilityChanged(alias, info),
      child: Padding(
        padding: isWeb
                ? EdgeInsets.zero
                : EdgeInsets.only(
                    bottom: index == _items.length - 1 ? 200 + MediaQuery.of(context).viewInsets.bottom + 120 : 0,
                    top: index == 0 ? widget.topOffset : 0,
                  ),
        child: isAdminUser
            ? AdminVideoItemWidget(
                appBloc: widget.appBloc,
                item: item,
                onPlay: (controller) async => await _controllerManager.setCurrentController(controller),
                onControllerReady: (controller) => _controllerManager.registerController(alias, controller),
                onControllerDispose: () => _controllerManager.unregisterController(alias),
                isWebGrid: isWeb,
                showDevTools: widget.showDevTools,
                onDeleted: () {
                  setState(() {
                    _items.removeWhere((i) => i.alias == item.alias);
                  });
                },
              )
            : VideoItemWidget(
                appBloc: widget.appBloc,
                item: item,
                onPlay: (controller) async => await _controllerManager.setCurrentController(controller),
                onControllerReady: (controller) => _controllerManager.registerController(alias, controller),
                onControllerDispose: () => _controllerManager.unregisterController(alias),
                isWebGrid: isWeb,
              ),
      ),
    );
  }
}

/// Manages video player controllers with proper lifecycle management
class VideoControllerManager {
  final Map<String, VideoPlayerController> _controllers = {};
  VideoPlayerController? _currentController;
  String? _currentAlias;

  /// Get the currently playing video alias
  String? get currentAlias => _currentAlias;

  /// Register a new controller
  void registerController(String alias, VideoPlayerController? controller) {
    if (controller != null && controller.value.isInitialized) {
      _controllers[alias] = controller;
    }
  }

  /// Unregister and dispose a controller
  void unregisterController(String alias) {
    final controller = _controllers.remove(alias);
    if (controller != null) {
      if (_currentController == controller) {
        _currentController = null;
        _currentAlias = null;
      }
      controller.dispose();
    }
  }

  /// Set the current playing controller and pause all others
  Future<void> setCurrentController(VideoPlayerController? controller) async {
    // If controller is null, it means the current video is pausing
    if (controller == null) {
      _currentController = null;
      _currentAlias = null;
      return;
    }

    // Stop all other playing videos first
    await _pauseAllExcept(controller);

    // Find the alias for this controller
    String? alias;
    _controllers.forEach((key, value) {
      if (value == controller) {
        alias = key;
      }
    });

    _currentController = controller;
    _currentAlias = alias;
  }

  /// Pause all controllers except the specified one
  Future<void> _pauseAllExcept(VideoPlayerController? exceptController) async {
    final pauseFutures = <Future>[];

    _controllers.forEach((alias, controller) {
      if (controller != exceptController && controller.value.isPlaying) {
        pauseFutures.add(controller.pause().catchError((e) {
          print('Error pausing video $alias: $e');
        }));
      }
    });

    // Wait for all pause operations to complete
    if (pauseFutures.isNotEmpty) {
      await Future.wait(pauseFutures);
    }
  }

  /// Play a specific video by alias
  Future<void> playVideo(String alias) async {
    // Don't play if it's already the current video and playing
    if (_currentAlias == alias && _currentController != null && _currentController!.value.isPlaying) {
      return;
    }

    final controller = _controllers[alias];
    if (controller == null || !controller.value.isInitialized) {
      print('Controller not ready for $alias');
      return;
    }

    try {
      // This will pause all other videos and set this as current
      await setCurrentController(controller);

      // Start new playback
      await controller.seekTo(Duration.zero);
      await controller.play();
    } catch (e) {
      print('Error playing video $alias: $e');
    }
  }

  /// Stop current playback
  Future<void> stopCurrentPlayback() async {
    if (_currentController != null && _currentController!.value.isPlaying) {
      try {
        await _currentController!.pause();
        _currentController = null;
        _currentAlias = null;
      } catch (e) {
        print('Error stopping playback: $e');
      }
    }
  }

  /// Dispose all controllers
  void dispose() {
    for (final controller in _controllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        print('Error disposing controller: $e');
      }
    }
    _controllers.clear();
    _currentController = null;
    _currentAlias = null;
  }
}
