import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'terrain_data.dart';
import 'terrain_detail_screen.dart';
import 'terrain_map_screen.dart';

const Color kGreen = Color(0xFF006F39);
const Color kBeige = Color(0xFFF5F0E8);

class TerrainListScreen extends StatefulWidget {
  const TerrainListScreen({super.key});

  @override
  State<TerrainListScreen> createState() => _TerrainListScreenState();
}

class _TerrainListScreenState extends State<TerrainListScreen> {
  String _query = '';

  List<Terrain> get _filtered => terrains
      .where((t) =>
          t.name.toLowerCase().contains(_query.toLowerCase()) ||
          t.address.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final nearby = filtered.take(2).toList();

    return Scaffold(
      backgroundColor: kBeige,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  Text('Localisation',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.black.withValues(alpha: 0.4))),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: kGreen, size: 16),
                    const SizedBox(width: 4),
                    const Text('Dakar, Sénégal',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: Colors.black54),
                  ]),

                  const SizedBox(height: 16),

                  // Recherche
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.search_rounded,
                              color: Colors.black38, size: 22),
                        ),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              hintText: 'Rechercher un terrain...',
                              hintStyle: TextStyle(
                                  color:
                                      Colors.black.withValues(alpha: 0.35),
                                  fontSize: 14),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4)
                            ],
                          ),
                          child: const Icon(Icons.tune_rounded,
                              size: 18, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Badge Football only
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: kGreen,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.sports_soccer_rounded,
                            size: 15, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Football',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Terrains à proximité
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Terrains à proximité',
                          style: GoogleFonts.orbitron(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: kGreen)),
                      Text('Voir tout',
                          style: TextStyle(
                              fontSize: 13,
                              color: kGreen,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),

            // ── CONTENU SCROLLABLE ──
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Grille 2 colonnes (image arrondie + texte dessous)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 6,
                        childAspectRatio: 0.78,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _NearbyItem(
                            terrain: nearby.length > i
                                ? nearby[i]
                                : terrains[i % terrains.length]),
                        childCount: 2,
                      ),
                    ),
                  ),

                  // Section Terrains Populaires
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 24, 20, 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Terrains populaires',
                              style: GoogleFonts.orbitron(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: kGreen)),
                          Text('Voir tout',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: kGreen,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),

                  // Liste populaires
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _PopularItem(terrain: filtered[i]),
                        childCount: filtered.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                      child: SizedBox(height: 20)),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── BARRE DE NAVIGATION ──
      bottomNavigationBar: _NavBar(
        onTap: (i) {
          if (i == 2) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TerrainMapScreen()));
          } else if (i == 0) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}

// ── ITEM NEARBY (image arrondie + texte dessous) ──
class _NearbyItem extends StatelessWidget {
  final Terrain terrain;
  const _NearbyItem({required this.terrain});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  TerrainDetailScreen(terrain: terrain))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    terrain.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                        decoration: BoxDecoration(
                          color: kGreen.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                        )),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark_border_rounded,
                        size: 16, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(terrain.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF1A1A1A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFB300), size: 12),
              const SizedBox(width: 2),
              Text('${terrain.rating}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.location_on_rounded,
                color: Colors.black38, size: 12),
            const SizedBox(width: 2),
            Expanded(
              child: Text(terrain.address,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.black38),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── ITEM POPULAIRE (horizontal) ──
class _PopularItem extends StatelessWidget {
  final Terrain terrain;
  const _PopularItem({required this.terrain});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  TerrainDetailScreen(terrain: terrain))),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                terrain.imageUrl,
                width: 80,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                    width: 80,
                    height: 70,
                    color: kGreen.withValues(alpha: 0.10)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(terrain.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.black38, size: 13),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(terrain.address,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black38),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(
                        5,
                        (i) => Icon(
                              i < terrain.rating.floor()
                                  ? Icons.star_rounded
                                  : (i < terrain.rating
                                      ? Icons.star_half_rounded
                                      : Icons.star_border_rounded),
                              color: const Color(0xFFFFB300),
                              size: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.bookmark_border_rounded,
                size: 20, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

// ── BARRE DE NAVIGATION ──
class _NavBar extends StatelessWidget {
  final ValueChanged<int> onTap;
  const _NavBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              left: 16,
              right: 16,
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 20,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavIcon(icon: Icons.home_rounded, onTap: () => onTap(0), active: true),
                    _NavIcon(icon: Icons.chat_bubble_outline_rounded, onTap: () => onTap(1)),
                    const SizedBox(width: 64),
                    _NavIcon(icon: Icons.notifications_none_rounded, onTap: () => onTap(3)),
                    _NavIcon(icon: Icons.person_outline_rounded, onTap: () => onTap(4)),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: kGreen, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset('assets/images/ballon.png',
                        fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _NavIcon({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? kGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 22, color: active ? Colors.white : Colors.black38),
      ),
    );
  }
}
