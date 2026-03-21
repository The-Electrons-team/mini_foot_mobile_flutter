import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'terrain_data.dart';
import 'terrain_booking_screen.dart';
import 'terrain_map_screen.dart';

const Color kGreen = Color(0xFF006F39);
const Color kDark = Color(0xFF1A1A1A);
const Color kBeige = Color(0xFFF5F0E8);

// ── Helpers thème ──
bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c)   => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c)  => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)  => _isDark(c)
    ? const Color(0xFFF0EBE0).withValues(alpha: 0.5)
    : Colors.black.withValues(alpha: 0.45);

class TerrainDetailScreen extends StatefulWidget {
  final Terrain terrain;
  const TerrainDetailScreen({super.key, required this.terrain});

  @override
  State<TerrainDetailScreen> createState() => _TerrainDetailScreenState();
}

class _TerrainDetailScreenState extends State<TerrainDetailScreen> {
  bool _isSaved = false;
  int _selectedTab = 0;
  int _selectedImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final t = widget.terrain;
    final currentImage = t.imageUrls[_selectedImageIndex];

    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _bg(context),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: _txt(context), size: 18),
        ),
        title: Text('Détail',
            style: GoogleFonts.orbitron(
                fontSize: 14, fontWeight: FontWeight.w800, color: _txt(context))),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => setState(() => _isSaved = !_isSaved),
              child: Icon(
                _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: _isSaved ? kGreen : _txt(context),
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── IMAGE PRINCIPALE + GALERIE OVERLAY ──
          SizedBox(
            height: 240,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image principale
                Image.network(
                  currentImage,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: kGreen.withValues(alpha: 0.12)),
                ),
                // Dégradé bas pour les miniatures
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        stops: const [0.55, 1.0],
                      ),
                    ),
                  ),
                ),
                // Miniatures centrées en bas (sur l'image)
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(t.imageUrls.length, (i) {
                      final selected = _selectedImageIndex == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedImageIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 46,
                          height: 38,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              t.imageUrls[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  Container(color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // ── CONTENU SCROLLABLE ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom + rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(t.name,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _txt(context),
                                height: 1.2)),
                      ),
                      const SizedBox(width: 8),
                      Row(children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFFFB300), size: 18),
                        const SizedBox(width: 3),
                        Text('${t.rating}',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: _txt(context))),
                      ]),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Adresse
                  Row(children: [
                    Icon(Icons.location_on_rounded,
                        color: _sub(context), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(t.address,
                          style: TextStyle(fontSize: 12, color: _sub(context))),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── ONGLETS ──
                  Row(
                    children: [
                      _Tab(label: 'À propos', index: 0, selected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0)),
                      _Tab(label: 'Avis', index: 1, selected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1)),
                      _Tab(label: 'Carte', index: 2, selected: _selectedTab == 2,
                          onTap: () => setState(() => _selectedTab = 2)),
                    ],
                  ),

                  Container(
                    height: 1,
                    color: Colors.black.withValues(alpha: 0.08),
                  ),

                  const SizedBox(height: 16),

                  // ── CONTENU ONGLET ──
                  if (_selectedTab == 0) _AboutTab(terrain: t),
                  if (_selectedTab == 1) _ReviewTab(terrain: t),
                  if (_selectedTab == 2) _MapTab(terrain: t),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── BOUTON RÉSERVER ──
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: _card(context),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -3))
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('par heure',
                    style: TextStyle(fontSize: 11, color: _sub(context))),
                const SizedBox(height: 2),
                Text(t.price,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _txt(context))),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TerrainBookingScreen(terrain: t))),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 36, vertical: 14),
                decoration: BoxDecoration(
                  color: kGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('Réserver',
                    style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ONGLET WIDGET ──
class _Tab extends StatelessWidget {
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  const _Tab(
      {required this.label,
      required this.index,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 24),
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? kGreen : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? _txt(context) : _sub(context))),
      ),
    );
  }
}

// ── ONGLET À PROPOS ──
class _AboutTab extends StatelessWidget {
  final Terrain terrain;
  const _AboutTab({required this.terrain});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: _txt(context))),
        const SizedBox(height: 8),
        Text(terrain.description,
            style: TextStyle(
                fontSize: 13,
                height: 1.65,
                color: _sub(context))),

        const SizedBox(height: 20),

        Text('Équipements',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: _txt(context))),
        const SizedBox(height: 12),

        // Grille 2 colonnes de cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3.2,
          children: terrain.features.map((f) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _card(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(f.icon, size: 18, color: kGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(f.label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _txt(context)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }
}

// ── ONGLET AVIS ──
class _ReviewTab extends StatelessWidget {
  final Terrain terrain;
  const _ReviewTab({required this.terrain});

  @override
  Widget build(BuildContext context) {
    final reviews = [
      _ReviewData(
        name: 'Moussa Diallo',
        initials: 'MD',
        color: kGreen,
        rating: 5,
        comment: 'Excellent terrain ! Gazon en très bon état et éclairage parfait pour jouer le soir. Je recommande vivement.',
        date: 'Il y a 2 jours',
      ),
      _ReviewData(
        name: 'Fatou Sall',
        initials: 'FS',
        color: Colors.orange,
        rating: 4,
        comment: 'Très bon terrain, bien entretenu. Le parking est pratique. Juste un peu cher mais ça vaut le coup.',
        date: 'Il y a 1 semaine',
      ),
      _ReviewData(
        name: 'Ibrahima Ndiaye',
        initials: 'IN',
        color: const Color(0xFF1565C0),
        rating: 5,
        comment: 'Meilleur terrain de Dakar ! Vestiaires propres, personnel accueillant. On reviendra.',
        date: 'Il y a 2 semaines',
      ),
      _ReviewData(
        name: 'Aminata Bâ',
        initials: 'AB',
        color: Colors.purple,
        rating: 4,
        comment: 'Terrain de qualité, bon accueil. La réservation en ligne est très pratique.',
        date: 'Il y a 3 semaines',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Note globale
        Row(
          children: [
            Text('${terrain.rating}',
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: _txt(context))),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(
                      5,
                      (i) => Icon(
                            i < terrain.rating.floor()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFFFB300),
                            size: 20)),
                ),
                const SizedBox(height: 4),
                Text('${terrain.booked}+ avis',
                    style: TextStyle(fontSize: 13, color: _sub(context))),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Liste avis
        ...reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }
}

class _ReviewData {
  final String name;
  final String initials;
  final Color color;
  final int rating;
  final String comment;
  final String date;
  const _ReviewData({
    required this.name,
    required this.initials,
    required this.color,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class _ReviewCard extends StatelessWidget {
  final _ReviewData review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: review.color,
                child: Text(review.initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13,
                            color: _txt(context))),
                    Text(review.date,
                        style: TextStyle(fontSize: 11, color: _sub(context))),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFFFB300),
                          size: 14)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.comment,
              style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: _sub(context))),
        ],
      ),
    );
  }
}

// ── ONGLET CARTE ──
class _MapTab extends StatelessWidget {
  final Terrain terrain;
  const _MapTab({required this.terrain});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Localisation',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: _txt(context))),
        const SizedBox(height: 12),

        // Mini carte
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 260,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(terrain.lat, terrain.lng),
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.minifoot.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(terrain.lat, terrain.lng),
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: kGreen.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 2)
                          ],
                        ),
                        child: const Icon(Icons.sports_soccer_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        const SizedBox(height: 14),

        // Adresse détaillée
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: kGreen, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(terrain.address,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: _txt(context))),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Bouton ouvrir carte complète
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TerrainMapScreen())),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: kGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.map_outlined, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Voir sur la carte complète',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
