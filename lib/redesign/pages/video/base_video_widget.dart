import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/pages/sheets/help_us_sheet.dart';
import 'package:politicsstatements/redesign/resources/models/media_item.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/utils/popup_utils.dart';
import 'package:politicsstatements/redesign/utils/utils.dart';
import 'package:rxdart/rxdart.dart';
import 'package:video_player/video_player.dart';

import '../../resources/prefs.dart';

/// Base class for video widgets with common functionality
abstract class BaseVideoWidget extends StatefulWidget {
  final AppBloc appBloc;
  final MediaItem item;
  final Future<void> Function(VideoPlayerController?) onPlay;
  final Function(VideoPlayerController?) onControllerReady;
  final VoidCallback onControllerDispose;
  final bool isWebGrid;

  const BaseVideoWidget({
    Key? key,
    required this.appBloc,
    required this.item,
    required this.onPlay,
    required this.onControllerReady,
    required this.onControllerDispose,
    this.isWebGrid = false,
  }) : super(key: key);
}

abstract class BaseVideoWidgetState<T extends BaseVideoWidget> extends State<T> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitializing = false;
  bool _hasError = false;
  bool _isPlayerInitialized = false;
  String? _errorMessage;
  int _retryCount = 0;
  static const int _maxRetries = 2;
  double? _imageAspectRatio;

  // Stream for UI updates
  final _updateStream = BehaviorSubject<bool>();

  @override
  void initState() {
    super.initState();
    // Initialize player immediately for mobile for better UX
    // For web, player will be initialized only when user clicks to play
    if (!kIsWeb) {
      _initializePlayer();
    }
    // Fetch image aspect ratio for web
    if (kIsWeb) {
      _fetchImageAspectRatio();
    }
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.videoUrl != widget.item.videoUrl || oldWidget.item.imageUrl != widget.item.imageUrl) {
      _disposeController();
      _isPlayerInitialized = false;
      _isInitializing = false;
      // Re-fetch image aspect ratio if image URL changed
      if (kIsWeb && oldWidget.item.imageUrl != widget.item.imageUrl) {
        _imageAspectRatio = null;
        _fetchImageAspectRatio();
      }
    }
  }

  @override
  void dispose() {
    _updateStream.close();
    _disposeController();
    super.dispose();
  }

  /// Initialize video player (called only when needed)
  Future<void> _initializePlayer() async {
    if (_isPlayerInitialized || _isInitializing) return;

    setState(() {
      _isInitializing = true;
    });

    final videoUrl = widget.item.videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Video URL is empty';
        _isInitializing = false;
      });
      return;
    }

    try {
      // Create controller with platform-specific headers
      if (kIsWeb) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
          httpHeaders: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
          },
        );
      } else {
        // For mobile, use specific headers to handle range requests properly
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
          httpHeaders: {
            'User-Agent': 'Flutter VideoPlayer',
            'Accept': '*/*',
            'Accept-Encoding': 'identity',
            'Connection': 'keep-alive',
          },
        );
      }

      await _controller!.initialize();

      if (!mounted) return;

      _controller!.setLooping(false);
      _controller!.addListener(_onPlayerStateChanged);

      widget.onControllerReady(_controller);

      setState(() {
        _isInitializing = false;
        _hasError = false;
        _isPlayerInitialized = true;
      });
    } catch (e) {
      print('Error initializing video player for ${widget.item.alias}: $e');

      // Special handling for iOS range request errors
      if (!kIsWeb && e.toString().contains('byte range') && _retryCount == 0) {
        _retryCount++;
        print('Retrying with simplified headers due to range request error...');

        try {
          // Retry with minimal headers for iOS range request issues
          _controller = VideoPlayerController.networkUrl(
            Uri.parse(videoUrl),
            httpHeaders: {
              'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
            },
          );

          await _controller!.initialize();

          if (!mounted) return;

          _controller!.setLooping(false);
          _controller!.addListener(_onPlayerStateChanged);
          widget.onControllerReady(_controller);

          setState(() {
            _isInitializing = false;
            _hasError = false;
            _isPlayerInitialized = true;
          });
          return;
        } catch (retryError) {
          print('Retry also failed: $retryError');
        }
      }

      // Standard retry logic for other errors
      if (_retryCount < _maxRetries && mounted) {
        _retryCount++;
        print('Retrying video initialization (attempt $_retryCount)...');

        // Wait a bit before retrying
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          _initializePlayer();
          return;
        }
      }

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video: ${e.toString().contains('byte range') ? 'Server configuration issue' : 'Network error'}';
          _isInitializing = false;
        });
      }
    }
  }

  /// Handle player state changes
  void _onPlayerStateChanged() {
    if (!mounted || _controller == null) return;

    final isPlaying = _controller!.value.isPlaying;
    if (_isPlaying != isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
      });
      _updateStream.add(isPlaying);
    }
  }

  /// Dispose controller safely
  void _disposeController() {
    if (_controller != null) {
      final controller = _controller!;
      _controller = null;
      controller.removeListener(_onPlayerStateChanged);
      widget.onControllerDispose();
      controller.dispose();
    }
  }

  /// Fetch image aspect ratio from URL
  Future<void> _fetchImageAspectRatio() async {
    if (widget.item.imageUrl == null || widget.item.imageUrl!.isEmpty) return;

    try {
      final image = Image.network(widget.item.imageUrl!);
      final completer = Completer<void>();

      image.image.resolve(const ImageConfiguration()).addListener(
            ImageStreamListener((ImageInfo info, bool _) {
              if (mounted) {
                setState(() {
                  _imageAspectRatio = info.image.width / info.image.height;
                });
              }
              completer.complete();
            }, onError: (exception, stackTrace) {
              print('Error loading image for aspect ratio: $exception');
              completer.complete();
            }),
          );

      await completer.future;
    } catch (e) {
      print('Error fetching image aspect ratio: $e');
    }
  }

  /// Handle play/pause button tap
  Future<void> onPlayTap() async {
    // Initialize player if not already initialized
    if (!_isPlayerInitialized && !_isInitializing) {
      await _initializePlayer();
    }

    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      if (_isPlaying) {
        await _controller!.pause();
        await widget.onPlay(null);
      } else {
        await widget.onPlay(_controller);
        await _controller!.seekTo(Duration.zero);
        await _controller!.play();
      }
    } catch (e) {
      print('Error toggling playback: $e');
    }
  }

  /// Build the video player area
  Widget buildVideoPlayer() {
    return GestureDetector(
      onTap: onPlayTap,
      behavior: HitTestBehavior.opaque,
      child: _hasError
          ? buildErrorWidget()
          : _controller != null && _controller!.value.isInitialized
              ? buildVideoWidget()
              : buildPlaceholderWidget(),
    );
  }

  /// Build video widget with player
  Widget buildVideoWidget() {
    // For web, use image aspect ratio if available, otherwise use video's aspect ratio
    // For mobile, always use video's aspect ratio
    double aspectRatio;
    if (kIsWeb && _imageAspectRatio != null) {
      aspectRatio = _imageAspectRatio!;
    } else {
      aspectRatio = _controller!.value.aspectRatio == 0 ? 16 / 9 : _controller!.value.aspectRatio;
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        children: [
          VideoPlayer(_controller!),
          buildPlayPauseOverlay(),
        ],
      ),
    );
  }

  /// Build play/pause overlay
  Widget buildPlayPauseOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.transparent,
        child: StreamBuilder<bool>(
          stream: _updateStream.stream,
          builder: (context, snapshot) {
            return Stack(
              children: [
                // Play/Pause icon
                Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isPlaying ? 0.0 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: AppTheme.primaryDark.withValues(alpha: 0.6),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: AppTheme.accentCyan,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build error widget
  Widget buildErrorWidget() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: AppTheme.primaryDark,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppTheme.textSecondary2,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'Video error',
                  style: AppTheme.mediaItemSubtitleStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build placeholder widget
  Widget buildPlaceholderWidget() {
    // For web, use thumbnails if available
    if (kIsWeb && widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty) {
      // If aspect ratio is not computed yet, show loading placeholder
      if (_imageAspectRatio == null) {
        return AspectRatio(
          aspectRatio: 16 / 9, // Default aspect ratio while loading
          child: Stack(
            children: [
              Container(
                color: AppTheme.primaryDark,
              ),
              Center(
                child: const CupertinoActivityIndicator(
                  color: AppTheme.accentCyan,
                  radius: 16,
                ),
              ),
            ],
          ),
        );
      }

      return Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _imageAspectRatio!,
              child: Image.network(
                widget.item.imageUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return AspectRatio(
                    aspectRatio: _imageAspectRatio!,
                    child: Container(
                      color: AppTheme.primaryDark,
                      child: const Center(
                        child: CupertinoActivityIndicator(
                          color: AppTheme.white,
                          radius: 16,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return AspectRatio(
                    aspectRatio: _imageAspectRatio!,
                    child: Container(
                      color: AppTheme.primaryDark,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: AppTheme.textSecondary2,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Play button or loading spinner overlay
          Center(
            child: _isInitializing
                ? const CupertinoActivityIndicator(
                    color: AppTheme.accentCyan,
                    radius: 16,
                  )
                : Icon(
                    Icons.play_arrow_rounded,
                    color: AppTheme.accentCyan,
                    size: 40,
                  ),
          ),
        ],
      );
    } else {
      // For mobile or when no image URL, show default placeholder
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            Container(
              color: AppTheme.primaryDark,
            ),
            Center(
              child: _isInitializing
                  ? const CupertinoActivityIndicator(
                      color: AppTheme.white,
                      radius: 16,
                    )
                  : Icon(
                      Icons.play_arrow_rounded,
                      color: AppTheme.accentCyan,
                      size: 40,
                    ),
            ),
          ],
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${duration.inMinutes}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  bool _isValidDuration(Duration duration) {
    return duration.inMilliseconds > 0 && duration.inHours < 24;
  }

  Widget _buildSeekBarContent({
    required Duration position,
    required Duration duration,
    ValueChanged<double>? onChanged,
  }) {
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(_formatDuration(position), style: AppTheme.mediaItemDurationStyle),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.accentCyan,
                inactiveTrackColor: AppTheme.dividerDark,
                thumbColor: AppTheme.accentCyan,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                trackHeight: 3,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                overlayColor: AppTheme.accentCyan.withValues(alpha: 0.1),
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(_formatDuration(duration), style: AppTheme.mediaItemDurationStyle),
        ],
      ),
    );
  }

  Widget _buildSeekBarPlaceholder() {
    return Visibility(
      visible: false,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: _buildSeekBarContent(
        position: Duration.zero,
        duration: Duration.zero,
        onChanged: null,
      ),
    );
  }

  Widget buildSeekBar() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return _buildSeekBarPlaceholder();
    }
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller!,
      builder: (context, value, child) {
        if (!value.isPlaying && value.position == Duration.zero) {
          return _buildSeekBarPlaceholder();
        }
        final duration = value.duration;
        return _buildSeekBarContent(
          position: value.position,
          duration: duration,
          onChanged: _isValidDuration(duration)
              ? (val) {
                  _controller!.seekTo(Duration(
                    milliseconds: (val * duration.inMilliseconds).round(),
                  ));
                }
              : null,
        );
      },
    );
  }

  // Getters for protected access
  bool get isPlaying => _isPlaying;

  bool get isInitializing => _isInitializing;

  bool get hasError => _hasError;

  bool get isPlayerInitialized => _isPlayerInitialized;

  VideoPlayerController? get controller => _controller;

  Stream<bool> get updateStream => _updateStream.stream;

  // Common button implementations - reused by both admin and regular video widgets
  Widget buildFavoriteButton() {
    return InkWell(
      onTap: () async {
        closeKeyboard(context);
        await widget.appBloc.toggleFavoriteVideo(widget.item);
        // Trigger UI update immediately after favorite status changes
        setState(() {});
      },
      child: SizedBox(
        width: AppTheme.mediaActionButtonSize,
        height: AppTheme.mediaActionButtonSize,
        child: Icon(
          widget.item.isFavorite == true ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          size: AppTheme.mediaIconSize,
          color: widget.item.isFavorite == true ? AppTheme.accentMagenta : AppTheme.textSecondary2,
        ),
      ),
    );
  }

  Widget buildDownloadButton() {
    // Only show download button on Android
    if (!isAndroid()) {
      return SizedBox(width: AppTheme.mediaActionButtonSize, height: AppTheme.mediaActionButtonSize);
    }

    return StreamBuilder<MediaItem?>(
      stream: widget.appBloc.isVideoDownloadingStream,
      builder: (context, snapshot) {
        final isDownloading = snapshot.data?.alias == widget.item.alias;
        return isDownloading
            ? const SizedBox(
                width: AppTheme.mediaActionButtonSize,
                height: AppTheme.mediaActionButtonSize,
                child: CupertinoActivityIndicator(color: AppTheme.textSecondary2),
              )
            : InkWell(
                onTap: () => downloadVideo(),
                child: const SizedBox(
                  width: AppTheme.mediaActionButtonSize,
                  height: AppTheme.mediaActionButtonSize,
                  child: Icon(Icons.download_rounded, size: AppTheme.mediaIconSize, color: AppTheme.textSecondary2),
                ),
              );
      },
    );
  }

  Widget buildShareButton() {
    return StreamBuilder<MediaItem?>(
      stream: widget.appBloc.isVideoDownloadingStream,
      builder: (context, snapshot) {
        final isDownloading = kIsWeb ? false : (snapshot.data?.alias == widget.item.alias);
        return isDownloading
            ? SizedBox(
                width: AppTheme.mediaActionButtonSize,
                height: AppTheme.mediaActionButtonSize,
                child: const CupertinoActivityIndicator(color: AppTheme.textSecondary2),
              )
            : InkWell(
                onTap: () => shareVideo(),
                child: SizedBox(
                  width: AppTheme.mediaActionButtonSize,
                  height: AppTheme.mediaActionButtonSize,
                  child: Icon(
                    isiOS() ? Icons.ios_share_rounded : Icons.share_rounded,
                    size: AppTheme.mediaIconSize,
                    color: AppTheme.textSecondary2,
                  ),
                ),
              );
      },
    );
  }

  Widget buildHelpUsButton() {
    return InkWell(
      onTap: () => showHelpUsModal(),
      child: const SizedBox(
        width: AppTheme.mediaActionButtonSize,
        height: AppTheme.mediaActionButtonSize,
        child: Icon(
          Icons.edit_outlined,
          size: AppTheme.mediaIconSize,
          color: AppTheme.textSecondary2,
        ),
      ),
    );
  }

  Future<void> downloadVideo() async {
    closeKeyboard(context);

    // Video download is only supported on Android
    if (!isAndroid()) {
      showToast("Ներբեռնումը հասանելի է միայն Android-ի համար");
      return;
    }

    if (widget.appBloc.isDownloading) return;

    widget.appBloc.saveVideo(widget.item, (success) {
      if (success) {
        showToast("Ֆայլը պահպանվեց");
      } else {
        showToast("Սխալ է տեղի ունեցել");
      }
    });
  }

  void shareVideo() {
    if (!kIsWeb && widget.appBloc.isDownloading) return;

    closeKeyboard(context);
    widget.appBloc.shareVideo(widget.item, (success) {
      if (success) {
        if (kIsWeb) {
          // Show success feedback for web since sharing URL is instant
          showToast("Հղումը կիսվեց");
        }
      } else {
        if (kIsWeb) {
          showToast("Չհաջողվեց կիսել հղումը");
        }
      }
    });
  }

  void showHelpUsModal() {
    closeKeyboard(context);
    showModal(context, HelpUsModal(widget.appBloc, widget.item));
  }
}
