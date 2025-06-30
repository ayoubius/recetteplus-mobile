// lib/features/delivery/presentation/pages/admin_assign_order_page.dart
// Page destinée aux administrateurs pour assigner les commandes en attente aux livreurs disponibles.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:recette_plus/core/constants/app_colors.dart';
import 'package:recette_plus/core/services/delivery_service.dart';
import 'package:recette_plus/core/services/admin_service.dart'; // Assuming admin check

class AdminAssignOrderPage extends StatefulWidget {
  const AdminAssignOrderPage({super.key});

  @override
  State<AdminAssignOrderPage> createState() => _AdminAssignOrderPageState();
}

class _AdminAssignOrderPageState extends State<AdminAssignOrderPage> {
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _deliveryPersons = [];
  bool _isLoading = true;
  String? _error;
  Map<String, String?> _selectedDeliveryPersonForOrder = {}; // orderId -> deliveryPersonId
  Map<String, bool> _isAssigningOrder = {}; // orderId -> bool (true if assigning)


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Charge les données nécessaires: commandes en attente et livreurs.
  /// Vérifie également si l'utilisateur actuel est un administrateur.
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // First, check if the current user is an admin
      final isAdminUser = await AdminService.isAdmin();
      if (!isAdminUser) {
          _error = "Accès refusé. Vous n'êtes pas un administrateur.";
          setState(() => _isLoading = false);
          return;
      }

      _pendingOrders = await DeliveryService.getPendingOrders();
      // Using getAllDeliveryPersons for now. Ideally, filter for 'available' status.
      _deliveryPersons = await DeliveryService.getAllDeliveryPersons();
    } catch (e) {
      _error = 'Erreur de chargement des données: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Assigne une commande à un livreur et rafraîchit la liste.
  Future<void> _assignOrder(String orderId, String deliveryPersonId) async {
    if (!mounted) return;
    setState(() {
      _isAssigningOrder[orderId] = true;
    });

    try {
      final success = await DeliveryService.assignDeliveryPerson(
        orderId: orderId,
        deliveryPersonId: deliveryPersonId,
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Commande assignée avec succès!'), backgroundColor: AppColors.success),
          );
        }
        _loadData(); // Rafraîchir la liste pour enlever la commande assignée.
      } else {
        throw Exception('Échec de l\'assignation de la commande');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'assignation: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAssigningOrder[orderId] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigner Commandes'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
              : _pendingOrders.isEmpty
                  ? Center(
                      child: Text(
                      'Aucune commande en attente d\'assignation.',
                      style: TextStyle(fontSize: 16, color: AppColors.getTextSecondary(isDark)),
                    ))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _pendingOrders.length,
                        itemBuilder: (context, index) {
                          final order = _pendingOrders[index];
                          final orderId = order['id']?.toString() ?? 'N/A';
                          final customerName = order['profiles']?['display_name'] ?? order['profiles']?['full_name'] ?? 'Client Inconnu';
                          final address = order['delivery_address']?.toString() ?? 'N/A';
                          final orderTotal = order['total_amount']?.toString() ?? 'N/A';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            elevation: 2,
                            color: AppColors.getCardBackground(isDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Commande #${orderId.substring(0, _getSafeSubstringLength(orderId, 8))}',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Client: $customerName', style: TextStyle(color: AppColors.getTextSecondary(isDark))),
                                  Text('Adresse: $address', style: TextStyle(color: AppColors.getTextSecondary(isDark))),
                                  Text('Montant: $orderTotal FCFA', style: TextStyle(color: AppColors.getTextSecondary(isDark))),
                                  const SizedBox(height: 8),
                                  if (_deliveryPersons.isNotEmpty)
                                    DropdownButtonFormField<String>(
                                      value: _selectedDeliveryPersonForOrder[orderId],
                                      hint: const Text('Choisir un livreur'),
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      items: _deliveryPersons.map((dp) {
                                        final dpId = dp['id']?.toString() ?? '';
                                        // Accessing profile data joined with delivery_persons
                                        final dpName = dp['profiles']?['display_name'] ?? dp['profiles']?['full_name'] ?? 'Livreur Inconnu';
                                        final dpStatus = dp['current_status']?.toString() ?? 'N/A';
                                        return DropdownMenuItem<String>(
                                          value: dpId,
                                          child: Text('$dpName ($dpStatus)'),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedDeliveryPersonForOrder[orderId] = value;
                                        });
                                      },
                                    )
                                  else
                                    Text("Aucun livreur disponible.", style: TextStyle(color: AppColors.getTextSecondary(isDark))),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: (_selectedDeliveryPersonForOrder[orderId] == null || _isAssigningOrder[orderId] == true)
                                          ? null
                                          : () => _assignOrder(orderId, _selectedDeliveryPersonForOrder[orderId]!),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: _isAssigningOrder[orderId] == true
                                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                          : const Text('Assigner ce livreur'),
                                    ),
                                  ),
                                ],
                              ),
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
