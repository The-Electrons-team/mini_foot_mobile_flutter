import 'package:flutter_test/flutter_test.dart';
import 'package:minifoot/reservations_screen.dart';
import 'package:minifoot/terrain_data.dart';

void main() {
  group('Reservation.fromApiJson', () {
    test('mappe correctement un objet API complet', () {
      final json = {
        'id': 'res-uuid-123',
        'date': '2025-06-15T00:00:00.000Z',
        'startSlot': '10h00',
        'endSlot': '11h30',
        'finalPrice': 7500,
        'reference': 'MF-ABC123',
        'status': 'CONFIRMED',
        'terrain': {
          'id': 'terrain-uuid',
          'name': 'Terrain Dakar Arena',
          'address': 'Diamniadio, Dakar',
          'zone': 'DAKAR',
          'pricePerHour': 5000,
          'rating': 4.8,
          'lat': 14.7645,
          'lng': -17.3660,
          'imageUrl': 'https://example.com/image.jpg',
        },
      };

      final reservation = Reservation.fromApiJson(json);

      expect(reservation.id, 'res-uuid-123');
      expect(reservation.startSlot, '10h00');
      expect(reservation.endSlot, '11h30');
      expect(reservation.price, 7500);
      expect(reservation.reference, 'MF-ABC123');
      expect(reservation.status, 'CONFIRMED');
      expect(reservation.terrain.name, 'Terrain Dakar Arena');
      expect(reservation.terrain.pricePerHour, 5000);
      expect(reservation.date.year, 2025);
      expect(reservation.date.month, 6);
      expect(reservation.date.day, 15);
    });

    test('utilise imageUrl depuis le tableau images si présent', () {
      final json = {
        'id': 'res-1',
        'date': '2025-06-15T00:00:00.000Z',
        'startSlot': '08h00',
        'endSlot': '09h00',
        'finalPrice': 4000,
        'reference': 'MF-XYZ',
        'status': 'PENDING_PAYMENT',
        'terrain': {
          'id': 'terrain-1',
          'name': 'Terrain Test',
          'address': 'Test, Dakar',
          'zone': 'DAKAR',
          'pricePerHour': 4000,
          'rating': 4.0,
          'lat': 14.7,
          'lng': -17.4,
          'images': [
            {'url': 'https://cdn.example.com/photo.jpg'},
          ],
        },
      };

      final reservation = Reservation.fromApiJson(json);
      expect(reservation.terrain.imageUrl, 'https://cdn.example.com/photo.jpg');
    });

    test('gère les champs manquants sans crash', () {
      final json = <String, dynamic>{};
      final reservation = Reservation.fromApiJson(json);

      expect(reservation.id, '');
      expect(reservation.startSlot, '');
      expect(reservation.price, 0);
      expect(reservation.status, 'PENDING_PAYMENT');
    });

    test('isPast est true quand status est CANCELLED', () {
      final json = {
        'id': 'res-1',
        'date': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'startSlot': '10h00',
        'endSlot': '11h00',
        'finalPrice': 5000,
        'reference': 'MF-1',
        'status': 'CANCELLED',
        'terrain': <String, dynamic>{},
      };

      final reservation = Reservation.fromApiJson(json);
      expect(reservation.isPast, isTrue);
      expect(reservation.isActive, isFalse);
    });

    test('isPast est true quand status est COMPLETED', () {
      final json = {
        'id': 'res-1',
        'date': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'startSlot': '10h00',
        'endSlot': '11h00',
        'finalPrice': 5000,
        'reference': 'MF-1',
        'status': 'COMPLETED',
        'terrain': <String, dynamic>{},
      };

      final reservation = Reservation.fromApiJson(json);
      expect(reservation.isPast, isTrue);
    });

    test('isActive est true quand CONFIRMED et date future', () {
      final json = {
        'id': 'res-1',
        'date': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'startSlot': '10h00',
        'endSlot': '11h00',
        'finalPrice': 5000,
        'reference': 'MF-1',
        'status': 'CONFIRMED',
        'terrain': <String, dynamic>{},
      };

      final reservation = Reservation.fromApiJson(json);
      expect(reservation.isActive, isTrue);
    });

    test('isPast est true pour une date passée même avec status CONFIRMED', () {
      final json = {
        'id': 'res-1',
        'date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'startSlot': '10h00',
        'endSlot': '11h00',
        'finalPrice': 5000,
        'reference': 'MF-1',
        'status': 'CONFIRMED',
        'terrain': <String, dynamic>{},
      };

      final reservation = Reservation.fromApiJson(json);
      expect(reservation.isPast, isTrue);
    });
  });

  group('Reservation model', () {
    test('cancelled=true rend isPast=true indépendamment du status', () {
      final r = Reservation(
        id: '1',
        terrain: const Terrain(
          id: '1', name: 'T', address: 'A', zone: 'DAKAR',
          pricePerHour: 5000, rating: 4.0, lat: 0, lng: 0, imageUrl: '',
        ),
        date: DateTime.now().add(const Duration(days: 10)),
        startSlot: '10h00',
        endSlot: '11h00',
        price: 5000,
        reference: 'MF-1',
        status: 'CONFIRMED',
        cancelled: true,
      );

      expect(r.isPast, isTrue);
      expect(r.isActive, isFalse);
    });
  });
}
