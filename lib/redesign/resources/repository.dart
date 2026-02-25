import 'dart:core';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:politicsstatements/redesign/resources/database/database.dart';
import 'package:politicsstatements/redesign/resources/models/migrate_request.dart';
import 'package:politicsstatements/redesign/resources/models/top_chart.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:politicsstatements/redesign/utils/constants.dart';
import 'package:politicsstatements/redesign/utils/utils.dart';
import 'package:politicsstatements/redesign/services/api_key_service.dart';
import 'package:dio/dio.dart';

import 'database/database_refactor.dart';
import 'models/favorites_response.dart';
import 'models/media_category.dart';
import 'models/media_group.dart';
import 'models/media_item.dart';
import 'models/medias.dart';
import 'models/userMessage.dart';
import 'models/userSuggestion.dart';
import 'models/user.dart';
import 'rest_client.dart';
import 'models/notification_request.dart';
import 'models/notification_response.dart';

Repository repository = Repository();

initRepo() async {
  repository.init();
}

class Repository {
  Dio dio = Dio();
  late DatabaseProvider databaseProvider;
  late RestClient restClient;
  late FirebaseFirestore firebaseDB;

  init() {
    firebaseDB = FirebaseFirestore.instance;
    databaseProvider = DatabaseProvider.db;
    restClient = RestClient(dio, baseUrl: baseUrl);
  }

  // Reinitialize REST client with new environment
  void reinitializeWithEnvironment() {
    restClient = RestClient(dio, baseUrl: baseUrl);
  }

  fetchData(Function() dataFetched) async {
    await repository.fetchTopChart();
    favorites = await DatabaseProvider.db.getFavorites();
    medias = await DatabaseProvider.db.getMediasFromDB();
    allItems.clear();
    allItems.addAll(medias?.getAllItems() ?? []);
    if (medias?.categories?.isNotEmpty == true) {
      dataFetched();
    }
    fetch(dataFetched);
  }

  fetchTopChart() async {
    chartList = await getTopChart();
    chartList.sort((a, b) {
      return b.shareCount! - a.shareCount!;
    });
  }

  // fetchTopChartFirebase() async {
  //   QuerySnapshot topChartEvent = await firebaseDB.collection("topChart").get();
  //   var documents = topChartEvent.docs;
  //   for (int i = 0; i < documents.length; i++) {
  //     MediaItem item = MediaItem.fromMap(documents[i].data() as Map<dynamic, dynamic>);
  //     chartList.add(item);
  //   }
  //   chartList.sort((a, b) {
  //     return b.shareCount! - a.shareCount!;
  //   });
  // }

  fetch(Function() dataFetched) async {
    Medias fetchingMedias = Medias(categories: []);
    fetchingMedias = (await fetchCategories())!;
    if (fetchingMedias.categories?.isEmpty == true) return;

    for (MediaCategory mediaCategory in fetchingMedias.categories ?? []) {
      mediaCategory.groups?.sort((a, b) => a.ordering! - b.ordering!);
    }

    medias = fetchingMedias;
    allItems = medias?.getAllItems().toSet() ?? {};
    _processAllItems();
    dataFetched();
    DatabaseProvider.db.insertAllItems(fetchingMedias.getAllItems());
    DatabaseProvider.db.insertAllMedias(fetchingMedias);
  }

  void _processAllItems() {
    for (MediaCategory category in medias?.categories ?? []) {
      for (MediaGroup group in category.groups ?? []) {
        for (MediaItem mediaItem in group.items!) {
          _processMediaItem(mediaItem);
        }
      }
    }
  }

  void _processMediaItem(MediaItem mediaItem) {
    if (favorites.contains(mediaItem)) {
      mediaItem.isFavorite = true;
    }

    List<String> keywords = [];
    mediaItem.keywords?.forEach((element) {
      if (element.isNotEmpty) keywords.add(replaceArmenianForSearch(element.toLowerCase()));
      String translatedKeyword = translateArmenianToEnglish(element.toLowerCase());
      String mistakeReplace = replaceMistakesEnglishForSearch(translatedKeyword);
      if (!keywords.contains(mistakeReplace)) keywords.add(mistakeReplace);
      String coupleLettersKeyword = replaceAllEnglishForSearch(translatedKeyword);
      if (!keywords.contains(coupleLettersKeyword)) keywords.add(coupleLettersKeyword);
    });

    String translatedName = translateArmenianToEnglish(mediaItem.name!.toLowerCase());
    keywords.add(replaceMistakesEnglishForSearch(translatedName));
    keywords.add(replaceAllEnglishForSearch(translatedName));
    keywords.add(replaceArmenianForSearch(mediaItem.name!.toLowerCase()));
    mediaItem.allKeywords = keywords;

    if (chartList.contains(mediaItem)) {
      mediaItem.shareCount = chartList.elementAt(chartList.indexOf(mediaItem)).shareCount;
      chartList[chartList.indexOf(mediaItem)].groupAlias = mediaItem.groupAlias;
      chartList[chartList.indexOf(mediaItem)].categoryAlias = mediaItem.categoryAlias;
      chartList[chartList.indexOf(mediaItem)].allKeywords = mediaItem.allKeywords;
      chartList[chartList.indexOf(mediaItem)].imageUrl = mediaItem.imageUrl;
    }
  }

  List<UserSuggestion> userSuggestions = [];

  fetchSuggestions() async {
    QuerySnapshot suggestions = await firebaseDB.collection("userSuggestions").get();
    for (var doc in suggestions.docs) {
      var suggestionItemsData = doc.data() as Map<dynamic, dynamic>;
      userSuggestions.add(UserSuggestion.fromMap(suggestionItemsData));
    }
    for (MediaCategory mediaCategory in medias!.categories!) {
      for (MediaGroup mediaGroup in mediaCategory.groups!) {
        for (MediaItem mediaItem in mediaGroup.items!) {
          for (UserSuggestion suggestion in userSuggestions) {
            if (suggestion.isThisForMediaItem(mediaItem)) {
              mediaItem.suggestedKeywords = suggestion.messages ?? [];
            }
          }
        }
      }
    }
  }

  Future<void> sendUserMessage(String userName, String links, String message) async {
    try {
      String topic = "${await getDeviceId()}";
      DocumentReference reference = firebaseDB.collection("userMessages").doc(topic);
      FirebaseMessaging.instance.subscribeToTopic(topic);
      FirebaseFirestore.instance.runTransaction((transaction) async {
        try {
          DocumentSnapshot snapshot = await transaction.get(reference);
          UserMessage? userMessage;
          DateTime now = DateTime.now();

          if (snapshot.data() != null) {
            userMessage = UserMessage.fromMap(snapshot.data() as Map<dynamic, dynamic>);
            userMessage.messages!.add(message);
            userMessage.links!.add(links);
            userMessage.fcmToken = fcmToken;
            userMessage.platform = isAndroid() ? "Android" : "iOS";
            userMessage.userName = userName;
            userMessage.sendingDate = now;
            transaction.update(reference, userMessage.toMap());
          } else {
            userMessage = UserMessage(
              messages: [message],
              links: [links],
              platform: Platform.isAndroid ? "Android" : "iOS",
              userName: userName,
              sendingDate: now,
            );
            userMessage.fcmToken = fcmToken;
            transaction.set(reference, userMessage.toMap());
          }
          return {};
        } on Exception {
          // transaction.set(reference, audio.toMap());
        }
      });
    } on PlatformException catch (e) {
      print("Failed to share file: '${e.message}'.");
    }
  }

  Future<void> sendSuggestion(String collection, MediaItem item, String message) async {
    try {
      String groupAlias = item.groupAlias ?? "";
      String itemAlias = item.alias ?? "";
      String categoryAlias = item.categoryAlias ?? "";
      String key = "${groupAlias}_${itemAlias}";

      // Initialize suggestedKeywords if null
      if (item.suggestedKeywords == null) {
        item.suggestedKeywords = [];
      }
      item.suggestedKeywords!.add(message);

      DocumentReference reference = firebaseDB.collection(collection).doc(key);
      firebaseDB.runTransaction((transaction) async {
        try {
          DocumentSnapshot snapshot = await transaction.get(reference);
          UserSuggestion? userSuggestion;
          if (snapshot.data() != null) {
            userSuggestion = UserSuggestion.fromMap(snapshot.data() as Map<dynamic, dynamic>);
            userSuggestion.messages?.add(message);
            transaction.update(reference, userSuggestion.toMap());
          } else {
            userSuggestion =
                UserSuggestion(messages: [message], mediaType: "", groupAlias: groupAlias, itemAlias: itemAlias, categoryAlias: categoryAlias);
            transaction.set(reference, userSuggestion.toMap());
          }

          return {};
        } on Exception {
          // transaction.set(reference, audio.toMap());
        }
      });
    } on PlatformException catch (e) {
      print("Failed to share file: '${e.message}'.");
    }
  }

  Future<void> addKeywordToItem(MediaItem item, String keyword, Function()? callback) async {
    String groupAlias = item.groupAlias ?? "";
    String itemAlias = item.alias ?? "";
    String categoryAlias = item.categoryAlias ?? "";

    // Add keyword to item
    if (item.keywords?.contains(keyword) == false) item.keywords?.add(keyword);

    // Update the found item in the data structure
    MediaItem? foundItem = findItemByAlias(itemAlias, groupAlias, categoryAlias);
    if (foundItem?.keywords?.contains(keyword) == false) foundItem?.keywords?.add(keyword);
    if (foundItem?.allKeywords?.contains(keyword) == false) foundItem?.allKeywords?.add(keyword);

    // Update the item in Firebase
    updateMedia(foundItem);

    callback?.call();
  }

  Future<void> addKeywordFromSuggestion(MediaItem item, String keyword, Function()? callback) async {
    // First add the keyword to the item
    await addKeywordToItem(item, keyword, null);

    // Then remove it from suggestions
    await _removeSuggestionFromCollectionAndItem(item, keyword);

    callback?.call();
  }

  Future<void> _removeSuggestionFromCollectionAndItem(MediaItem item, String suggestion) async {
    String groupAlias = item.groupAlias ?? "";
    String itemAlias = item.alias ?? "";
    String categoryAlias = item.categoryAlias ?? "";
    String key = "${groupAlias}_$itemAlias";

    // Remove from userSuggestions collection
    DocumentReference reference = firebaseDB.collection("userSuggestions").doc(key);
    await firebaseDB.runTransaction((transaction) async {
      try {
        DocumentSnapshot snapshot = await transaction.get(reference);
        if (snapshot.exists) {
          UserSuggestion userSuggestion = UserSuggestion.fromMap(snapshot.data() as Map<dynamic, dynamic>);
          userSuggestion.messages?.remove(suggestion);
          if (userSuggestion.messages?.isEmpty == true) {
            transaction.delete(reference);
          } else {
            transaction.update(reference, userSuggestion.toMap());
          }
        }
      } on Exception catch (e) {
        print("Error removing suggestion from collection: $e");
      }
    });

    // Remove from item's suggestedKeywords
    if (item.suggestedKeywords == null) {
      item.suggestedKeywords = [];
    }
    item.suggestedKeywords!.remove(suggestion);

    MediaItem? foundItem = findItemByAlias(itemAlias, groupAlias, categoryAlias);
    if (foundItem?.suggestedKeywords == null) {
      foundItem?.suggestedKeywords = [];
    }
    foundItem?.suggestedKeywords!.remove(suggestion);
    updateMedia(foundItem);
  }

  void saveTitle(MediaItem item, String title, Function() callback) async {
    String groupAlias = item.groupAlias ?? "";
    String itemAlias = item.alias ?? "";
    String categoryAlias = item.categoryAlias ?? "";
    MediaItem? foundItem = findItemByAlias(itemAlias, groupAlias, categoryAlias);
    item.name = title;
    foundItem?.name = title;
    updateMedia(item);
    callback();
  }

  void removeSuggestion(MediaItem item, String suggestion, Function() callback) async {
    await _removeSuggestionFromCollectionAndItem(item, suggestion);
    callback();
  }

  String replaceMistakesEnglishForSearch(String name) {
    return name.replaceAll("_", " ").replaceAll("d", "t").replaceAll("g", "k").replaceAll("q", "k").replaceAll("b", "p");
  }

  String replaceAllEnglishForSearch(String name) {
    return name
        .replaceAll("_", " ")
        .replaceAll("dz", "c")
        .replaceAll("ts", "c")
        .replaceAll("d", "t")
        .replaceAll("g", "k")
        .replaceAll("q", "k")
        .replaceAll("b", "p")
        .replaceAll("vo", "o");
  }

  String translateArmenianToEnglish(String name) {
    List<String> nameSplit = name.split(" ");
    nameSplit.remove("");
    List<String> nameSplitTranslations = [];
    for (String item in nameSplit) {
      String result = item;
      if (item.startsWith("ո") && !item.startsWith("ու")) {
        result = item.replaceAll("վո", "vo");
        result = item.replaceAll("ո", "vo");
      }
      result = result
          .replaceAll("վո", "vo")
          .replaceAll("ու", "u")
          .replaceAll("ա", "a")
          .replaceAll("բ", "b")
          .replaceAll("գ", "g")
          .replaceAll("դ", "d")
          .replaceAll("ե", "e")
          .replaceAll("զ", "z")
          .replaceAll("է", "e")
          .replaceAll("ը", "@")
          .replaceAll("թ", "t")
          .replaceAll("ժ", "j")
          .replaceAll("ի", "i")
          .replaceAll("լ", "l")
          .replaceAll("խ", "x")
          .replaceAll("ծ", "c")
          .replaceAll("կ", "k")
          .replaceAll("հ", "h")
          .replaceAll("ձ", "dz")
          .replaceAll("ղ", "x")
          .replaceAll("ճ", "c")
          .replaceAll("մ", "m")
          .replaceAll("յ", "y")
          .replaceAll("ն", "n")
          .replaceAll("շ", "sh")
          .replaceAll("օ", "o")
          .replaceAll("ո", "o")
          .replaceAll("չ", "ch")
          .replaceAll("պ", "p")
          .replaceAll("ջ", "j")
          .replaceAll("ռ", "r")
          .replaceAll("ս", "s")
          .replaceAll("վ", "v")
          .replaceAll("տ", "t")
          .replaceAll("ր", "r")
          .replaceAll("ց", "c")
          .replaceAll("փ", "p")
          .replaceAll("ք", "q")
          .replaceAll("և", "ev")
          .replaceAll("ֆ", "f");
      nameSplitTranslations.add(result);
    }
    return nameSplitTranslations.join(" ");
  }

  String replaceArmenianForSearch(String name) {
    return name
        .replaceAll("է", "ե")
        .replaceAll("դ", "տ")
        .replaceAll("թ", "տ")
        .replaceAll("գ", "կ")
        .replaceAll("ք", "կ")
        .replaceAll("ջ", "չ")
        .replaceAll("ճ", "չ")
        .replaceAll("ձ", "ց")
        .replaceAll("ծ", "ց")
        .replaceAll("բ", "պ")
        .replaceAll("փ", "պ")
        .replaceAll("ղ", "խ")
        .replaceAll("է", "փ")
        .replaceAll("օ", "ո")
        .replaceAll("ռ", "ր");
  }

  makeFavorite(MediaItem item) async {
    item.isFavorite = true;
    favorites.insert(0, item);
    DatabaseProvider.db.insertItem(item);

    // Add to backend favorites
    try {
      if (user != null && item.alias != null) {
        await restClient.addToFavorites(user?.firebaseUid ?? "", item);
      }
    } catch (e) {
      print("Failed to add favorite to backend: $e");
    }
  }

  unFavorite(MediaItem item) async {
    item.isFavorite = false;
    favorites.remove(item);
    DatabaseProvider.db.insertItem(item);

    // Remove from backend favorites
    try {
      if (user != null && item.alias != null) {
        await restClient.removeFromFavorites(user?.firebaseUid ?? "", item);
      }
    } catch (e) {
      print("Failed to remove favorite from backend: $e");
    }
  }

  Future<void> toggleFavoriteAudio(MediaItem item) async {
    if (item.isFavorite == true) {
      await unFavorite(item);
    } else {
      await makeFavorite(item);
      sendEvent("addFavoriteVideo", {"alias": item.alias!});
    }
  }

  Future<void> toggleFavoriteVideo(MediaItem item) async {
    if (item.isFavorite == true) {
      await unFavorite(item);
    } else {
      await makeFavorite(item);
      sendEvent("addFavoriteVideo", {"alias": item.alias!});
    }
  }

  // Get user favorites from backend
  Future<GetUserFavoritesResponse?> getUserFavorites() async {
    try {
      if (user == null) return null;

      return await restClient.getUserFavorites(user?.firebaseUid ?? "");
    } catch (e) {
      print("Failed to get user favorites: $e");
      return null;
    }
  }

  /// Fetch medias from the server using the REST client
  Future<Medias?> fetchCategories() async {
    try {
      return await restClient.fetchCategories();
    } catch (e) {
      print("");
      return null;
    }
  }

  /// Get top chart items from the server
  Future<List<MediaItem>> getTopChart() async {
    try {
      return (await restClient.getTopChart()).items ?? [];
    } catch (e) {
      print(e);
      return [];
    }
  }

  /// Update a single chart item on the server
  Future<void> updateChartItem(MediaItem item) async {
    try {
      await ApiKeyService().waitForInitialization();
      final apiKey = bulki;
      if (apiKey == null) throw Exception('API key not available');
      await restClient.updateChartItem(apiKey, item);

      // Update the item in allItems source data
      _updateItemInSourceData(item);
    } catch (e) {
      print(e);
    }
  }

  /// Update a single media item on the server
  Future<void> updateMedia(MediaItem? item) async {
    try {
      await ApiKeyService().waitForInitialization();
      final apiKey = bulki;
      if (apiKey == null) throw Exception('API key not available');
      await restClient.updateMedia(apiKey, item);

      // Update the item in allItems source data
      if (item != null) {
        _updateItemInSourceData(item);
      }
    } catch (e) {
      print(e);
    }
  }

  /// Helper method to update an item in the allItems source data
  void _updateItemInSourceData(MediaItem updatedItem) {
    // Find and update the item in allItems
    for (MediaItem sourceItem in allItems) {
      if (sourceItem.alias == updatedItem.alias) {
        sourceItem.name = updatedItem.name;
        sourceItem.shareCount = updatedItem.shareCount;
        sourceItem.keywords = updatedItem.keywords;
        sourceItem.relatedKeywords = updatedItem.relatedKeywords;
        sourceItem.allKeywords = updatedItem.allKeywords;
        sourceItem.audioUrl = updatedItem.audioUrl;
        sourceItem.videoUrl = updatedItem.videoUrl;
        sourceItem.sourceUrl = updatedItem.sourceUrl;
        sourceItem.imageUrl = updatedItem.imageUrl;
        break;
      }
    }

    // Also update in the structured medias data
    for (MediaCategory category in medias?.categories ?? []) {
      for (MediaGroup group in category.groups ?? []) {
        for (MediaItem item in group.items ?? []) {
          if (item.alias == updatedItem.alias) {
            item.name = updatedItem.name;
            item.shareCount = updatedItem.shareCount;
            item.keywords = updatedItem.keywords;
            item.relatedKeywords = updatedItem.relatedKeywords;
            item.allKeywords = updatedItem.allKeywords;
            item.audioUrl = updatedItem.audioUrl;
            item.videoUrl = updatedItem.videoUrl;
            item.sourceUrl = updatedItem.sourceUrl;
            item.imageUrl = updatedItem.imageUrl;
            break;
          }
        }
      }
    }
  }

  // User Authentication Methods

  /// Get user by Firebase UID from backend
  Future<User?> getUserByFirebaseUid(String firebaseUid) async {
    try {
      return await restClient.getUserByFirebaseUid(firebaseUid);
    } catch (e) {
      print("Failed to get user by Firebase UID: $e");
      return null;
    }
  }

  /// Create a new user in the backend
  Future<User?> createUser(User? user) async {
    try {
      await ApiKeyService().waitForInitialization();
      final apiKey = bulki;
      if (apiKey == null) throw Exception('API key not available');
      return await restClient.createUser(apiKey, user);
    } catch (e) {
      print("Failed to create user: $e");
      return null;
    }
  }

  /// Update user in the backend
  Future<User?> updateUser(User user) async {
    try {
      // Note: You would need an API key for this operation
      // For now, we'll just return the user as-is
      // return await restClient.updateUser(apiKey, user);
      return user;
    } catch (e) {
      print("Failed to update user: $e");
      return null;
    }
  }

  /// Migrate database between environments
  Future<bool> migrateDatabase() async {
    try {
      await ApiKeyService().waitForInitialization();
      final apiKey = bulki;
      if (apiKey == null) throw Exception('API key not available');
      await restClient.migrateDatabase(apiKey, MigrateRequest(email: user?.email ?? ""));
      return true;
    } catch (e) {
      print("Failed to migrate database: $e");
      return false;
    }
  }

  /// Get all user messages from Firebase
  Future<List<UserMessage>> getUserMessages() async {
    try {
      QuerySnapshot snapshot = await firebaseDB.collection("userMessages").get();
      List<UserMessage> messages = [];
      for (var doc in snapshot.docs) {
        var messageData = doc.data() as Map<dynamic, dynamic>;
        UserMessage userMessage = UserMessage.fromMap(messageData);
        // Add deviceId to the message for display purposes
        userMessage.deviceId = doc.id;
        messages.add(userMessage);
      }
      return messages;
    } catch (e) {
      print("Failed to get user messages: $e");
      return [];
    }
  }

  /// Remove a specific message from a device's messages list
  Future<void> removeUserMessage(String deviceId, int messageIndex) async {
    try {
      DocumentReference reference = firebaseDB.collection("userMessages").doc(deviceId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(reference);
        if (snapshot.data() != null) {
          UserMessage userMessage = UserMessage.fromMap(snapshot.data() as Map<dynamic, dynamic>);

          // Remove the message and corresponding link if they exist
          if (userMessage.messages != null && messageIndex < userMessage.messages!.length) {
            userMessage.messages!.removeAt(messageIndex);
          }
          if (userMessage.links != null && messageIndex < userMessage.links!.length) {
            userMessage.links!.removeAt(messageIndex);
          }

          // If no messages left, delete the document
          if (userMessage.messages?.isEmpty == true) {
            transaction.delete(reference);
          } else {
            // Update the document with remaining messages
            transaction.update(reference, userMessage.toMap());
          }
        }
      });
    } catch (e) {
      print("Failed to remove user message: $e");
    }
  }

  /// Send notification to user
  Future<bool> sendNotification(String topic, String title, String message) async {
    try {
      await ApiKeyService().waitForInitialization();
      final apiKey = bulki;
      if (apiKey == null) throw Exception('API key not available');

      final notificationRequest = NotificationRequest(
        topic: topic,
        title: title,
        message: message,
      );

      final response = await restClient.sendNotification(apiKey, notificationRequest);
      print("Notification sent successfully: $response");
      return true;
    } catch (e) {
      print("Failed to send notification: $e");
      return false;
    }
  }

  /// Fetch admin users from Firebase Firestore
  Future<List<String>> getAdminUsers() async {
    try {
      DocumentSnapshot doc = await firebaseDB.collection("general").doc("adminusers").get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> adminsList = data['admins'] ?? [];

        // Convert to list of strings and normalize to lowercase
        return adminsList.map((email) => email.toString().toLowerCase().trim()).where((email) => email.isNotEmpty).toList();
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching admin users: $e');
      }
      return [];
    }
  }
}
