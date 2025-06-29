import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_utils.dart';

class ImageService {
  static final SupabaseClient _client = Supabase.instance.client;
  static final ImagePicker _picker = ImagePicker();

  /// Sélectionner une image depuis la galerie ou l'appareil photo
  static Future<Uint8List?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (image == null) return null;

      // Lire les bytes de l'image
      final Uint8List imageBytes = await image.readAsBytes();

      // Valider la taille
      if (!ImageUtils.isValidImageSize(imageBytes)) {
        throw Exception('Image trop volumineuse (max 5MB)');
      }

      // Valider le format
      if (!ImageUtils.isValidImageFormat(image.name)) {
        throw Exception('Format d\'image non supporté');
      }

      return imageBytes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur sélection image: $e');
      }
      rethrow;
    }
  }

  /// Uploader un avatar utilisateur
  static Future<String?> uploadAvatar({
    required Uint8List imageBytes,
    required String userId,
    String? oldAvatarUrl,
  }) async {
    try {
      // Supprimer l'ancien avatar s'il existe
      if (oldAvatarUrl != null) {
        await deleteAvatar(oldAvatarUrl);
      }

      // Générer un nom de fichier unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId/avatar_$timestamp.jpg';

      // Uploader vers Supabase Storage
      await _client.storage.from('avatars').uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      // Obtenir l'URL publique
      final publicUrl = _client.storage.from('avatars').getPublicUrl(fileName);

      // Mettre à jour le profil avec la nouvelle URL
      await _client.rpc('update_profile_avatar', params: {
        'user_id': userId,
        'avatar_url': publicUrl,
      });

      if (kDebugMode) {
        print('✅ Avatar uploadé avec succès: $publicUrl');
      }

      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur upload avatar: $e');
      }
      rethrow;
    }
  }

  /// Supprimer un avatar
  static Future<void> deleteAvatar(String avatarUrl) async {
    try {
      // Extraire le chemin du fichier de l'URL
      final uri = Uri.parse(avatarUrl);
      final pathSegments = uri.pathSegments;
      
      // Trouver l'index du segment 'avatars'
      final avatarsIndex = pathSegments.indexOf('avatars');
      if (avatarsIndex == -1 || avatarsIndex >= pathSegments.length - 1) {
        if (kDebugMode) {
          print('⚠️  URL d\'avatar invalide: $avatarUrl');
        }
        return;
      }

      // Construire le chemin du fichier
      final filePath = pathSegments.sublist(avatarsIndex + 1).join('/');

      // Supprimer du storage
      await _client.storage.from('avatars').remove([filePath]);

      if (kDebugMode) {
        print('✅ Avatar supprimé: $filePath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur suppression avatar: $e');
      }
      // Ne pas faire échouer l'opération pour une erreur de suppression
    }
  }

  /// Redimensionner une image (placeholder pour une vraie implémentation)
  static Future<Uint8List> resizeImage(
    Uint8List imageBytes, {
    int maxWidth = 400,
    int maxHeight = 400,
  }) async {
    // TODO: Implémenter le redimensionnement réel avec le package image
    // Pour l'instant, retourner l'image originale
    return imageBytes;
  }

  /// Compresser une image (placeholder pour une vraie implémentation)
  static Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int quality = 85,
  }) async {
    // TODO: Implémenter la compression réelle
    // Pour l'instant, retourner l'image originale
    return imageBytes;
  }

  /// Afficher un sélecteur de source d'image
  static Future<ImageSource?> showImageSourceSelector(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Titre
              Text(
                'Choisir une photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              
              // Options
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: Text(
                  'Appareil photo',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: Text(
                  'Galerie',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: Text(
                  'Annuler',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}