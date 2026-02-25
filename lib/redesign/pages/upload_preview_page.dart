import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:politicsstatements/redesign/resources/theme.dart';
import 'package:politicsstatements/redesign/services/admin_upload_service.dart';
import 'package:politicsstatements/redesign/utils/armenian_transliterator.dart';
import 'package:path/path.dart' as p;

class UploadPreviewPage extends StatefulWidget {
  final List<PlatformFile> pickedFiles;
  final String groupAlias;
  final String categoryAlias;

  const UploadPreviewPage({
    Key? key,
    required this.pickedFiles,
    required this.groupAlias,
    required this.categoryAlias,
  }) : super(key: key);

  @override
  State<UploadPreviewPage> createState() => _UploadPreviewPageState();
}

class _UploadPreviewPageState extends State<UploadPreviewPage> {
  late List<_ItemEditorState> _itemStates;
  bool _isUploading = false;
  UploadProgress? _currentProgress;

  @override
  void initState() {
    super.initState();
    _itemStates = widget.pickedFiles.map((file) {
      final fileNameNoExt = p.basenameWithoutExtension(file.name);
      final extension = p.extension(file.name);
      final armenianName =
          ArmenianTransliterator.transliterateToArmenian(fileNameNoExt);
      final renamedBase = ArmenianTransliterator.renameAlias(fileNameNoExt);
      final ordering = ArmenianTransliterator.extractOrdering(fileNameNoExt);

      VideoPlayerController? videoController;
      if (!kIsWeb && file.path != null) {
        videoController = VideoPlayerController.file(File(file.path!));
      }

      final fullAlias =
          '${renamedBase}_${widget.categoryAlias}_${widget.groupAlias}';

      return _ItemEditorState(
        originalFileName: file.name,
        originalFilePath: file.path,
        fileBytes: file.bytes,
        extension: extension,
        nameController: TextEditingController(text: armenianName),
        aliasController: TextEditingController(text: fullAlias),
        fileNameController: TextEditingController(text: renamedBase),
        originalFileNameController: TextEditingController(text: file.name),
        orderingController: TextEditingController(text: ordering.toString()),
        keywordsController: TextEditingController(),
        relatedKeywordsController: TextEditingController(),
        videoController: videoController,
      );
    }).toList();

    for (var item in _itemStates) {
      item.videoController?.initialize().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (var item in _itemStates) {
      item.dispose();
    }
    super.dispose();
  }

  List<UploadItemData> _buildUploadItems() {
    return _itemStates.map((item) {
      return UploadItemData(
        originalFileName: item.originalFileName,
        originalFilePath: item.originalFilePath ?? '',
        fileBytes: item.fileBytes,
        armenianName: item.nameController.text.trim(),
        alias: item.aliasController.text.trim(),
        fileName: item.fileNameController.text.trim(),
        ordering: int.tryParse(item.orderingController.text.trim()) ?? 100,
        keywords: item.keywordsController.text.trim(),
        relatedKeywords: item.relatedKeywordsController.text.trim(),
        groupAlias: widget.groupAlias,
        categoryAlias: widget.categoryAlias,
      );
    }).toList();
  }

  void _updateFileName(_ItemEditorState item) {
    setState(() {});
  }

  Future<void> _startUpload() async {
    setState(() => _isUploading = true);
    final items = _buildUploadItems();
    final service = AdminUploadService();
    await service.processAndUpload(
      items: items,
      onProgress: (progress) {
        if (mounted) {
          setState(() => _currentProgress = progress);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'Upload Preview (${_itemStates.length} files)',
          style: AppTheme.headingSStyle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: _isUploading ? null : () => Navigator.pop(context),
        ),
        actions: [
          if (!_isUploading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: _startUpload,
                icon: const Icon(Icons.cloud_upload, size: 18),
                label: const Text('Upload All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: AppTheme.primaryDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
        ],
      ),
      body: _isUploading ? _buildProgressView() : _buildPreviewList(),
    );
  }

  Widget _buildProgressView() {
    final progress = _currentProgress;
    if (progress == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accentCyan));
    }

    IconData stepIcon;
    Color stepColor;
    switch (progress.step) {
      case UploadStep.copyingFiles:
        stepIcon = Icons.file_copy;
        stepColor = AppTheme.accentCyan;
        break;
      case UploadStep.convertingAudio:
        stepIcon = Icons.audiotrack;
        stepColor = AppTheme.accentPurple;
        break;
      case UploadStep.creatingItems:
        stepIcon = Icons.storage;
        stepColor = AppTheme.accentOrange;
        break;
      case UploadStep.uploadingVideos:
        stepIcon = Icons.videocam;
        stepColor = AppTheme.accentCyan;
        break;
      case UploadStep.uploadingAudios:
        stepIcon = Icons.music_note;
        stepColor = AppTheme.accentGreen;
        break;
      case UploadStep.completed:
        stepIcon = Icons.check_circle;
        stepColor = AppTheme.accentGreen;
        break;
      case UploadStep.failed:
        stepIcon = Icons.error;
        stepColor = AppTheme.accentMagenta;
        break;
      default:
        stepIcon = Icons.hourglass_empty;
        stepColor = AppTheme.textSecondary2;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(stepIcon, size: 64, color: stepColor),
            const SizedBox(height: 24),
            Text(progress.message,
                style: AppTheme.strongStyle, textAlign: TextAlign.center),
            if (progress.overallProgress > 0 &&
                progress.step != UploadStep.completed &&
                progress.step != UploadStep.failed) ...[
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.overallProgress,
                  minHeight: 8,
                  backgroundColor: AppTheme.dividerDark,
                  valueColor: AlwaysStoppedAnimation<Color>(stepColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress.overallProgress * 100).toStringAsFixed(0)}%',
                style: AppTheme.mediaItemDurationStyle,
              ),
            ],
            if (progress.currentIndex > 0 && progress.totalCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${progress.currentIndex} / ${progress.totalCount}',
                style: AppTheme.mediaItemSubtitleStyle,
              ),
            ],
            if (progress.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentMagenta.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.accentMagenta.withValues(alpha: 0.3)),
                ),
                child: Text(
                  progress.error!,
                  style: const TextStyle(
                      color: AppTheme.accentMagenta, fontSize: 13),
                ),
              ),
            ],
            if (progress.step == UploadStep.completed ||
                progress.step == UploadStep.failed) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(
                    context, progress.step == UploadStep.completed),
                style: ElevatedButton.styleFrom(
                  backgroundColor: progress.step == UploadStep.completed
                      ? AppTheme.accentGreen
                      : AppTheme.accentMagenta,
                  foregroundColor: AppTheme.primaryDark,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(progress.step == UploadStep.completed
                    ? 'Done'
                    : 'Close'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.surfaceDark,
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: AppTheme.textSecondary2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Group: ${widget.groupAlias} | Category: ${widget.categoryAlias}',
                  style: AppTheme.mediaItemSubtitleStyle,
                ),
              ),
              if (kIsWeb) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.accentOrange),
                  ),
                  child: const Text(
                    'Web: no audio conversion',
                    style: TextStyle(
                      color: AppTheme.accentOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 380,
            ),
            itemCount: _itemStates.length,
            itemBuilder: (context, index) => _buildItemCard(index),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(int index) {
    final item = _itemStates[index];
    final hasVideo = item.videoController != null;
    final isInitialized =
        hasVideo && item.videoController!.value.isInitialized;

    return Card(
      color: AppTheme.cardDark,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.mediaCardRadius)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('#${index + 1}',
                      style: const TextStyle(
                          color: AppTheme.accentCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.originalFileName,
                      style: const TextStyle(
                          color: AppTheme.textSecondary2, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildSmallField(item.nameController, 'Armenian Name',
                  icon: Icons.translate),
              const SizedBox(height: 6),
              _buildSmallField(item.aliasController, 'Alias',
                  icon: Icons.drive_file_rename_outline,
                  onChanged: (_) => _updateFileName(item)),
              const SizedBox(height: 6),
              _buildSmallField(item.fileNameController, 'File Name',
                  icon: Icons.insert_drive_file, readOnly: true),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildSmallField(
                        item.orderingController, 'Ordering',
                        icon: Icons.sort,
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: _buildSmallField(
                        item.keywordsController, 'Keywords',
                        icon: Icons.label),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _buildSmallField(
                  item.relatedKeywordsController, 'Related Keywords',
                  icon: Icons.link),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.videocam,
                      size: 12, color: AppTheme.textSecondary2),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      '${item.fileNameController.text}.mp4',
                      style: const TextStyle(
                          color: AppTheme.textSecondary2, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.audiotrack,
                      size: 12, color: AppTheme.textSecondary2),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      '${item.fileNameController.text}.mp3',
                      style: const TextStyle(
                          color: AppTheme.textSecondary2, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallField(
    TextEditingController controller,
    String label, {
    IconData? icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppTheme.textSecondary2, fontSize: 11),
        prefixIcon: icon != null
            ? Icon(icon, size: 16, color: AppTheme.textSecondary2)
            : null,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 32, minHeight: 0),
        filled: true,
        fillColor: readOnly
            ? AppTheme.primaryDark.withValues(alpha: 0.5)
            : AppTheme.surfaceDark,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppTheme.dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppTheme.dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppTheme.accentCyan),
        ),
      ),
    );
  }
}

class _ItemEditorState {
  final String originalFileName;
  final String? originalFilePath;
  final Uint8List? fileBytes;
  final String extension;
  final TextEditingController nameController;
  final TextEditingController aliasController;
  final TextEditingController fileNameController;
  final TextEditingController originalFileNameController;
  final TextEditingController orderingController;
  final TextEditingController keywordsController;
  final TextEditingController relatedKeywordsController;
  final VideoPlayerController? videoController;

  _ItemEditorState({
    required this.originalFileName,
    this.originalFilePath,
    this.fileBytes,
    required this.extension,
    required this.nameController,
    required this.aliasController,
    required this.fileNameController,
    required this.originalFileNameController,
    required this.orderingController,
    required this.keywordsController,
    required this.relatedKeywordsController,
    this.videoController,
  });

  void dispose() {
    nameController.dispose();
    aliasController.dispose();
    fileNameController.dispose();
    originalFileNameController.dispose();
    orderingController.dispose();
    keywordsController.dispose();
    relatedKeywordsController.dispose();
    videoController?.dispose();
  }
}
