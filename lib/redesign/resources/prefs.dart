import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import 'models/user.dart';

var isInternetConnected = true;
String fcmToken = "";
bool isAutoPlay = true;
bool isLoop = false;
bool isLoggedIn = false;
bool isAdminUser = false;
bool envDefaultValue = !kDebugMode;
bool isProductionEnvironment = envDefaultValue; // false = staging, true = production
User? user;
String currentUserId = "";
String currentUserName = "";
String currentUserEmail = "";
String currentUserPhotoUrl = "";
String appVersion = "1.0.11";
DateTime? lastUpdateTime;
GetStorage storage = GetStorage();

List<String> devDevices = ["05122043cc05f9738ae95e6e8f49d8d0b630b714dbdb1fbacfcb7a08a4aa6342"];

TargetPlatform platform = TargetPlatform.iOS;

setSavedDate() async {
  isAutoPlay = storage.read(PREF_IS_AUTO_PLAY) ?? true;
  isLoop = storage.read(PREF_IS_LOOP) ?? false;
  isLoggedIn = storage.read(PREF_IS_LOGGED_IN) ?? false;
  isAdminUser = storage.read(PREF_IS_ADMIN_USER) ?? false;
  isProductionEnvironment = storage.read(PREF_IS_PRODUCTION_ENV) ?? envDefaultValue;
  currentUserId = storage.read(PREF_CURRENT_USER_ID) ?? "";
  currentUserName = storage.read(PREF_CURRENT_USER_NAME) ?? "";
  currentUserEmail = storage.read(PREF_CURRENT_USER_EMAIL) ?? "";
  currentUserPhotoUrl = storage.read(PREF_CURRENT_USER_PHOTO_URL) ?? "";

  lastUpdateTime = storage.hasData(PREF_LAST_UPDATE_TIME) ? DateFormat("yyyy-MM-dd").parse(storage.read(PREF_LAST_UPDATE_TIME)) : DateTime.now();

  if (kDebugMode) {
    print('Prefs: Loaded saved preferences - isLoggedIn: $isLoggedIn, isAdminUser: $isAdminUser, userEmail: $currentUserEmail');
  }
}

saveIsAutoPlay(bool autoPlay) {
  isAutoPlay = autoPlay;
  storage.write(PREF_IS_AUTO_PLAY, isAutoPlay);
}

saveIsLoop(bool loop) {
  isLoop = loop;
  storage.write(PREF_IS_LOOP, isAutoPlay);
}

saveUpdateDateTime(DateTime dateTime) {
  lastUpdateTime = dateTime;
  storage.write(PREF_LAST_UPDATE_TIME, DateFormat("yyyy-MM-dd").format(dateTime));
}

saveLoginState(bool loggedIn) {
  isLoggedIn = loggedIn;
  storage.write(PREF_IS_LOGGED_IN, isLoggedIn);
}

saveAdminUser(bool admin) {
  isAdminUser = admin;
  storage.write(PREF_IS_ADMIN_USER, isAdminUser);
  if (kDebugMode) {
    print('Prefs: Saved admin status - isAdminUser: $isAdminUser');
  }
}

saveProductionEnvironment(bool isProd) {
  isProductionEnvironment = isProd;
  storage.write(PREF_IS_PRODUCTION_ENV, isProductionEnvironment);
}

saveCurrentUser(String userId, String userName, String userEmail, String photoUrl) {
  currentUserId = userId;
  currentUserName = userName;
  currentUserEmail = userEmail;
  currentUserPhotoUrl = photoUrl;

  storage.write(PREF_CURRENT_USER_ID, currentUserId);
  storage.write(PREF_CURRENT_USER_NAME, currentUserName);
  storage.write(PREF_CURRENT_USER_EMAIL, currentUserEmail);
  storage.write(PREF_CURRENT_USER_PHOTO_URL, currentUserPhotoUrl);
}

clearUserData() {
  isLoggedIn = false;
  isAdminUser = false;
  currentUserId = "";
  currentUserName = "";
  currentUserEmail = "";
  currentUserPhotoUrl = "";

  storage.remove(PREF_IS_LOGGED_IN);
  storage.remove(PREF_IS_ADMIN_USER);
  storage.remove(PREF_CURRENT_USER_ID);
  storage.remove(PREF_CURRENT_USER_NAME);
  storage.remove(PREF_CURRENT_USER_EMAIL);
  storage.remove(PREF_CURRENT_USER_PHOTO_URL);
}

bool isAndroid() {
  return defaultTargetPlatform == TargetPlatform.android;
}

bool isiOS() {
  return defaultTargetPlatform == TargetPlatform.iOS;
}

const PREF_IS_AUTO_PLAY = "pref.is.autoplay";
const PREF_IS_LOOP = "pref.is.loop";
const PREF_LAST_UPDATE_TIME = "pref.last.update.time";
const PREF_IS_LOGGED_IN = "pref.is.logged.in";
const PREF_IS_ADMIN_USER = "pref.is.admin.user";
const PREF_CURRENT_USER_ID = "pref.current.user.id";
const PREF_CURRENT_USER_NAME = "pref.current.user.name";
const PREF_CURRENT_USER_EMAIL = "pref.current.user.email";
const PREF_CURRENT_USER_PHOTO_URL = "pref.current.user.photo.url";
const PREF_APP_VERSION = "pref.app.version";
const PREF_IS_PRODUCTION_ENV = "pref.is.production.env";
