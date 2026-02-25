import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/resources/models/userMessage.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/utils/popup_utils.dart';
import 'package:politicsstatements/redesign/utils/utils.dart';
import 'package:politicsstatements/redesign/popups/respond_to_user_popup.dart';
import 'package:url_launcher/url_launcher.dart';

class UserMessagesPage extends StatefulWidget {
  final AppBloc appBloc;

  const UserMessagesPage({Key? key, required this.appBloc}) : super(key: key);

  @override
  State<UserMessagesPage> createState() => _UserMessagesPageState();
}

class _UserMessagesPageState extends State<UserMessagesPage> {
  List<UserMessage> messages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      isLoading = true;
    });
    try {
      final fetchedMessages = await widget.appBloc.getUserMessages();
      
      // Sort messages by sendingDate: latest first, null dates at the end
      fetchedMessages.sort((a, b) {
        // If both have dates, compare them (latest first)
        if (a.sendingDate != null && b.sendingDate != null) {
          return b.sendingDate!.compareTo(a.sendingDate!);
        }
        // If only a has date, a comes first
        if (a.sendingDate != null && b.sendingDate == null) {
          return -1;
        }
        // If only b has date, b comes first
        if (a.sendingDate == null && b.sendingDate != null) {
          return 1;
        }
        // If neither has date, maintain original order
        return 0;
      });
      
      setState(() {
        messages = fetchedMessages;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showToast("Հաղորդագրությունները բեռնելիս սխալ՝ $e");
    }
  }

  Future<void> _removeMessage(String deviceId, int messageIndex) async {
    try {
      await widget.appBloc.removeUserMessage(deviceId, messageIndex);
      await _loadMessages(); // Reload messages after removal
      showToast("Հաղորդագրությունը հաջողությամբ ջնջվեց");
    } catch (e) {
      showToast("Հաղորդագրությունը ջնջելիս սխալ՝ $e");
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    showToast("$label պատճենվեց");
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    
    try {
      // Add https:// if no protocol is specified
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        showToast("Հղումը չի կարող բացվել՝ $url");
      }
    } catch (e) {
      showToast("Հղումը բացելիս սխալ՝ $e");
    }
  }

  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return '1 օր առաջ';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} օր առաջ';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? '1 շաբաթ առաջ' : '$weeks շաբաթ առաջ';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? '1 ամիս առաջ' : '$months ամիս առաջ';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? '1 տարի առաջ' : '$years տարի առաջ';
      }
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? '1 ժամ առաջ' : '${difference.inHours} ժամ առաջ';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 ? '1 րոպե առաջ' : '${difference.inMinutes} րոպե առաջ';
    } else {
      return 'Հենց նոր';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.dividerDark),
        ),
        title: Text(
          'Օգտատերերի հաղորդագրություններ',
          style: AppTheme.headingMStyle.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textSecondary2),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
              ),
            )
          : messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 64,
                        color: AppTheme.textSecondary2,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Հաղորդագրություններ դեռ չկան',
                        style: AppTheme.itemTitleStyle.copyWith(
                          color: AppTheme.textSecondary2,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final userMessage = messages[index];
                    return _buildMessageCard(userMessage);
                  },
                ),
    );
  }

  Widget _buildMessageCard(UserMessage userMessage) {
    return Card(
      color: AppTheme.cardDark,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediaCardRadius),
        side: const BorderSide(color: AppTheme.dividerDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device info header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  userMessage.platform?.toLowerCase() == 'android'
                      ? Icons.android
                      : Icons.phone_iphone,
                  color: userMessage.platform?.toLowerCase() == 'android'
                      ? AppTheme.accentGreen
                      : AppTheme.textSecondary2,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Սարքի ID: ${userMessage.deviceId ?? 'Անհայտ'}',
                                    style: AppTheme.itemTitleStyle.copyWith(fontSize: 14),
                                  ),
                                ),
                                if (userMessage.deviceId != null && userMessage.deviceId!.isNotEmpty)
                                  IconButton(
                                    icon: Icon(Icons.copy, color: AppTheme.textSecondary2, size: 16),
                                    onPressed: () => _copyToClipboard(userMessage.deviceId!, 'Սարքի ID'),
                                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                    padding: EdgeInsets.zero,
                                    tooltip: 'Պատճենել սարքի ID-ն',
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (userMessage.sendingDate != null) ...[
                            Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary2),
                            const SizedBox(width: 4),
                            Text(
                              _formatMessageDate(userMessage.sendingDate!),
                              style: AppTheme.itemSubTitleStyle.copyWith(fontSize: 12),
                            ),
                          ] else ...[
                            Text(
                              'Ամսաթիվ չկա',
                              style: AppTheme.itemSubTitleStyle.copyWith(
                                fontSize: 12, 
                                color: Colors.red.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (userMessage.userName != null && userMessage.userName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: AppTheme.textSecondary2),
                            const SizedBox(width: 4),
                            Text(
                              'Օգտատեր: ${userMessage.userName!}',
                              style: AppTheme.itemSubTitleStyle.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      if (userMessage.platform != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: userMessage.platform?.toLowerCase() == 'android'
                                    ? AppTheme.accentGreen.withValues(alpha: 0.15)
                                    : AppTheme.accentPurple.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: userMessage.platform?.toLowerCase() == 'android'
                                      ? AppTheme.accentGreen
                                      : AppTheme.accentPurple,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                userMessage.platform!,
                                style: TextStyle(
                                  color: userMessage.platform?.toLowerCase() == 'android'
                                      ? AppTheme.accentGreen
                                      : AppTheme.accentPurple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Respond button
                            if (userMessage.fcmToken != null && userMessage.fcmToken!.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: () => _showRespondDialog(userMessage),
                                icon: const Icon(Icons.reply, size: 16),
                                label: const Text('Պատասխանել'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentCyan,
                                  foregroundColor: AppTheme.primaryDark,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: const Size(0, 32),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            // FCM Token section
            if (userMessage.fcmToken != null && userMessage.fcmToken!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerDark),
                ),
                child: Row(
                  children: [
                    Icon(Icons.token, color: AppTheme.textSecondary2, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'FCM Տոկեն: ${userMessage.fcmToken!.length > 50 ? '${userMessage.fcmToken!.substring(0, 50)}...' : userMessage.fcmToken!}',
                        style: AppTheme.itemSubTitleStyle.copyWith(fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: AppTheme.textSecondary2, size: 18),
                      onPressed: () => _copyToClipboard(userMessage.fcmToken!, 'FCM Տոկեն'),
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            const Divider(color: AppTheme.dividerDark),
            const SizedBox(height: 12),
            
            // Messages section
            if (userMessage.messages != null && userMessage.messages!.isNotEmpty)
              ...List.generate(userMessage.messages!.length, (messageIndex) {
                final message = userMessage.messages![messageIndex];
                final link = (userMessage.links != null && 
                            messageIndex < userMessage.links!.length)
                    ? userMessage.links![messageIndex]
                    : null;
                
                                 return Container(
                   margin: const EdgeInsets.only(bottom: 12),
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: AppTheme.surfaceDark,
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: AppTheme.dividerDark),
                   ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message header with remove button
                      Row(
                        children: [
                          Icon(Icons.message, color: AppTheme.accentCyan, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Հաղորդագրություն ${messageIndex + 1}',
                            style: AppTheme.itemTitleStyle.copyWith(fontSize: 14),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            onPressed: () => _showRemoveMessageDialog(
                              userMessage.deviceId ?? 'Անհայտ',
                              messageIndex,
                            ),
                            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Message content
                      Text(
                        message,
                        style: AppTheme.activeTextsStyle.copyWith(fontSize: 14),
                      ),
                      
                      // Link section
                      if (link != null && link.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentCyan.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.link, color: AppTheme.accentCyan, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _openUrl(link),
                                  child: Text(
                                    link,
                                    style: TextStyle(
                                      color: AppTheme.accentCyan,
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.copy, color: AppTheme.accentCyan, size: 16),
                                onPressed: () => _copyToClipboard(link, 'Link'),
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              })
            else
              Text(
                'No messages',
                style: AppTheme.itemSubTitleStyle,
              ),
          ],
        ),
      ),
    );
  }

  void _showRemoveMessageDialog(String deviceId, int messageIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.mediaCardRadius),
          side: const BorderSide(color: AppTheme.dividerDark),
        ),
        title: Text(
          'Ջնջել հաղորդագրությունը',
          style: AppTheme.itemTitleStyle,
        ),
        content: Text(
          'Համոզվա՞ծ եք, ուզում եք ջնջել այս հաղորդագրությունը:',
          style: AppTheme.activeTextsStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Չեղարկել',
              style: TextStyle(color: AppTheme.textSecondary2),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeMessage(deviceId, messageIndex);
            },
            child: Text(
              'Ջնջել',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showRespondDialog(UserMessage userMessage) {
    if (userMessage.deviceId == null || userMessage.deviceId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Սարքի ID-ն բացակայում է այս օգտվողի համար'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userMessage.fcmToken == null || userMessage.fcmToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('FCM տոկենը բացակայում է այս օգտվողի համար'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
        child: RespondToUserPopup(
          appBloc: widget.appBloc,
          fcmToken: userMessage.fcmToken!,
          deviceId: userMessage.deviceId!,
        ),
      ),
    );
  }
} 