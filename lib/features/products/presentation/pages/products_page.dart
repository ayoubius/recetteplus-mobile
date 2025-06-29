import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/utils/currency_utils.dart';
import 'preconfigured_carts_page.dart';
import 'product_cart_detail_page.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final PageController _cartsPageController = PageController();
  String _selectedCategory = 'Tous';
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _featuredCarts = [];
  bool _isLoading = true;
  Timer? _autoScrollTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _categories = [
    'Tous',
    'Épices',
    'Huiles',
    'Ustensiles',
    'Électroménager',
    'Livres',
    'Bio',
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
    _loadData();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _cartsPageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_featuredCarts.isNotEmpty && _cartsPageController.hasClients) {
        final nextPage = (_cartsPageController.page?.round() ?? 0) + 1;
        final targetPage = nextPage >= _featuredCarts.length ? 0 : nextPage;

        _cartsPageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les produits et les paniers préconfigurés en parallèle
      await Future.wait([
        _loadProducts(),
        _loadFeaturedCarts(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _products = _getSampleProducts();
          _featuredCarts = _getSampleFeaturedCarts();
          _isLoading = false;
        });
        _animationController.forward();
      }
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await SupabaseService.getProducts(
        category: _selectedCategory == 'Tous' ? null : _selectedCategory,
        searchQuery: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
      );

      // Si aucun produit en base, utiliser des données d'exemple
      if (products.isEmpty && _selectedCategory == 'Tous' && _searchController.text.isEmpty) {
        _products = _getSampleProducts();
      } else {
        _products = products;
      }
    } catch (e) {
      _products = _getSampleProducts();
    }
  }

  Future<void> _loadFeaturedCarts() async {
    try {
      final carts = await CartService.getFeaturedPreconfiguredCarts();

      if (carts.isEmpty) {
        _featuredCarts = _getSampleFeaturedCarts();
      } else {
        _featuredCarts = carts;
      }
    } catch (e) {
      _featuredCarts = _getSampleFeaturedCarts();
    }
  }

  List<Map<String, dynamic>> _getSampleProducts() {
    return [
      {
        'id': '1',
        'name': 'Huile d\'olive extra vierge',
        'category': 'Huiles',
        'price': 4250.0,
        'rating': 4.8,
        'image': 'https://images.pexels.com/photos/33783/olive-oil-salad-dressing-cooking-olive.jpg',
        'description': 'Huile d\'olive premium de première pression à froid',
        'in_stock': true,
        'unit': 'bouteille 500ml',
      },
      {
        'id': '2',
        'name': 'Set d\'épices du monde',
        'category': 'Épices',
        'price': 16400.0,
        'rating': 4.6,
        'image': 'https://images.pexels.com/photos/1340116/pexels-photo-1340116.jpeg',
        'description': 'Collection de 12 épices exotiques',
        'in_stock': true,
        'unit': 'coffret',
      },
      {
        'id': '3',
        'name': 'Couteau de chef professionnel',
        'category': 'Ustensiles',
        'price': 59000.0,
        'rating': 4.9,
        'image': 'https://images.pexels.com/photos/2284166/pexels-photo-2284166.jpeg',
        'description': 'Couteau en acier inoxydable de haute qualité',
        'in_stock': false,
        'unit': 'pièce',
      },
      {
        'id': '4',
        'name': 'Mixeur haute performance',
        'category': 'Électroménager',
        'price': 131000.0,
        'rating': 4.7,
        'image': 'https://images.pexels.com/photos/4226796/pexels-photo-4226796.jpeg',
        'description': 'Mixeur puissant 1200W',
        'in_stock': true,
        'unit': 'appareil',
      },
      {
        'id': '5',
        'name': 'Livre "Cuisine du monde"',
        'category': 'Livres',
        'price': 19700.0,
        'rating': 4.5,
        'image': 'https://images.pexels.com/photos/1370295/pexels-photo-1370295.jpeg',
        'description': '200 recettes traditionnelles',
        'in_stock': true,
        'unit': 'livre',
      },
      {
        'id': '6',
        'name': 'Miel bio de lavande',
        'category': 'Bio',
        'price': 10500.0,
        'rating': 4.8,
        'image': 'https://images.pexels.com/photos/1638280/pexels-photo-1638280.jpeg',
        'description': 'Miel artisanal bio récolté en Provence',
        'in_stock': true,
        'unit': 'pot 250g',
      },
    ];
  }

  List<Map<String, dynamic>> _getSampleFeaturedCarts() {
    return [
      {
        'id': 'featured-cart-1',
        'name': 'Kit Pâtisserie Complet',
        'description': 'Tout pour commencer la pâtisserie comme un chef',
        'image': 'https://images.pexels.com/photos/1070850/pexels-photo-1070850.jpeg',
        'total_price': 45000.0,
        'category': 'Pâtisserie',
        'is_featured': true,
        'items_count': 8,
      },
      {
        'id': 'featured-cart-2',
        'name': 'Épices du Monde',
        'description': 'Sélection d\'épices exotiques pour voyager',
        'image': 'https://images.pexels.com/photos/1340116/pexels-photo-1340116.jpeg',
        'total_price': 32000.0,
        'category': 'Épices',
        'is_featured': true,
        'items_count': 12,
      },
      {
        'id': 'featured-cart-3',
        'name': 'Cuisine Healthy',
        'description': 'Produits bio et naturels pour une cuisine saine',
        'image': 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg',
        'total_price': 28500.0,
        'category': 'Bio',
        'is_featured': true,
        'items_count': 6,
      },
      {
        'id': 'featured-cart-4',
        'name': 'Ustensiles Pro',
        'description': 'Équipement professionnel pour votre cuisine',
        'image': 'https://images.pexels.com/photos/2284166/pexels-photo-2284166.jpeg',
        'total_price': 89000.0,
        'category': 'Ustensiles',
        'is_featured': true,
        'items_count': 5,
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_searchController.text.isEmpty && _selectedCategory == 'Tous') {
      return _products;
    }

    return _products.where((product) {
      final matchesCategory = _selectedCategory == 'Tous' ||
                             product['category'] == _selectedCategory;
      final matchesSearch = _searchController.text.isEmpty ||
                           product['name']
                               .toLowerCase()
                               .contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    try {
      await CartService.addProductToPersonalCart(
        productId: product['id'],
        quantity: 1,
      );

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product['name']} ajouté au panier'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Voir panier',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Naviguer vers le panier
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

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterModal(),
    );
  }

  void _viewCartDetails(Map<String, dynamic> cart) {
    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductCartDetailPage(cart: cart),
      ),
    );
  }

  void _viewAllPreconfiguredCarts() {
    HapticFeedback.mediumImpact();

    // Navigation vers la page dédiée aux paniers préconfigurés
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PreconfiguredCartsPage(),
      ),
    );
  }

  void _viewProduct(Map<String, dynamic> product) {
    HapticFeedback.mediumImpact();

    // TODO: Naviguer vers la page de détail du produit
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de: ${product['name']}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      body: SafeArea(
        child: Column(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Produits',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                        ),
                      ),
                      // Bouton filtre
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: IconButton(
                          onPressed: _showFilterModal,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.tune,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_bag,
                          color: AppColors.primary,
                          size: 24,
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
                        setState(() {});
                        if (value.isEmpty) {
                          _loadProducts();
                        }
                      },
                      onSubmitted: (value) => _loadProducts(),
                      style: TextStyle(color: AppColors.getTextPrimary(isDark)),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un produit...',
                        hintStyle: TextStyle(color: AppColors.getTextSecondary(isDark)),
                        prefixIcon: Icon(Icons.search, color: AppColors.getTextSecondary(isDark)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: AppColors.getTextSecondary(isDark)),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadProducts();
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

            // Paniers préconfigurés en vedette avec défilement automatique
            if (_featuredCarts.isNotEmpty) ...[
              Container(
                height: 200, // Augmenté de 180 à 200
                decoration: BoxDecoration(
                  color: AppColors.getSurface(isDark),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.getBorder(isDark),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8), // Réduit de 16 à 12 en haut
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Paniers en vedette',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextPrimary(isDark),
                            ),
                          ),
                          TextButton(
                            onPressed: _viewAllPreconfiguredCarts,
                            child: const Text(
                              'Voir tout',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _cartsPageController,
                        itemCount: _featuredCarts.length,
                        itemBuilder: (context, index) {
                          final cart = _featuredCarts[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildFeaturedCartCard(cart, isDark),
                          );
                        },
                      ),
                    ),
                    // Indicateurs de page
                    Container(
                      height: 20,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _featuredCarts.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Grille des produits
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? _buildEmptyState(isDark)
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: RefreshIndicator(
                            onRefresh: _loadData,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(20),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7, // Ajusté pour éviter l'overflow
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return _buildProductCard(product, isDark);
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCartCard(Map<String, dynamic> cart, bool isDark) {
    return Container(
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
        child: Stack(
          children: [
            // Image de fond
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: cart['image'] != null
                    ? Image.network(
                        cart['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: const Icon(
                              Icons.shopping_basket,
                              color: AppColors.primary,
                              size: 60,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppColors.primary.withOpacity(0.1),
                        child: const Icon(
                          Icons.shopping_basket,
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

            // Contenu
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge catégorie
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
                  const SizedBox(height: 8),

                  // Nom du panier
                  Text(
                    cart['name'] ?? 'Panier',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Description - Limitée à 1 ligne pour éviter la déformation
                  Text(
                    cart['description'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    maxLines: 1, // Changé de 2 à 1 ligne
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Prix et nombre d'articles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyUtils.formatPrice(cart['total_price']?.toDouble() ?? 0.0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${cart['items_count'] ?? 0} articles',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
              'Filtrer les produits',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 20),

            // Catégories
            Text(
              'Catégories',
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
              children: _categories.map((category) {
                final isSelected = category == _selectedCategory;
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category;
                    });
                    Navigator.pop(context);
                    _loadProducts();
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
            'Aucun produit trouvé',
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
              });
              _loadProducts();
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

  Widget _buildProductCard(Map<String, dynamic> product, bool isDark) {
    final isInStock = product['in_stock'] ?? true;

    return Container(
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
        onTap: () => _viewProduct(product),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du produit
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: product['image'] != null
                          ? Image.network(
                              product['image'],
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.primary.withOpacity(0.1),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: AppColors.primary,
                                      size: 40,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.primary.withOpacity(0.1),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: AppColors.primary,
                                  size: 40,
                                ),
                              ),
                            ),
                    ),
                  ),

                  // Badge de disponibilité
                  if (!isInStock)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Rupture',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Badge catégorie
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        product['category'] ?? 'Autre',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Rating
                  if (product['rating'] != null)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product['rating'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Informations du produit
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du produit
                    Flexible(
                      child: Text(
                        product['name'],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(isDark),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Unité
                    if (product['unit'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        product['unit'],
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const Spacer(),

                    // Prix et bouton d'ajout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Prix
                        Expanded(
                          child: Text(
                            CurrencyUtils.formatPrice(product['price']?.toDouble() ?? 0.0),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Bouton d'ajout au panier
                        GestureDetector(
                          onTap: isInStock ? () => _addToCart(product) : null,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isInStock
                                  ? AppColors.primary
                                  : AppColors.getTextSecondary(isDark),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isInStock ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}