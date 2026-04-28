# PROGRESSION — Connexion App Joueur ↔ Backend

Fichier de suivi pour savoir exactement où on en est pour chaque partie de l'app.

**Légende :**
- ✅ CONNECTÉ — données réelles depuis le backend
- 🔧 PARTIEL — partiellement connecté, il reste des choses à faire
- ❌ MOCK — données entièrement fausses, hardcodées dans le code
- ⏳ À FAIRE — planifié mais pas encore commencé

---

## 🚨 BUGS CRITIQUES À CORRIGER EN PRIORITÉ

Ces bugs bloquent des fonctionnalités clés. À traiter avant de connecter de nouveaux modules.

| # | Bug | Fichiers concernés | Ticket ClickUp |
|---|-----|--------------------|----------------|
| 1 | Payment screen ne crée **pas** de réservation en base | `payment_screen.dart` | [86c9gz7d1](https://app.clickup.com/t/86c9gz7d1) |
| 2 | Webhooks Wave/Orange/Free ne mettent **pas à jour** les réservations après paiement | `minifoot_backend/src/modules/webhooks/` | [86c9gz7da](https://app.clickup.com/t/86c9gz7da) |

---

## 1. AUTHENTIFICATION

| Écran / Action | État | Fichiers Flutter | Endpoint Backend |
|---|---|---|---|
| Splash → auto-login | ✅ CONNECTÉ | `splash_screen.dart` + `providers/auth_provider.dart` | `GET /users/me` |
| Login (téléphone + mot de passe) | ✅ CONNECTÉ | `auth_screen.dart` + `services/auth_service.dart` | `POST /auth/login` |
| Inscription étape 1 (numéro) | ✅ CONNECTÉ | `auth_screen.dart` | `POST /auth/signup` |
| Vérification OTP | ✅ CONNECTÉ | `auth_screen.dart` | `POST /auth/verify-otp` |
| Inscription étape 2 (nom/prénom) | ✅ CONNECTÉ | `auth_screen.dart` | `POST /auth/register` |
| Déconnexion | ✅ CONNECTÉ | `profile_screen.dart` + `providers/auth_provider.dart` | (local — supprime token) |

**Notes :** Le token JWT est sauvegardé dans `SharedPreferences` et envoyé dans les headers `Authorization: Bearer <token>`.

---

## 2. TERRAINS

| Écran / Action | État | Fichiers Flutter | Endpoint Backend |
|---|---|---|---|
| Liste des terrains | ✅ CONNECTÉ | `terrain_list_screen.dart` + `providers/terrain_provider.dart` | `GET /terrains` |
| Recherche / filtre | ✅ CONNECTÉ | `terrain_list_screen.dart` | `GET /terrains?search=` |
| Détail d'un terrain | ✅ CONNECTÉ | `terrain_detail_screen.dart` | `GET /terrains/:id` (via provider) |
| Carte des terrains | 🔧 PARTIEL | `terrain_map_screen.dart` | navigation vers détail connectée, carte encore locale |
| Créneaux disponibles | ✅ CONNECTÉ | `terrain_booking_screen.dart` + `services/terrain_service.dart` | `GET /terrains/:id/slots?date=YYYY-MM-DD` |
| Terrains populaires (Home) | ✅ CONNECTÉ | `home_screen.dart` + `providers/terrain_provider.dart` | `GET /terrains` |

**Notes :**
- `terrain_data.dart` — modèle `Terrain` mis à jour avec `fromJson`, `priceLabel`, `featureIcons`
- Créneaux de 30 min uniquement (aligné avec le backend)
- 4 terrains peuplés dans la BDD via `prisma/seed.ts`

---

## 3. RÉSERVATIONS

| Écran / Action | État | Fichiers Flutter | Endpoint Backend |
|---|---|---|---|
| Créer une réservation | ❌ MOCK | `terrain_booking_screen.dart` | `POST /reservations` |
| Liste de mes réservations | ❌ MOCK | `reservations_screen.dart` | `GET /reservations` |
| Détail d'une réservation | ❌ MOCK | `reservations_screen.dart` | `GET /reservations/:id` |
| Annuler une réservation | ❌ MOCK | `reservations_screen.dart` | `DELETE /reservations/:id` |
| Générer lien de paiement | ❌ MOCK | `payment_screen.dart` | `POST /reservations/:id/payment-link` |
| Confirmation de réservation | ❌ MOCK | `booking_confirmation_screen.dart` | (affichage seulement) |

**Ce qu'il faut créer :**
- `services/reservation_service.dart`
- `providers/reservation_provider.dart`
- Flux complet : booking → paiement → confirmation (webhook côté backend)

---

## 4. PROFIL JOUEUR

| Écran / Action | État | Fichiers Flutter | Endpoint Backend |
|---|---|---|---|
| Afficher mon profil | 🔧 PARTIEL | `profile_screen.dart` + `providers/auth_provider.dart` | `GET /users/me` |
| Modifier mon profil | ❌ MOCK | `profile_screen.dart` | `PATCH /users/me` |
| Changer photo de profil | ❌ MOCK | `profile_screen.dart` | `POST /users/me/avatar` |
| Statistiques joueur | ❌ MOCK | `profile_screen.dart` | `GET /users/me` (champ `stats`) |

**Notes :** L'affichage du prénom/nom fonctionne car il vient du token JWT, mais la mise à jour ne fait rien encore. La photo n'est que locale (non envoyée au serveur).

**Ce qu'il faut créer :**
- `services/user_service.dart` — pour `PATCH /users/me` et upload avatar

---

## 5. NOTIFICATIONS

| Écran / Action | État | Fichiers Flutter | Endpoint Backend |
|---|---|---|---|
| Liste des notifications | ❌ MOCK | `notifications_screen.dart` | `GET /notifications` |
| Marquer comme lu | ❌ MOCK | `notifications_screen.dart` | `PATCH /notifications/:id/read` |
| Tout marquer comme lu | ❌ MOCK | `notifications_screen.dart` | `PATCH /notifications/read-all` |
| Badge notif non lues | ❌ MOCK | `home_screen.dart` (`unreadNotifNotifier`) | `GET /notifications` (compter les non lues) |

**Ce qu'il faut créer :**
- `services/notification_service.dart`
- `providers/notification_provider.dart`

---

## 6. ÉQUIPES

| Écran / Action | État | Fichiers Flutter | Endpoint Backend |
|---|---|---|---|
| Voir mon équipe | ❌ MOCK | `team_screen.dart` | `GET /teams/mine` |
| Créer une équipe | ❌ MOCK | `team_screen.dart` | `POST /teams` |
| Rejoindre via code | ❌ MOCK | `team_screen.dart` | `POST /teams/join/:code` |
| Liste des membres | ❌ MOCK | `team_roster_screen.dart` | `GET /teams/:id` |
| Composition (positions) | ❌ MOCK | `team_composition_screen.dart` | `PATCH /teams/:id/members/:memberId` |
| Accepter un membre | ❌ MOCK | `team_screen.dart` | `PATCH /teams/:id/members/:memberId/accept` |
| Retirer un membre | ❌ MOCK | `team_screen.dart` | `DELETE /teams/:id/members/:memberId` |
| Logo de l'équipe | ❌ MOCK | `team_screen.dart` | `POST /teams/:id/logo` |
| Publications de l'équipe | ❌ MOCK | `team_publications_screen.dart` | `GET /feed` (filtre par équipe) |
| Tournois de l'équipe | ❌ MOCK | `team_tournaments_screen.dart` | à définir |

**Ce qu'il faut créer :**
- `services/team_service.dart`
- `providers/team_provider.dart`

---

## 7. MATCHS & CHALLENGES

| Écran / Action | État | Fichiers Flutter | Endpoint Backend |
|---|---|---|---|
| Voir les matchs de mon équipe | ❌ MOCK | `match_screen.dart` | `GET /matches/team/:teamId` |
| Envoyer un challenge | ❌ MOCK | `match_screen.dart` | `POST /matches/challenge` |
| Répondre à un challenge | ❌ MOCK | `match_screen.dart` | `PATCH /matches/challenge/:id/respond` |
| Challenges en attente | ❌ MOCK | `match_screen.dart` | `GET /matches/challenges/pending/:teamId` |
| Saisir un score | ❌ MOCK | `match_screen.dart` | `PATCH /matches/:id/score` |

**Ce qu'il faut créer :**
- `services/match_service.dart`

---

## 8. CLASSEMENT

| Écran / Action | État | Fichiers Flutter | Endpoint Backend |
|---|---|---|---|
| Classement général | ❌ MOCK | `ranking_screen.dart` | `GET /teams/ranking` |
| Classement par zone | ❌ MOCK | `ranking_screen.dart` | `GET /teams/ranking?zone=DAKAR` |

**Ce qu'il faut créer :**
- Intégrer dans `services/team_service.dart`

---

## 9. CHAT

| Écran / Action | État | Fichiers Flutter | Endpoint Backend |
|---|---|---|---|
| Liste des conversations | ❌ MOCK | `chat_screen.dart` | `GET /chat/conversations` |
| Ouvrir / créer une conversation | ❌ MOCK | `chat_screen.dart` | `POST /chat/conversations/direct/:targetId` |
| Messages d'une conversation | ❌ MOCK | `chat_screen.dart` | `GET /chat/conversations/:id/messages` |
| Envoyer un message | ❌ MOCK | `chat_screen.dart` | `POST /chat/conversations/:id/messages` |
| Temps réel (Socket.io) | ❌ MOCK | `chat_screen.dart` | WebSocket event `message.sent` |

**Ce qu'il faut créer :**
- `services/chat_service.dart`
- Intégrer `socket_io_client` pour le temps réel

---

## 10. FEED SOCIAL

| Écran / Action | État | Fichiers Flutter | Endpoint Backend |
|---|---|---|---|
| Voir le fil d'actualité | ❌ MOCK | `social_feed_screen.dart` | `GET /feed` |
| Liker un post | ❌ MOCK | `social_feed_screen.dart` | `POST /feed/:id/like` |
| Voir les commentaires | ❌ MOCK | `social_feed_screen.dart` | `GET /feed/:id/comments` |
| Poster un commentaire | ❌ MOCK | `social_feed_screen.dart` | `POST /feed/:id/comments` |
| Créer un post (avec photo) | ❌ MOCK | `social_feed_screen.dart` | `POST /feed` |
| Supprimer un commentaire | ❌ MOCK | `social_feed_screen.dart` | `DELETE /feed/comments/:commentId` |

**Ce qu'il faut créer :**
- `services/feed_service.dart`

---

## 11. TOURNOIS

| Écran / Action | État | Fichiers Flutter | Endpoint Backend |
|---|---|---|---|
| Liste des tournois | ❌ MOCK | `tournaments_screen.dart` | `GET /tournaments` |
| Détail d'un tournoi (bracket) | ❌ MOCK | `tournaments_screen.dart` | `GET /tournaments/:id` |
| Inscrire mon équipe | ❌ MOCK | `tournaments_screen.dart` | `POST /tournaments/:id/register` |
| Résultats & scores | ❌ MOCK | `tournaments_screen.dart` | `GET /tournaments/:id/matches` |

**Ticket ClickUp :** [86c9gz7bh](https://app.clickup.com/t/86c9gz7bh)

**Ce qu'il faut créer :**
- `services/tournament_service.dart`

---

## 12. BOUTIQUE

| Écran / Action | État | Fichiers Flutter | Endpoint Backend |
|---|---|---|---|
| Liste des produits | ❌ MOCK | `shop_screen.dart` | `GET /boutique/products` |
| Détail d'un produit | ❌ MOCK | `shop_screen.dart` | `GET /boutique/products/:id` |
| Contact vendeur (WhatsApp) | ✅ OK | `shop_screen.dart` | (lien externe WhatsApp) |

**Notes :** La boutique utilise WhatsApp comme canal de contact, pas de paiement intégré.

**Ce qu'il faut créer :**
- `services/boutique_service.dart`

---

## Ordre recommandé de connexion

Voici l'ordre logique pour connecter les modules, du plus important au moins urgent :

```
0. 🚨 BUGS CRITIQUES  — corriger payment + webhooks en premier
1. ✅ AUTH            — déjà fait
2. ✅ TERRAINS         — connecté (liste, détail, créneaux, home)
3. ⏳ RÉSERVATIONS     — suit directement les terrains (booking flow)
4. ⏳ PROFIL           — simple à finir (PATCH users/me)
5. ⏳ NOTIFICATIONS    — important pour l'engagement utilisateur
6. ⏳ ÉQUIPES          — fonctionnalité sociale centrale
7. ⏳ MATCHS           — dépend des équipes
8. ⏳ CLASSEMENT       — dépend des matchs/équipes
9. ⏳ FEED SOCIAL      — dépend des équipes
10. ⏳ TOURNOIS        — backend prêt, front à connecter
11. ⏳ CHAT            — le plus complexe (WebSocket)
12. ⏳ BOUTIQUE        — le moins urgent
```

---

## Architecture des services à créer

Chaque nouveau service doit suivre le même modèle que `services/auth_service.dart` :

```dart
// lib/services/<nom>_service.dart
class <Nom>Service {
  final String _base = dotenv.get('API_URL');

  // Méthode qui prend le token en paramètre
  Future<...> methode(String token, ...) async {
    final response = await http.get(
      Uri.parse('$_base/<route>'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur: ${response.body}');
  }
}
```

Le token se récupère toujours via `context.read<AuthProvider>().token`.

---

*Dernière mise à jour : 27 avril 2026 — synchronisé avec ClickUp (liste 901523025992)*
