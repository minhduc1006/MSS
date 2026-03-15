import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

class DownloadService {
  static Future<void> saveTextFile({
    required String filename,
    required String content,
  }) async {
    final bytes = Uint8List.fromList(content.codeUnits);
    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      fileExtension: 'txt',
      mimeType: MimeType.text,
    );
  }

  static Future<void> saveCsvFile({
    required String filename,
    required String content,
  }) async {
    final bytes = Uint8List.fromList(content.codeUnits);
    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }
}
