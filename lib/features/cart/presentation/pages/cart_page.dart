import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/services/delivery_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/currency_utils.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _expandedCartDetails = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _total = 0.0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Adresse de livraison
  final TextEditingController _addressController = TextEditingController();
  String? _selectedZoneId;
  List<Map<String, dynamic>> _deliveryZones = [];
  bool _isPlacingOrder = false;
  bool _isGettingLocation = false;
  
  // État d'expansion des paniers
  Set<String> _expandedCarts = {};

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
    _loadCartItems();
    _loadDeliveryZones();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCartItems() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final items = await CartService.getMainCartItems();
      final total = await CartService.calculateMainCartTotal();
      
      // Charger les détails des paniers
      await _loadCartDetails(items);
      
      if (mounted) {
        setState(() {
          _cartItems = items;
          _total = total;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadCartDetails(List<Map<String, dynamic>> cartItems) async {
    List<Map<String, dynamic>> details = [];
    
    for (var item in cartItems) {
      final cartType = item['cart_reference_type'] ?? '';
      final cartId = item['cart_reference_id'];
      
      if (cartId != null) {
        try {
          List<Map<String, dynamic>> itemDetails = [];
          
          if (cartType == 'personal') {
            // Charger les détails du panier personnel
            final personalItems = await CartService.getPersonalCartItems(cartId);
            itemDetails = personalItems;
          } else if (cartType == 'recipe') {
            // Charger les détails du panier recette
            final recipeItems = await CartService.getRecipeCartItems(cartId);
            itemDetails = recipeItems;
          } else if (cartType == 'preconfigured') {
            // Charger les détails du panier préconfiguré
            final preconfiguredItems = await CartService.getPreconfiguredCartItems(cartId);
            itemDetails = preconfiguredItems;
          }
          
          details.add({
            'cart_id': cartId,
            'cart_type': cartType,
            'items': itemDetails,
          });
        } catch (e) {
          print('Erreur chargement détails panier $cartId: $e');
        }
      }
    }
    
    setState(() {
      _expandedCartDetails = details;
    });
  }
  
  Future<void> _loadDeliveryZones() async {
    try {
      final zones = await DeliveryService.getActiveDeliveryZones();
      if (mounted) {
        setState(() {
          _deliveryZones = zones.map((zone) => zone.toJson()).toList();
          if (_deliveryZones.isNotEmpty) {
            _selectedZoneId = _deliveryZones.first['id'];
          }
        });
      }
    } catch (e) {
      // Erreur silencieuse pour ne pas bloquer le chargement du panier
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement des zones de livraison: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Fonction utilitaire pour convertir en double de manière sécurisée
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Fonction utilitaire pour convertir en int de manière sécurisée
  int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Future<void> _removeItem(int index) async {
    HapticFeedback.mediumImpact();
    
    final removedItem = _cartItems[index];
    
    try {
      // Supprimer de la base de données si c'est un vrai item
      if (removedItem['id'] != null && removedItem['id'] is String && removedItem['id'].length > 5) {
        await CartService.removeFromMainCart(removedItem['id']);
      }
      
      setState(() {
        _cartItems.removeAt(index);
        _total -= _safeToDouble(removedItem['cart_total_price']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${removedItem['cart_name']} supprimé du panier'),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Annuler',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _cartItems.insert(index, removedItem);
                _total += _safeToDouble(removedItem['cart_total_price']);
              });
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _updateProductQuantity(String cartId, String productId, int newQuantity) async {
    if (newQuantity <= 0) {
      _removeProductFromCart(cartId, productId);
      return;
    }

    HapticFeedback.lightImpact();
    
    try {
      await CartService.updateProductQuantity(
        cartId: cartId,
        productId: productId,
        quantity: newQuantity,
      );
      
      // Recharger les paniers pour refléter les changements
      _loadCartItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  Future<void> _removeProductFromCart(String cartId, String productId) async {
    HapticFeedback.mediumImpact();
    
    try {
      await CartService.removeProductFromCart(
        cartId: cartId,
        productId: productId,
      );
      
      // Recharger les paniers pour refléter les changements
      _loadCartItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _toggleCartExpansion(String cartId) {
    setState(() {
      if (_expandedCarts.contains(cartId)) {
        _expandedCarts.remove(cartId);
      } else {
        _expandedCarts.add(cartId);
      }
    });
  }

  void _proceedToCheckout() {
    HapticFeedback.mediumImpact();
    
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre panier est vide'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCheckoutBottomSheet(),
    );
  }
  
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });
    
    try {
      // Vérifier les permissions
      final hasPermission = await LocationService.checkAndRequestLocationPermission();
      if (!hasPermission) {
        if (mounted) {
          final shouldOpenSettings = await LocationService.showLocationPermissionDialog(context);
          if (shouldOpenSettings) {
            await LocationService.openAppSettings();
          }
        }
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }
      
      // Obtenir la position actuelle
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        // Obtenir l'adresse à partir des coordonnées
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude, 
          position.longitude
        );
        
        if (mounted && address != null) {
          setState(() {
            _addressController.text = address;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }
  
  Future<void> _placeOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une adresse de livraison'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_selectedZoneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une zone de livraison'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isPlacingOrder = true;
    });
    
    try {
      // Préparer les items pour la commande
      final items = _cartItems.map((item) {
        return {
          'name': item['cart_name'],
          'quantity': item['items_count'],
          'price': _safeToDouble(item['unit_price']),
          'total': _safeToDouble(item['cart_total_price']),
          'type': item['cart_reference_type'] ?? 'product',
          'reference_id': item['cart_reference_id'] ?? item['id'],
        };
      }).toList();
      
      // Créer la commande
      final userId = await _getUserId();
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      // Obtenir la position actuelle si disponible
      final position = await LocationService.getCurrentPosition();
      Map<String, dynamic>? locationData;
      
      if (position != null) {
        locationData = {
          'delivery_latitude': position.latitude,
          'delivery_longitude': position.longitude,
        };
      }
      
      final order = await DeliveryService.createOrderWithDelivery(
        userId: userId,
        totalAmount: _total + CurrencyUtils.deliveryFee,
        items: items,
        deliveryAddress: _addressController.text.trim(),
        deliveryZoneId: _selectedZoneId!,
        deliveryNotes: 'Commande passée via l\'application mobile',
        additionalData: locationData,
      );
      
      if (order != null) {
        // Vider le panier après commande réussie
        await CartService.clearMainCart();
        
        if (mounted) {
          // Fermer la modal
          Navigator.pop(context);
          
          // Afficher un message de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Commande #${order.id.substring(0, 8)} confirmée !'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Voir',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Naviguer vers la page de détail de la commande
                },
              ),
            ),
          );
          
          // Recharger le panier (qui sera vide)
          _loadCartItems();
        }
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
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }
  
  Future<String?> _getUserId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      return user?.id;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text('Mon Panier'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.getCardBackground(isDark),
                    title: Text(
                      'Vider le panier',
                      style: TextStyle(color: AppColors.getTextPrimary(isDark)),
                    ),
                    content: Text(
                      'Êtes-vous sûr de vouloir vider votre panier ?',
                      style: TextStyle(color: AppColors.getTextSecondary(isDark)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Annuler',
                          style: TextStyle(color: AppColors.getTextSecondary(isDark)),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await CartService.clearMainCart();
                            setState(() {
                              _cartItems.clear();
                              _expandedCartDetails.clear();
                              _total = 0.0;
                            });
                            HapticFeedback.mediumImpact();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                        child: const Text('Vider', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_sweep),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorState(isDark)
              : _cartItems.isEmpty
                  ? _buildEmptyCart(isDark)
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          // Header avec résumé
                          _buildCartHeader(isDark),
                          
                          // Liste des articles
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _cartItems.length,
                              itemBuilder: (context, index) {
                                final item = _cartItems[index];
                                return _buildCartItem(item, index, isDark);
                              },
                            ),
                          ),
                          
                          // Bouton de commande
                          _buildCheckoutButton(isDark),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.error.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage.isNotEmpty 
                  ? _errorMessage 
                  : 'Impossible de charger votre panier. Veuillez vérifier votre connexion.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.getTextSecondary(isDark),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadCartItems,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
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

  Widget _buildEmptyCart(bool isDark) {
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
              Icons.shopping_cart_outlined,
              size: 60,
              color: AppColors.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Votre panier est vide',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Découvrez nos produits et ajoutez-les à votre panier',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.getTextSecondary(isDark),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Naviguer vers la page produits
              Navigator.of(context).pushReplacementNamed('/products');
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Découvrir les produits'),
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

  Widget _buildCartHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_cart,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_cartItems.length} article${_cartItems.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Total: ${CurrencyUtils.formatPrice(_total)}',
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
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index, bool isDark) {
    // Déterminer le type de panier
    final cartType = item['cart_reference_type'] ?? 'product';
    final cartId = item['cart_reference_id'] ?? '';
    final isExpanded = _expandedCarts.contains(cartId);
    
    IconData cartIcon;
    Color cartIconColor;
    
    switch (cartType) {
      case 'personal':
        cartIcon = Icons.shopping_bag;
        cartIconColor = Colors.blue;
        break;
      case 'recipe':
        cartIcon = Icons.restaurant_menu;
        cartIconColor = Colors.green;
        break;
      case 'preconfigured':
        cartIcon = Icons.shopping_basket;
        cartIconColor = Colors.purple;
        break;
      default:
        cartIcon = Icons.shopping_cart;
        cartIconColor = AppColors.primary;
    }
    
    // Trouver les détails du panier
    final cartDetails = _expandedCartDetails.firstWhere(
      (detail) => detail['cart_id'] == cartId,
      orElse: () => {'items': []},
    );
    
    final cartItems = cartDetails['items'] as List<dynamic>? ?? [];
    
    return Column(
      children: [
        // En-tête du panier
        Container(
          margin: EdgeInsets.only(bottom: isExpanded ? 0 : 16),
          decoration: BoxDecoration(
            color: AppColors.getCardBackground(isDark),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(20),
              bottom: isExpanded ? Radius.zero : const Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.getShadow(isDark),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _toggleCartExpansion(cartId),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(20),
              bottom: isExpanded ? Radius.zero : const Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icône du type de panier
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: cartIconColor.withOpacity(0.1),
                    ),
                    child: item['image'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              item['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  cartIcon,
                                  color: cartIconColor,
                                  size: 30,
                                );
                              },
                            ),
                          )
                        : Icon(
                            cartIcon,
                            color: cartIconColor,
                            size: 30,
                          ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Informations du panier
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // Pour le panier personnel, simplifier le nom
                          cartType == 'personal' ? 'Panier personnel' : (item['cart_name'] ?? 'Article'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        
                        // Badge type de panier - seulement pour les types non-personnel
                        if (cartType != 'personal')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: cartIconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getCartTypeLabel(cartType),
                              style: TextStyle(
                                fontSize: 12,
                                color: cartIconColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        
                        // Nombre d'articles et prix
                        Row(
                          children: [
                            Text(
                              '${_safeToInt(item['items_count'])} article${_safeToInt(item['items_count']) > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.getTextSecondary(isDark),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              CurrencyUtils.formatPrice(_safeToDouble(item['cart_total_price'])),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Boutons d'action
                  Column(
                    children: [
                      // Bouton de suppression
                      GestureDetector(
                        onTap: () => _removeItem(index),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Indicateur d'expansion
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Détails du panier (produits) - visible uniquement si le panier est développé
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.getBackground(isDark),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getShadow(isDark),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: cartItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Chargement des produits...',
                        style: TextStyle(
                          color: AppColors.getTextSecondary(isDark),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: cartItems.map((product) {
                      return _buildProductItem(product, cartId, cartType, isDark);
                    }).toList(),
                  ),
          ),
      ],
    );
  }
  
  Widget _buildProductItem(Map<String, dynamic> product, String cartId, String cartType, bool isDark) {
    final productId = product['product_id'] ?? product['id'];
    final quantity = product['quantity'] ?? 1;
    final productName = product['name'] ?? product['product_name'] ?? 'Produit';
    final productImage = product['image'] ?? product['product_image'];
    final productPrice = _safeToDouble(product['price'] ?? product['product_price'] ?? 0);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.getBorder(isDark),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Image du produit
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: productImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      productImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primary,
                  ),
          ),
          
          const SizedBox(width: 12),
          
          // Nom et prix du produit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyUtils.formatPrice(productPrice),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // Contrôles de quantité
          Row(
            children: [
              // Bouton moins
              GestureDetector(
                onTap: () => _updateProductQuantity(cartId, productId, quantity - 1),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.getBackground(isDark),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.getBorder(isDark),
                    ),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
              ),
              
              // Quantité
              Container(
                width: 36,
                height: 28,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  quantity.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
              ),
              
              // Bouton plus
              GestureDetector(
                onTap: () => _updateProductQuantity(cartId, productId, quantity + 1),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _getCartTypeLabel(String cartType) {
    switch (cartType) {
      case 'personal':
        return 'Panier personnel';
      case 'recipe':
        return 'Panier recette';
      case 'preconfigured':
        return 'Panier préconfiguré';
      default:
        return 'Produit';
    }
  }

  Widget _buildCheckoutButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(isDark),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Résumé des coûts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sous-total:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
                Text(
                  CurrencyUtils.formatPrice(_total),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Livraison:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                ),
                Text(
                  CurrencyUtils.formatPrice(CurrencyUtils.deliveryFee),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                Text(
                  CurrencyUtils.formatPrice(_total + CurrencyUtils.deliveryFee),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Bouton commander
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cartItems.isNotEmpty ? _proceedToCheckout : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Commander',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
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
              'Finaliser la commande',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 20),
            
            // Adresse de livraison
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Adresse de livraison',
                      hintText: 'Entrez votre adresse complète',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isGettingLocation ? null : _getCurrentLocation,
                  icon: _isGettingLocation 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  tooltip: 'Utiliser ma position actuelle',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Zone de livraison
            DropdownButtonFormField<String>(
              value: _selectedZoneId,
              decoration: InputDecoration(
                labelText: 'Zone de livraison',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.map),
              ),
              items: _deliveryZones.map((zone) {
                final fee = _safeToDouble(zone['delivery_fee']);
                return DropdownMenuItem<String>(
                  value: zone['id'],
                  child: Text('${zone['name']} (${CurrencyUtils.formatPrice(fee)})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedZoneId = value;
                });
              },
            ),
            const SizedBox(height: 20),
            
            // Résumé de la commande
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getBackground(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sous-total:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                      ),
                      Text(
                        CurrencyUtils.formatPrice(_total),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Livraison:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                      ),
                      Text(
                        CurrencyUtils.formatPrice(CurrencyUtils.deliveryFee),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                      Text(
                        CurrencyUtils.formatPrice(_total + CurrencyUtils.deliveryFee),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Méthode de paiement
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getBackground(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payments,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paiement à la livraison',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                        ),
                        Text(
                          'Payez en espèces à la réception',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            
            // Boutons
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isPlacingOrder ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: AppColors.getBorder(isDark)),
                    ),
                    child: Text(
                      'Annuler',
                      style: TextStyle(color: AppColors.getTextPrimary(isDark)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isPlacingOrder ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isPlacingOrder
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirmer la commande',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}