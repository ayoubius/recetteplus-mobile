import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'app_constants.dart';

class ImageUtils {
  /// Valider le format d'une image
  static bool isValidImageFormat(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return AppConstants.supportedImageFormats.contains(extension);
  }

  /// Valider la taille d'une image
  static bool isValidImageSize(Uint8List imageBytes) {
    return imageBytes.length <= AppConstants.maxImageSize;
  }

  /// Obtenir l'extension d'un fichier
  static String getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  /// Générer un nom de fichier unique
  static String generateUniqueFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = getFileExtension(originalName);
    return '${timestamp}_${originalName.split('.').first}.$extension';
  }

  /// Valider une URL d'image
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             AppConstants.supportedImageFormats.any(
               (format) => url.toLowerCase().endsWith('.$format')
             );
    } catch (e) {
      return false;
    }
  }

  /// Obtenir une URL d'image placeholder
  static String getPlaceholderImageUrl({
    int width = 400,
    int height = 300,
    String text = 'Image',
  }) {
    return 'https://via.placeholder.com/${width}x$height/FF6B35/FFFFFF?text=$text';
  }

  /// Redimensionner une image (simulation - nécessiterait une vraie implémentation)
  static Future<Uint8List?> resizeImage(
    Uint8List imageBytes, {
    int? maxWidth,
    int? maxHeight,
    int quality = 85,
  }) async {
    try {
      // TODO: Implémenter le redimensionnement réel avec image package
      // Pour l'instant, retourner l'image originale si elle est dans les limites
      if (imageBytes.length <= AppConstants.maxImageSize) {
        return imageBytes;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur redimensionnement image: $e');
      }
      return null;
    }
  }

  /// Compresser une image (simulation)
  static Future<Uint8List?> compressImage(
    Uint8List imageBytes, {
    int quality = 85,
  }) async {
    try {
      // TODO: Implémenter la compression réelle
      return imageBytes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur compression image: $e');
      }
      return null;
    }
  }

  /// Obtenir les dimensions d'une image (simulation)
  static Future<Map<String, int>?> getImageDimensions(Uint8List imageBytes) async {
    try {
      // TODO: Implémenter la lecture des dimensions réelles
      return {'width': 400, 'height': 300};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lecture dimensions: $e');
      }
      return null;
    }
  }

  /// Convertir une image en base64
  static String imageToBase64(Uint8List imageBytes) {
    return base64Encode(imageBytes);
  }

  /// Convertir du base64 en image
  static Uint8List base64ToImage(String base64String) {
    return base64Decode(base64String);
  }
}