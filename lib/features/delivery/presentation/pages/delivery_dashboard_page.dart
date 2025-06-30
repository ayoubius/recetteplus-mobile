import 'package:flutter/material.dart';
import 'package:recette_plus/core/constants/app_colors.dart';
import 'package:recette_plus/core/services/delivery_service.dart';
// Import a model for Order if you have one, or use Map<String, dynamic>
// For now, we'll assume DeliveryService returns List<Map<String, dynamic>>
// and we'll access fields directly.
import 'delivery_order_detail_page.dart'; // Import the detail page

class DeliveryDashboardPage extends StatefulWidget {
  const DeliveryDashboardPage({super.key});

  @override
  State<DeliveryDashboardPage> createState() => _DeliveryDashboardPageState();
}

class _DeliveryDashboardPageState extends State<DeliveryDashboardPage> {
  List<Map<String, dynamic>> _assignedOrders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssignedOrders();
  }

  Future<void> _loadAssignedOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // First, check if the current user is a delivery person
      final isDeliverer = await DeliveryService.isDeliveryPerson();
      if (!isDeliverer) {
        _error = "Accès refusé. Vous n'êtes pas un livreur.";
        setState(() => _isLoading = false);
        return;
      }
      _assignedOrders = await DeliveryService.getAssignedOrders();
    } catch (e) {
      _error = 'Erreur de chargement des commandes: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Livraisons Assignées'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssignedOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _error!,
                      style: TextStyle(color: AppColors.error, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ))
              : _assignedOrders.isEmpty
                  ? Center(
                      child: Text(
                      'Aucune commande assignée pour le moment.',
                      style: TextStyle(fontSize: 16, color: AppColors.getTextSecondary(isDark)),
                    ))
                  : RefreshIndicator(
                      onRefresh: _loadAssignedOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _assignedOrders.length,
                        itemBuilder: (context, index) {
                          final order = _assignedOrders[index];
                          // Safely access order details
                          final orderId = order['id']?.toString() ?? 'N/A';
                          final status = order['status']?.toString() ?? 'N/A';
                          final customerName = order['profiles']?['display_name'] ?? order['profiles']?['full_name'] ?? 'Client Inconnu';
                          final address = order['delivery_address']?.toString() ?? 'Adresse non fournie';
                          final totalAmount = order['total_amount']?.toString() ?? 'N/A';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            elevation: 2,
                            color: AppColors.getCardBackground(isDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Icon(Icons.delivery_dining, color: AppColors.primary),
                              ),
                              title: Text(
                                'Commande #${orderId.substring(0,_getSafeSubstringLength(orderId, 8))}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Client: $customerName', style: TextStyle(color: AppColors.getTextSecondary(isDark))),
                                  Text('Adresse: $address', style: TextStyle(color: AppColors.getTextSecondary(isDark))),
                                  Text('Statut: $status', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.primary)),
                                  Text('Montant: $totalAmount FCFA', style: TextStyle(color: AppColors.getTextSecondary(isDark))),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, color: AppColors.getTextSecondary(isDark), size: 16),
                              isThreeLine: true, // Adjust if content varies
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DeliveryOrderDetailPage(order: order),
                                  ),
                                ).then((_) {
                                  // Refresh the list when returning from detail page
                                  // in case status was updated.
                                  _loadAssignedOrders();
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  int _getSafeSubstringLength(String str, int desiredLength) {
    return str.length < desiredLength ? str.length : desiredLength;
  }
}
