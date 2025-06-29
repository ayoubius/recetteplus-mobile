import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/utils/currency_utils.dart';

class PreconfiguredCartsPage extends StatefulWidget {
  const PreconfiguredCartsPage({super.key});

  @override
  State<PreconfiguredCartsPage> createState() => _PreconfiguredCartsPageState();
}

class _PreconfiguredCartsPageState extends State<PreconfiguredCartsPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allCarts = [];
  List<Map<String, dynamic>> _filteredCarts = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tous';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    'Tous',
    'Pâtisserie',
    'Épices',
    'Bio',
    'Ustensiles',
    'Électroménager',
    'Cuisine du Monde',
    'Débutant',
  ];

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
    _loadPreconfiguredCarts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPreconfiguredCarts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger tous les paniers préconfigurés (pas seulement ceux en vedette)
      final carts = await CartService.getFeaturedPreconfiguredCarts();
      
      if (carts.isEmpty) {
        _allCarts = _getSampleCarts();
      } else {
        _allCarts = carts;
      }
      
      _filterCarts();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allCarts = _getSampleCarts();
          _filterCarts();
          _isLoading = false;
        });
        _animationController.forward();
      }
    }
  }

  void _filterCarts() {
    _filteredCarts = _allCarts.where((cart) {
      final matchesCategory = _selectedCategory == 'Tous' || 
                             cart['category'] == _selectedCategory;
      final matchesSearch = _searchController.text.isEmpty ||
                           cart['name']
                               .toLowerCase()
                               .contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<Map<String, dynamic>> _getSampleCarts() {
    return [
      {
        'id': 'cart-1',
        'name': 'Kit Pâtisserie Complet',
        'description': 'Tout pour commencer la pâtisserie comme un chef professionnel avec les meilleurs ustensiles',
        'image': 'https://images.pexels.com/photos/1070850/pexels-photo-1070850.jpeg',
        'total_price': 45000.0,
        'category': 'Pâtisserie',
        'is_featured': true,
        'items_count': 8,
        'items': [
          {'name': 'Fouet professionnel', 'quantity': 1},
          {'name': 'Moules à gâteau', 'quantity': 3},
          {'name': 'Balance de précision', 'quantity': 1},
          {'name': 'Spatules silicone', 'quantity': 2},
        ]
      },
      {
        'id': 'cart-2',
        'name': 'Épices du Monde',
        'description': 'Sélection d\'épices exotiques pour voyager à travers les saveurs du monde entier',
        'image': 'https://images.pexels.com/photos/1340116/pexels-photo-1340116.jpeg',
        'total_price': 32000.0,
        'category': 'Épices',
        'is_featured': true,
        'items_count': 12,
        'items': [
          {'name': 'Curcuma bio', 'quantity': 1},
          {'name': 'Cardamome verte', 'quantity': 1},
          {'name': 'Paprika fumé', 'quantity': 1},
          {'name': 'Cannelle de Ceylan', 'quantity': 1},
        ]
      },
      {
        'id': 'cart-3',
        'name': 'Cuisine Healthy',
        'description': 'Produits bio et naturels pour une cuisine saine et équilibrée au quotidien',
        'image': 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg',
        'total_price': 28500.0,
        'category': 'Bio',
        'is_featured': true,
        'items_count': 6,
        'items': [
          {'name': 'Quinoa bio', 'quantity': 2},
          {'name': 'Huile de coco vierge', 'quantity': 1},
          {'name': 'Graines de chia', 'quantity': 1},
          {'name': 'Spiruline en poudre', 'quantity': 1},
        ]
      },
      {
        'id': 'cart-4',
        'name': 'Ustensiles Pro',
        'description': 'Équipement professionnel pour transformer votre cuisine en laboratoire culinaire',
        'image': 'https://images.pexels.com/photos/2284166/pexels-photo-2284166.jpeg',
        'total_price': 89000.0,
        'category': 'Ustensiles',
        'is_featured': false,
        'items_count': 5,
        'items': [
          {'name': 'Couteau de chef 20cm', 'quantity': 1},
          {'name': 'Planche à découper bambou', 'quantity': 1},
          {'name': 'Mandoline professionnelle', 'quantity': 1},
          {'name': 'Set de casseroles inox', 'quantity': 1},
        ]
      },
      {
        'id': 'cart-5',
        'name': 'Électroménager Essentiel',
        'description': 'Les appareils indispensables pour une cuisine moderne et efficace',
        'image': 'https://images.pexels.com/photos/4226796/pexels-photo-4226796.jpeg',
        'total_price': 156000.0,
        'category': 'Électroménager',
        'is_featured': false,
        'items_count': 4,
        'items': [
          {'name': 'Mixeur haute performance', 'quantity': 1},
          {'name': 'Robot multifonction', 'quantity': 1},
          {'name': 'Grille-pain design', 'quantity': 1},
          {'name': 'Bouilloire électrique', 'quantity': 1},
        ]
      },
      {
        'id': 'cart-6',
        'name': 'Épices Méditerranéennes',
        'description': 'Saveurs authentiques de la Méditerranée pour des plats ensoleillés',
        'image': 'https://images.pexels.com/photos/1340116/pexels-photo-1340116.jpeg',
        'total_price': 18500.0,
        'category': 'Épices',
        'is_featured': false,
        'items_count': 8,
        'items': [
          {'name': 'Herbes de Provence', 'quantity': 1},
          {'name': 'Origan grec', 'quantity': 1},
          {'name': 'Thym de Provence', 'quantity': 1},
          {'name': 'Romarin séché', 'quantity': 1},
        ]
      },
      {
        'id': 'cart-7',
        'name': 'Cuisine Asiatique',
        'description': 'Découvrez les secrets de la cuisine asiatique avec cette sélection d\'ingrédients',
        'image': 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg',
        'total_price': 24000.0,
        'category': 'Cuisine du Monde',
        'is_featured': false,
        'items_count': 10,
        'items': [
          {'name': 'Sauce soja premium', 'quantity': 1},
          {'name': 'Huile de sésame', 'quantity': 1},
          {'name': 'Miso blanc', 'quantity': 1},
          {'name': 'Nouilles soba', 'quantity': 2},
        ]
      },
      {
        'id': 'cart-8',
        'name': 'Kit Débutant',
        'description': 'Parfait pour commencer en cuisine avec les bases essentielles',
        'image': 'https://images.pexels.com/photos/2284166/pexels-photo-2284166.jpeg',
        'total_price': 35000.0,
        'category': 'Débutant',
        'is_featured': false,
        'items_count': 6,
        'items': [
          {'name': 'Couteau d\'office', 'quantity': 1},
          {'name': 'Planche à découper', 'quantity': 1},
          {'name': 'Poêle antiadhésive', 'quantity': 1},
          {'name': 'Casserole 2L', 'quantity': 1},
        ]
      },
    ];
  }

  Future<void> _addToCart(Map<String, dynamic> cart) async {
    try {
      await CartService.addPreconfiguredCartToUser(cart['id']);
      
      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${cart['name']} ajouté au panier'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Voir panier',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Naviguer vers le panier
                Navigator.pop(context);
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

  void _viewCartDetails(Map<String, dynamic> cart) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCartDetailsModal(cart),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text('Paniers Préconfigurés'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Ajouter fonctionnalité de tri
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité de tri à venir')),
              );
            },
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header avec recherche
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getSurface(isDark),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getShadow(isDark),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Statistiques
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${_allCarts.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Paniers disponibles',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.getTextSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${_allCarts.where((c) => c['is_featured'] == true).length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                            Text(
                              'En vedette',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.getTextSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Barre de recherche
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.getBackground(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.getBorder(isDark),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _filterCarts();
                      });
                    },
                    style: TextStyle(color: AppColors.getTextPrimary(isDark)),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un panier...',
                      hintStyle: TextStyle(color: AppColors.getTextSecondary(isDark)),
                      prefixIcon: Icon(Icons.search, color: AppColors.getTextSecondary(isDark)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: AppColors.getTextSecondary(isDark)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _filterCarts();
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Filtres par catégorie
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.getSurface(isDark),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.getBorder(isDark),
                  width: 1,
                ),
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                final categoryCount = category == 'Tous' 
                    ? _allCarts.length 
                    : _allCarts.where((c) => c['category'] == category).length;
                
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(category),
                        if (categoryCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.primary 
                                  : AppColors.getTextSecondary(isDark),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              categoryCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _filterCarts();
                      });
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
                  ),
                );
              },
            ),
          ),
          
          // Liste des paniers
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCarts.isEmpty
                    ? _buildEmptyState(isDark)
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: RefreshIndicator(
                          onRefresh: _loadPreconfiguredCarts,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _filteredCarts.length,
                            itemBuilder: (context, index) {
                              final cart = _filteredCarts[index];
                              return _buildCartCard(cart, isDark);
                            },
                          ),
                        ),
                      ),
          ),
        ],
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
              Icons.shopping_basket_outlined,
              size: 60,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun panier trouvé',
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
                _selectedCategory = 'Tous';
                _filterCarts();
              });
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

  Widget _buildCartCard(Map<String, dynamic> cart, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        onTap: () => _viewCartDetails(cart),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image du panier
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: cart['image'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          cart['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.shopping_basket,
                              color: AppColors.primary,
                              size: 40,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.shopping_basket,
                        color: AppColors.primary,
                        size: 40,
                      ),
              ),
              
              const SizedBox(width: 16),
              
              // Informations du panier
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cart['name'] ?? 'Panier',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextPrimary(isDark),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (cart['is_featured'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Vedette',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cart['description'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            cart['category'] ?? 'Autre',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${cart['items_count'] ?? 0} articles',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyUtils.formatPrice(cart['total_price']?.toDouble() ?? 0.0),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bouton d'ajout
              GestureDetector(
                onTap: () => _addToCart(cart),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_shopping_cart,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartDetailsModal(Map<String, dynamic> cart) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.getBorder(isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header avec image
          Container(
            height: 200,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getShadow(isDark),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: cart['image'] != null
                      ? Image.network(
                          cart['image'],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.primary.withOpacity(0.1),
                              child: const Icon(
                                Icons.shopping_basket,
                                color: AppColors.primary,
                                size: 80,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.shopping_basket,
                            color: AppColors.primary,
                            size: 80,
                          ),
                        ),
                ),
                
                // Overlay avec informations
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              cart['category'] ?? 'Panier',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (cart['is_featured'] == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Vedette',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cart['name'] ?? 'Panier',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyUtils.formatPrice(cart['total_price']?.toDouble() ?? 0.0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cart['description'] ?? 'Aucune description disponible',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.getTextSecondary(isDark),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Articles inclus
                  Text(
                    'Articles inclus (${cart['items_count'] ?? 0})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: (cart['items'] as List?)?.length ?? 0,
                      itemBuilder: (context, index) {
                        final item = (cart['items'] as List)[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.getBackground(isDark),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['name'] ?? 'Article',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.getTextPrimary(isDark),
                                  ),
                                ),
                              ),
                              Text(
                                'x${item['quantity'] ?? 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.getTextSecondary(isDark),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Boutons d'action
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppColors.getBorder(isDark)),
                    ),
                    child: Text(
                      'Fermer',
                      style: TextStyle(color: AppColors.getTextPrimary(isDark)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _addToCart(cart);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ajouter au panier',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}