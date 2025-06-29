import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_service.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Toutes';
  String _selectedDifficulty = 'Toutes';
  String _sortBy = 'recent'; // recent, popular, rating
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final List<String> _categories = [
    'Toutes',
    'Entrées',
    'Plats principaux',
    'Desserts',
    'Boissons',
    'Végétarien',
    'Rapide',
  ];

  final List<String> _difficulties = [
    'Toutes',
    'Facile',
    'Moyen',
    'Difficile',
  ];

  final Map<String, String> _sortOptions = {
    'recent': 'Plus récentes',
    'popular': 'Plus populaires',
    'rating': 'Mieux notées',
    'time': 'Temps de cuisson',
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recipes = await SupabaseService.getRecipes(
        category: _selectedCategory == 'Toutes' ? null : _selectedCategory,
        searchQuery: _searchController.text.trim().isNotEmpty 
            ? _searchController.text.trim() 
            : null,
      );

      // Si aucune recette en base, utiliser des données d'exemple
      if (recipes.isEmpty && _selectedCategory == 'Toutes' && _searchController.text.isEmpty) {
        _recipes = _getSampleRecipes();
      } else {
        _recipes = recipes;
      }

      // Appliquer les filtres et le tri
      _applyFiltersAndSort();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recipes = _getSampleRecipes();
          _applyFiltersAndSort();
          _isLoading = false;
        });
        _animationController.forward();
      }
    }
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = List.from(_recipes);

    // Filtrer par difficulté
    if (_selectedDifficulty != 'Toutes') {
      filtered = filtered.where((recipe) => 
        recipe['difficulty'] == _selectedDifficulty
      ).toList();
    }

    // Filtrer par recherche
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((recipe) {
        final title = recipe['title']?.toString().toLowerCase() ?? '';
        final description = recipe['description']?.toString().toLowerCase() ?? '';
        return title.contains(searchTerm) || description.contains(searchTerm);
      }).toList();
    }

    // Trier
    switch (_sortBy) {
      case 'popular':
        filtered.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
        break;
      case 'rating':
        filtered.sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
        break;
      case 'time':
        filtered.sort((a, b) => (a['cook_time'] ?? 0).compareTo(b['cook_time'] ?? 0));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
        break;
    }

    setState(() {
      _recipes = filtered;
    });
  }

  List<Map<String, dynamic>> _getSampleRecipes() {
    return [
      {
        'id': '1',
        'title': 'Pasta Carbonara Authentique',
        'category': 'Plats principaux',
        'cook_time': 20,
        'servings': 4,
        'difficulty': 'Facile',
        'rating': 4.8,
        'image': 'https://images.pexels.com/photos/1279330/pexels-photo-1279330.jpeg',
        'description': 'Un classique italien crémeux et délicieux avec seulement 5 ingrédients',
        'ingredients': ['400g de spaghetti', '200g de pancetta', '4 œufs', '100g de parmesan', 'Poivre noir'],
        'instructions': ['Faire cuire les pâtes', 'Faire revenir la pancetta', 'Mélanger œufs et parmesan', 'Combiner le tout'],
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': '2',
        'title': 'Salade César Parfaite',
        'category': 'Entrées',
        'cook_time': 15,
        'servings': 2,
        'difficulty': 'Facile',
        'rating': 4.5,
        'image': 'https://images.pexels.com/photos/2097090/pexels-photo-2097090.jpeg',
        'description': 'Salade fraîche avec croûtons croustillants et parmesan',
        'ingredients': ['Laitue romaine', 'Croûtons', 'Parmesan', 'Sauce césar', 'Anchois'],
        'instructions': ['Laver la salade', 'Préparer les croûtons', 'Mélanger avec la sauce'],
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': '3',
        'title': 'Tiramisu Express',
        'category': 'Desserts',
        'cook_time': 30,
        'servings': 6,
        'difficulty': 'Moyen',
        'rating': 4.9,
        'image': 'https://images.pexels.com/photos/6880219/pexels-photo-6880219.jpeg',
        'description': 'Dessert italien au café et mascarpone, version rapide',
        'ingredients': ['Mascarpone', 'Œufs', 'Sucre', 'Café', 'Biscuits à la cuillère', 'Cacao'],
        'instructions': ['Préparer la crème', 'Tremper les biscuits', 'Monter en couches', 'Réfrigérer'],
        'created_at': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      },
      {
        'id': '4',
        'title': 'Smoothie Bowl Tropical',
        'category': 'Boissons',
        'cook_time': 5,
        'servings': 1,
        'difficulty': 'Facile',
        'rating': 4.3,
        'image': 'https://images.pexels.com/photos/1092730/pexels-photo-1092730.jpeg',
        'description': 'Boisson rafraîchissante aux fruits exotiques',
        'ingredients': ['Mangue', 'Ananas', 'Banane', 'Lait de coco', 'Granola'],
        'instructions': ['Mixer les fruits', 'Verser dans un bol', 'Ajouter les toppings'],
        'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      },
      {
        'id': '5',
        'title': 'Buddha Bowl Nutritif',
        'category': 'Végétarien',
        'cook_time': 25,
        'servings': 2,
        'difficulty': 'Facile',
        'rating': 4.6,
        'image': 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg',
        'description': 'Bol nutritif avec légumes colorés et quinoa',
        'ingredients': ['Quinoa', 'Avocat', 'Légumes variés', 'Graines', 'Sauce tahini'],
        'instructions': ['Cuire le quinoa', 'Préparer les légumes', 'Assembler le bol'],
        'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'id': '6',
        'title': 'Omelette Express',
        'category': 'Rapide',
        'cook_time': 8,
        'servings': 1,
        'difficulty': 'Facile',
        'rating': 4.2,
        'image': 'https://images.pexels.com/photos/824635/pexels-photo-824635.jpeg',
        'description': 'Petit-déjeuner rapide et protéiné',
        'ingredients': ['3 œufs', 'Beurre', 'Herbes fraîches', 'Fromage', 'Sel et poivre'],
        'instructions': ['Battre les œufs', 'Chauffer la poêle', 'Cuire l\'omelette'],
        'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      },
      {
        'id': '7',
        'title': 'Coq au Vin Traditionnel',
        'category': 'Plats principaux',
        'cook_time': 120,
        'servings': 6,
        'difficulty': 'Difficile',
        'rating': 4.7,
        'image': 'https://images.pexels.com/photos/958545/pexels-photo-958545.jpeg',
        'description': 'Plat traditionnel français mijoté au vin rouge',
        'ingredients': ['Poulet fermier', 'Vin rouge', 'Lardons', 'Champignons', 'Oignons'],
        'instructions': ['Faire mariner le poulet', 'Faire revenir', 'Mijoter longuement'],
        'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'id': '8',
        'title': 'Tarte Tatin aux Pommes',
        'category': 'Desserts',
        'cook_time': 60,
        'servings': 8,
        'difficulty': 'Moyen',
        'rating': 4.4,
        'image': 'https://images.pexels.com/photos/1126359/pexels-photo-1126359.jpeg',
        'description': 'Tarte renversée aux pommes caramélisées',
        'ingredients': ['Pommes', 'Pâte brisée', 'Sucre', 'Beurre', 'Cannelle'],
        'instructions': ['Caraméliser les pommes', 'Recouvrir de pâte', 'Cuire et retourner'],
        'created_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
      },
    ];
  }

  Future<void> _addToFavorites(Map<String, dynamic> recipe) async {
    try {
      await SupabaseService.addToFavorites(recipe['id'], 'recipe');
      
      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${recipe['title']} ajouté aux favoris'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Voir favoris',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Naviguer vers les favoris
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _viewRecipe(Map<String, dynamic> recipe) {
    HapticFeedback.mediumImpact();
    
    // Ajouter à l'historique
    SupabaseService.addToHistory(recipe['id']);
    
    // TODO: Naviguer vers la page de détail de la recette
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de: ${recipe['title']}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text('Recettes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Bouton de tri
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              _applyFiltersAndSort();
            },
            itemBuilder: (context) => _sortOptions.entries.map((entry) {
              return PopupMenuItem<String>(
                value: entry.key,
                child: Row(
                  children: [
                    Icon(
                      _sortBy == entry.key ? Icons.check : Icons.sort,
                      color: _sortBy == entry.key ? AppColors.primary : null,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(entry.value),
                  ],
                ),
              );
            }).toList(),
          ),
          // Bouton de filtres
          IconButton(
            onPressed: _showFilterModal,
            icon: Stack(
              children: [
                const Icon(Icons.tune),
                if (_selectedDifficulty != 'Toutes')
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                // Barre de recherche
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      _applyFiltersAndSort();
                    },
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une recette...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                _applyFiltersAndSort();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filtres par catégorie
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                            _loadRecipes();
                          },
                          backgroundColor: Colors.white.withOpacity(0.2),
                          selectedColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : Colors.white,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                            width: isSelected ? 2 : 1,
                          ),
                          elevation: isSelected ? 2 : 0,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? _buildEmptyState(isDark)
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _loadRecipes,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _recipes[index];
                        return _buildRecipeCard(recipe, isDark);
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildFilterModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.getBorder(isDark),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Titre
            Text(
              'Filtres avancés',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 20),
            
            // Difficulté
            Text(
              'Difficulté',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _difficulties.map((difficulty) {
                final isSelected = difficulty == _selectedDifficulty;
                return FilterChip(
                  label: Text(difficulty),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedDifficulty = difficulty;
                    });
                    _applyFiltersAndSort();
                  },
                  backgroundColor: AppColors.getBackground(isDark),
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.getTextSecondary(isDark),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.getBorder(isDark),
                    width: isSelected ? 2 : 1,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedDifficulty = 'Toutes';
                      });
                      _applyFiltersAndSort();
                      Navigator.pop(context);
                    },
                    child: const Text('Réinitialiser'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 60,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune recette trouvée',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos critères de recherche',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.getTextSecondary(isDark),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _selectedCategory = 'Toutes';
                _selectedDifficulty = 'Toutes';
              });
              _loadRecipes();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réinitialiser les filtres'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecipeCard(Map<String, dynamic> recipe, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(isDark),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewRecipe(recipe),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de la recette
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: recipe['image'] != null
                        ? Image.network(
                            recipe['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.primary.withOpacity(0.1),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: AppColors.primary,
                                  size: 60,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: const Icon(
                              Icons.restaurant,
                              color: AppColors.primary,
                              size: 60,
                            ),
                          ),
                  ),
                ),
                
                // Overlay gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Badge catégorie
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      recipe['category'] ?? 'Autre',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                // Badge difficulté
                if (recipe['difficulty'] != null)
                  Positioned(
                    top: 16,
                    right: 70,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(recipe['difficulty']),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        recipe['difficulty'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                
                // Bouton favori
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => _addToFavorites(recipe),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                
                // Rating
                if (recipe['rating'] != null)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recipe['rating'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            
            // Informations de la recette
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['title'] ?? 'Recette sans titre',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  if (recipe['description'] != null)
                    Text(
                      recipe['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextSecondary(isDark),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Informations détaillées
                  Row(
                    children: [
                      if (recipe['cook_time'] != null)
                        _buildInfoChip(
                          Icons.access_time,
                          '${recipe['cook_time']} min',
                          isDark,
                        ),
                      const SizedBox(width: 8),
                      if (recipe['servings'] != null)
                        _buildInfoChip(
                          Icons.people,
                          '${recipe['servings']} pers.',
                          isDark,
                        ),
                      const Spacer(),
                      // Indicateur de nouveauté
                      if (_isRecent(recipe['created_at']))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NOUVEAU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorder(isDark),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.getTextSecondary(isDark),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextSecondary(isDark),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return Colors.green;
      case 'moyen':
        return Colors.orange;
      case 'difficile':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _isRecent(String? createdAt) {
    if (createdAt == null) return false;
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      return now.difference(date).inDays <= 7; // Nouveau si moins de 7 jours
    } catch (e) {
      return false;
    }
  }
}