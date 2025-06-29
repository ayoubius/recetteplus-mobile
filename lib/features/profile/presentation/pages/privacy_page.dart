import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_service.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _isLoading = true;
  Map<String, dynamic> _privacySettings = {};
  Map<String, dynamic> _notificationSettings = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await SupabaseService.getUserProfile(user.id);
        
        if (mounted && profile != null) {
          setState(() {
            _privacySettings = Map<String, dynamic>.from(
              profile['privacy_settings'] ?? {}
            );
            _notificationSettings = Map<String, dynamic>.from(
              profile['notification_settings'] ?? {}
            );
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _updatePrivacySetting(String key, dynamic value) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      setState(() {
        _privacySettings[key] = value;
      });

      await SupabaseService.updateUserProfile(
        uid: user.id,
        additionalData: {
          'privacy_settings': _privacySettings,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paramètres mis à jour'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _updateNotificationSetting(String key, dynamic value) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      setState(() {
        _notificationSettings[key] = value;
      });

      await SupabaseService.updateUserProfile(
        uid: user.id,
        additionalData: {
          'notification_settings': _notificationSettings,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paramètres mis à jour'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text('Confidentialité'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Visibilité du profil
                  _buildSectionHeader('Visibilité du profil', isDark),
                  _buildSettingsCard(isDark, [
                    _buildDropdownTile(
                      title: 'Profil public',
                      subtitle: 'Qui peut voir votre profil',
                      value: _privacySettings['profile_visibility'] ?? 'public',
                      options: const {
                        'public': 'Tout le monde',
                        'friends': 'Amis seulement',
                        'private': 'Privé',
                      },
                      onChanged: (value) => _updatePrivacySetting('profile_visibility', value),
                      icon: Icons.visibility,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildDropdownTile(
                      title: 'Email',
                      subtitle: 'Visibilité de votre adresse email',
                      value: _privacySettings['email_visibility'] ?? 'private',
                      options: const {
                        'public': 'Public',
                        'friends': 'Amis seulement',
                        'private': 'Privé',
                      },
                      onChanged: (value) => _updatePrivacySetting('email_visibility', value),
                      icon: Icons.email,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildDropdownTile(
                      title: 'Téléphone',
                      subtitle: 'Visibilité de votre numéro',
                      value: _privacySettings['phone_visibility'] ?? 'private',
                      options: const {
                        'public': 'Public',
                        'friends': 'Amis seulement',
                        'private': 'Privé',
                      },
                      onChanged: (value) => _updatePrivacySetting('phone_visibility', value),
                      icon: Icons.phone,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildDropdownTile(
                      title: 'Localisation',
                      subtitle: 'Visibilité de votre localisation',
                      value: _privacySettings['location_visibility'] ?? 'public',
                      options: const {
                        'public': 'Public',
                        'friends': 'Amis seulement',
                        'private': 'Privé',
                      },
                      onChanged: (value) => _updatePrivacySetting('location_visibility', value),
                      icon: Icons.location_on,
                      isDark: isDark,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Section Activité
                  _buildSectionHeader('Activité', isDark),
                  _buildSettingsCard(isDark, [
                    _buildSwitchTile(
                      title: 'Statut en ligne',
                      subtitle: 'Afficher quand vous êtes en ligne',
                      value: _privacySettings['show_online_status'] ?? true,
                      onChanged: (value) => _updatePrivacySetting('show_online_status', value),
                      icon: Icons.circle,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildDropdownTile(
                      title: 'Activité',
                      subtitle: 'Qui peut voir votre activité',
                      value: _privacySettings['activity_visibility'] ?? 'public',
                      options: const {
                        'public': 'Tout le monde',
                        'friends': 'Amis seulement',
                        'private': 'Privé',
                      },
                      onChanged: (value) => _updatePrivacySetting('activity_visibility', value),
                      icon: Icons.timeline,
                      isDark: isDark,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Section Interactions
                  _buildSectionHeader('Interactions', isDark),
                  _buildSettingsCard(isDark, [
                    _buildSwitchTile(
                      title: 'Demandes d\'amis',
                      subtitle: 'Autoriser les demandes d\'amis',
                      value: _privacySettings['allow_friend_requests'] ?? true,
                      onChanged: (value) => _updatePrivacySetting('allow_friend_requests', value),
                      icon: Icons.person_add,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSwitchTile(
                      title: 'Messages',
                      subtitle: 'Autoriser les messages privés',
                      value: _privacySettings['allow_messages'] ?? true,
                      onChanged: (value) => _updatePrivacySetting('allow_messages', value),
                      icon: Icons.message,
                      isDark: isDark,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Section Notifications
                  _buildSectionHeader('Notifications', isDark),
                  _buildSettingsCard(isDark, [
                    _buildSwitchTile(
                      title: 'Notifications email',
                      subtitle: 'Recevoir des notifications par email',
                      value: _notificationSettings['email_notifications'] ?? true,
                      onChanged: (value) => _updateNotificationSetting('email_notifications', value),
                      icon: Icons.email_outlined,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSwitchTile(
                      title: 'Notifications push',
                      subtitle: 'Recevoir des notifications sur l\'appareil',
                      value: _notificationSettings['push_notifications'] ?? true,
                      onChanged: (value) => _updateNotificationSetting('push_notifications', value),
                      icon: Icons.notifications,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSwitchTile(
                      title: 'Nouvelles recettes',
                      subtitle: 'Être notifié des nouvelles recettes',
                      value: _notificationSettings['recipe_updates'] ?? true,
                      onChanged: (value) => _updateNotificationSetting('recipe_updates', value),
                      icon: Icons.restaurant_menu,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSwitchTile(
                      title: 'Nouveaux produits',
                      subtitle: 'Être notifié des nouveaux produits',
                      value: _notificationSettings['product_updates'] ?? true,
                      onChanged: (value) => _updateNotificationSetting('product_updates', value),
                      icon: Icons.shopping_bag,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSwitchTile(
                      title: 'Emails marketing',
                      subtitle: 'Recevoir des offres promotionnelles',
                      value: _notificationSettings['marketing_emails'] ?? false,
                      onChanged: (value) => _updateNotificationSetting('marketing_emails', value),
                      icon: Icons.local_offer,
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildSwitchTile(
                      title: 'Résumé hebdomadaire',
                      subtitle: 'Recevoir un résumé de votre activité',
                      value: _notificationSettings['weekly_digest'] ?? true,
                      onChanged: (value) => _updateNotificationSetting('weekly_digest', value),
                      icon: Icons.summarize,
                      isDark: isDark,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Section Données
                  _buildSectionHeader('Données personnelles', isDark),
                  _buildSettingsCard(isDark, [
                    _buildActionTile(
                      title: 'Télécharger mes données',
                      subtitle: 'Obtenir une copie de vos données',
                      icon: Icons.download,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fonctionnalité à venir')),
                        );
                      },
                      isDark: isDark,
                    ),
                    _buildDivider(isDark),
                    _buildActionTile(
                      title: 'Supprimer mon compte',
                      subtitle: 'Supprimer définitivement votre compte',
                      icon: Icons.delete_forever,
                      textColor: Colors.red,
                      onTap: () => _showDeleteAccountDialog(),
                      isDark: isDark,
                    ),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.getTextPrimary(isDark),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(isDark),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.getTextPrimary(isDark),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.getTextSecondary(isDark),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
    required IconData icon,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.getTextPrimary(isDark),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.getTextSecondary(isDark),
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    Color? textColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (textColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: textColor ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.getTextPrimary(isDark),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.getTextSecondary(isDark),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.getTextSecondary(isDark),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: AppColors.getBorder(isDark),
      indent: 70,
      endIndent: 20,
    );
  }

  void _showDeleteAccountDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getCardBackground(isDark),
        title: Text(
          'Supprimer le compte',
          style: TextStyle(color: AppColors.getTextPrimary(isDark)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action est irréversible. Toutes vos données seront définitivement supprimées :',
              style: TextStyle(color: AppColors.getTextSecondary(isDark)),
            ),
            const SizedBox(height: 12),
            Text(
              '• Profil et informations personnelles\n'
              '• Recettes et favoris\n'
              '• Historique et commandes\n'
              '• Photos et contenus',
              style: TextStyle(
                color: AppColors.getTextSecondary(isDark),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Êtes-vous sûr de vouloir continuer ?',
              style: TextStyle(
                color: AppColors.getTextPrimary(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: TextStyle(color: AppColors.getTextSecondary(isDark)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
            child: const Text(
              'Supprimer définitivement',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}