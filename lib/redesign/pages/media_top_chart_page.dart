import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:politicsstatements/main.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/pages/media_list_widget.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';

class MediaTopChartPage extends StatefulWidget {
  AppBloc appBloc;
  Function()? backClick;

  MediaTopChartPage(this.appBloc, {this.backClick});

  @override
  State<StatefulWidget> createState() {
    return _MediaTopChartPageState();
  }
}

class _MediaTopChartPageState extends State<MediaTopChartPage> {
  bool isAudio = false;
  MediaListView? mediaListView;

  @override
  void initState() {
    super.initState();

    mediaListView = MediaListView(widget.appBloc, chartList,
        showSearch: true,
        showAd: false,
        searchText: "Որոնում պոպուլյարներում",
        showActionBar: false,
        backClicked: widget.backClick,
        isAutoPlayDefault: isAutoPlay,
        showSortAndShuffle: false, tabChanged: (index) {
      isAudio = index == 1;
      // mediaListView?.setItems(isAudio ? audioTopChart : videoTopChart);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
              child: mediaListView == null
                  ? Center(
                      child: CupertinoActivityIndicator(
                      color: AppTheme.accentCyan,
                    ))
                  : mediaListView!)
        ],
      ),
    );
  }
}
