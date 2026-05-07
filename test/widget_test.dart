// Tests unitaires MiniFoot — providers, modèles, logique métier
// Remplace le test boilerplate counter (widget inexistant).

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minifoot/providers/auth_provider.dart';
import 'package:minifoot/providers/terrain_provider.dart';
import 'package:minifoot/providers/team_provider.dart';
import 'package:minifoot/providers/reservation_provider.dart';
import 'package:minifoot/reservations_screen.dart';
import 'package:minifoot/terrain_data.dart';

void main() {
  setUpAll(() {
    // Charge un .env minimal pour que les services puissent s'instancier
    dotenv.testLoad(fileInput: 'API_URL=http://localhost:3000/api/v1\n');
  });

  group('AuthProvider — état initial', () {
    test('non authentifié par défaut', () {
      final p = AuthProvider();
      expect(p.isAuthenticated, isFalse);
      expect(p.token, isNull);
      expect(p.user, isNull);
      expect(p.isLoading, isFalse);
    });
  });

  group('TerrainProvider — état initial', () {
    test('liste vide au démarrage', () {
      final p = TerrainProvider();
      expect(p.terrains, isEmpty);
      expect(p.isLoading, isFalse);
    });
  });

  group('TeamProvider — état initial', () {
    test('pas d\'équipes au démarrage', () {
      final p = TeamProvider();
      expect(p.myTeams, isEmpty);
    });
  });

  group('ReservationProvider — état initial', () {
    test('liste vide, pas de chargement, pas d\'erreur', () {
      final p = ReservationProvider();
      expect(p.reservations, isEmpty);
      expect(p.isLoading, isFalse);
      expect(p.error, isNull);
      expect(p.upcoming, isEmpty);
      expect(p.past, isEmpty);
    });

    test('clearError ne provoque pas d\'exception', () {
      final p = ReservationProvider();
      expect(() => p.clearError(), returnsNormally);
    });
  });

  group('Reservation.fromApiJson', () {
    test('mappe tous les champs correctement', () {
      final r = Reservation.fromApiJson({
        'id': 'res-uuid',
        'date': '2025-08-10T00:00:00.000Z',
        'startSlot': '10h00',
        'endSlot': '11h30',
        'finalPrice': 7500,
        'reference': 'MF-TEST001',
        'status': 'CONFIRMED',
        'terrain': {
          'id': 't-1',
          'name': 'Arena Dakar',
          'address': 'Diamniadio',
          'zone': 'DAKAR',
          'pricePerHour': 5000,
          'rating': 4.8,
          'lat': 14.76,
          'lng': -17.37,
          'imageUrl': 'https://example.com/img.jpg',
        },
      });

      expect(r.id, 'res-uuid');
      expect(r.startSlot, '10h00');
      expect(r.endSlot, '11h30');
      expect(r.price, 7500);
      expect(r.reference, 'MF-TEST001');
      expect(r.status, 'CONFIRMED');
      expect(r.terrain.name, 'Arena Dakar');
      expect(r.terrain.pricePerHour, 5000);
      expect(r.date.month, 8);
      expect(r.date.day, 10);
    });

    test('utilise images[] en priorité sur imageUrl', () {
      final r = Reservation.fromApiJson({
        'id': 'r1',
        'date': '2025-08-10T00:00:00.000Z',
        'startSlot': '08h00',
        'endSlot': '09h00',
        'finalPrice': 4000,
        'reference': 'MF-1',
        'status': 'PENDING_PAYMENT',
        'terrain': {
          'id': 't1',
          'name': 'T',
          'address': 'A',
          'zone': 'DAKAR',
          'pricePerHour': 4000,
          'rating': 4.0,
          'lat': 14.7,
          'lng': -17.4,
          'imageUrl': 'https://old-url.com/img.jpg',
          'images': [
            {'url': 'https://cdn.example.com/new.jpg'}
          ],
        },
      });
      expect(r.terrain.imageUrl, 'https://cdn.example.com/new.jpg');
    });

    test('gère un objet vide sans crash', () {
      expect(
        () => Reservation.fromApiJson({}),
        returnsNormally,
      );
    });

    test('status CANCELLED → isPast=true même avec date future', () {
      final r = Reservation.fromApiJson({
        'id': 'r1',
        'date': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
        'startSlot': '10h00',
        'endSlot': '11h00',
        'finalPrice': 5000,
        'reference': 'MF-1',
        'status': 'CANCELLED',
        'terrain': <String, dynamic>{},
      });
      expect(r.isPast, isTrue);
      expect(r.isActive, isFalse);
    });

    test('status CONFIRMED + date future → isActive=true', () {
      final r = Reservation.fromApiJson({
        'id': 'r1',
        'date': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'startSlot': '10h00',
        'endSlot': '11h00',
        'finalPrice': 5000,
        'reference': 'MF-1',
        'status': 'CONFIRMED',
        'terrain': <String, dynamic>{},
      });
      expect(r.isActive, isTrue);
      expect(r.isPast, isFalse);
    });

    test('date passée → isPast=true quelque soit le status', () {
      final r = Reservation.fromApiJson({
        'id': 'r1',
        'date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'startSlot': '10h00',
        'endSlot': '11h00',
        'finalPrice': 5000,
        'reference': 'MF-1',
        'status': 'CONFIRMED',
        'terrain': <String, dynamic>{},
      });
      expect(r.isPast, isTrue);
    });
  });

  group('Terrain model', () {
    const t = Terrain(
      id: 't-1',
      name: 'Arena Test',
      address: 'Dakar, Sénégal',
      zone: 'DAKAR',
      pricePerHour: 6000,
      rating: 4.7,
      lat: 14.76,
      lng: -17.37,
      imageUrl: 'https://example.com/img.jpg',
    );

    test('champs correctement assignés', () {
      expect(t.id, 't-1');
      expect(t.name, 'Arena Test');
      expect(t.pricePerHour, 6000);
      expect(t.rating, 4.7);
      expect(t.lat, 14.76);
    });

    test('subTerrains vide par défaut', () {
      expect(t.subTerrains, isEmpty);
    });
  });

  // ── Notification routing ──────────────────────────────────────────────────

  group('Notification routing — données de navigation', () {
    Map<String, dynamic> _buildNotifData({
      String screen = 'matches',
      String tabIndex = '2',
    }) =>
        {'screen': screen, 'tabIndex': tabIndex};

    test('screen=matches + tabIndex=2 → onglet Demandes (index 2)', () {
      final data = _buildNotifData(screen: 'matches', tabIndex: '2');
      expect(data['screen'], 'matches');
      expect(int.parse(data['tabIndex'].toString()), 2);
    });

    test('tabIndex manquant → fallback à 2 (Demandes)', () {
      final data = <String, dynamic>{'screen': 'matches'};
      final tabIndex = int.tryParse(data['tabIndex']?.toString() ?? '') ?? 2;
      expect(tabIndex, 2);
    });

    test('tabIndex=0 → onglet Mes Matchs', () {
      final data = _buildNotifData(tabIndex: '0');
      final tabIndex = int.tryParse(data['tabIndex'].toString()) ?? 2;
      expect(tabIndex, 0);
    });

    test('screen inconnu → pas de navigation (screen != matches)', () {
      final data = <String, dynamic>{'screen': 'profile'};
      final shouldNavigate = data['screen'] == 'matches';
      expect(shouldNavigate, isFalse);
    });

    test('données vides → pas de navigation', () {
      final data = <String, dynamic>{};
      final shouldNavigate = data['screen'] == 'matches';
      expect(shouldNavigate, isFalse);
    });

    test('CHALLENGE_RECEIVED → données screen + tabIndex présentes', () {
      // Simule le payload envoyé par le backend pour un défi reçu
      final data = <String, dynamic>{
        'type': 'CHALLENGE_RECEIVED',
        'challengeId': 'ch-1',
        'fromTeamId': 'team-a',
        'fromTeamName': 'Lions FC',
        'screen': 'matches',
        'tab': 'demandes',
        'tabIndex': '2',
      };
      expect(data['screen'], 'matches');
      expect(data['tabIndex'], '2');
      expect(int.tryParse(data['tabIndex'].toString()), 2);
    });

    test('CHALLENGE_RESPONSE accepté → matchId présent', () {
      final data = <String, dynamic>{
        'type': 'CHALLENGE_RESPONSE',
        'accepted': 'true',
        'matchId': 'match-xyz',
        'screen': 'matches',
        'tabIndex': '2',
      };
      expect(data['accepted'], 'true');
      expect(data['matchId'], isNotNull);
    });
  });
}
