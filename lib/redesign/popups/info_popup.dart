import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/utils/constants.dart';
import 'package:politicsstatements/redesign/widgets/commong_widgets.dart';

class InfoPopup extends StatelessWidget {
  String? messageText;
  String? titleText;
  String buttonText = "Ok";
  Function()? okClick;

  InfoPopup(InfoPopupEvent event) {
    this.buttonText = event.buttonText ?? "Ok";
    this.messageText = event.messageText;
    this.titleText = event.titleText;
    this.okClick = event.okClick;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: screenWidth * 0.917,
          constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(POPUPS_CORNER),
            border: Border.all(color: AppTheme.dividerDark),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ModalTitle(
                  title: titleText ?? "",
                  showCloseButton: false,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    physics: ClampingScrollPhysics(),
                    child: Text(
                      messageText ?? "",
                      style: AppTheme.bodyStyle,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppTheme.dividerDark,
                ),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    okClick?.call();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Լավ',
                        style: TextStyle(
                          color: AppTheme.accentCyan,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoPopupEvent {
  String? messageText;
  String? titleText;
  String buttonText = "O,";
  Function()? okClick;

  InfoPopupEvent({this.buttonText = "Ok", this.messageText, this.titleText, this.okClick});
}
