import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/phone_formatter.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_button.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  bool _isUploadingImage = false;
  String? _errorMessage;
  String? _successMessage;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await SupabaseService.getUserProfile(user.id);
        
        if (mounted) {
          setState(() {
            _displayNameController.text = profile?['display_name'] ?? user.userMetadata?['display_name'] ?? '';
            _emailController.text = user.email ?? '';
            _phoneController.text = profile?['phone_number'] ?? '';
            _bioController.text = profile?['bio'] ?? '';
            _locationController.text = profile?['location'] ?? '';
            _currentAvatarUrl = profile?['photo_url'];
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _errorMessage = 'Erreur lors du chargement du profil';
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Normaliser le numéro de téléphone
      final normalizedPhone = PhoneValidator.normalizePhone(_phoneController.text.trim());

      // Mettre à jour les métadonnées utilisateur
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'display_name': _displayNameController.text.trim(),
          },
        ),
      );

      // Mettre à jour le profil dans la base de données
      await SupabaseService.updateUserProfile(
        uid: user.id,
        displayName: _displayNameController.text.trim(),
        phoneNumber: normalizedPhone,
        additionalData: {
          'bio': _bioController.text.trim().isNotEmpty 
              ? _bioController.text.trim() 
              : null,
          'location': _locationController.text.trim().isNotEmpty 
              ? _locationController.text.trim() 
              : null,
        },
      );

      if (mounted) {
        setState(() {
          _successMessage = 'Profil mis à jour avec succès';
        });
        
        // Masquer le message de succès après 3 secondes
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de la mise à jour: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeProfilePicture() async {
    try {
      // Afficher le sélecteur de source
      final source = await ImageService.showImageSourceSelector(context);
      if (source == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Sélectionner l'image
      final imageBytes = await ImageService.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 85,
      );

      if (imageBytes == null) {
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }

      // Uploader l'image
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final newAvatarUrl = await ImageService.uploadAvatar(
          imageBytes: imageBytes,
          userId: user.id,
          oldAvatarUrl: _currentAvatarUrl,
        );

        if (mounted && newAvatarUrl != null) {
          setState(() {
            _currentAvatarUrl = newAvatarUrl;
            _isUploadingImage = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo de profil mise à jour'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        
        String errorMessage = 'Erreur lors de l\'upload de l\'image';
        
        // Messages d'erreur plus spécifiques
        if (e.toString().contains('Permission')) {
          errorMessage = 'Permission refusée. Vérifiez les paramètres de l\'app.';
        } else if (e.toString().contains('trop volumineuse')) {
          errorMessage = 'Image trop volumineuse (max 5MB)';
        } else if (e.toString().contains('format')) {
          errorMessage = 'Format d\'image non supporté';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _changeProfilePicture,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo de profil
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.1),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.getShadow(isDark),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: _isUploadingImage
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                      ),
                                    )
                                  : ClipOval(
                                      child: _currentAvatarUrl != null
                                          ? Image.network(
                                              _currentAvatarUrl!,
                                              fit: BoxFit.cover,
                                              width: 120,
                                              height: 120,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: AppColors.primary,
                                                );
                                              },
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: AppColors.primary,
                                            ),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUploadingImage ? null : _changeProfilePicture,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Messages d'erreur/succès
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_successMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Champs de saisie
                      CustomTextField(
                        label: 'Nom complet',
                        controller: _displayNameController,
                        validator: Validators.validateFullName,
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        label: 'Adresse e-mail',
                        controller: _emailController,
                        enabled: false, // L'email ne peut pas être modifié
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'L\'adresse e-mail ne peut pas être modifiée',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        label: 'Numéro de téléphone (optionnel)',
                        hint: '+223 XX XX XX XX ou XX XX XX XX',
                        controller: _phoneController,
                        validator: Validators.validatePhoneNumber,
                        keyboardType: TextInputType.phone,
                        isPhoneNumber: true,
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        label: 'Bio (optionnel)',
                        controller: _bioController,
                        maxLines: 3,
                        hint: 'Parlez-nous de vous...',
                        prefixIcon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        label: 'Localisation (optionnel)',
                        controller: _locationController,
                        hint: 'Ville, Pays',
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bouton de sauvegarde
                      CustomButton(
                        text: 'Sauvegarder les modifications',
                        onPressed: _updateProfile,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Bouton de déconnexion
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            final shouldSignOut = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.getCardBackground(isDark),
                                title: Text(
                                  'Déconnexion',
                                  style: TextStyle(color: AppColors.getTextPrimary(isDark)),
                                ),
                                content: Text(
                                  'Êtes-vous sûr de vouloir vous déconnecter ?',
                                  style: TextStyle(color: AppColors.getTextSecondary(isDark)),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text(
                                      'Annuler',
                                      style: TextStyle(color: AppColors.getTextSecondary(isDark)),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text(
                                      'Déconnexion',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (shouldSignOut == true) {
                              await Supabase.instance.client.auth.signOut();
                              if (mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/welcome',
                                  (route) => false,
                                );
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Se déconnecter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}