import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:politicsstatements/redesign/resources/repository.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/utils/popup_utils.dart';
import 'package:politicsstatements/redesign/utils/utils.dart';
import 'package:rxdart/rxdart.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';

import '../resources/models/media_item.dart';
import '../resources/models/medias.dart';
import '../resources/models/userMessage.dart';
import '../resources/prefs.dart';

class AppBloc extends Bloc<void, int> {
  bool isLoading = false;
  bool isDownloading = false;
  bool isSearching = false;

  int lastMessageSendTime = 0;

  final _updatePlayingItemController = BehaviorSubject<bool>();
  final _isShowSearchSearch = BehaviorSubject<bool>();
  final _isLoadingController = BehaviorSubject<bool>();
  final _dataLoadingController = BehaviorSubject<bool>();

  final _isAudioDownloadingController = BehaviorSubject<MediaItem?>();
  final _isVideoDownloadingController = BehaviorSubject<MediaItem?>();

  Stream<bool> get updatePlayingItemStream => _updatePlayingItemController.stream;

  Stream<bool> get dataLoadingStream => _dataLoadingController.stream;

  Stream<MediaItem?> get isAudioDownloadingStream => _isAudioDownloadingController.stream;

  Stream<MediaItem?> get isVideoDownloadingStream => _isVideoDownloadingController.stream;

  Stream<bool> get isLoadingStream => _isLoadingController.stream;

  Stream<bool> get isShowSearchStream => _isShowSearchSearch.stream;

  static const channelPlatform = const MethodChannel('com.armenia.famousstatements.flutter.dev/channel');
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  AppBloc() : super(0) {
    //Checking broadcast stream, if deep link was clicked in opened appication
  }

  registerInternetStream() {
    checkInternet();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      Future.delayed(Duration(seconds: 2), () async {
        if (await checkInternet()) {}
      });
    });
  }

  void openCategoriesSearch() {
    _isShowSearchSearch.sink.add(true);
  }

  void closeCategoriesSearch() {
    _isShowSearchSearch.sink.add(false);
  }

  void saveAudio(MediaItem item, Function(bool) callback) async {
    bool success = true;

    File file = File(await getAudioSaveFilePath(item.fileName ?? item.alias, item.groupAlias));

    if (!(await file.exists())) {
      try {
        _isAudioDownloadingController.sink.add(item);
        isDownloading = true;
        await downloadFromUrlToPath(file.path, item.audioUrl ?? "", () {});
      } catch (exception) {
        success = false;
      }
      _isAudioDownloadingController.sink.add(null);
      isDownloading = false;
    }

    callback(success);
  }

  void shareAudio(MediaItem item, Function(bool) callback) async {
    bool success = true;

    if (kIsWeb) {
      try {
        final audioUrl = item.audioUrl ?? "";
        final audioTitle = item.name ?? "Audio";

        if (audioUrl.isNotEmpty) {
          // Update share count immediately for web
          item.shareCount = item.shareCount! + 1;
          repository.updateChartItem(item);
          sendEvent("shareItem", {"alias": item.alias!, "shareCount": item.shareCount!, "type": "audio"});

          await SharePlus.instance.share(
            ShareParams(
              uri: Uri.parse(audioUrl),
              sharePositionOrigin: null,
              downloadFallbackEnabled: true,
            ),
          );
        } else {
          success = false;
        }
      } catch (exception) {
        success = false;
      }
    } else {
      // For mobile, download and share the file as before
      File file = File(await getAudioFilePath(item.fileName ?? item.alias, item.groupAlias));
      if (!(await file.exists())) {
        _isAudioDownloadingController.sink.add(item);
        isDownloading = true;
        try {
          await downloadFromUrlToPath(file.path, item.audioUrl ?? "", () {});
        } catch (exception) {
          success = false;
        }
        _isAudioDownloadingController.sink.add(null);
        isDownloading = false;
      }
      if (success) {
        item.shareCount = item.shareCount! + 1;
        repository.updateChartItem(item);
        sendEvent("shareItem", {"alias": item.alias!, "shareCount": item.shareCount!, "type": "audio"});
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile('${file.path}')],
            sharePositionOrigin: null,
            downloadFallbackEnabled: true,
          ),
        );
      }
    }

    callback(success);
  }

  void saveVideo(MediaItem item, Function(bool) callback) async {
    bool success = true;

    if (Platform.isAndroid) {
      File file = File(await getVideoSaveFilePath(item.fileName ?? item.alias, item.groupAlias));

      if (!(await file.exists())) {
        try {
          _isVideoDownloadingController.sink.add(item);
          isDownloading = true;
          await downloadFromUrlToPath(file.path, item.videoUrl ?? "", () {});
          await SaverGallery.saveFile(filePath: file.path, skipIfExists: true, fileName: '${item.fileName ?? item.alias!}.mp4', androidRelativePath: "Movies");
        } catch (exception) {
          success = false;
        }
        _isVideoDownloadingController.sink.add(null);
        isDownloading = false;
      }
    }
    callback(success);
  }

  void shareVideo(MediaItem item, Function(bool) callback) async {
    bool success = true;

    if (kIsWeb) {
      try {
        final videoUrl = item.videoUrl ?? "";
        final videoTitle = item.name ?? "Video";

        if (videoUrl.isNotEmpty) {
          // Update share count immediately for web
          item.shareCount = item.shareCount! + 1;
          repository.updateChartItem(item);
          sendEvent("shareItem", {"alias": item.alias!, "shareCount": item.shareCount!, "type": "video"});

          await SharePlus.instance.share(
            ShareParams(
              uri: Uri.parse(videoUrl),
              sharePositionOrigin: null,
              downloadFallbackEnabled: true,
            ),
          );
        } else {
          success = false;
        }
      } catch (exception) {
        success = false;
      }
    } else {
      // For mobile, download and share the file as before
      File file = File(await getVideoFilePath(item.fileName ?? item.alias, item.groupAlias));
      if (!(await file.exists())) {
        _isVideoDownloadingController.sink.add(item);
        isDownloading = true;

        try {
          await downloadFromUrlToPath(file.path, item.videoUrl ?? "", () {});
        } catch (exception) {
          success = false;
        }
        _isVideoDownloadingController.sink.add(null);
        isDownloading = false;
      }
      if (success) {
        item.shareCount = item.shareCount! + 1;
        repository.updateChartItem(item);
        sendEvent("shareItem", {"alias": item.alias!, "shareCount": item.shareCount!, "type": "video"});
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile('${file.path}')],
            sharePositionOrigin: null,
            downloadFallbackEnabled: true,

          ),
        );
      }
    }

    callback(success);
  }

  void scheduleNotification(String title, String subtitle) async {
    // print("scheduling one with $title and $subtitle");
    var rng = new Random();
    var androidPlatformChannelSpecifics =
        AndroidNotificationDetails("10", "bolola", importance: Importance.high, priority: Priority.high, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(rng.nextInt(100000), title, subtitle, platformChannelSpecifics, payload: 'item x');
  }

  fetchSources() async {
    _dataLoadingController.sink.add(true);
    repository.fetchData(
      () {
        _dataLoadingController.sink.add(false);
        saveUpdateDateTime(DateTime.now());
      },
    );
  }

  @override
  void dispose() {
    _isLoadingController.close();
  }

  Future<void> toggleFavoriteAudio(MediaItem item) {
    return repository.toggleFavoriteAudio(item);
  }

  Future<void> toggleFavoriteVideo(MediaItem item) {
    return repository.toggleFavoriteVideo(item);
  }

  bool checkSendingTime() {
    if (DateTime.now().millisecondsSinceEpoch - lastMessageSendTime < 30000 && !isAdminUser) {
      showToast("Պետք է անցնի 30 վարկյան վերջին ուղարկման պահից");
      return false;
    }
    return true;
  }

  bool sendMessage(String name, String links, String message) {
    if (checkSendingTime()) {
      repository.sendUserMessage(name, links, message);
      lastMessageSendTime = DateTime.now().millisecondsSinceEpoch;
      return true;
    }
    return false;
  }

  void sendFix(MediaItem item, String message) {
    if (checkSendingTime()) {
      repository.sendSuggestion("userFixes", item, message);
      lastMessageSendTime = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void sendKeywordSuggestion(MediaItem item, String message) {
    if (checkSendingTime()) {
      repository.sendSuggestion("userSuggestions", item, message);
      lastMessageSendTime = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void addKeywordFromSuggestion(MediaItem item, String keyword, Function() callback) {
    if (checkSendingTime()) {
      repository.addKeywordFromSuggestion(item, keyword, callback);
      lastMessageSendTime = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void saveTitle(MediaItem item, String title, Function() callback) {
    repository.saveTitle(item, title, callback);
  }

  Future<void> updateItem(
    MediaItem item,
  ) async {
    await repository.updateMedia(item);
  }

  void removeSuggestion(MediaItem item, String suggestion, Function() callback) {
    repository.removeSuggestion(item, suggestion, callback);
  }

  void setLoading(bool loading) {
    this.isLoading = loading;
    _dataLoadingController.sink.add(loading);
  }

  void updateChartItem(MediaItem item) {
    repository.updateChartItem(item);
  }

  void fetchSuggestions() {
    repository.fetchSuggestions();
  }

  /// Get all user messages
  Future<List<UserMessage>> getUserMessages() async {
    return await repository.getUserMessages();
  }

  /// Remove a specific user message
  Future<void> removeUserMessage(String deviceId, int messageIndex) async {
    await repository.removeUserMessage(deviceId, messageIndex);
  }

  /// Migrate database between environments
  Future<bool> migrateDatabase(Function(bool) callback) async {
    bool success = await repository.migrateDatabase();
    callback.call(success);
    return success;
  }

  Future<bool> sendNotification(String topic, String title, String message) async {
    return await repository.sendNotification(topic, title, message);
  }

  /// Get admin users list from Firestore
  Future<List<String>> getAdminUsers() async {
    return await repository.getAdminUsers();
  }
}
