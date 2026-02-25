import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';

import '../utils/constants.dart';

class AboutRoute extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AboutRouteState();
}

class _AboutRouteState extends State<AboutRoute> {
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
              aboutUsTitle,
              style: AppTheme.headingSStyle,
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 16,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, right: 12),
                    child: Text(
                      aboutUsDescription,
                      style: AppTheme.strongStyle,
                    ),
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
