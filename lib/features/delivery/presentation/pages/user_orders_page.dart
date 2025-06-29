import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/delivery_service.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../data/models/order.dart';
import 'order_tracking_page.dart';

class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _activeDeliveries = [];
  bool _isLoading = true;
  String _currentTab = 'active'; // 'active' ou 'history'
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadData();
    
    // Rafraîchir les données toutes les 60 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentTab = _tabController.index == 0 ? 'active' : 'history';
      });
    }
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Charger les commandes de l'utilisateur
      final orders = await DeliveryService.getUserOrdersWithTracking();
      
      // Charger les livraisons actives
      final activeDeliveries = await DeliveryService.getUserActiveDeliveries();
      
      if (mounted) {
        setState(() {
          _orders = orders;
          _activeDeliveries = activeDeliveries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
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
        title: const Text('Mes commandes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: const Icon(Icons.delivery_dining),
              text: 'En cours (${_activeDeliveries.length})',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'Historique',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Onglet des livraisons actives
                _activeDeliveries.isEmpty
                    ? _buildEmptyActiveDeliveries(isDark)
                    : _buildActiveDeliveriesList(isDark),
                
                // Onglet de l'historique
                _orders.isEmpty
                    ? _buildEmptyOrderHistory(isDark)
                    : _buildOrderHistoryList(isDark),
              ],
            ),
    );
  }

  Widget _buildEmptyActiveDeliveries(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delivery_dining,
            size: 80,
            color: AppColors.getTextSecondary(isDark),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune livraison en cours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos commandes en cours de livraison apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondary(isDark),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Naviguer vers la page des produits
              Navigator.pop(context);
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Découvrir nos produits'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrderHistory(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: AppColors.getTextSecondary(isDark),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune commande passée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos commandes passées apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextSecondary(isDark),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Naviguer vers la page des produits
              Navigator.pop(context);
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Découvrir nos produits'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveriesList(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeDeliveries.length,
        itemBuilder: (context, index) {
          final order = _activeDeliveries[index];
          return _buildActiveDeliveryCard(order, isDark);
        },
      ),
    );
  }

  Widget _buildOrderHistoryList(bool isDark) {
    // Filtrer pour exclure les commandes actives
    final historyOrders = _orders.where((order) {
      final status = order['status'] as String? ?? '';
      return status == 'delivered' || status == 'cancelled';
    }).toList();
    
    if (historyOrders.isEmpty) {
      return _buildEmptyOrderHistory(isDark);
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyOrders.length,
        itemBuilder: (context, index) {
          final order = historyOrders[index];
          return _buildOrderHistoryCard(order, isDark);
        },
      ),
    );
  }

  Widget _buildActiveDeliveryCard(Map<String, dynamic> order, bool isDark) {
    final orderObj = Order.fromJson(order);
    final tracking = order['order_tracking'] as List?;
    final deliveryPerson = order['delivery_persons'] as Map<String, dynamic>?;
    final deliveryPersonProfile = deliveryPerson != null && order['profiles'] != null
        ? order['profiles'] as Map<String, dynamic>?
        : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(isDark),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingPage(
                orderId: orderObj.id,
              ),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getOrderStatusColor(orderObj.status).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getOrderStatusColor(orderObj.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getOrderStatusIcon(orderObj.status),
                      color: _getOrderStatusColor(orderObj.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande #${orderObj.id.substring(0, 8)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                        ),
                        if (orderObj.createdAt != null)
                          Text(
                            app_date_utils.AppDateUtils.formatDateTime(orderObj.createdAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.getTextSecondary(isDark),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getOrderStatusColor(orderObj.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getOrderStatusDisplay(orderObj.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Livreur
                  if (deliveryPersonProfile != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.delivery_dining,
                          size: 20,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Livreur: ${deliveryPersonProfile['display_name'] ?? 'Inconnu'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Adresse
                  if (orderObj.deliveryAddress != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 20,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Adresse: ${orderObj.deliveryAddress}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.getTextPrimary(isDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Heure estimée
                  if (orderObj.estimatedDeliveryTime != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 20,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Livraison estimée: ${app_date_utils.AppDateUtils.formatDateTime(orderObj.estimatedDeliveryTime!)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Montant
                  if (orderObj.totalAmount != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.payments,
                          size: 20,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Montant: ${orderObj.totalAmount!.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Bouton de suivi
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderTrackingPage(
                              orderId: orderObj.id,
                            ),
                          ),
                        ).then((_) => _loadData());
                      },
                      icon: const Icon(Icons.map, size: 16),
                      label: const Text('Suivre la livraison'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistoryCard(Map<String, dynamic> order, bool isDark) {
    final orderObj = Order.fromJson(order);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.getShadow(isDark),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getOrderStatusColor(orderObj.status).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(orderObj.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getOrderStatusIcon(orderObj.status),
                    color: _getOrderStatusColor(orderObj.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Commande #${orderObj.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                      if (orderObj.createdAt != null)
                        Text(
                          app_date_utils.AppDateUtils.formatDateTime(orderObj.createdAt!),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(orderObj.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getOrderStatusDisplay(orderObj.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date de livraison
                if (orderObj.actualDeliveryTime != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 20,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Livrée le: ${app_date_utils.AppDateUtils.formatDateTime(orderObj.actualDeliveryTime!)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Adresse
                if (orderObj.deliveryAddress != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 20,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Adresse: ${orderObj.deliveryAddress}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Montant
                if (orderObj.totalAmount != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.payments,
                        size: 20,
                        color: AppColors.getTextSecondary(isDark),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Montant: ${orderObj.totalAmount!.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Bouton de détails
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderTrackingPage(
                            orderId: orderObj.id,
                          ),
                        ),
                      ).then((_) => _loadData());
                    },
                    icon: const Icon(Icons.receipt_long, size: 16),
                    label: const Text('Voir les détails'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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

  Color _getOrderStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.grey;
      case 'confirmed': return Colors.blue;
      case 'preparing': return Colors.orange;
      case 'ready_for_pickup': return Colors.amber;
      case 'out_for_delivery': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getOrderStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.receipt;
      case 'confirmed': return Icons.check_circle;
      case 'preparing': return Icons.inventory;
      case 'ready_for_pickup': return Icons.inventory_2;
      case 'out_for_delivery': return Icons.delivery_dining;
      case 'delivered': return Icons.home;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help;
    }
  }

  String _getOrderStatusDisplay(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'preparing': return 'En préparation';
      case 'ready_for_pickup': return 'Prête';
      case 'out_for_delivery': return 'En livraison';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return 'Inconnu';
    }
  }
}