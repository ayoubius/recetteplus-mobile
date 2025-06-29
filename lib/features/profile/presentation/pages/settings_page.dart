import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/theme_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Apparence
            _buildSectionHeader('Apparence', isDark),
            _buildSettingsCard(isDark, [
              _buildThemeSelector(themeService, isDark),
            ]),
            
            const SizedBox(height: 24),
            
            // Section Notifications
            _buildSectionHeader('Notifications', isDark),
            _buildSettingsCard(isDark, [
              _buildSwitchTile(
                title: 'Notifications',
                subtitle: 'Activer toutes les notifications',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                icon: Icons.notifications,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildSwitchTile(
                title: 'Notifications par email',
                subtitle: 'Recevoir des emails de notification',
                value: _emailNotifications,
                onChanged: _notificationsEnabled ? (value) {
                  setState(() {
                    _emailNotifications = value;
                  });
                } : null,
                icon: Icons.email,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildSwitchTile(
                title: 'Notifications push',
                subtitle: 'Recevoir des notifications sur l\'appareil',
                value: _pushNotifications,
                onChanged: _notificationsEnabled ? (value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                } : null,
                icon: Icons.phone_android,
                isDark: isDark,
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Section Compte
            _buildSectionHeader('Compte', isDark),
            _buildSettingsCard(isDark, [
              _buildListTile(
                title: 'Changer le mot de passe',
                subtitle: 'Modifier votre mot de passe',
                icon: Icons.lock,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à venir')),
                  );
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildListTile(
                title: 'Confidentialité',
                subtitle: 'Gérer vos données personnelles',
                icon: Icons.privacy_tip,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à venir')),
                  );
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildListTile(
                title: 'Supprimer le compte',
                subtitle: 'Supprimer définitivement votre compte',
                icon: Icons.delete_forever,
                onTap: () {
                  _showDeleteAccountDialog();
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                textColor: Colors.red,
                isDark: isDark,
              ),
            ]),
            
            const SizedBox(height: 24),
            
            // Section À propos
            _buildSectionHeader('À propos', isDark),
            _buildSettingsCard(isDark, [
              _buildListTile(
                title: 'Version de l\'application',
                subtitle: '1.0.0',
                icon: Icons.info,
                onTap: null,
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildListTile(
                title: 'Conditions d\'utilisation',
                subtitle: 'Lire nos conditions',
                icon: Icons.description,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à venir')),
                  );
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                isDark: isDark,
              ),
              _buildDivider(isDark),
              _buildListTile(
                title: 'Politique de confidentialité',
                subtitle: 'Lire notre politique',
                icon: Icons.policy,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à venir')),
                  );
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

  Widget _buildThemeSelector(ThemeService themeService, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.palette,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thème',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                    Text(
                      'Choisissez l\'apparence de l\'application',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  'Clair',
                  Icons.light_mode,
                  ThemeMode.light,
                  themeService,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildThemeOption(
                  'Sombre',
                  Icons.dark_mode,
                  ThemeMode.dark,
                  themeService,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildThemeOption(
                  'Système',
                  Icons.settings_system_daydream,
                  ThemeMode.system,
                  themeService,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    String label,
    IconData icon,
    ThemeMode mode,
    ThemeService themeService,
    bool isDark,
  ) {
    final isSelected = themeService.themeMode == mode;
    
    return GestureDetector(
      onTap: () => themeService.setThemeMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.getBackground(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : AppColors.getBorder(isDark),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? AppColors.primary 
                  : AppColors.getTextSecondary(isDark),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                    ? AppColors.primary 
                    : AppColors.getTextSecondary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
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
          color: onChanged != null 
              ? AppColors.getTextPrimary(isDark) 
              : AppColors.getTextSecondary(isDark),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: onChanged != null 
              ? AppColors.getTextSecondary(isDark) 
              : AppColors.getTextTertiary(isDark),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
    Widget? trailing,
    Color? textColor,
    required bool isDark,
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
      trailing: trailing,
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
        content: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement votre compte ? Cette action est irréversible.',
          style: TextStyle(color: AppColors.getTextSecondary(isDark)),
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
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}