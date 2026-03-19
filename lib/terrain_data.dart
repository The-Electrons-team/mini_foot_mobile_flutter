import 'package:flutter/material.dart';

class Terrain {
  final String id;
  final String name;
  final String address;
  final String price;
  final double rating;
  final String distance;
  final int booked;
  final double lat;
  final double lng;
  final String imageUrl;
  final List<String> imageUrls;
  final List<TerrainFeature> features;
  final String description;
  final List<String> bookedSlots; // format 'HHhMM', ex: ['10h00','10h15']

  const Terrain({
    required this.id,
    required this.name,
    required this.address,
    required this.price,
    required this.rating,
    required this.distance,
    required this.booked,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    required this.imageUrls,
    required this.features,
    required this.description,
    this.bookedSlots = const [],
  });
}

class TerrainFeature {
  final IconData icon;
  final String label;
  const TerrainFeature(this.icon, this.label);
}

final List<Terrain> terrains = [
  Terrain(
    id: '1',
    name: 'Terrain Dakar Arena',
    address: 'Diamniadio, Dakar',
    price: '5000 F/h',
    rating: 4.8,
    distance: '1.2 km',
    booked: 24,
    lat: 14.7645,
    lng: -17.3660,
    imageUrl: 'https://images.pexels.com/photos/12486370/pexels-photo-12486370.jpeg?auto=compress&cs=tinysrgb&w=800',
    imageUrls: [
      'https://images.pexels.com/photos/12486370/pexels-photo-12486370.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/13783930/pexels-photo-13783930.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/7160121/pexels-photo-7160121.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/13890306/pexels-photo-13890306.jpeg?auto=compress&cs=tinysrgb&w=800',
    ],
    description: 'Terrain Dakar Arena est un terrain de football moderne situé à Diamniadio. Connu pour son gazon synthétique de haute qualité et son éclairage LED, il est idéal pour les matchs en soirée et les tournois locaux.',
    bookedSlots: ['10h00','10h15','10h30','10h45','14h00','14h15','14h30','18h00','18h15','18h30','18h45'],
    features: [
      TerrainFeature(Icons.straighten_rounded, '100 x 65 m'),
      TerrainFeature(Icons.local_parking_rounded, 'Parking gratuit'),
      TerrainFeature(Icons.grass_rounded, 'Gazon synthétique'),
      TerrainFeature(Icons.lightbulb_outline_rounded, 'Éclairage LED'),
      TerrainFeature(Icons.group_rounded, '22 joueurs max'),
      TerrainFeature(Icons.shower_rounded, 'Vestiaires'),
    ],
  ),
  Terrain(
    id: '2',
    name: 'Stade Léopold Sédar',
    address: 'Plateau, Dakar',
    price: '8000 F/h',
    rating: 4.5,
    distance: '2.5 km',
    booked: 38,
    lat: 14.6760,
    lng: -17.4469,
    imageUrl: 'https://images.pexels.com/photos/13783930/pexels-photo-13783930.jpeg?auto=compress&cs=tinysrgb&w=800',
    imageUrls: [
      'https://images.pexels.com/photos/13783930/pexels-photo-13783930.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/12486370/pexels-photo-12486370.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/13890306/pexels-photo-13890306.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/7160121/pexels-photo-7160121.jpeg?auto=compress&cs=tinysrgb&w=800',
    ],
    description: 'Le Stade Léopold Sédar est un terrain officiel situé au cœur du Plateau. Avec son gazon naturel et ses installations professionnelles, c\'est le choix idéal pour les compétitions officielles.',
    bookedSlots: ['09h00','09h15','09h30','09h45','13h00','13h15','20h00','20h15','20h30'],
    features: [
      TerrainFeature(Icons.straighten_rounded, '105 x 68 m'),
      TerrainFeature(Icons.local_parking_rounded, 'Parking'),
      TerrainFeature(Icons.eco_rounded, 'Gazon naturel'),
      TerrainFeature(Icons.lightbulb_outline_rounded, 'Éclairage'),
      TerrainFeature(Icons.group_rounded, '22 joueurs max'),
      TerrainFeature(Icons.emoji_events_rounded, 'Terrain officiel'),
    ],
  ),
  Terrain(
    id: '3',
    name: 'Terrain Point E',
    address: 'Point E, Dakar',
    price: '6500 F/h',
    rating: 4.3,
    distance: '3.1 km',
    booked: 15,
    lat: 14.6928,
    lng: -17.4571,
    imageUrl: 'https://images.pexels.com/photos/7160121/pexels-photo-7160121.jpeg?auto=compress&cs=tinysrgb&w=800',
    imageUrls: [
      'https://images.pexels.com/photos/7160121/pexels-photo-7160121.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/12486370/pexels-photo-12486370.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/13783930/pexels-photo-13783930.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/13890306/pexels-photo-13890306.jpeg?auto=compress&cs=tinysrgb&w=800',
    ],
    description: 'Le Terrain Point E est un espace de jeu convivial dans le quartier résidentiel de Point E. Parfait pour les matchs entre amis, il dispose d\'une buvette et de vestiaires confortables.',
    bookedSlots: ['11h00','11h15','11h30','11h45','16h00','16h15','16h30','16h45','21h00','21h15'],
    features: [
      TerrainFeature(Icons.straighten_rounded, '80 x 50 m'),
      TerrainFeature(Icons.grass_rounded, 'Gazon synthétique'),
      TerrainFeature(Icons.lightbulb_outline_rounded, 'Éclairage'),
      TerrainFeature(Icons.group_rounded, '14 joueurs max'),
      TerrainFeature(Icons.shower_rounded, 'Vestiaires'),
      TerrainFeature(Icons.local_bar_rounded, 'Buvette'),
    ],
  ),
  Terrain(
    id: '4',
    name: 'Terrain HLM',
    address: 'HLM Grand Yoff, Dakar',
    price: '4000 F/h',
    rating: 4.1,
    distance: '0.8 km',
    booked: 10,
    lat: 14.7120,
    lng: -17.4620,
    imageUrl: 'https://images.pexels.com/photos/13890306/pexels-photo-13890306.jpeg?auto=compress&cs=tinysrgb&w=800',
    imageUrls: [
      'https://images.pexels.com/photos/13890306/pexels-photo-13890306.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/7160121/pexels-photo-7160121.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/12486370/pexels-photo-12486370.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/13783930/pexels-photo-13783930.jpeg?auto=compress&cs=tinysrgb&w=800',
    ],
    description: 'Le Terrain HLM est le terrain de quartier par excellence à Grand Yoff. Accessible et bien équipé, il accueille des joueurs de tous niveaux dans une ambiance conviviale et familiale.',
    bookedSlots: ['08h00','08h15','12h00','12h15','12h30','17h00','17h15','17h30','17h45','22h00','22h15'],
    features: [
      TerrainFeature(Icons.straighten_rounded, '60 x 40 m'),
      TerrainFeature(Icons.grass_rounded, 'Gazon synthétique'),
      TerrainFeature(Icons.group_rounded, '10 joueurs max'),
      TerrainFeature(Icons.local_bar_rounded, 'Buvette'),
      TerrainFeature(Icons.lightbulb_outline_rounded, 'Éclairage'),
      TerrainFeature(Icons.checkroom_rounded, 'Location maillots'),
    ],
  ),
];
