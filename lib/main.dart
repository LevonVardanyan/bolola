import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:politicsstatements/firebase_options.dart';
import 'package:politicsstatements/redesign/pages/home_page.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/utils/migrate_to_server.dart';
import 'package:politicsstatements/redesign/utils/upload_dev_tool.dart';
import 'package:sqflite/sqflite.dart';
import 'package:politicsstatements/redesign/services/auth_service.dart';
import 'package:politicsstatements/redesign/services/api_key_service.dart';
import 'package:politicsstatements/redesign/resources/database/database_refactor.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

openCrashEmail(String crashLog) {
  const channelPlatform = const MethodChannel('com.skimore.ticketshop.flutter.dev/channel');
  channelPlatform.invokeMethod('sendCrashEmail', <String, Object>{'crashLog': crashLog ?? ""});
}

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log Flutter framework errors
    print('Flutter framework error: ${details.exception}');
    print(details.stack);
  };

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Log version information - this will be compiled into main.dart.js

    // DartPluginRegistrant.ensureInitialized();
    // FlutterError.onError = (FlutterErrorDetails details) {
    //   openCrashEmail(details.exception.toString() + "\n\n\nerror \n\n\n" + details.stack.toString());
    // };

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize API key service after Firebase
    try {
      await ApiKeyService().initialize();
      if (kDebugMode) print('API key service initialized successfully');
    } catch (e) {
      if (kDebugMode) print('Failed to initialize API key service: $e');
    }

    // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // FlutterError.onError = (FlutterErrorDetails details) {
    //   openCrashEmail(details.exception.toString() + "\n\n\nerror \n\n\n" + details.stack.toString());
    // };

    if (!kIsWeb) {
      if (Platform.isIOS) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
      } else if (Platform.isAndroid) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, //
          statusBarIconBrightness: Brightness.dark, // For Android (dark icons)

          // status bar color
        ));
      }
    }

    await GetStorage.init();

    await setSavedDate();

    // Initialize database early to ensure proper setup
    try {
      await DatabaseProvider.db.testConnection();
      if (kDebugMode) print('Database initialized successfully');
    } catch (e) {
      if (kDebugMode) print('Database initialization failed: $e');
      // Continue anyway - the app might still work with limited functionality
    }

    // Initialize AuthService early to ensure auth state listener is set up
    // This will check for logged-in users and admin status on both mobile and web
    if (kDebugMode) print('Initializing AuthService to check for logged-in admin users...');
    AuthService().initialize();
    if (kDebugMode) print('AuthService initialization complete');

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);

    runApp(const BololaApp());
    // runApp(UploadWidget());
    // runApp(MigrateServerWidget());
  }, (error, stack) {
    // Log uncaught Dart errors
    print('Uncaught Dart error: ${error}');
    print(stack);
  });
}

class BololaApp extends StatelessWidget {
  const BololaApp({Key? key}) : super(key: key);

  // This widget is the root of application.
  @override
  Widget build(BuildContext context) {
    platform = Theme.of(context).platform; //?? defaultTargetPlatform;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => HomePageRoute(),
      },
      builder: (context, child) {
        return MediaQuery(
          child: child!,
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0), //textScaleFactor is for ignoring system text scale
        );
      },
    );
  }
}

class CustomBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
