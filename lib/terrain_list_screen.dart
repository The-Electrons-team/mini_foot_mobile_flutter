import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'terrain_data.dart';
import 'terrain_detail_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'player_experience_helpers.dart';
import 'providers/terrain_provider.dart';
import 'providers/auth_provider.dart';

const Color kGreen = Color(0xFF006F39);

bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c)   => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c)  => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)  => _isDark(c)
    ? const Color(0xFFF0EBE0).withOpacity(0.5)
    : Colors.black.withOpacity(0.45);

class TerrainListScreen extends StatefulWidget {
  const TerrainListScreen({super.key});

  @override
  State<TerrainListScreen> createState() => _TerrainListScreenState();
}

class _TerrainListScreenState extends State<TerrainListScreen> {
  String _query = '';
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  TerrainDiscoveryFilter _selectedFilter = TerrainDiscoveryFilter.nearby;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = context.read<TerrainProvider>();
      tp.loadTerrains(refresh: true);
      tp.updateLocation();
      final auth = context.read<AuthProvider>();
      if (auth.token != null) {
        tp.loadFavorites(auth.token!);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final tp = context.read<TerrainProvider>();
      if (!tp.isLoading && tp.hasMore) {
        tp.loadMoreTerrains(search: _query);
      }
    }
  }

  List<Terrain> _getPopular(List<Terrain> all) {
    var list = List<Terrain>.from(all);
    list.sort((a, b) => b.rating.compareTo(a.rating));
    return list.take(10).toList();
  }

  List<Terrain> _getNearby(List<Terrain> all, Position? pos) {
    final tp = context.read<TerrainProvider>();
    return filterAndSortTerrains(
      terrains: all,
      query: _query,
      filter: _selectedFilter,
      distanceFor: pos == null ? null : (terrain) => tp.distanceTo(terrain),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TerrainProvider>();
    final all = provider.terrains;
    final popular = _getPopular(all);
    final nearby = _getNearby(all, provider.userPosition);
    final locationLabel = provider.userPosition != null
        ? 'Autour de vous'
        : 'Dakar, Sénégal';
    final helperLabel = provider.userPosition != null
        ? 'Résultats triés selon votre position'
        : 'Activez la localisation pour voir le plus proche';

    return Scaffold(
      backgroundColor: _bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER (Location + Search) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Localisation', style: TextStyle(fontSize: 11, color: _sub(context))),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, color: kGreen, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _txt(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.tune_rounded, size: 18, color: _sub(context)),
                  ]),
                  const SizedBox(height: 6),
                  Text(helperLabel, style: TextStyle(fontSize: 12, color: _sub(context))),
                  const SizedBox(height: 16),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.search_rounded, color: _sub(context), size: 22)),
                        Expanded(
                          child: TextField(
                            onChanged: (v) {
                              setState(() => _query = v);
                              _searchDebounce?.cancel();
                              _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                                if (!mounted) return;
                                provider.loadTerrains(search: v, refresh: true);
                              });
                            },
                            style: TextStyle(color: _txt(context)),
                            decoration: InputDecoration(hintText: 'Rechercher un terrain...', hintStyle: TextStyle(color: _sub(context), fontSize: 14), border: InputBorder.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── CONTENU PRINCIPAL ──
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _DiscoveryFilterChip(
                            label: 'Plus proches',
                            selected: _selectedFilter == TerrainDiscoveryFilter.nearby,
                            onTap: () => setState(() => _selectedFilter = TerrainDiscoveryFilter.nearby),
                          ),
                          _DiscoveryFilterChip(
                            label: 'Mieux notés',
                            selected: _selectedFilter == TerrainDiscoveryFilter.topRated,
                            onTap: () => setState(() => _selectedFilter = TerrainDiscoveryFilter.topRated),
                          ),
                          _DiscoveryFilterChip(
                            label: 'Moins chers',
                            selected: _selectedFilter == TerrainDiscoveryFilter.affordable,
                            onTap: () => setState(() => _selectedFilter = TerrainDiscoveryFilter.affordable),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _query.isEmpty
                                  ? '${nearby.length} terrain${nearby.length > 1 ? 's' : ''} à explorer'
                                  : '${nearby.length} résultat${nearby.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _sub(context),
                              ),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() => _query = '');
                                provider.loadTerrains(refresh: true);
                              },
                              child: const Text(
                                'Effacer',
                                style: TextStyle(
                                  color: kGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // 1. TERRAINS POPULAIRES (Horizontal)
                  if (_query.isEmpty && popular.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                        child: Text('Terrains populaires', style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.w800, color: kGreen)),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: popular.length,
                          itemBuilder: (_, i) => _PopularHorizontalItem(terrain: popular[i]),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],

                  // 2. TOUS LES TERRAINS / PROXIMITÉ (Vertical)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: Text(
                        _query.isEmpty ? 'Terrains à proximité' : 'Résultats de recherche',
                        style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.w800, color: kGreen),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: nearby.isEmpty
                        ? SliverToBoxAdapter(
                            child: _TerrainEmptyState(hasQuery: _query.isNotEmpty),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _PopularItem(terrain: nearby[i]),
                              childCount: nearby.length,
                            ),
                          ),
                  ),

                  // Indicateur de chargement pagination
                  if (provider.isLoading && nearby.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ITEM POPULAIRE (horizontal) ──
class _PopularHorizontalItem extends StatelessWidget {
  final Terrain terrain;
  const _PopularHorizontalItem({required this.terrain});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TerrainDetailScreen(terrain: terrain))),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  terrain.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: kGreen.withOpacity(0.1), child: const Icon(Icons.image, color: kGreen)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(terrain.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.orange, size: 14),
                      const SizedBox(width: 2),
                      Text(terrain.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text('${terrain.pricePerHour} F', style: const TextStyle(color: kGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _PopularItem extends StatelessWidget {
  final Terrain terrain;
  const _PopularItem({required this.terrain});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TerrainProvider>();
    final auth = context.watch<AuthProvider>();
    final isFav = provider.favorites.any((t) => t.id == terrain.id);

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
                    color: kGreen.withOpacity(0.10)),
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
                      if (provider.userPosition != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${(provider.distanceTo(terrain) / 1000).toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 11,
                              color: kGreen,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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
            GestureDetector(
              onTap: () {
                if (auth.token != null) {
                  provider.toggleFavorite(auth.token!, terrain.id);
                }
              },
              child: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 20,
                color: isFav ? Colors.red : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DiscoveryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? kGreen : _card(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _txt(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _TerrainEmptyState extends StatelessWidget {
  final bool hasQuery;

  const _TerrainEmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 36, color: _sub(context)),
          const SizedBox(height: 10),
          Text(
            hasQuery ? 'Aucun terrain trouvé' : 'Aucun terrain à afficher',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _txt(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasQuery
                ? 'Essaie un autre quartier ou retire quelques mots.'
                : 'Recharge la liste ou active la localisation pour affiner.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _sub(context), height: 1.4),
          ),
        ],
      ),
    );
  }
}
