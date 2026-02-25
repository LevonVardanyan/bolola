import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/main.dart';
import 'package:politicsstatements/redesign/pages/audio/audios_list_widget.dart';
import 'package:politicsstatements/redesign/pages/media_list_widget.dart';
import 'package:politicsstatements/redesign/pages/upload_preview_page.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/utils/popup_utils.dart';

import '../resources/models/media_group.dart';

class MediaGroupRoute extends StatefulWidget {
  AppBloc appBloc;
  MediaGroup group;

  MediaGroupRoute(this.appBloc, this.group);

  @override
  State<StatefulWidget> createState() {
    return _MediaGroupRouteState();
  }
}

class _MediaGroupRouteState extends State<MediaGroupRoute> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    widget.group.items?.shuffle();
  }

  Future<void> _pickAndPreviewFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4'],
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    if (!mounted) return;
    final uploaded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UploadPreviewPage(
          pickedFiles: result.files,
          groupAlias: widget.group.alias ?? '',
          categoryAlias: widget.group.categoryAlias ?? '',
        ),
      ),
    );
    if (uploaded == true && mounted) {
      widget.appBloc.fetchSources();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Files uploaded successfully!'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (_) => widget.appBloc,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          floatingActionButton: isAdminUser
              ? FloatingActionButton.extended(
                  onPressed: _pickAndPreviewFiles,
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: AppTheme.primaryDark,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Files'),
                )
              : null,
          body: CupertinoPageScaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: AppTheme.primaryDark,
            child: ScrollConfiguration(
              behavior: CustomBehavior(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                      child: StreamBuilder<bool>(
                          stream: widget.appBloc.dataLoadingStream,
                          initialData: false,
                          builder: (context, loadingSnapshot) {
                            return loadingSnapshot.data == true
                                ? Center(
                                    child: CupertinoActivityIndicator(
                                    color: AppTheme.white,
                                  ))
                                : MediaListView(
                                    widget.appBloc,
                                    widget.group.items ?? [],
                                    groupSortingTypes: widget.group.sortingTypes,
                                    showActionBar: true,
                                    isAutoPlayDefault: isAutoPlay,
                                    actionBarTitle: (widget.group.name ?? "") + " (${widget.group.items!.length})",
                                  );
                          }))
                ],
              ),
            ),
          ),
        ));
  }
}
