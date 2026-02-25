import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/pages/video/base_video_widget.dart';
import 'package:politicsstatements/redesign/resources/models/media_item.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/utils/utils.dart';
import 'package:video_player/video_player.dart';

import '../../resources/prefs.dart';

/// Enhanced video item widget with better error handling and lifecycle management
class VideoItemWidget extends BaseVideoWidget {
  const VideoItemWidget({
    Key? key,
    required AppBloc appBloc,
    required MediaItem item,
    required Future<void> Function(VideoPlayerController?) onPlay,
    required Function(VideoPlayerController?) onControllerReady,
    required VoidCallback onControllerDispose,
    bool isWebGrid = false,
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
  State<VideoItemWidget> createState() => _VideoItemWidgetState();
}

class _VideoItemWidgetState extends BaseVideoWidgetState<VideoItemWidget> {
  bool get _isNewGroup {
    final group = findGroupByAlias(
      widget.item.groupAlias ?? '',
      widget.item.categoryAlias ?? '',
    );
    return (group?.isNewGroup ?? 0) == 1;
  }

  @override
  Future<void> onPlayTap() async {
    closeKeyboard(context);
    await super.onPlayTap();
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
            flex: 7,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.mediaCardRadius - 1),
                    topRight: Radius.circular(AppTheme.mediaCardRadius - 1),
                  ),
                  child: buildVideoPlayer(),
                ),
                if (_isNewGroup)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildNewBadge(),
                  ),
              ],
            ),
          ),
          buildSeekBar(),
          Expanded(
            flex: 3,
            child: _buildWebVideoInfo(),
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.mediaCardRadius - 1),
                    topRight: Radius.circular(AppTheme.mediaCardRadius - 1),
                  ),
                  child: buildVideoPlayer(),
                ),
                if (_isNewGroup)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildNewBadge(),
                  ),
              ],
            ),
            buildSeekBar(),
            _buildVideoInfo(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildWebVideoInfo() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              widget.item.name ?? "",
              style: AppTheme.mediaItemTitleStyle.copyWith(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "${widget.item.shareCount} shares",
                  style: AppTheme.mediaItemSubtitleStyle.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildFavoriteButton(),
                  if (kIsWeb) const SizedBox(width: 8), // Add spacing between buttons on web
                  buildShareButton(),
                  if (kIsWeb) const SizedBox(width: 8), // Add spacing between buttons on web
                  buildHelpUsButton(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo() {
    return StreamBuilder<bool>(
      stream: updateStream,
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTitleSection()),
                  _buildActionButtons(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.item.name ?? "",
          style: AppTheme.mediaItemTitleStyle,
        ),
        Text(
          "Կիսվել են ${widget.item.shareCount} անգամ",
          style: AppTheme.mediaItemSubtitleStyle,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildFavoriteButton(),
        SizedBox(
          width: 8,
        ),
        if (isAndroid()) buildDownloadButton(),
        if (isAndroid())
          SizedBox(
            width: 4,
          ),
        buildShareButton(),
        SizedBox(
          width: 8,
        ),
        buildHelpUsButton(),
      ],
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        children: [
          const Icon(
            Icons.fiber_new,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 4),
          const Text(
            'NEW',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
