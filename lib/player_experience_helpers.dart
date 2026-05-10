import 'package:minifoot/reservations_screen.dart';
import 'package:minifoot/terrain_data.dart';

enum TerrainDiscoveryFilter { nearby, topRated, affordable }

typedef TerrainDistanceResolver = double Function(Terrain terrain);

List<Terrain> filterAndSortTerrains({
  required List<Terrain> terrains,
  required String query,
  required TerrainDiscoveryFilter filter,
  TerrainDistanceResolver? distanceFor,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final filtered = terrains.where((terrain) {
    if (normalizedQuery.isEmpty) return true;
    return terrain.name.toLowerCase().contains(normalizedQuery) ||
        terrain.address.toLowerCase().contains(normalizedQuery);
  }).toList();

  filtered.sort((a, b) {
    switch (filter) {
      case TerrainDiscoveryFilter.nearby:
        if (distanceFor != null) {
          final distanceCompare = distanceFor(a).compareTo(distanceFor(b));
          if (distanceCompare != 0) return distanceCompare;
        }
        return b.rating.compareTo(a.rating);
      case TerrainDiscoveryFilter.topRated:
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        return a.pricePerHour.compareTo(b.pricePerHour);
      case TerrainDiscoveryFilter.affordable:
        final priceCompare = a.pricePerHour.compareTo(b.pricePerHour);
        if (priceCompare != 0) return priceCompare;
        return b.rating.compareTo(a.rating);
    }
  });

  return filtered;
}

class ReservationSections {
  final Reservation? nextReservation;
  final List<Reservation> today;
  final List<Reservation> upcoming;
  final List<Reservation> past;

  const ReservationSections({
    required this.nextReservation,
    required this.today,
    required this.upcoming,
    required this.past,
  });
}

ReservationSections buildReservationSections({
  required List<Reservation> reservations,
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();
  final active = reservations.where((reservation) => reservation.isActive).toList()
    ..sort((a, b) => reservationDateTime(a).compareTo(reservationDateTime(b)));
  final past = reservations.where((reservation) => reservation.isPast).toList()
    ..sort((a, b) => reservationDateTime(b).compareTo(reservationDateTime(a)));

  final today = active.where((reservation) => isSameDay(reservation.date, currentTime)).toList();
  final upcoming = active.where((reservation) => !isSameDay(reservation.date, currentTime)).toList();

  return ReservationSections(
    nextReservation: active.isEmpty ? null : active.first,
    today: today,
    upcoming: upcoming,
    past: past,
  );
}

DateTime reservationDateTime(Reservation reservation) {
  final normalized = reservation.startSlot.replaceAll(':', 'h');
  final parts = normalized.split('h');
  final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
  final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  return DateTime(
    reservation.date.year,
    reservation.date.month,
    reservation.date.day,
    hour,
    minute,
  );
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
