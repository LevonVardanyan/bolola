import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/main.dart';
import 'package:politicsstatements/redesign/pages/video/video_list_widget.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';

import '../resources/models/media_item.dart';

class ModerationRoute extends StatefulWidget {
  AppBloc appBloc;
  String mediaType;

  ModerationRoute(this.appBloc, this.mediaType);

  @override
  State<StatefulWidget> createState() {
    return _ModerationRouteState();
  }
}

class _ModerationRouteState extends State<ModerationRoute> {
  @override
  void initState() {
    super.initState();
    // Fetch suggestions when moderation page loads
    widget.appBloc.fetchSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    List<MediaItem> moderatingItems = findModeratingItems("video");
    
    return BlocProvider(
        create: (_) => widget.appBloc,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppTheme.primaryDark,
          body: CupertinoPageScaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: AppTheme.primaryDark,
            child: ScrollConfiguration(
              behavior: CustomBehavior(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 16.0, right: 16, top: 48, bottom: 12),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceDark,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.dividerDark),
                      ),
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
                              color: AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.dividerDark),
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_left_rounded,
                              size: 28,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                "Moderation",
                                style: AppTheme.headingSStyle,
                              ),
                              Text(
                                "${moderatingItems.length} videos with suggestions",
                                style: AppTheme.mediaItemSubtitleStyle.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: moderatingItems.isEmpty 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 64,
                                color: AppTheme.accentOrange,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No suggestions yet",
                                style: AppTheme.mediaItemTitleStyle.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Videos with user suggestions will appear here",
                                style: AppTheme.mediaItemSubtitleStyle,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : VideoListWidget(
                          appBloc: widget.appBloc, 
                          initialItems: moderatingItems, 
                          showDevTools: true
                        ),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
