import 'package:flutter_test/flutter_test.dart';
import 'package:minifoot/player_experience_helpers.dart';
import 'package:minifoot/reservations_screen.dart';
import 'package:minifoot/terrain_data.dart';

void main() {
  group('filterAndSortTerrains', () {
    const terrains = [
      Terrain(
        id: 't1',
        name: 'Arena Parcelles',
        address: 'Parcelles Assainies',
        zone: 'DAKAR',
        pricePerHour: 7000,
        rating: 4.2,
        lat: 0,
        lng: 0,
        imageUrl: '',
      ),
      Terrain(
        id: 't2',
        name: 'Dakar Five',
        address: 'Point E',
        zone: 'DAKAR',
        pricePerHour: 5000,
        rating: 4.9,
        lat: 0,
        lng: 0,
        imageUrl: '',
      ),
      Terrain(
        id: 't3',
        name: 'Stade Amitie',
        address: 'Yoff',
        zone: 'DAKAR',
        pricePerHour: 4500,
        rating: 4.6,
        lat: 0,
        lng: 0,
        imageUrl: '',
      ),
    ];

    test('filtre par requete puis trie par proximite quand une distance est disponible', () {
      final results = filterAndSortTerrains(
        terrains: terrains,
        query: 'ar',
        filter: TerrainDiscoveryFilter.nearby,
        distanceFor: (terrain) => switch (terrain.id) {
          't1' => 8,
          't2' => 2,
          _ => 12,
        },
      );

      expect(results.map((t) => t.id).toList(), ['t2', 't1']);
    });

    test('trie par note puis prix pour le filtre mieux notes', () {
      final results = filterAndSortTerrains(
        terrains: terrains,
        query: '',
        filter: TerrainDiscoveryFilter.topRated,
      );

      expect(results.map((t) => t.id).toList(), ['t2', 't3', 't1']);
    });

    test('trie par prix puis note pour le filtre abordable', () {
      final results = filterAndSortTerrains(
        terrains: terrains,
        query: '',
        filter: TerrainDiscoveryFilter.affordable,
      );

      expect(results.map((t) => t.id).toList(), ['t3', 't2', 't1']);
    });
  });

  group('buildReservationSections', () {
    Reservation reservation({
      required String id,
      required DateTime date,
      required String startSlot,
      required String status,
    }) {
      return Reservation(
        id: id,
        terrain: const Terrain(
          id: 'terrain-1',
          name: 'Terrain Test',
          address: 'Dakar',
          zone: 'DAKAR',
          pricePerHour: 6000,
          rating: 4.5,
          lat: 0,
          lng: 0,
          imageUrl: '',
        ),
        date: date,
        startSlot: startSlot,
        endSlot: '11h00',
        price: 6000,
        reference: 'MF-REF',
        status: status,
      );
    }

    test('separe prochain match, aujourd hui, a venir et historique', () {
      final now = DateTime(2026, 5, 10, 9, 0);
      final sections = buildReservationSections(
        reservations: [
          reservation(
            id: 'past',
            date: DateTime(2026, 5, 6),
            startSlot: '18h00',
            status: 'COMPLETED',
          ),
          reservation(
            id: 'today-late',
            date: DateTime(2026, 5, 10),
            startSlot: '20h00',
            status: 'CONFIRMED',
          ),
          reservation(
            id: 'upcoming',
            date: DateTime(2026, 5, 12),
            startSlot: '08h00',
            status: 'CONFIRMED',
          ),
          reservation(
            id: 'today-next',
            date: DateTime(2026, 5, 10),
            startSlot: '10h00',
            status: 'PENDING_PAYMENT',
          ),
        ],
        now: now,
      );

      expect(sections.nextReservation?.id, 'today-next');
      expect(sections.today.map((r) => r.id).toList(), ['today-next', 'today-late']);
      expect(sections.upcoming.map((r) => r.id).toList(), ['upcoming']);
      expect(sections.past.map((r) => r.id).toList(), ['past']);
    });
  });
}
