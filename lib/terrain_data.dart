import 'dart:convert';
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

class SubTerrain {
  final String id;
  final String name;
  final String? physicalName;
  final String? divisionGroup;
  final String divisionType;
  final int divisionIndex;
  final int capacity;
  final String type;
  final String? surface;
  final int? pricePerHour;

  SubTerrain({
    required this.id,
    required this.name,
    this.physicalName,
    this.divisionGroup,
    this.divisionType = 'FULL',
    this.divisionIndex = 0,
    required this.capacity,
    required this.type,
    this.surface,
    this.pricePerHour,
  });

  factory SubTerrain.fromJson(Map<String, dynamic> json) {
    return SubTerrain(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      physicalName: json['physicalName']?.toString(),
      divisionGroup: json['divisionGroup']?.toString(),
      divisionType: json['divisionType']?.toString() ?? 'FULL',
      divisionIndex: _asInt(json['divisionIndex'], fallback: 0),
      capacity: _asInt(json['capacity'], fallback: 10),
      type: json['type']?.toString() ?? '5v5',
      surface: json['surface']?.toString(),
      pricePerHour: _asNullableInt(
        json['pricePerHour'] ?? json['price_per_hour'],
      ),
    );
  }

  String get reservationLabel {
    final base = physicalName ?? name;
    final suffix = switch (divisionType) {
      'HALF' => 'Demi $divisionIndex',
      'THIRD' => 'Tiers $divisionIndex',
      _ => 'Entier',
    };
    if (name.contains(suffix)) return name;
    return '$base - $suffix';
  }

  String get divisionLabel => switch (divisionType) {
    'HALF' => 'Demi-terrain',
    'THIRD' => 'Tiers de terrain',
    _ => 'Terrain entier',
  };
}

class Terrain {
  final String id;
  final String? subTerrainId;
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
  final List<String> contactPhones;
  final String description;
  final String? managerId;
  final bool isActive;
  final List<SubTerrain> subTerrains;

  const Terrain({
    required this.id,
    this.subTerrainId,
    required this.name,
    required this.address,
    required this.zone,
    required this.pricePerHour,
    required this.rating,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    this.managerId,
    this.imageUrls = const [],
    this.features = const [],
    this.contactPhones = const [],
    this.description = '',
    this.isActive = true,
    this.subTerrains = const [],
  });

  String get priceLabel => '$pricePerHour F/h';

  List<TerrainFeature> get featureIcons =>
      features.map((f) => TerrainFeature(_iconFor(f), f)).toList();

  factory Terrain.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String && val.startsWith('[')) {
        try {
          return (jsonDecode(val) as List).map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return [];
    }

    return Terrain(
      id: json['id']?.toString() ?? '',
      subTerrainId:
          json['subTerrainId']?.toString() ??
          json['sub_terrain_id']?.toString(),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      zone: json['zone']?.toString() ?? '',
      pricePerHour: _asInt(json['pricePerHour'] ?? json['price_per_hour']),
      rating: _asDouble(json['rating']),
      lat: _asDouble(json['lat']),
      lng: _asDouble(json['lng']),
      imageUrl:
          json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? '',
      managerId: json['managerId']?.toString(),
      imageUrls: parseList(json['imageUrls'] ?? json['image_urls']),
      features: parseList(json['features']),
      contactPhones: parseList(json['contactPhones'] ?? json['contact_phones']),
      description: json['description']?.toString() ?? '',
      isActive: json['isActive'] is bool
          ? json['isActive'] as bool
          : json['is_active'] is bool
          ? json['is_active'] as bool
          : true,
      subTerrains: (json['subTerrains'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((s) => SubTerrain.fromJson(s))
          .toList(),
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

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

class TerrainReview {
  final String id;
  final String terrainId;
  final String userId;
  final double rating;
  final String? comment;
  final String userName;
  final String? userAvatar;
  final DateTime createdAt;

  TerrainReview({
    required this.id,
    required this.terrainId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.userName,
    this.userAvatar,
    required this.createdAt,
  });

  factory TerrainReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return TerrainReview(
      id: json['id']?.toString() ?? '',
      terrainId: json['terrainId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'],
      userName: user != null
          ? '${user['first_name']} ${user['last_name']}'
          : 'Anonyme',
      userAvatar: user?['avatar_url'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
