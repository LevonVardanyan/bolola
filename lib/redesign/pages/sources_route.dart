import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:url_launcher/url_launcher.dart';

import '../resources/models/sources.dart';


class SourcesRoute extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SourcesRouteState();
}

class _SourcesRouteState extends State<SourcesRoute> {
  String aboutText = "";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: AppTheme.primaryDark,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppTheme.surfaceDark,
            surfaceTintColor: Colors.transparent,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppTheme.dividerDark),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.dividerDark),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.accentCyan,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            title: Text(
              "Աղբյուրներ",
              style: AppTheme.headingSStyle,
            ),
            centerTitle: true,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SourcesWidget(),
            ),
          )),
    );
  }
}

class SourcesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (SourceLinkItem sourceItem in sourceLinks)
          RichText(
            text: new TextSpan(
              children: [
                new TextSpan(
                  text: sourceItem.name, //'Kargin TV',
                  style: const TextStyle(decoration: TextDecoration.underline, color: AppTheme.accentCyan, fontFamily: "avenir-medium", fontSize: 24),
                  recognizer: new TapGestureRecognizer()
                    ..onTap = () async {
                      var url = sourceItem.url ?? ""; //'https://www.youtube.com/user/KarginTV';
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
