import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:politicsstatements/redesign/bloc/appBloc.dart';
import 'package:politicsstatements/redesign/pages/aboute_route.dart';
import 'package:politicsstatements/redesign/pages/categories_page.dart';
import 'package:politicsstatements/redesign/pages/media_favorites_page.dart';
import 'package:politicsstatements/redesign/pages/media_top_chart_page.dart';
import 'package:politicsstatements/redesign/pages/search_page.dart';
import 'package:politicsstatements/redesign/pages/sources_route.dart';
import 'package:politicsstatements/redesign/pages/user_messages_page.dart';
import 'package:politicsstatements/redesign/popups/send_message_popup.dart';
import 'package:politicsstatements/redesign/popups/login_popup.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/repository.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/utils/constants.dart';
import 'package:politicsstatements/redesign/utils/popup_utils.dart';
import 'package:politicsstatements/redesign/utils/utils.dart';
import 'package:politicsstatements/redesign/widgets/commong_widgets.dart';
import 'package:politicsstatements/redesign/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'moderation_page.dart';

class HomePageRoute extends StatefulWidget {
  HomePageRoute();

  @override
  State<StatefulWidget> createState() {
    return _HomePageRouteState();
  }
}

class _HomePageRouteState extends State<HomePageRoute> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AppBloc appBloc;
  int selectedPageIndex = 0;
  PageController pageController = PageController();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    KeyboardVisibilityController().onChange.listen((isVisible) {
      if (!isVisible) {
        KeyboardOverlay.removeOverlay();
      } else {
        KeyboardOverlay.showOverlay(context);
      }
    });
    appBloc = AppBloc();
    appBloc.registerInternetStream();

    // AuthService is now initialized in main.dart

    _pages = <Widget>[
      CategoriesPage(
        appBloc,
      ),
      MediaFavoritesPage(
        appBloc,
        backClick: () {
          pageController.animateToPage(0, duration: Duration(milliseconds: 200), curve: Curves.linear);
        },
      ),
      MediaTopChartPage(appBloc, backClick: () {
        pageController.animateToPage(0, duration: Duration(milliseconds: 200), curve: Curves.linear);
      })
    ];

    var initializationSettingsAndroid = new AndroidInitializationSettings('@mipmap/app_icon');
    var initializationSettingsIOS = DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    // appBloc.flutterLocalNotificationsPlugin.initialize(initializationSettings);

    initRepo();
    pageController.addListener(() {
      setState(() {
        selectedPageIndex = pageController.page!.toInt();
      });
    });
    handleMessaging();
    Future.delayed(Duration(seconds: 1), () {
      _firebaseMessaging.getToken().then((firebaseToken) {
        fcmToken = firebaseToken ?? "";
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: 1), () async {
        if (platform == TargetPlatform.iOS) await AppTrackingTransparency.requestTrackingAuthorization();
        _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: false,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
      });

      screenWidth = MediaQuery.of(context).size.width;
      screenHeight = MediaQuery.of(context).size.height;
      checkInternet().then((isConnected) {
        if (!isConnected) {
          showPopup(context, "Ինտերնետ չկա", "Խնդրում ենք միացրեք ինտերնետը և վերաբացեք ծրագիրը");
        } else {
          appBloc.fetchSources();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  handleMessaging() async {
    // _firebaseMessaging.getToken().then((firebaseToken) {
    //   fcmToken = firebaseToken ?? "";
    // });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      messageReceivedOnForeground(message);
    });

    try {
      _firebaseMessaging.getToken().then((firebaseToken) {
        fcmToken = firebaseToken ?? "";
      });
    } catch (exception) {}
    RemoteMessage? message = await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (message != null) {
      messageReceivedOnBackground(message);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      messageReceivedOnBackground(message);
    });
  }

  messageReceivedOnForeground(RemoteMessage message) {
    handleRemoteMessage(message, true);
  }

  messageReceivedOnBackground(RemoteMessage message) {
    handleRemoteMessage(message, false);
  }

  handleRemoteMessage(RemoteMessage message, bool isForeground) async {
    var pendingMessageData = message.data;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (selectedPageIndex != 0) {
          setState(() {
            selectedPageIndex = 0;
          });
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: BlocProvider(
          create: (_) => appBloc,
          child: StreamBuilder<bool>(
            stream: AuthService().adminStatusStream,
            initialData: AuthService().currentAdminStatus,
            builder: (context, adminSnapshot) {
              final newAdminStatus = adminSnapshot.data ?? AuthService().currentAdminStatus;
              if (isAdminUser != newAdminStatus) {
                isAdminUser = newAdminStatus;
                if (kDebugMode) {
                  print('HomePage: Admin status changed to $isAdminUser');
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              }
              return Scaffold(
                resizeToAvoidBottomInset: false,
                backgroundColor: AppTheme.primaryDark,
                bottomNavigationBar: _buildBottomNavigationBar(),
                drawer: getDrawer(),
                body: Center(
                    child: Stack(
                  children: [
                    PageView(
                      scrollBehavior: CupertinoScrollBehavior(),
                      controller: pageController,
                      children: [for (var i = 0; i < 3; i++) _pages[i]],
                    ),
                    StreamBuilder<bool>(
                        stream: appBloc.isShowSearchStream,
                        initialData: false,
                        builder: (context, snapshot) {
                          return snapshot.data == true
                              ? SearchPage(
                                  appBloc,
                                  backClick: () {
                                    setState(() {
                                      appBloc.closeCategoriesSearch();
                                    });
                                  },
                                )
                              : Container();
                        })
                  ],
                )),
              );
            },
          )),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      selectedPageIndex = index;
      appBloc.closeCategoriesSearch();
      pageController.jumpToPage(index);
    });
  }

  Widget _buildBottomNavigationBar() {
    const double navBarHeight = 72.0;
    const double topRadius = 16.0;

    return Container(
      height: navBarHeight,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(topRadius),
          topRight: Radius.circular(topRadius),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNavItem(
                index: 0,
                activeIcon: Icons.category_rounded,
                inactiveIcon: Icons.category_outlined,
                label: '\u0532\u0578\u056C\u0578\u0580\u0568',
                isSelected: selectedPageIndex == 0,
              ),
              _buildNavItem(
                index: 1,
                activeIcon: Icons.favorite_rounded,
                inactiveIcon: Icons.favorite_outline_rounded,
                label: '\u0540\u0561\u057E\u0561\u0576\u0561\u056E (${favorites.length})',
                isSelected: selectedPageIndex == 1,
              ),
              _buildNavItem(
                index: 2,
                activeIcon: Icons.bar_chart_rounded,
                inactiveIcon: Icons.bar_chart_rounded,
                label: '\u0539\u0578\u0583',
                isSelected: selectedPageIndex == 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required bool isSelected,
  }) {
    const double iconSize = 26.0;
    const double labelFontSize = 11.0;
    const double containerHeight = 56.0;
    const Color activeColor = AppTheme.accentCyan;
    const Color inactiveColor = AppTheme.textSecondary2;
    final Color iconColor = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: containerHeight,
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  size: iconSize,
                  color: iconColor,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? activeColor : inactiveColor,
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getDrawer() {
    return Drawer(
      backgroundColor: AppTheme.primaryDark,
      child: StreamBuilder<firebase_auth.User?>(
        stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          return StreamBuilder<bool>(
            stream: AuthService().adminStatusStream,
            initialData: AuthService().currentAdminStatus,
            builder: (context, adminSnapshot) {
              final currentAdmin = adminSnapshot.data ?? AuthService().currentAdminStatus;
              if (isAdminUser != currentAdmin) {
                isAdminUser = currentAdmin;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              }
          
          return ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  dividerTheme: const DividerThemeData(color: Colors.transparent),
                ),
                child: Container(
                  height: kIsWeb ? 200 : 250,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // App name/logo
                          InkWell(
                            onTap: () async {
                              await Clipboard.setData(ClipboardData(text: await getDeviceId()));
                            },
                            child: Text(
                              "Bolola",
                              style: AppTheme.headingMStyle,
                            ),
                          ),
                          SizedBox(height: 16),

                          // User profile or login section
                          Expanded(
                            child: isLoggedIn ? _buildUserProfile() : _buildLoginSection(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              ListTile(
                title: const Text(
                  "Աղբյուրներ",
                  style: AppTheme.drawerTileStyle,
                ),
                leading: Icon(
                  Icons.source_rounded,
                  color: AppTheme.textSecondary2,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SourcesRoute()));
                },
              ),
              ListTile(
                title: const Text(
                  'Գրել մեզ',
                  style: AppTheme.drawerTileStyle,
                ),
                leading: Icon(
                  Icons.email_rounded,
                  color: AppTheme.textSecondary2,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final messageSent = await showSendMessagePopup(context, appBloc);
                  if (messageSent == true) {
                    // Message was sent successfully
                    // Could add additional actions here if needed
                  }
                },
              ),
              ListTile(
                title: const Text(
                  'Ծրագրի մասին',
                  style: AppTheme.drawerTileStyle,
                ),
                leading: Icon(
                  Icons.info_rounded,
                  color: AppTheme.textSecondary2,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AboutRoute()));
                },
              ),
              isAdminUser
                  ? ListTile(
                      title: const Text(
                        'Video Moderation',
                        style: AppTheme.drawerTileStyle,
                      ),
                      leading: Icon(
                        Icons.settings,
                        color: AppTheme.textSecondary2,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ModerationRoute(appBloc, "video")));
                      },
                    )
                  : Container(),
              isAdminUser
                  ? ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Environment',
                              style: AppTheme.drawerTileStyle,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isProductionEnvironment ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isProductionEnvironment ? Colors.red : Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isProductionEnvironment ? 'PROD' : 'STAGING',
                              style: TextStyle(
                                color: isProductionEnvironment ? Colors.red : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: isProductionEnvironment,
                            onChanged: (value) {
                              setState(() {
                                saveProductionEnvironment(value);
                              });
                              repository.reinitializeWithEnvironment();
                              // Fetch updated data from new environment
                              appBloc.fetchSources();
                              // Show confirmation dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Environment Changed'),
                                  content: Text(
                                    'Environment switched to ${value ? 'Production' : 'Staging'}.\n\nThe app will now use the ${value ? 'production' : 'staging'} server.\n\nData is being refreshed from the new environment.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            activeColor: Colors.red,
                            inactiveTrackColor: Colors.orange.withValues(alpha: 0.3),
                            inactiveThumbColor: Colors.orange,
                          ),
                        ],
                      ),
                      leading: Icon(
                        Icons.cloud_outlined,
                        color: AppTheme.textSecondary2,
                      ),
                      onTap: null, // Disable tap since we're using the switch
                    )
                  : Container(),
              // Migrate DB button for admin users
              isAdminUser
                  ? StreamBuilder<bool>(
                      stream: appBloc.isLoadingStream,
                      builder: (context, snapshot) {
                        final isLoading = snapshot.data ?? false;
                        return ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Migrate Database',
                                  style: AppTheme.drawerTileStyle,
                                ),
                              ),
                              if (isLoading)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
                                  ),
                                ),
                            ],
                          ),
                          leading: Icon(
                            Icons.sync_rounded,
                            color: AppTheme.textSecondary2,
                          ),
                          onTap: isLoading
                              ? null
                              : () {
                                  _showMigrateDatabaseDialog();
                                },
                        );
                      },
                    )
                  : Container(),
              isAdminUser
                  ? ListTile(
                      title: const Text(
                        'User Messages',
                        style: AppTheme.drawerTileStyle,
                      ),
                      leading: Icon(
                        Icons.message_rounded,
                        color: AppTheme.textSecondary2,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => UserMessagesPage(appBloc: appBloc)));
                      },
                    )
                  : Container(),
            ],
          );
            },
          );
        },
      ),
      surfaceTintColor: AppTheme.primaryDark,
    );
  }

  Widget _buildUserProfile() {
    return Row(
      children: [
        // User avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.textSecondary2.withValues(alpha: 0.3),
          ),
          child: currentUserPhotoUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    currentUserPhotoUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      color: AppTheme.textSecondary2,
                      size: 30,
                    ),
                  ),
                )
              : Icon(
                  Icons.person,
                  color: AppTheme.textSecondary2,
                  size: 30,
                ),
        ),

        SizedBox(width: 12),

        // User info and logout
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currentUserName.isNotEmpty ? currentUserName : 'User',
                style: AppTheme.itemTitleStyle.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (currentUserEmail.isNotEmpty) ...[
                SizedBox(height: 2),
                Text(
                  currentUserEmail,
                  style: AppTheme.itemSubTitleStyle.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 8),
              Row(
                children: [
                  if (isAdminUser) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Admin',
                        style: TextStyle(
                          color: AppTheme.accentCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                  InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      await AuthService().signOut();
                      // No need to manually setState - StreamBuilder will handle it
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.accentCyan, width: 1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Sign Out',
                        style: TextStyle(
                          color: AppTheme.accentCyan,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Մուտք գործեք կամ ստեղծել անձնական հաշիվ",
          style: AppTheme.itemSubTitleStyle,
        ),
        SizedBox(height: 12),
        InkWell(
          onTap: () async {
            Navigator.pop(context);
            final loginSuccess = await showLoginPopup(context);
            if (loginSuccess == true) {
              appBloc.fetchSuggestions();
              // No need to manually setState - StreamBuilder will handle it
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.accentCyan, width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Մուտք / Գրանցում',
              style: TextStyle(
                color: AppTheme.accentCyan,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Show migrate database confirmation dialog
  void _showMigrateDatabaseDialog() {
    Navigator.pop(context); // Close drawer first

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text(
          'Migrate Database',
          style: AppTheme.itemTitleStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will migrate the database between environments:',
              style: AppTheme.itemTitleStyle,
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current: ${isProductionEnvironment ? 'PRODUCTION' : 'STAGING'}',
                    style: AppTheme.itemTitleStyle.copyWith(
                      color: isProductionEnvironment ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Target: ${isProductionEnvironment ? 'STAGING' : 'PRODUCTION'}',
                    style: AppTheme.itemTitleStyle.copyWith(
                      color: isProductionEnvironment ? Colors.orange : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'This operation cannot be undone. Are you sure you want to proceed?',
              style: AppTheme.itemSubTitleStyle,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary2),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performDatabaseMigration();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
            ),
            child: Text(
              'Migrate',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Perform the actual database migration
  void _performDatabaseMigration() {
    appBloc.migrateDatabase((success) {
      if (success) {
        showToast('Database migration completed successfully');
        // Optionally refresh data after migration
        appBloc.fetchSources();
      } else {
        showToast('Database migration failed. Please try again.');
      }
    });
  }
}
