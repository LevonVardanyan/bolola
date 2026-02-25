import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jumping_dot/jumping_dot.dart';
import 'package:politicsstatements/redesign/pages/sheets/help_us_sheet.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';

double getKeyboardBottomInset(BuildContext context, bool includePadding) {
  if (!includePadding) return MediaQuery.of(context).viewInsets.bottom;
  return MediaQuery.of(context).viewInsets.bottom == 0 ? 0 : MediaQuery.of(context).viewInsets.bottom + (KeyboardOverlay.isAdded() ? 46 : 0);
}

class KeyboardOverlay {
  static OverlayEntry? _overlayEntry;

  static isAdded() {
    return _overlayEntry != null && _overlayEntry!.mounted;
  }

  static showOverlay(BuildContext context) {
    if (_overlayEntry != null) {
      return;
    }

    OverlayState overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: (context) {
      return Positioned(bottom: MediaQuery.of(context).viewInsets.bottom, right: 0.0, left: 0.0, child: const InputDoneView());
    });

    overlayState.insert(_overlayEntry!);
  }

  static removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
}

class InputDoneView extends StatelessWidget {
  const InputDoneView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        color: AppTheme.primaryDark,
        height: 46,
        child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: CupertinoButton(
                padding: const EdgeInsets.only(right: 24.0, top: 8.0, bottom: 8.0),
                onPressed: () {
                  SystemChannels.textInput.invokeMethod('TextInput.hide');

                  FocusScope.of(context).unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: const Text("Done",
                    style: TextStyle(
                      color: CupertinoColors.activeBlue,
                    )),
              ),
            )));
  }
}

class ModalCloseBtn extends StatelessWidget {
  Function() click;

  ModalCloseBtn(this.click);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: click,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(60), color: AppTheme.blue100),
          child: Center(
            child: Icon(
              Icons.close_rounded,
              color: AppTheme.blue900,
            ),
          ),
        ));
  }
}

class InputFieldBox extends StatefulWidget {
  TextEditingController controller;
  String boxLabel;
  Function(String)? onChanged;
  double height = 64;
  TextInputAction textInputAction = TextInputAction.done;
  TextInputType keyboardType = TextInputType.text;
  LengthLimitingTextInputFormatter? length = LengthLimitingTextInputFormatter(-1);
  String hintText = "";

  InputFieldBox(
    this.controller,
    this.boxLabel,
    this.onChanged, {
    this.height = 64,
    this.textInputAction = TextInputAction.done,
    this.keyboardType = TextInputType.text,
    this.length,
    this.hintText = "",
  });

  @override
  State<StatefulWidget> createState() {
    return _InputFieldBoxState();
  }
}

class _InputFieldBoxState extends State<InputFieldBox> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      color: AppTheme.textFieldBG,
      child: TextField(
          key: Key(widget.boxLabel),
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          maxLines: 10,
          keyboardAppearance: Brightness.dark,
          textInputAction: widget.textInputAction,
          cursorColor: AppTheme.white,
          onChanged: (value) {
            widget.onChanged?.call(value);
          },
          style: AppTheme.activeTextsStyle,
          decoration: InputDecoration(
            labelText: widget.boxLabel.isNotEmpty ? widget.boxLabel : null,
            labelStyle: AppTheme.textFieldLabelStyle,
            isDense: true,
            focusedBorder: const OutlineInputBorder(
              // width: 0.0 produces a thin "hairline" border
              borderSide: const BorderSide(
                color: AppTheme.white,
              ),
            ),
            enabledBorder: const OutlineInputBorder(
              // width: 0.0 produces a thin "hairline" border
              borderSide: const BorderSide(
                color: AppTheme.textFieldBorder,
              ),
            ),
            hintText: widget.hintText,
            hintStyle: AppTheme.itemSubTitleStyle,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          )),
    );
  }
}

class MainActionButton extends StatelessWidget {
  String text = "";
  String? icon;
  bool inactive = false;
  bool isLoading = false;
  Color? iconColor;
  TextStyle? textStyle;
  TextStyle? inactiveTextStyle;
  Color? bgColor;
  Color? loadingColor;
  Color? inactiveColor;
  Function()? onClick;

  MainActionButton(this.text,
      {this.icon,
      this.iconColor,
      this.textStyle,
      this.inactiveTextStyle,
      this.bgColor,
      this.inactiveColor,
      this.loadingColor,
      this.inactive = false,
      this.isLoading = false,
      this.onClick});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: inactive || isLoading,
      child: InkWell(
        onTap: onClick,
        child: Container(
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(29)),
              color: inactive
                  ? (inactiveColor ?? AppTheme.grey100)
                  : bgColor != null
                      ? bgColor
                      : AppTheme.blue900),
          child: isLoading
              ? JumpingDots(
                  animationDuration: Duration(milliseconds: 300),
                  color: loadingColor != null ? loadingColor! : AppTheme.blue100,
                  radius: 5,
                  verticalOffset: -10,
                  numberOfDots: 3,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: icon != null ? 8.0 : 0),
                      child: Text(
                        text,
                        style: inactive ? (inactiveTextStyle ?? AppTheme.strongAlpha50Style) : (textStyle ?? AppTheme.strongStyleWhite),
                      ),
                    )
                  ],
                ),
        ),
      ),
    );
  }
}

class ModalTitle extends StatelessWidget {
  String? icon;
  String? title;
  bool showCloseButton = true;
  Function()? cancelClick;

  ModalTitle({this.icon, this.title, this.cancelClick, this.showCloseButton = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              title ?? "",
              style: AppTheme.popupTitleStyle,
            ),
          ),
          showCloseButton
              ? ModalCloseBtn(() {
                  cancelClick?.call();
                  Navigator.of(context).pop();
                })
              : Container()
        ],
      ),
    );
  }
}

class OverlayActionButton extends StatelessWidget {
  Function() click;
  Color bgColor;
  String? icon;
  String label;
  TextStyle textStyle;
  double? width;
  bool iconFromRight = false;

  OverlayActionButton(this.click, this.bgColor, this.label, this.textStyle, {this.icon, this.width, this.iconFromRight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: width,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: click,
        child: Padding(
          padding: EdgeInsets.only(left: width == null ? 16.0 : 0, right: width == null ? 16 : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: textStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchWidget extends StatefulWidget {
  Function(String) search;
  Function() stopSearch;
  Function()? backClick;
  FocusNode focusNode;

  TextEditingController searchController;
  String hint;

  SearchWidget(this.hint, this.searchController, this.focusNode, this.search, this.stopSearch, {this.backClick});

  @override
  State<StatefulWidget> createState() {
    return SearchWidgetState();
  }
}

class SearchWidgetState extends State<SearchWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            widget.backClick != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: InkWell(
                      onTap: () {
                        widget.backClick?.call();
                      },
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: AppTheme.white,
                      ),
                    ),
                  )
                : Container(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: AppTheme.actionBarColor, borderRadius: BorderRadius.circular(10)),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: TextField(
                          controller: widget.searchController,
                          textInputAction: TextInputAction.done,
                          keyboardAppearance: Brightness.dark,
                          focusNode: widget.focusNode,
                          maxLines: 1,
                          onChanged: (value) async {
                            if (value.isEmpty) {
                              widget.stopSearch();
                            } else {
                              widget.search(value);
                            }
                          },
                          style: AppTheme.strongStyle,
                          cursorColor: Colors.white,
                          cursorHeight: 16,
                          cursorWidth: 1,
                          decoration: new InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              icon: Icon(
                                Icons.search_rounded,
                                color: widget.searchController.text.isEmpty ? AppTheme.textSecondary2 : AppTheme.textPrimary,
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: -10, vertical: 14),
                              isDense: true,
                              disabledBorder: InputBorder.none,
                              hintStyle: AppTheme.textFieldHintStyle,
                              hintText: widget.hint),
                        ),
                      ),
                      widget.searchController.text.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      widget.stopSearch();
                                    });
                                  },
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: AppTheme.accentCyan,
                                    size: 24,
                                  )),
                            )
                          : Container()
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircleRadioButton extends StatelessWidget {
  bool isChecked = false;

  CircleRadioButton(this.isChecked);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isChecked ? null : Border.all(color: AppTheme.white),
          color: isChecked ? AppTheme.white : Colors.transparent),
      child: isChecked
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: AppTheme.blueGreen),
              ),
            )
          : null,
    );
  }
}
