import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';

class DownloadService {
  static Future<String?> saveTextFile({
    required String filename,
    required String content,
  }) async {
    final bytes = Uint8List.fromList(content.codeUnits);
    return _saveBytes(
      filename: filename,
      bytes: bytes,
      fileExtension: 'txt',
      mimeType: MimeType.text,
    );
  }

  static Future<String?> saveCsvFile({
    required String filename,
    required String content,
  }) async {
    final bytes = Uint8List.fromList(content.codeUnits);
    return _saveBytes(
      filename: filename,
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  static Future<String?> _saveBytes({
    required String filename,
    required Uint8List bytes,
    required String fileExtension,
    required MimeType mimeType,
  }) async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      final selectedPath = await FileSaver.instance.saveAs(
        name: filename,
        bytes: bytes,
        fileExtension: fileExtension,
        mimeType: mimeType,
      );
      if (selectedPath != null && selectedPath.isNotEmpty) {
        return selectedPath;
      }
    }

    return FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      fileExtension: fileExtension,
      mimeType: mimeType,
    );
  }
}
