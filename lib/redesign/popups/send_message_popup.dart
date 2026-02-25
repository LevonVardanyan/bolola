import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/utils/constants.dart';
import 'package:politicsstatements/redesign/utils/popup_utils.dart';
import 'package:politicsstatements/redesign/utils/utils.dart';
import 'package:politicsstatements/redesign/widgets/commong_widgets.dart';

class SendMessagePopup extends StatefulWidget {
  AppBloc appBloc;

  SendMessagePopup(this.appBloc);

  @override
  State<SendMessagePopup> createState() => _SendMessagePopupState();
}

class _SendMessagePopupState extends State<SendMessagePopup> {
  final TextEditingController messageController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController linksController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Add listeners to scroll to focused field when keyboard opens
  }

  @override
  void dispose() {
    messageController.dispose();
    nameController.dispose();
    linksController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (messageController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Խնդրում ենք լրացրեք նամակի բովանդակությունը';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final success = widget.appBloc.sendMessage(
        nameController.text.toLowerCase().trim(),
        linksController.text.trim(),
        messageController.text.trim(),
      );

      if (success) {
        Navigator.of(context).pop(true);
        showPopup(context, "Շնորհակալություն", "Ձեր նամակն ուղարկված է, ձեզ կարող է պատասխան գալ նոթիֆիքեյշնով");
      } else {
        setState(() {
          _errorMessage = 'Պետք է անցնի 30 վարկյան վերջին ուղարկման պահից';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      setState(() {
        _errorMessage = 'Սխալ է տեղի ունեցել նամակ ուղարկելիս';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
    bool required = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _errorMessage.isNotEmpty && required && controller.text.isEmpty
              ? Colors.red.withValues(alpha: 0.5)
              : AppTheme.dividerDark,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: AppTheme.activeTextsStyle.copyWith(fontSize: 14, color: AppTheme.textPrimary),
        onChanged: (value) {
          if (_errorMessage.isNotEmpty) {
            setState(() {
              _errorMessage = '';
            });
          }
        },
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTheme.textFieldHintStyle.copyWith(fontSize: 14, color: AppTheme.textSecondary2),
          prefixIcon: Icon(icon, color: AppTheme.textSecondary2, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: kIsWeb ? 24 : 0,
      ),
      child: SingleChildScrollView(
        child: Container(
          width: kIsWeb ? 400 : double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button (fixed)
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 16, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.dividerDark,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.send_rounded,
                      color: AppTheme.accentCyan,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ուղարկել նամակ',
                        style: AppTheme.popupTitleStyle,
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                      icon: Icon(Icons.close, color: AppTheme.textSecondary2),
                      iconSize: 22,
                      padding: EdgeInsets.all(4),
                    ),
                  ],
                ),
              ),

              // Scrollable content with keyboard-aware behavior
              Padding(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Error message
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Message field (main/required)
                    _buildCompactTextField(
                      controller: messageController,
                      hintText: 'Ձեր նամակը...',
                      icon: Icons.message_rounded,
                      maxLines: 4,
                      required: true,
                    ),

                    SizedBox(height: 16),

                    // Optional fields
                    SizedBox(height: 16),
                    _buildCompactTextField(
                      controller: nameController,
                      hintText: 'Ձեր անունը',
                      icon: Icons.person_outline_rounded,
                    ),

                    SizedBox(height: 12),
                    _buildCompactTextField(
                      controller: linksController,
                      hintText: 'Հղումներ',
                      icon: Icons.link_rounded,
                    ),

                    SizedBox(height: 24),

                    // Send Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.send_rounded,
                                  size: 18,
                                  color: AppTheme.primaryDark,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Ուղարկել',
                                  style: AppTheme.strongStyle.copyWith(color: AppTheme.primaryDark),
                                ),
                              ],
                            ),
                    ),

                    SizedBox(height: 12),

                    // Cancel Button
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pop(false);
                            },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Չեղարկել',
                        style: AppTheme.itemSubTitleStyle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Help text
                    SizedBox(height: 8),
                    Text(
                      'Ձեր նամակը կուղարկվի ադմինիստրատորներին։ Պատասխանը կստանաք ծանուցման միջոցով։',
                      style: AppTheme.itemSubTitleStyle.copyWith(
                        fontSize: 12,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24)
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
