import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/utils/constants.dart';
import 'package:politicsstatements/redesign/widgets/commong_widgets.dart';

class ChooseSortTypeModal extends StatefulWidget {
  List<String> sortTypes;
  String selectedSort;
  Function(String) onSelect;

  ChooseSortTypeModal(this.sortTypes, this.selectedSort, this.onSelect);

  @override
  State<StatefulWidget> createState() {
    return _ChooseSortTypeModalState();
  }
}

class _ChooseSortTypeModalState extends State<ChooseSortTypeModal> {
  String selectedSortType = "0";

  _ChooseSortTypeModalState();

  @override
  void initState() {
    super.initState();
    selectedSortType = widget.selectedSort;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: AppTheme.cardDark,
        child: Padding(
          padding: EdgeInsets.only(left: 24.0, right: 24, top: 24, bottom: getKeyboardBottomInset(context, false)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalTitle(
                title: "Դասավորվածություն",
                showCloseButton: true,
              ),
              for (var i = 0; i < widget.sortTypes.length; i++)
                InkWell(
                  onTap: () {
                    setState(() {
                      Navigator.of(context).pop();
                      widget.onSelect(widget.sortTypes[i]);
                    });
                  },
                  child: Container(
                    height: 54,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                        ),
                        CircleRadioButton(selectedSortType == widget.sortTypes[i]),
                        SizedBox(
                          width: 16,
                        ),
                        Text(
                          getSortTypeName(widget.sortTypes[i]),
                          style: selectedSortType == widget.sortTypes[i] ? AppTheme.strongStyleWhite : AppTheme.strongStyleWhiteAlpha50,
                        ),
                        SizedBox(
                          width: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(
                height: 48,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
