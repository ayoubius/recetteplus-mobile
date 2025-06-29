import 'package:flutter/material.dart';

class DeliveryMapWidget extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? deliveryAddress;

  const DeliveryMapWidget({
    super.key,
    this.latitude,
    this.longitude,
    this.deliveryAddress,
  });

  @override
  Widget build(BuildContext context) {
    // Vérifier si les coordonnées sont disponibles
    final hasCoordinates = latitude != null && longitude != null;
    
    return Stack(
      children: [
        // Placeholder de carte (à remplacer par une vraie carte)
        Container(
          color: Colors.grey[200],
          child: hasCoordinates
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.map,
                        size: 60,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Carte de livraison',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Position: $latitude, $longitude',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (deliveryAddress != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            deliveryAddress!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Position non disponible',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Le livreur n\'a pas encore partagé sa position',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ),
        
        // Overlay avec informations
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Livraison en cours',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (hasCoordinates)
                  const Text(
                    'Le livreur est en route vers votre adresse',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  )
                else
                  const Text(
                    'En attente de la position du livreur',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Bouton plein écran
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.black87),
              onPressed: () {
                // TODO: Ouvrir la carte en plein écran
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité à venir'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}