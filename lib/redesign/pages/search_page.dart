import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/main.dart';
import 'package:politicsstatements/redesign/pages/media_list_widget.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';

import '../resources/models/media_item.dart';

class SearchPage extends StatefulWidget {
  AppBloc appBloc;
  Function()? backClick;

  SearchPage(this.appBloc, {this.backClick});

  @override
  State<StatefulWidget> createState() {
    return _SearchPageState();
  }
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  List<MediaItem> allItems = [];

  @override
  void initState() {
    super.initState();
    allItems = medias?.getAllItems() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
              child: MediaListView(
            widget.appBloc,
            [],
            searchText: "Բոլորում, հայատառ և լատինատառ",
            textWhenEmpty: "Դուք կարող եք կատարել որոնում հայատառ և լատինատառ, որոնումը ավելի կլավանա ժամանակի ընթացքում",
            focusOnSearch: true,
            isAutoPlayDefault: isAutoPlay,
            backClicked: widget.backClick,
          ))
        ],
      ),
    );
  }
}
