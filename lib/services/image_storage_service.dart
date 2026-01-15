import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service for storing recipe images in Supabase Storage
/// Downloads images from external URLs and uploads them to Supabase Storage
/// to ensure they persist permanently
class ImageStorageService {
  ImageStorageService._();
  static final ImageStorageService instance = ImageStorageService._();

  static const String _bucketName = 'recipe-images';
  static const int _maxImageSize = 5 * 1024 * 1024; // 5MB max

  SupabaseClient get _client => SupabaseService.client;

  /// Upload an image from a URL to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String?> uploadImageFromUrl({
    required String imageUrl,
    required String recipeId,
    String? fileName,
  }) async {
    try {
      // Download image from URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        print('Failed to download image: ${response.statusCode}');
        return null;
      }

      final imageBytes = response.bodyBytes;
      if (imageBytes.length > _maxImageSize) {
        print('Image too large: ${imageBytes.length} bytes');
        return null;
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getFileExtension(imageUrl);
      final finalFileName = fileName ?? 'recipe-$recipeId-$timestamp$extension';
      final storagePath = '$recipeId/$finalFileName';

      // Upload to Supabase Storage (using bytes)
      await _client.storage.from(_bucketName).uploadBinary(
        storagePath,
        imageBytes,
        fileOptions: FileOptions(
          contentType: _getContentType(extension),
          upsert: false,
        ),
      );

      // Get public URL
      final publicUrl = _client.storage.from(_bucketName).getPublicUrl(storagePath);
      
      print('Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Upload an image file directly to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String?> uploadImageFile({
    required File imageFile,
    required String recipeId,
    String? fileName,
  }) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      if (imageBytes.length > _maxImageSize) {
        print('Image too large: ${imageBytes.length} bytes');
        return null;
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getFileExtension(imageFile.path);
      final finalFileName = fileName ?? 'recipe-$recipeId-$timestamp$extension';
      final storagePath = '$recipeId/$finalFileName';

      // Upload to Supabase Storage (using bytes)
      await _client.storage.from(_bucketName).uploadBinary(
        storagePath,
        imageBytes,
        fileOptions: FileOptions(
          contentType: _getContentType(extension),
          upsert: false,
        ),
      );

      // Get public URL
      final publicUrl = _client.storage.from(_bucketName).getPublicUrl(storagePath);
      
      print('Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading image file: $e');
      return null;
    }
  }

  /// Delete an image from Supabase Storage
  Future<bool> deleteImage(String storagePath) async {
    try {
      await _client.storage.from(_bucketName).remove([storagePath]);
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Extract file extension from URL or path
  String _getFileExtension(String urlOrPath) {
    final uri = Uri.tryParse(urlOrPath);
    if (uri != null && uri.path.isNotEmpty) {
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1 && lastDot < path.length - 1) {
        return path.substring(lastDot);
      }
    }
    // Default to .jpg if no extension found
    return '.jpg';
  }

  /// Get content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  /// Check if a URL is already a Supabase Storage URL
  bool isSupabaseStorageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('supabase.co') && 
             uri.path.contains('/storage/v1/object/public/');
    } catch (_) {
      return false;
    }
  }
}
