import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/utils/constants.dart';
import 'package:politicsstatements/redesign/utils/popup_utils.dart';
import 'package:politicsstatements/redesign/utils/utils.dart';
import 'package:politicsstatements/redesign/widgets/commong_widgets.dart';

import '../../resources/models/media_item.dart';

class HelpUsModal extends StatefulWidget {
  AppBloc appBloc;
  MediaItem item;

  HelpUsModal(this.appBloc, this.item);

  @override
  State<StatefulWidget> createState() {
    return _HelpUsModalState();
  }
}

class _HelpUsModalState extends State<HelpUsModal> {
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _fixController = TextEditingController();

  bool _isLoadingKeyword = false;
  bool _isLoadingFix = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _keywordController.dispose();
    _fixController.dispose();
    super.dispose();
  }

  Future<void> _sendKeywordSuggestion() async {
    if (_keywordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Խնդրում ենք լրացրեք բանալի բառերի դաշտը';
      });
      return;
    }

    setState(() {
      _isLoadingKeyword = true;
      _errorMessage = '';
    });

    try {
      widget.appBloc.sendKeywordSuggestion(widget.item, _keywordController.text.trim());

      setState(() {
        _keywordController.clear();
      });

      showToast("Շնորհակալություն! Ձեր առաջարկը ուղարկված է");
    } catch (e) {
      if (kDebugMode) {
        print('Error sending keyword suggestion: $e');
      }
      setState(() {
        _errorMessage = 'Սխալ է տեղի ունեցել առաջարկը ուղարկելիս';
      });
    } finally {
      setState(() {
        _isLoadingKeyword = false;
      });
    }
  }

  Future<void> _sendFixSuggestion() async {
    if (_fixController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Խնդրում ենք լրացրեք սխալի ուղղման դաշտը';
      });
      return;
    }

    setState(() {
      _isLoadingFix = true;
      _errorMessage = '';
    });

    try {
      widget.appBloc.sendFix(widget.item, _fixController.text.trim());

      // Close modal and show success message
      Navigator.of(context).pop();
      showToast("Շնորհակալություն! Ձեր առաջարկը ուղարկված է");
    } catch (e) {
      if (kDebugMode) {
        print('Error sending fix suggestion: $e');
      }
      setState(() {
        _errorMessage = 'Սխալ է տեղի ունեցել առաջարկը ուղարկելիս';
      });
    } finally {
      setState(() {
        _isLoadingFix = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: AppTheme.primaryDark,
        child: Padding(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24,
            top: 24,
            bottom: getKeyboardBottomInset(context, false) + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                ModalTitle(
                  title: "Օգնել Բոլոլայի բարելավմանը",
                  showCloseButton: true,
                ),

                // Subtitle explaining the purpose
                Text(
                  "Ձեր առաջարկությունները կօգնեն մեզ բարելավել որոնման արդյունքները և ուղղել սխալները:",
                  style: AppTheme.itemSubTitleStyle.copyWith(fontSize: 14),
                ),

                const SizedBox(height: 24),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),

                // Keyword suggestion section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.textSecondary2.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: AppTheme.accentCyan,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Առաջարկել բանալի բառեր",
                            style: AppTheme.itemTitleStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Գրեք բառեր կամ արտահայտություններ, որոնք կարծում եք վերաբերվում են այս վիդեոյին",
                        style: AppTheme.itemSubTitleStyle.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _keywordController,
                        maxLines: 3,
                        style: AppTheme.itemTitleStyle.copyWith(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: "Օրինակ: ոնց ես, ինչ կա, կամ վիդեոյում ասվող տեքստի հետ կապված",
                          hintStyle: AppTheme.itemSubTitleStyle,
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.textSecondary2.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.textSecondary2.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.accentCyan, width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _isLoadingKeyword ? null : _sendKeywordSuggestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentCyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoadingKeyword
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                )
                              : const Text(
                                  'Ուղարկել',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Fix suggestion section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: AppTheme.accentOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Առաջարկել սխալի ուղղում",
                            style: AppTheme.itemTitleStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Եթե նկատել եք սխալներ վերնագրում կամ այլ տեղեկություններում, խնդրում ենք տեղեկացնել մեզ",
                        style: AppTheme.itemSubTitleStyle.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _fixController,
                        maxLines: 2,
                        style: AppTheme.itemTitleStyle.copyWith(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: "Նկարագրեք սխալը կամ առաջարկեք ուղղում...",
                          hintStyle: AppTheme.itemSubTitleStyle,
                          filled: true,
                          fillColor: AppTheme.surfaceDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.accentOrange, width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _isLoadingFix ? null : _sendFixSuggestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoadingFix
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Ուղարկել',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
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
