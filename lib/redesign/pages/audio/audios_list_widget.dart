import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/pages/sheets/help_us_sheet.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/utils/constants.dart';
import 'package:politicsstatements/redesign/utils/popup_utils.dart';
import 'package:politicsstatements/redesign/utils/utils.dart';
import 'package:politicsstatements/redesign/widgets/media_widgets.dart';
import 'package:swipe_refresh/swipe_refresh.dart';

import '../../resources/models/media_item.dart';

class AudioListView extends StatefulWidget {
  List<MediaItem> items;
  AppBloc appBloc;
  double marginTop = 0.0;
  bool isAutoPlay = false;
  bool isLoop = false;
  double topOffset;
  _AudioListViewState state = _AudioListViewState();

  AudioListView(this.appBloc, this.items, {this.marginTop = 0.0, this.isAutoPlay = false, this.isLoop = false, this.topOffset = 0}) {
    // Force autoplay to false on web regardless of parameter
    if (kIsWeb) {
      this.isAutoPlay = false;
    }
  }

  setItems(List<MediaItem> items) {
    this.items = items;
    state.itemsUpdated();
  }

  setIsAutoPlay(bool isAutoPlay) {
    // Force autoplay to false on web regardless of user preference
    this.isAutoPlay = kIsWeb ? false : isAutoPlay;
  }

  setIsLoop(bool isLoop) {
    this.isLoop = isLoop;
  }

  stopAll() {
    state.stopPlaying();
  }

  @override
  State<StatefulWidget> createState() {
    return this.state = _AudioListViewState();
  }
}

class _AudioListViewState extends State<AudioListView> {
  MediaItem? playingItem;
  int? playingItemIndex;
  AudioPlayer player = AudioPlayer();
  bool isPlaying = false;
  bool isDownloading = false;

  final _swipeRefreshController = StreamController<SwipeRefreshState>.broadcast();

  Future<void> _onRefresh() async {
    widget.items.shuffle();
    itemsUpdated();
    _swipeRefreshController.sink.add(SwipeRefreshState.hidden);
  }

  void itemsUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    player.onPlayerComplete.listen((event) async {
      // Disable autoplay on web due to browser policies and better UX
      if (!kIsWeb && widget.isAutoPlay && playingItemIndex != null && playingItemIndex! + 1 < widget.items.length) {
        await playItem(widget.items[playingItemIndex! + 1], playingItemIndex! + 1);
      } else {
        playingItem = null;
        playingItemIndex = null;
        isPlaying = false;
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    player.dispose();
    _swipeRefreshController.close();
    super.dispose();
  }

  Future<void> playItem(MediaItem item, int index) async {
    playingItem = item;
    playingItemIndex = index;

    if (kIsWeb) {
      try {
        await player.play(UrlSource(item.audioUrl!));
        if (mounted) {
          setState(() {
            isPlaying = true;
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error playing audio on web: $e');
        }
        // Reset state on error
        playingItem = null;
        playingItemIndex = null;
        if (mounted) {
          setState(() {
            isPlaying = false;
          });
        }
      }
    } else {
      // On mobile, use file caching as before
      File? audioFile = File(await getAudioFilePath(item.fileName ?? item.alias!, item.groupAlias!));
      if ((await audioFile.exists()) == true) {
        await player.play(DeviceFileSource(audioFile.path));
        if (mounted) {
          setState(() {
            isPlaying = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isDownloading = true;
          });
          downloadFromUrlToPath(audioFile!.path, item.audioUrl!, () async {
            await player.play(DeviceFileSource(audioFile!.path));
            if (mounted) {
              setState(() {
                isDownloading = false;
                isPlaying = true;
              });
            }
          });
        }
      }
    }
    return;
  }

  Future<void> stopPlaying() async {
    if (mounted) {
      await player.stop();
      setState(() {
        isPlaying = false;
        playingItem = null;
        playingItemIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryDark,
      height: screenHeight,
      child: ListView.builder(
          itemCount: widget.items.length,
          padding: EdgeInsets.zero,
          addAutomaticKeepAlives: false,
          itemBuilder: (BuildContext context, int index) {
            List<MediaItem> list = widget.items;
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index == list.length - 1 ? 100 + MediaQuery.of(context).viewInsets.bottom + 120 : 0,
                  top: index == 0 ? widget.topOffset : 0),
              child: AudioItemWidget(
                appBloc: widget.appBloc,
                item: list[index],
                playingItem: playingItem,
                player: player,
                isPlayerPlaying: isPlaying,
                isDownloading: kIsWeb ? false : isDownloading,
                onPlay: (item) async {
                  if (playingItem != null) {
                    await player.stop();
                    isPlaying = false;
                  }
                  if (playingItem?.alias != item.alias) {
                    await playItem(item, index);
                  } else {
                    playingItem = null;
                    playingItemIndex = null;
                    setState(() {});
                  }
                },
              ),
            );
          }),
    );
  }
}

class AudioItemWidget extends StatefulWidget {
  final AppBloc appBloc;
  final MediaItem item;
  final MediaItem? playingItem;
  final AudioPlayer player;
  final Function(MediaItem) onPlay;
  final Function()? onFavoriteClick;
  final bool isPlayerPlaying;
  final bool isDownloading;

  const AudioItemWidget({
    Key? key,
    required this.appBloc,
    required this.item,
    this.playingItem,
    required this.player,
    required this.isPlayerPlaying,
    required this.isDownloading,
    required this.onPlay,
    this.onFavoriteClick,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AudioItemWidgetState();
}

class _AudioItemWidgetState extends State<AudioItemWidget> {
  bool get _isCurrentItem => widget.item.alias == widget.playingItem?.alias;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${duration.inMinutes}:${twoDigits(duration.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.mediaCardPadding,
        vertical: AppTheme.mediaItemSpacing / 2,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _isCurrentItem ? AppTheme.surfaceDark : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(AppTheme.mediaCardRadius),
          border: Border.all(
            color: _isCurrentItem
                ? AppTheme.accentCyan.withValues(alpha: 0.3)
                : AppTheme.dividerDark,
            width: 1,
          ),
        ),
        child: Material(
          color: AppTheme.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.mediaCardRadius),
            onTap: () {
              if (widget.appBloc.isDownloading) return;
              closeKeyboard(context);
              widget.onPlay(widget.item);
            },
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.mediaCardPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMainRow(),
                  if (_isCurrentItem) _buildProgressBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildPlayButton(),
        const SizedBox(width: 12),
        Expanded(child: _buildTextColumn()),
        const SizedBox(width: 8),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildPlayButton() {
    if (!kIsWeb && widget.isDownloading && _isCurrentItem) {
      return Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.accentCyan.withValues(alpha: 0.1),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(color: AppTheme.accentCyan),
        ),
      );
    }
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isCurrentItem
            ? AppTheme.accentCyan.withValues(alpha: 0.15)
            : AppTheme.dividerDark,
      ),
      child: Icon(
        _isCurrentItem ? Icons.stop_rounded : Icons.play_arrow_rounded,
        size: 26,
        color: _isCurrentItem ? AppTheme.accentCyan : AppTheme.textSecondary2,
      ),
    );
  }

  Widget _buildTextColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.item.name ?? "",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.mediaItemTitleStyle,
        ),
        const SizedBox(height: 2),
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
        _buildActionIcon(
          icon: widget.item.isFavorite == true
              ? Icons.favorite_rounded
              : Icons.favorite_outline_rounded,
          color: widget.item.isFavorite == true
              ? AppTheme.accentMagenta
              : AppTheme.textSecondary2,
          onTap: () async {
            closeKeyboard(context);
            await widget.appBloc.toggleFavoriteAudio(widget.item);
            widget.onFavoriteClick?.call();
            setState(() {});
          },
        ),
        if (isAndroid()) _buildDownloadIcon(),
        _buildShareIcon(),
        _buildActionIcon(
          icon: Icons.edit_outlined,
          color: AppTheme.textSecondary2,
          onTap: () {
            closeKeyboard(context);
            showModal(context, HelpUsModal(widget.appBloc, widget.item));
          },
        ),
      ],
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: SizedBox(
        width: AppTheme.mediaActionButtonSize,
        height: AppTheme.mediaActionButtonSize,
        child: Icon(icon, size: AppTheme.mediaIconSize, color: color),
      ),
    );
  }

  Widget _buildDownloadIcon() {
    return StreamBuilder<MediaItem?>(
        stream: widget.appBloc.isAudioDownloadingStream,
        initialData: null,
        builder: (context, snapshot) {
          return snapshot.data?.alias == widget.item.alias
              ? SizedBox(
                  width: AppTheme.mediaActionButtonSize,
                  height: AppTheme.mediaActionButtonSize,
                  child: const Center(
                    child: SizedBox(width: 16, height: 16, child: CupertinoActivityIndicator(color: AppTheme.textSecondary2)),
                  ),
                )
              : _buildActionIcon(
                  icon: Icons.download_rounded,
                  color: AppTheme.textSecondary2,
                  onTap: () {
                    if (!kIsWeb && widget.appBloc.isDownloading) return;
                    closeKeyboard(context);
                    widget.appBloc.saveAudio(widget.item, (success) {
                      if (success) {
                        setState(() {});
                        showToast("Ֆայլը պահպանվեց");
                      } else {
                        showToast("Սխալ է տեղի ունեցել");
                      }
                    });
                  },
                );
        });
  }

  Widget _buildShareIcon() {
    return StreamBuilder<MediaItem?>(
        stream: widget.appBloc.isAudioDownloadingStream,
        initialData: null,
        builder: (context, snapshot) {
          final isDownloading = kIsWeb ? false : (snapshot.data?.alias == widget.item.alias);
          return isDownloading
              ? SizedBox(
                  width: AppTheme.mediaActionButtonSize,
                  height: AppTheme.mediaActionButtonSize,
                  child: const Center(
                    child: SizedBox(width: 16, height: 16, child: CupertinoActivityIndicator(color: AppTheme.textSecondary2)),
                  ),
                )
              : _buildActionIcon(
                  icon: isiOS() ? Icons.ios_share_rounded : Icons.share_rounded,
                  color: AppTheme.textSecondary2,
                  onTap: () {
                    if (!kIsWeb && widget.appBloc.isDownloading) return;
                    closeKeyboard(context);
                    widget.appBloc.shareAudio(widget.item, (success) {
                      if (success) {
                        setState(() {});
                        if (kIsWeb) {
                          showToast("Հղումը կիսվեց");
                        } else {
                          showToast("Ներբեռնվեց");
                        }
                      } else {
                        if (kIsWeb) {
                          showToast("Չհաջողվեց կիսել հղումը");
                        }
                      }
                    });
                  },
                );
        });
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: StreamBuilder<Duration>(
        stream: widget.player.onPositionChanged,
        builder: (context, posSnapshot) {
          return StreamBuilder<Duration>(
            stream: widget.player.onDurationChanged,
            builder: (context, durSnapshot) {
              final position = posSnapshot.data ?? Duration.zero;
              final duration = durSnapshot.data ?? Duration.zero;
              final progress = duration.inMilliseconds > 0
                  ? position.inMilliseconds / duration.inMilliseconds
                  : 0.0;
              return Row(
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
                        onChanged: (value) {
                          if (duration.inMilliseconds > 0) {
                            widget.player.seek(Duration(
                              milliseconds: (value * duration.inMilliseconds).round(),
                            ));
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(_formatDuration(duration), style: AppTheme.mediaItemDurationStyle),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
