import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/popups/info_popup.dart';
import 'package:politicsstatements/redesign/popups/send_message_popup.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/widgets/commong_widgets.dart';


showPopup(BuildContext context, String title, String message) {
  showCupertinoDialog(
      context: context,
      builder: (context) {
        return InfoPopup(InfoPopupEvent(
          titleText: title,
          messageText: message,
        ));
      });
}

Future<bool?> showSendMessagePopup(BuildContext context, AppBloc appBloc) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return SendMessagePopup(appBloc);
    },
  );
}

Future showModal(BuildContext context, Widget modal) {
  if (platform == TargetPlatform.iOS) {
    return showCupertinoModalBottomSheet(
        context: context,
        builder: (context) => modal,
        barrierColor: Colors.black45,
        enableDrag: true,
        isDismissible: true,
        topRadius: Radius.circular(32));
  } else {
    return showMaterialModalBottomSheet(
      context: context,
      builder: (context) => modal,
      barrierColor: Colors.black45,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      enableDrag: true,
      isDismissible: true,
    );
  }
}
