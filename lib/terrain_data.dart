import 'package:flutter/material.dart';

class TerrainFeature {
  final IconData icon;
  final String label;
  const TerrainFeature(this.icon, this.label);
}

class TerrainSlot {
  final String slot;
  final bool available;
  TerrainSlot({required this.slot, required this.available});

  factory TerrainSlot.fromJson(Map<String, dynamic> json) => TerrainSlot(
        slot: json['slot'] ?? '',
        available: json['available'] ?? true,
      );
}

class Terrain {
  final String id;
  final String name;
  final String address;
  final String zone;
  final int pricePerHour;
  final double rating;
  final double lat;
  final double lng;
  final String imageUrl;
  final List<String> imageUrls;
  final List<String> features;
  final String description;
  final bool isActive;

  const Terrain({
    required this.id,
    required this.name,
    required this.address,
    required this.zone,
    required this.pricePerHour,
    required this.rating,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    this.imageUrls = const [],
    this.features = const [],
    this.description = '',
    this.isActive = true,
  });

  String get priceLabel => '$pricePerHour F/h';

  List<TerrainFeature> get featureIcons =>
      features.map((f) => TerrainFeature(_iconFor(f), f)).toList();

  factory Terrain.fromJson(Map<String, dynamic> json) {
    return Terrain(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      zone: json['zone'] ?? '',
      pricePerHour: (json['pricePerHour'] ?? 0) as int,
      rating: (json['rating'] ?? 0).toDouble(),
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  static IconData _iconFor(String feature) {
    final f = feature.toLowerCase();
    if (f.contains('gazon')) return Icons.grass_rounded;
    if (f.contains('parking')) return Icons.local_parking_rounded;
    if (f.contains('clairage')) return Icons.lightbulb_outline_rounded;
    if (f.contains('vestiaire')) return Icons.shower_rounded;
    if (f.contains('buvette')) return Icons.local_bar_rounded;
    if (f.contains('joueur')) return Icons.group_rounded;
    if (f.contains('officiel')) return Icons.emoji_events_rounded;
    if (f.contains('maillot')) return Icons.checkroom_rounded;
    if (RegExp(r'\d+ x \d+').hasMatch(f)) return Icons.straighten_rounded;
    return Icons.check_circle_outline_rounded;
  }
}
