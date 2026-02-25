import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/main.dart';
import 'package:politicsstatements/redesign/pages/media_list_widget.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';

class MediaFavoritesPage extends StatefulWidget {
  AppBloc appBloc;
  Function()? backClick;

  MediaFavoritesPage(this.appBloc, {this.backClick});

  @override
  State<StatefulWidget> createState() {
    return _MediaFavoritesPageState();
  }
}

class _MediaFavoritesPageState extends State<MediaFavoritesPage> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: MediaListView(
              widget.appBloc,
              favorites,
              searchText: "Որոնում հավանածներում",
              textWhenEmpty: "Հավանածներ չկան, սեղմեք սրտիկներին ավելացնելու համար",
              isAutoPlayDefault: isAutoPlay,
              backClicked: widget.backClick,
              showAd: false,
              showSortAndShuffle: false,
            ),
          )
        ],
      ),
    );
  }
}
