# minifoot_mobile — App Flutter (utilisateur)

Application mobile Flutter pour réserver et gérer des terrains de mini-football.

## Stack
- Flutter SDK ^3.11.3 / Dart
- Packages : google_fonts, lottie, flutter_map + latlong2, cupertino_icons

## Structure `lib/`
```
main.dart
auth_screen.dart
home_screen.dart
booking_confirmation_screen.dart
match_screen.dart
chat_screen.dart
notifications_screen.dart
payment_screen.dart
profile_screen.dart
onboarding_screen.dart
```

---

## Règles de codage — Flutter/Dart

### Logging
- Utiliser le package `logger` — jamais `print()` en dehors du debug
- `debugPrint()` acceptable en développement uniquement (retiré avant release)

```dart
// ✅ Correct
final _logger = Logger();
_logger.i('[BookingService][create] booking created id=$id');
_logger.e('[BookingService][create] Error: $error');

// ❌ Interdit
print('booking: $booking');   // INTERDIT en production
```

### Gestion des erreurs
- `try-catch` un seul niveau — pas d'imbrication
- Exceptions typées : créer des classes d'exception métier
- Toujours afficher un message utilisateur via `SnackBar` ou dialog sur erreur UI

```dart
// ✅ Correct
Future<Booking> createBooking(BookingDto dto) async {
  try {
    return await _apiService.createBooking(dto);
  } on NetworkException catch (e) {
    _logger.e('[createBooking] Network error: ${e.message}');
    rethrow;
  } catch (e, stack) {
    _logger.e('[createBooking] Unexpected error', e, stack);
    throw AppException('Erreur lors de la réservation');
  }
}

// ❌ Interdit — catch imbriqué
try {
  try { ... } catch (e) { } // INTERDIT
} catch (e) { }
```

### Architecture — séparation des responsabilités
- **Screens** : uniquement UI, délègue au service/provider/bloc
- **Services** : logique métier et appels API
- **Models** : classes de données avec `fromJson`/`toJson`
- Utiliser `Provider` ou `Riverpod` pour la gestion d'état (éviter `setState` dans les grandes features)

### Widgets
```dart
// ✅ Préférer les StatelessWidget
class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) { ... }
}
```

### Design — standards UI
- Respecter Material Design 3
- Couleurs via `ThemeData` — jamais hardcodées dans les widgets
- Responsive : tester sur petits (360px) et grands écrans
- Animations via Lottie pour les états de chargement/succès/erreur
- Dark mode support obligatoire
- Accessibilité : `Semantics` sur les éléments interactifs

### Sécurité
- Jamais de tokens/secrets dans le code — utiliser `flutter_secure_storage`
- Valider les inputs avant envoi à l'API
- Certificate pinning pour les appels API en production
- Obfuscation activée en build release : `flutter build apk --obfuscate`

### Performance
- `const` sur tous les widgets qui peuvent l'être
- `ListView.builder` pour les listes longues — jamais `Column` avec beaucoup d'enfants
- Images : `cached_network_image` pour le cache
- Éviter les rebuilds inutiles (sélecteurs Riverpod, `Consumer` ciblé)

---

## Commandes
```bash
flutter pub get           # Installer dépendances
flutter run               # Lancer
flutter build apk --release --obfuscate --split-debug-info=debug/
flutter test              # Tests
```

## Git — commits activés
Utiliser `/commit` ou `/commit-push-pr` pour les commits.
Convention : `feat:`, `fix:`, `refactor:` (Conventional Commits)
