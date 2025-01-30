import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/constants.dart';

class FileHelper {
  static Future<String> saveFile(File file, String directory) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          '${const Uuid().v4()}_${DateTime.now().millisecondsSinceEpoch}${extension(file.path)}';
      final String filePath = '${appDir.path}/$directory/$fileName';

      // Create directory if it doesn't exist
      final Directory dir = Directory('${appDir.path}/$directory');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Copy file to app directory
      await file.copy(filePath);
      return filePath;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  static Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  static String extension(String path) {
    return path.substring(path.lastIndexOf('.'));
  }

  static bool isValidFileSize(File file) {
    return file.lengthSync() <= AppConstants.maxAttachmentSize;
  }

  static Future<String> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.length();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return '0 B';
    }
  }

  static bool isImage(String path) {
    final ext = extension(path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif'].contains(ext);
  }

  static bool isPDF(String path) {
    return extension(path).toLowerCase() == '.pdf';
  }

  static Future<void> clearDirectory(String directory) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/$directory');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      throw Exception('Failed to clear directory: $e');
    }
  }

  static Future<int> getDirectorySize(String directory) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/$directory');
      if (!await dir.exists()) {
        return 0;
      }

      int size = 0;
      await for (final file in dir.list(recursive: true)) {
        if (file is File) {
          size += await file.length();
        }
      }
      return size;
    } catch (e) {
      return 0;
    }
  }
}
