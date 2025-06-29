import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Aide et support'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section FAQ
            _buildSectionHeader('Questions fréquentes'),
            _buildFAQCard(),

            const SizedBox(height: 24),

            // Section Contact
            _buildSectionHeader('Nous contacter'),
            _buildContactCard(context),

            const SizedBox(height: 24),

            // Section Ressources
            _buildSectionHeader('Ressources utiles'),
            _buildResourcesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildFAQCard() {
    final faqs = [
      {
        'question': 'Comment ajouter une recette aux favoris ?',
        'answer':
            'Appuyez sur l\'icône cœur sur n\'importe quelle recette pour l\'ajouter à vos favoris.',
      },
      {
        'question': 'Comment modifier mon profil ?',
        'answer':
            'Allez dans l\'onglet Profil, puis appuyez sur "Modifier le profil" pour changer vos informations.',
      },
      {
        'question': 'Comment vérifier mon numéro de téléphone ?',
        'answer':
            'Dans la page de modification du profil, entrez votre numéro et appuyez sur "Vérifier". Vous recevrez un SMS avec un code.',
      },
      {
        'question': 'Comment rechercher des recettes ?',
        'answer':
            'Utilisez la barre de recherche dans l\'onglet Recettes ou filtrez par catégorie.',
      },
      {
        'question': 'Mes données sont-elles sécurisées ?',
        'answer':
            'Oui, nous utilisons Firebase pour sécuriser vos données avec un chiffrement de niveau entreprise.',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: faqs.asMap().entries.map((entry) {
          final index = entry.key;
          final faq = entry.value;
          return Column(
            children: [
              ExpansionTile(
                title: Text(
                  faq['question']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      faq['answer']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (index < faqs.length - 1)
                Divider(
                  height: 1,
                  color: AppColors.border,
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildContactTile(
            icon: Icons.email,
            title: 'Email',
            subtitle: 'support@recetteplus.com',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ouverture de l\'email...')),
              );
            },
          ),
          _buildDivider(),
          _buildContactTile(
            icon: Icons.phone,
            title: 'Téléphone',
            subtitle: '+33 1 23 45 67 89',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ouverture du téléphone...')),
              );
            },
          ),
          _buildDivider(),
          _buildContactTile(
            icon: Icons.chat,
            title: 'Chat en direct',
            subtitle: 'Disponible 9h-18h',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
          ),
          _buildDivider(),
          _buildContactTile(
            icon: Icons.bug_report,
            title: 'Signaler un bug',
            subtitle: 'Aidez-nous à améliorer l\'app',
            onTap: () {
              _showBugReportDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildResourceTile(
            icon: Icons.video_library,
            title: 'Tutoriels vidéo',
            subtitle: 'Apprenez à utiliser l\'application',
            onTap: () {
              // Fonctionnalité à venir
            },
          ),
          _buildDivider(),
          _buildResourceTile(
            icon: Icons.article,
            title: 'Guide d\'utilisation',
            subtitle: 'Documentation complète',
            onTap: () {
              // Fonctionnalité à venir
            },
          ),
          _buildDivider(),
          _buildResourceTile(
            icon: Icons.update,
            title: 'Nouveautés',
            subtitle: 'Découvrez les dernières fonctionnalités',
            onTap: () {
              // Fonctionnalité à venir
            },
          ),
          _buildDivider(),
          _buildResourceTile(
            icon: Icons.feedback,
            title: 'Donner votre avis',
            subtitle: 'Notez l\'application sur le store',
            onTap: () {
              // Fonctionnalité à venir
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildResourceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: AppColors.border,
      indent: 70,
      endIndent: 20,
    );
  }

  void _showBugReportDialog(BuildContext context) {
    final TextEditingController bugController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Signaler un bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Décrivez le problème rencontré :'),
            const SizedBox(height: 16),
            TextField(
              controller: bugController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Décrivez le bug en détail...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rapport envoyé. Merci !')),
              );
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
