import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/utils/constants.dart';
import 'package:politicsstatements/redesign/utils/utils.dart';

class RespondToUserPopup extends StatefulWidget {
  final AppBloc appBloc;
  final String fcmToken;
  final String deviceId;

  const RespondToUserPopup({
    Key? key,
    required this.appBloc,
    required this.fcmToken,
    required this.deviceId,
  }) : super(key: key);

  @override
  State<RespondToUserPopup> createState() => _RespondToUserPopupState();
}

class _RespondToUserPopupState extends State<RespondToUserPopup> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  String _errorMessage = '';
  bool _showDeviceInfo = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Խնդրում ենք լրացրեք բոլոր դաշտերը';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = '';
    });

    try {
      final success = await widget.appBloc.sendNotification(
        widget.deviceId,
        _titleController.text.trim(),
        _messageController.text.trim(),
      );

      if (success) {
        showToast("Ծանուցումը հաջողությամբ ուղարկվեց");
        Navigator.of(context).pop();
      } else {
        setState(() {
          _errorMessage = 'Չհաջողվեց ուղարկել ծանուցումը';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Սխալ՝ $e';
      });
    } finally {
      setState(() {
        _isSending = false;
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
        color: AppTheme.textFieldBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _errorMessage.isNotEmpty && required && controller.text.isEmpty
              ? Colors.red.withValues(alpha: 0.5)
              : AppTheme.textFieldBorder,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: AppTheme.activeTextsStyle.copyWith(fontSize: 14),
        onChanged: (value) {
          if (_errorMessage.isNotEmpty) {
            setState(() {
              _errorMessage = '';
            });
          }
        },
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTheme.textFieldHintStyle,
          prefixIcon: Icon(icon, color: AppTheme.textSecondary2, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.textFieldBG,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textFieldBorder),
      ),
      child: Column(
        children: [
          // Toggle header
          InkWell(
            onTap: () {
              setState(() {
                _showDeviceInfo = !_showDeviceInfo;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.accentCyan,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Օգտվողի տեղեկություններ',
                      style: AppTheme.strongStyle2,
                    ),
                  ),
                  Icon(
                    _showDeviceInfo 
                        ? Icons.keyboard_arrow_up_rounded 
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary2,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_showDeviceInfo) ...[
            Divider(color: AppTheme.textFieldBorder, height: 1),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Device ID
                  Row(
                    children: [
                      Icon(Icons.phone_android_rounded, 
                          size: 18, color: AppTheme.textSecondary2),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Սարքի ID',
                              style: AppTheme.smallStrongStyle,
                            ),
                            SizedBox(height: 2),
                            Text(
                              widget.deviceId,
                              style: AppTheme.smallStyle2.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy_rounded, size: 16, color: AppTheme.textSecondary2),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.deviceId));
                          showToast('Սարքի ID-ն պատճենվել է');
                        },
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // FCM Token
                  Row(
                    children: [
                      Icon(Icons.notifications_rounded, 
                          size: 18, color: AppTheme.textSecondary2),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FCM Տոկեն',
                              style: AppTheme.smallStrongStyle,
                            ),
                            SizedBox(height: 2),
                            Text(
                              '${widget.fcmToken.substring(0, 24)}...',
                              style: AppTheme.smallStyle2.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy_rounded, size: 16, color: AppTheme.textSecondary2),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.fcmToken));
                          showToast('FCM տոկենը պատճենվել է');
                        },
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
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
      child: Container(
        width: kIsWeb ? 400 : double.infinity,
        height: screenHeight * 0.7,
        constraints: BoxConstraints(
          maxWidth: 400,
        ),
        child: Column(
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
                    Icons.reply_rounded,
                    color: AppTheme.accentCyan,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Պատասխանել օգտվողին',
                      style: AppTheme.popupTitleStyle,
                    ),
                  ),
                  IconButton(
                    onPressed: _isSending ? null : () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppTheme.textSecondary2),
                    iconSize: 22,
                    padding: EdgeInsets.all(4),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                style: AppTheme.smallStyle.copyWith(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Title field
                    _buildCompactTextField(
                      controller: _titleController,
                      hintText: 'Ծանուցման վերնագիր...',
                      icon: Icons.title_rounded,
                      required: true,
                    ),

                    SizedBox(height: 16),

                    // Message field
                    _buildCompactTextField(
                      controller: _messageController,
                      hintText: 'Ծանուցման հաղորդագրություն...',
                      icon: Icons.message_rounded,
                      maxLines: 4,
                      required: true,
                    ),

                    SizedBox(height: 16),

                    // Device info (collapsible)
                    _buildDeviceInfoCard(),

                    SizedBox(height: 24),

                    // Send Button
                    ElevatedButton(
                      onPressed: _isSending ? null : _sendNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: AppTheme.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSending
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Ուղարկել ծանուցում',
                                  style: AppTheme.strongStyleWhite,
                                ),
                              ],
                            ),
                    ),

                    SizedBox(height: 12),

                    // Cancel Button
                    TextButton(
                      onPressed: _isSending ? null : () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Չեղարկել',
                        style: AppTheme.strongStyle2.copyWith(
                          color: AppTheme.textSecondary2,
                        ),
                      ),
                    ),

                    // Help text
                    SizedBox(height: 8),
                    Text(
                      'Ծանուցումը կուղարկվի ուղղակի օգտվողի սարքին push notification-ի միջոցով։',
                      style: AppTheme.itemInfoMessageStyle.copyWith(
                        fontSize: 12,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
