import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:politicsstatements/redesign/resources/rest_client.dart';
import 'package:politicsstatements/redesign/services/api_key_service.dart';
import 'package:politicsstatements/redesign/utils/constants.dart';

const String cdnBaseUrl = 'https://cdn.bolola.org';

enum UploadStep {
  idle,
  copyingFiles,
  convertingAudio,
  creatingItems,
  uploadingVideos,
  uploadingAudios,
  completed,
  failed,
}

class UploadProgress {
  final UploadStep step;
  final String message;
  final double overallProgress;
  final int currentIndex;
  final int totalCount;
  final String? error;

  const UploadProgress({
    required this.step,
    required this.message,
    this.overallProgress = 0,
    this.currentIndex = 0,
    this.totalCount = 0,
    this.error,
  });
}

class UploadItemData {
  String originalFileName;
  String originalFilePath;
  Uint8List? fileBytes;
  String armenianName;
  String alias;
  String fileName;
  int ordering;
  String keywords;
  String relatedKeywords;
  String groupAlias;
  String categoryAlias;

  UploadItemData({
    required this.originalFileName,
    required this.originalFilePath,
    this.fileBytes,
    required this.armenianName,
    required this.alias,
    required this.fileName,
    required this.ordering,
    this.keywords = '',
    this.relatedKeywords = '',
    required this.groupAlias,
    required this.categoryAlias,
  });

  String get videoFileName => '$fileName.mp4';
  String get audioFileName => '$fileName.mp3';

  String get videoUrl =>
      '$cdnBaseUrl/$categoryAlias/$groupAlias/videos/$videoFileName';
  String get audioUrl =>
      '$cdnBaseUrl/$categoryAlias/$groupAlias/audios/$audioFileName';
  String get imageUrl =>
      '$cdnBaseUrl/video_thumbnails/$categoryAlias/$groupAlias/$fileName.jpg';

  Map<String, dynamic> toItemJson() {
    List<String> keywordList = keywords
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();
    List<String> relatedKeywordList = relatedKeywords
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();
    return {
      'alias': alias,
      'name': armenianName,
      'fileName': fileName,
      'groupAlias': groupAlias,
      'categoryAlias': categoryAlias,
      'ordering': ordering,
      'shareCount': 0,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'sourceUrl': '',
      'imageUrl': imageUrl,
      'isFavorite': false,
      'keywords': keywordList,
      'relatedKeywords': relatedKeywordList,
    };
  }
}

class AdminUploadService {
  final Dio _dio = Dio();

  Future<String> _getApiKey() async {
    await ApiKeyService().waitForInitialization();
    final apiKey = bulki;
    if (apiKey == null) throw Exception('API key not available');
    return apiKey;
  }

  Map<String, String> _authHeaders(String apiKey) => {'x-api-key': apiKey};

  Future<Map<String, dynamic>> deleteItem(String alias) async {
    final apiKey = await _getApiKey();
    final response = await _dio.delete(
      '$baseUrl/delete-item/$alias',
      options: Options(headers: _authHeaders(apiKey)),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteGroup(String alias) async {
    final apiKey = await _getApiKey();
    final response = await _dio.delete(
      '$baseUrl/delete-group/$alias',
      options: Options(headers: _authHeaders(apiKey)),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteCategory(String alias) async {
    final apiKey = await _getApiKey();
    final response = await _dio.delete(
      '$baseUrl/delete-category/$alias',
      options: Options(headers: _authHeaders(apiKey)),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadThumbnailFromBytes(
      Uint8List bytes, String fileName) async {
    final apiKey = await _getApiKey();
    final formData = FormData.fromMap({
      'thumbnail': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final response = await _dio.post(
      '$baseUrl/upload-thumbnail',
      data: formData,
      options: Options(headers: _authHeaders(apiKey)),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCategory({
    required String alias,
    String? name,
    int? ordering,
  }) async {
    final apiKey = await _getApiKey();
    final data = <String, dynamic>{'alias': alias};
    if (name != null) data['name'] = name;
    if (ordering != null) data['ordering'] = ordering;
    final response = await _dio.post(
      '$baseUrl/update-category',
      data: data,
      options: Options(headers: _authHeaders(apiKey)),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateGroup({
    required String alias,
    String? name,
    String? categoryAlias,
    int? count,
    String? iconUrl,
    int? ordering,
    int? isNewGroup,
  }) async {
    final apiKey = await _getApiKey();
    final data = <String, dynamic>{'alias': alias};
    if (name != null) data['name'] = name;
    if (categoryAlias != null) data['categoryAlias'] = categoryAlias;
    if (count != null) data['count'] = count;
    if (iconUrl != null) data['iconUrl'] = iconUrl;
    if (ordering != null) data['ordering'] = ordering;
    if (isNewGroup != null) data['isNewGroup'] = isNewGroup;
    final response = await _dio.post(
      '$baseUrl/update-group',
      data: data,
      options: Options(headers: _authHeaders(apiKey)),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createCategory({
    required String alias,
    required String name,
    int ordering = 0,
  }) async {
    final apiKey = await _getApiKey();
    final response = await _dio.post(
      '$baseUrl/create-category',
      data: {
        'alias': alias,
        'name': name,
        'ordering': ordering,
        'groupNames': [],
      },
      options: Options(headers: _authHeaders(apiKey)),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createGroup({
    required String alias,
    required String name,
    required String categoryAlias,
    int count = 0,
    String iconUrl = '',
    int ordering = 0,
    int isNewGroup = 0,
  }) async {
    final apiKey = await _getApiKey();
    final response = await _dio.post(
      '$baseUrl/create-group',
      data: {
        'alias': alias,
        'name': name,
        'categoryAlias': categoryAlias,
        'count': count,
        'iconUrl': iconUrl,
        'ordering': ordering,
        'isNewGroup': isNewGroup,
      },
      options: Options(headers: _authHeaders(apiKey)),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> bulkAddItems(
      List<Map<String, dynamic>> items) async {
    final apiKey = await _getApiKey();
    final response = await _dio.post(
      '$baseUrl/bulk-add-items',
      data: {'items': items},
      options: Options(headers: _authHeaders(apiKey)),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> bulkUploadFiles({
    required String categoryAlias,
    required String groupAlias,
    required String type,
    required List<File> files,
    Function(double)? onProgress,
  }) async {
    final apiKey = await _getApiKey();
    List<MultipartFile> multipartFiles = [];
    for (File file in files) {
      multipartFiles.add(await MultipartFile.fromFile(
        file.path,
        filename: p.basename(file.path),
      ));
    }
    FormData formData = FormData.fromMap({
      'categoryAlias': categoryAlias,
      'groupAlias': groupAlias,
      'type': type,
      'files': multipartFiles,
    });
    final response = await _dio.post(
      '$baseUrl/bulk-upload-files',
      data: formData,
      options: Options(headers: _authHeaders(apiKey)),
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> bulkUploadFilesFromBytes({
    required String categoryAlias,
    required String groupAlias,
    required String type,
    required List<MapEntry<String, Uint8List>> namedFiles,
    Function(double)? onProgress,
  }) async {
    final apiKey = await _getApiKey();
    List<MultipartFile> multipartFiles = [];
    for (var entry in namedFiles) {
      multipartFiles.add(
        MultipartFile.fromBytes(entry.value, filename: entry.key),
      );
    }
    FormData formData = FormData.fromMap({
      'categoryAlias': categoryAlias,
      'groupAlias': groupAlias,
      'type': type,
      'files': multipartFiles,
    });
    final response = await _dio.post(
      '$baseUrl/bulk-upload-files',
      data: formData,
      options: Options(headers: _authHeaders(apiKey)),
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> processAndUpload({
    required List<UploadItemData> items,
    required Function(UploadProgress) onProgress,
  }) async {
    final totalSteps = 2;
    try {
      // Step 1: Create items in database (videoUrl and audioUrl are pre-set)
      onProgress(UploadProgress(
        step: UploadStep.creatingItems,
        message: 'Creating items in database...',
        overallProgress: 0.0,
        totalCount: items.length,
      ));
      final itemsJson = items.map((item) => item.toItemJson()).toList();
      await bulkAddItems(itemsJson);

      // Step 2: Upload video files (server handles audio conversion)
      onProgress(UploadProgress(
        step: UploadStep.uploadingVideos,
        message: 'Uploading video files...',
        overallProgress: 1.0 / totalSteps,
        totalCount: items.length,
      ));

      if (kIsWeb) {
        final namedFiles = <MapEntry<String, Uint8List>>[];
        for (var item in items) {
          if (item.fileBytes != null) {
            namedFiles.add(MapEntry(item.videoFileName, item.fileBytes!));
          }
        }
        if (namedFiles.isNotEmpty) {
          await bulkUploadFilesFromBytes(
            categoryAlias: items.first.categoryAlias,
            groupAlias: items.first.groupAlias,
            type: 'videos',
            namedFiles: namedFiles,
            onProgress: (progress) {
              onProgress(UploadProgress(
                step: UploadStep.uploadingVideos,
                message:
                    'Uploading videos: ${(progress * 100).toStringAsFixed(0)}%',
                overallProgress: (1.0 + progress) / totalSteps,
              ));
            },
          );
        }
      } else {
        final tempDir = await getTemporaryDirectory();
        final videosDir = Directory(p.join(tempDir.path, 'uploadingVideos'));
        if (await videosDir.exists()) {
          await videosDir.delete(recursive: true);
        }
        await videosDir.create(recursive: true);

        List<File> renamedVideoFiles = [];
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          final destPath = p.join(videosDir.path, item.videoFileName);
          await File(item.originalFilePath).copy(destPath);
          renamedVideoFiles.add(File(destPath));
          onProgress(UploadProgress(
            step: UploadStep.copyingFiles,
            message:
                'Preparing ${i + 1}/${items.length}: ${item.videoFileName}',
            overallProgress:
                (1.0 + (i + 1) / items.length * 0.3) / totalSteps,
            currentIndex: i + 1,
            totalCount: items.length,
          ));
        }

        await bulkUploadFiles(
          categoryAlias: items.first.categoryAlias,
          groupAlias: items.first.groupAlias,
          type: 'videos',
          files: renamedVideoFiles,
          onProgress: (progress) {
            onProgress(UploadProgress(
              step: UploadStep.uploadingVideos,
              message:
                  'Uploading videos: ${(progress * 100).toStringAsFixed(0)}%',
              overallProgress: (1.0 + 0.3 + progress * 0.7) / totalSteps,
            ));
          },
        );

        try {
          if (await videosDir.exists()) {
            await videosDir.delete(recursive: true);
          }
        } catch (_) {}
      }

      onProgress(UploadProgress(
        step: UploadStep.completed,
        message:
            'Upload completed! ${items.length} items added successfully.',
        overallProgress: 1.0,
        totalCount: items.length,
      ));
    } catch (e) {
      onProgress(UploadProgress(
        step: UploadStep.failed,
        message: 'Upload failed: ${e.toString()}',
        error: e.toString(),
      ));
    }
  }
}
