import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorHandler {
  /// Gérer les erreurs Supabase de manière centralisée
  static String handleSupabaseError(dynamic error) {
    if (error is PostgrestException) {
      switch (error.code) {
        case 'PGRST116':
          return 'Aucune donnée trouvée';
        case 'PGRST301':
          return 'Accès non autorisé';
        case '23505':
          return 'Cette donnée existe déjà';
        case '23503':
          return 'Référence invalide';
        default:
          if (kDebugMode) {
            print('❌ Erreur Postgrest: ${error.message} (${error.code})');
          }
          return 'Erreur de base de données: ${error.message}';
      }
    }
    
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Email ou mot de passe incorrect';
        case 'User not found':
          return 'Utilisateur introuvable';
        case 'Email not confirmed':
          return 'Veuillez confirmer votre email';
        default:
          return 'Erreur d\'authentification: ${error.message}';
      }
    }
    
    if (error is StorageException) {
      return 'Erreur de stockage: ${error.message}';
    }
    
    // Erreur générique
    return 'Une erreur inattendue s\'est produite';
  }

  /// Logger centralisé pour les erreurs
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ [$context] $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Vérifier la connectivité réseau
  static Future<bool> checkConnectivity() async {
    try {
      // Test simple de connectivité avec Supabase
      await Supabase.instance.client.from('profiles').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }
}