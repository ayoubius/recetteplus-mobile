import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class GoogleAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Configuration Google Sign-In pour Android natif
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // Utiliser le client ID web pour Supabase
    serverClientId:
        '361640124056-aipd8mae8vjocm6v9hn7r4qdasp9thml.apps.googleusercontent.com', // À remplacer par votre vrai client ID
  );

  /// Connexion Google native pour Android
  static Future<AuthResponse?> signInWithGoogleNative() async {
    try {
      if (kDebugMode) {
        print('🔍 Démarrage de l\'authentification Google native...');
      }

      // 1. Déconnecter l'utilisateur précédent si nécessaire
      await _googleSignIn.signOut();

      // 2. Lancer le processus de connexion Google natif
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (kDebugMode) {
          print('❌ Connexion Google annulée par l\'utilisateur');
        }
        return null;
      }

      if (kDebugMode) {
        print('✅ Utilisateur Google sélectionné: ${googleUser.email}');
      }

      // 3. Obtenir les tokens d'authentification
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Impossible d\'obtenir les tokens Google');
      }

      if (kDebugMode) {
        print('✅ Tokens Google obtenus');
        print('📧 Email: ${googleUser.email}');
        print('👤 Nom: ${googleUser.displayName}');
      }

      // 4. Authentifier avec Supabase en utilisant les tokens Google
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        if (kDebugMode) {
          print('✅ Authentification Supabase réussie');
          print('🆔 User ID: ${response.user!.id}');
        }

        // 5. Créer ou mettre à jour le profil utilisateur
        await _createOrUpdateUserProfile(response.user!, googleUser);

        return response;
      } else {
        throw Exception('Échec de l\'authentification Supabase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'authentification Google: $e');
      }

      // Nettoyer en cas d'erreur
      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        if (kDebugMode) {
          print('⚠️  Erreur lors de la déconnexion Google: $signOutError');
        }
      }

      rethrow;
    }
  }

  /// Créer ou mettre à jour le profil utilisateur après connexion Google
  static Future<void> _createOrUpdateUserProfile(
    User supabaseUser,
    GoogleSignInAccount googleUser,
  ) async {
    try {
      // Vérifier si le profil existe déjà
      final existingProfile =
          await SupabaseService.getUserProfile(supabaseUser.id);

      if (existingProfile == null) {
        // Créer un nouveau profil
        await SupabaseService.createUserProfile(
          uid: supabaseUser.id,
          displayName: googleUser.displayName ??
              googleUser.email.split('@')[0] ??
              'Utilisateur Google',
          email: googleUser.email,
          phoneNumber: null, // Google ne fournit pas le numéro de téléphone
        );

        if (kDebugMode) {
          print('✅ Nouveau profil utilisateur créé');
        }
      } else {
        // Mettre à jour le profil existant si nécessaire
        final needsUpdate =
            existingProfile['display_name'] != googleUser.displayName ||
                existingProfile['email'] != googleUser.email;

        if (needsUpdate) {
          await SupabaseService.updateUserProfile(
            uid: supabaseUser.id,
            displayName: googleUser.displayName,
            additionalData: {
              'email': googleUser.email,
              'photo_url': googleUser.photoUrl,
            },
          );

          if (kDebugMode) {
            print('✅ Profil utilisateur mis à jour');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️  Erreur lors de la gestion du profil: $e');
      }
      // Ne pas faire échouer l'authentification pour un problème de profil
    }
  }

  /// Déconnexion Google
  static Future<void> signOut() async {
    try {
      // Déconnecter de Supabase
      await _supabase.auth.signOut();

      // Déconnecter de Google
      await _googleSignIn.signOut();

      if (kDebugMode) {
        print('✅ Déconnexion Google et Supabase réussie');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la déconnexion: $e');
      }
      rethrow;
    }
  }

  /// Vérifier si l'utilisateur est connecté à Google
  static Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur vérification statut Google: $e');
      }
      return false;
    }
  }

  /// Obtenir l'utilisateur Google actuel
  static GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }
}
