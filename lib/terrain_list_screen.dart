import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'terrain_data.dart';
import 'terrain_detail_screen.dart';
import 'providers/terrain_provider.dart';

const Color kGreen = Color(0xFF006F39);

bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c)   => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c)  => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)  => _isDark(c)
    ? const Color(0xFFF0EBE0).withValues(alpha: 0.5)
    : Colors.black.withValues(alpha: 0.45);

class TerrainListScreen extends StatefulWidget {
  const TerrainListScreen({super.key});

  @override
  State<TerrainListScreen> createState() => _TerrainListScreenState();
}

class _TerrainListScreenState extends State<TerrainListScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TerrainProvider>().loadTerrains();
    });
  }

  List<Terrain> _filtered(List<Terrain> all) => all
      .where((t) =>
          t.name.toLowerCase().contains(_query.toLowerCase()) ||
          t.address.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TerrainProvider>();
    final filtered = _filtered(provider.terrains);
    final nearby = filtered.take(2).toList();

    return Scaffold(
      backgroundColor: _bg(context),
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
                          color: _sub(context))),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        color: kGreen, size: 16),
                    const SizedBox(width: 4),
                    Text('Dakar, Sénégal',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14,
                            color: _txt(context))),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: _sub(context)),
                  ]),

                  const SizedBox(height: 16),

                  // Recherche
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _card(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.search_rounded,
                              color: _sub(context), size: 22),
                        ),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v),
                            style: TextStyle(color: _txt(context)),
                            decoration: InputDecoration(
                              hintText: 'Rechercher un terrain...',
                              hintStyle: TextStyle(
                                  color: _sub(context),
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
                            color: _bg(context),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4)
                            ],
                          ),
                          child: Icon(Icons.tune_rounded,
                              size: 18, color: _sub(context)),
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
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off_rounded,
                                  size: 48, color: Colors.black26),
                              const SizedBox(height: 12),
                              Text('Impossible de charger les terrains',
                                  style: TextStyle(color: _sub(context))),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => context.read<TerrainProvider>().loadTerrains(),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : CustomScrollView(
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
                        (_, i) => _NearbyItem(terrain: nearby[i]),
                        childCount: nearby.length < 2 ? nearby.length : 2,
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
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: _txt(context)),
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
                  style: TextStyle(
                      fontSize: 10, color: _sub(context)),
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
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14,
                          color: _txt(context))),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on_rounded,
                        color: _sub(context), size: 13),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(terrain.address,
                          style: TextStyle(
                              fontSize: 12, color: _sub(context)),
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


