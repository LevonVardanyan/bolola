import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:politicsstatements/redesign/resources/prefs.dart';
import 'package:politicsstatements/redesign/resources/sourceData.dart';
import 'package:share_plus/share_plus.dart';

import '../resources/models/media_item.dart';

Color? getCheckboxColor(Set<MaterialState> states) {
  const Set<MaterialState> interactiveStates = <MaterialState>{
    MaterialState.pressed,
    MaterialState.hovered,
    MaterialState.focused,
  };
  if (states.any(interactiveStates.contains)) {
    return Colors.blue;
  }
  return Colors.red;
}

Future<String> getDeviceId() async {
  return await FlutterUdid.consistentUdid;
}

String decimalIntegerPartPreview(double price) {
  return double.parse(price.toStringAsFixed(2)).round().toString();
}

int decimalIntegerPart(double price) {
  return double.parse(price.toStringAsFixed(2)).round();
}

Future<bool> isWifiEnabled() async {
  final List<ConnectivityResult> result = await Connectivity().checkConnectivity();

  if (result.contains(ConnectivityResult.wifi)) {
    return true;
  } else {
    return false;
  }
}

Future<bool> isMobileDataEnabled() async {
  final List<ConnectivityResult> result = await Connectivity().checkConnectivity();

  if (await checkInternet() || !result.contains(ConnectivityResult.wifi)) {
    return true;
  } else {
    return false;
  }
}

Future<bool> checkInternet() async {
  if (kIsWeb) {
    isInternetConnected = true;
  } else {
    try {
      final response = await Dio().get('https://google.com');
      if (response.statusCode == 200) {
        isInternetConnected = true;
      } else {
        isInternetConnected = false;
      }
    } on Exception catch (_) {
      isInternetConnected = false;
    }
  }
  return isInternetConnected;
}
//
// bool isNullOrEmpty(String? value) {
//   return value == null || value.isEmpty == true;
// }
// bool isNullOrZero(int? value) {
//   return value == null || value == 0;
// }
//
// bool isValidEmail(String email) {
//   return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
// }

String makeBase64(String text) {
  var bytes = utf8.encode(text);
  var base64Str = base64.encode(bytes);
  return base64Str;
}

void showToast(String message) {
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: Colors.black54,
      textColor: Colors.white70,
      fontSize: (16));
}

removeFile(String fileName) async {
  if (kIsWeb) {
    // On web, file operations are not supported in the same way
    return;
  }

  final Directory directory = await getApplicationDocumentsDirectory();
  final File file = File('${directory.path}/${fileName}');
  file.delete();
}

writeOnFile(String text, String fileName) async {
  if (kIsWeb) {
    // On web, use localStorage or other web storage mechanisms
    return;
  }

  final Directory directory = await getApplicationDocumentsDirectory();
  final File file = File('${directory.path}/${fileName}');
  file.writeAsStringSync(text);
  print("success write");
}

Future<String?> readFromFile(String fileName) async {
  if (kIsWeb) {
    // On web, use localStorage or other web storage mechanisms
    return null;
  }

  String? text = null;
  try {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/${fileName}');
    text = await file.readAsString();
  } catch (e) {
    return null;
  }
  return text;
}

downloadFromUrlToPath(String path, String url, Function() complete) async {
  if (kIsWeb) {
    // On web, downloads are handled differently by the browser
    complete();
    return;
  }

  await Dio().download(
    url,
    path,
    onReceiveProgress: (rcv, total) {
      if (rcv == total) {
        complete();
      }
    },
    deleteOnError: false,
  );
}

Future<String> getVideoFilePath(videoName, folder) async {
  if (kIsWeb) {
    // On web, return empty path since we don't cache files locally
    return '';
  }

  String path = '';
  Directory dir = Directory("${(await getApplicationSupportDirectory()).path}/Bolola/$folder");
  dir.create(recursive: true);
  path = '${dir.path}/$videoName.mp4';
  return path;
}

Future<String> getVideoSaveFilePath(videoName, folder) async {
  if (kIsWeb) {
    // On web, downloads are handled by the browser
    return '';
  }

  String path = '';
  Directory dir = Directory("${(await getExternalStorageDirectory())?.path}/Bolola");
  dir.create(recursive: true);
  path = '${dir.path}/$videoName.mp4';
  return path;
}

Future<String> getVideoThumbFilePath(videoName, folder) async {
  if (kIsWeb) {
    // On web, return empty path since we don't cache files locally
    return '';
  }

  String path = '';
  Directory dir = Directory("${(await getApplicationSupportDirectory()).path}/Bolola/$folder");
  dir.create(recursive: true);
  path = '${dir.path}';
  return path;
}

String getVideoThumbFileName(videoName, category, group) {
  return isAndroid() ? Uri.encodeComponent("videoCategories/$category/$group/$videoName.jpg") : "$videoName.jpg";
}

Future<String> getAudioFilePath(audioName, folder) async {
  if (kIsWeb) {
    // On web, return empty path since we don't cache files locally
    return '';
  }

  String path = '';
  Directory dir = Directory("${(await getApplicationSupportDirectory()).path}/Bolola/$folder");
  dir.create(recursive: true);
  path = '${dir.path}/$audioName.mp3';
  return path;
}

Future<String> getAudioSaveFilePath(audioName, folder) async {
  if (kIsWeb) {
    // On web, downloads are handled by the browser
    return '';
  }

  String path = '';
  Directory dir = Directory("${(await getDownloadsDirectory())?.path}");
  dir.create(recursive: true);
  path = '${dir.path}/$audioName.mp3';
  return path;
}

Future<String> getAudioTempFilePath(audioName, folder) async {
  if (kIsWeb) {
    // On web, return empty path since we don't use temporary files
    return '';
  }

  String path = '';
  Directory dir = Directory("${(await getTemporaryDirectory()).path}/Bolola/$folder");
  dir.create(recursive: true);
  path = '${dir.path}/$audioName.mp3';
  return path;
}

String generateMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

closeKeyboard(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  FocusScope.of(context).requestFocus(FocusNode());
}

int compareStrings(String str1, String str2) {
  int minLength = str1.length < str2.length ? str1.length : str2.length;
  int differences = 0;

  for (int i = 0; i < minLength; i++) {
    var s1 = str1[i];
    var s2 = str2[i];
    if (s1 != s2) {
      if ((similars1.contains(s1) && similars1.contains(s2)) ||
          (similars11.contains(s1) && similars11.contains(s2)) ||
          (similars2.contains(s1) && similars2.contains(s2)) ||
          (similars22.contains(s1) && similars22.contains(s2)) ||
          (similars3.contains(s1) && similars3.contains(s2)) ||
          (similars4.contains(s1) && similars4.contains(s2)) ||
          (similars5.contains(s1) && similars5.contains(s2)) ||
          (similars55.contains(s1) && similars55.contains(s2)) ||
          (similars6.contains(s1) && similars6.contains(s2)) ||
          (similars7.contains(s1) && similars7.contains(s2))) {
      } else {
        differences++;
      }
    }
  }

  return differences;
}

var similars1 = ["տ", "դ", "թ"];
var similars11 = ["t", "d"];
var similars2 = ["գ", "կ", "ք"];
var similars22 = ["g", "k", "q"];
var similars3 = ["ջ", "ճ", "չ"];
var similars4 = ["ձ", "ծ", "ց"];
var similars5 = ["պ", "բ", "փ"];
var similars55 = ["p", "b"];
var similars6 = ["ղ", "խ"];
var similars7 = ["ռ", "ր"];

bool isDayBeforeToday(DateTime date) {
  final now = DateTime.now();
  final yesterday = DateTime.now().subtract(Duration(days: 1));
  return date.isBefore(yesterday) || isSameDay(date, yesterday);
}

bool isSameDay(DateTime? first, DateTime? second) {
  return first?.year == second?.year && first?.month == second?.month && first?.day == second?.day;
}

sendEvent(String event, Map<String, Object> params) async {
  await FirebaseAnalytics.instance.logEvent(
    name: event,
    parameters: params,
  );
}
