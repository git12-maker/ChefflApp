import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

/// Service for camera and image picker functionality
class CameraService {
  CameraService._();
  static final CameraService instance = CameraService._();

  final ImagePicker _picker = ImagePicker();

  /// Request camera permission with settings fallback
  Future<bool> requestCameraPermission() async {
    // On web/desktop, permission_handler is not needed
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    // Check current status
    var status = await Permission.camera.status;

    // If already granted, return true
    if (status.isGranted) {
      return true;
    }

    // If denied, request permission (this will show the iOS permission dialog)
    if (status.isDenied) {
      status = await Permission.camera.request();
      
      if (status.isGranted) {
        return true;
      }
    }

    // If permanently denied or restricted, open app settings
    if (status.isPermanentlyDenied || status.isRestricted) {
      // On iOS, we need to show a dialog first before opening settings
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Request gallery/photos permission with settings fallback
  Future<bool> requestGalleryPermission() async {
    // On web/desktop, permission_handler is not needed
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    // Use photos permission on both platforms (permission_handler handles mapping)
    final status = await Permission.photos.status;

    if (status.isGranted) return true;

    final result = await Permission.photos.request();

    if (result.isGranted) {
      return true;
    }

    if (result.isPermanentlyDenied || result.isRestricted) {
      await openAppSettings();
    }

    return false;
  }

  /// Take a photo using the camera
  /// 
  /// Best Practice: On iOS, image_picker automatically requests camera permission
  /// when pickImage is called with ImageSource.camera. We should let it handle
  /// the permission request natively to ensure iOS properly registers it.
  Future<File?> takePhoto() async {
    try {
      if (Platform.isAndroid) {
        // On Android, explicitly request permission first
        final hasPermission = await requestCameraPermission();
        if (!hasPermission) {
          throw Exception(
            'Camera permission denied. Please enable camera access in your device settings.',
          );
        }
      }
      // On iOS: Let image_picker handle the permission request natively
      // This ensures iOS properly registers the permission and shows it in Settings
      // image_picker will automatically show the iOS permission dialog when needed

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return null;

      final file = File(image.path);
      
      // Compress image if too large (max 1MB)
      final compressedFile = await _compressImage(file);
      
      return compressedFile;
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // Check if it's a permission error
      if (errorMessage.toLowerCase().contains('permission') || 
          errorMessage.toLowerCase().contains('camera')) {
        if (Platform.isIOS) {
          // On iOS, guide user to Settings
          throw Exception(
            'Camera access is required. Please enable it in Settings > Cheffl > Camera.',
          );
        } else {
          throw Exception(
            'Camera permission denied. Please enable camera access in your device settings.',
          );
        }
      }
      
      throw Exception('Failed to take photo: $errorMessage');
    }
  }

  /// Pick an image from gallery
  Future<File?> pickFromGallery() async {
    try {
      // Request gallery permission
      final hasPermission = await requestGalleryPermission();
      if (!hasPermission && Platform.isAndroid) {
        throw Exception('Gallery permission denied');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return null;

      final file = File(image.path);
      
      // Compress image if too large (max 1MB)
      final compressedFile = await _compressImage(file);
      
      return compressedFile;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Compress image to max 1MB for API efficiency
  /// Runs on background isolate for better performance
  Future<File> _compressImage(File file) async {
    // Run compression in compute isolate to avoid blocking UI
    return await compute(_compressImageIsolate, file.path);
  }
}

/// Top-level function for isolate (required by compute)
Future<File> _compressImageIsolate(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final sizeInMB = bytes.length / (1024 * 1024);

    // If already under 1MB, return as is
    if (sizeInMB <= 1.0) {
      return file;
    }

    // Decode image
    final image = img.decodeImage(bytes);
    if (image == null) return file;

    // Calculate compression quality (target ~800KB)
    int quality = 85;
    if (sizeInMB > 2.0) {
      quality = 70;
    } else if (sizeInMB > 1.5) {
      quality = 75;
    } else if (sizeInMB > 1.2) {
      quality = 80;
    }

    // Compress
    var compressedBytes = Uint8List.fromList(
      img.encodeJpg(image, quality: quality),
    );

    // Check if still too large, resize if needed
    if (compressedBytes.length > 1024 * 1024) {
      // Resize to max 1920px width while maintaining aspect ratio
      final maxDimension = 1920;
      final aspectRatio = image.width / image.height;
      int newWidth, newHeight;
      
      if (image.width > image.height) {
        newWidth = maxDimension;
        newHeight = (maxDimension / aspectRatio).round();
      } else {
        newHeight = maxDimension;
        newWidth = (maxDimension * aspectRatio).round();
      }
      
      final resized = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
      );
      compressedBytes = Uint8List.fromList(
        img.encodeJpg(resized, quality: 75),
      );
    }

    // Write compressed file
    final compressedFile = File(filePath.replaceAll('.jpg', '_compressed.jpg')
        .replaceAll('.png', '_compressed.jpg'));
    await compressedFile.writeAsBytes(compressedBytes);
    return compressedFile;
}
