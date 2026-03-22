import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'terrain_data.dart';
import 'terrain_detail_screen.dart';

const Color kGreen = Color(0xFF006F39);
const Color kGreenLight = Color(0xFF00C264);
const Color kDark = Color(0xFF1C1C1E);

// ── Modèle local ─────────────────────────────────────────────────────────────
class _Terrain {
  final String name, address, price;
  final double lat, lng, rating;
  final String distance;
  const _Terrain({
    required this.name, required this.address, required this.price,
    required this.lat, required this.lng,
    this.rating = 4.5, this.distance = '2.0 km',
  });
}

final List<_Terrain> _terrains = [
  _Terrain(name: 'Terrain Dakar Arena',  address: 'Diamniadio, Dakar',    price: '5 000 F/h', rating: 4.8, distance: '4.0 km', lat: 14.7645, lng: -17.3660),
  _Terrain(name: 'Stade Léopold Sédar', address: 'Plateau, Dakar',        price: '8 000 F/h', rating: 4.5, distance: '2.1 km', lat: 14.6760, lng: -17.4469),
  _Terrain(name: 'Terrain Point E',      address: 'Point E, Dakar',        price: '6 500 F/h', rating: 4.7, distance: '1.3 km', lat: 14.6928, lng: -17.4571),
  _Terrain(name: 'Terrain HLM',          address: 'HLM Grand Yoff, Dakar', price: '4 000 F/h', rating: 4.2, distance: '3.5 km', lat: 14.7120, lng: -17.4620),
];

// ── Écran principal ───────────────────────────────────────────────────────────
class TerrainMapScreen extends StatefulWidget {
  const TerrainMapScreen({super.key});
  @override
  State<TerrainMapScreen> createState() => _TerrainMapScreenState();
}

class _TerrainMapScreenState extends State<TerrainMapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<_Terrain> _filtered = List.from(_terrains);
  LatLng? _myPosition;
  bool _locating = false;
  _Terrain? _selectedTerrain;
  List<LatLng> _routePoints = [];
  bool _loadingRoute = false;
  String? _routeDuration;
  String? _routeDistance;

  // Animation pulse position utilisateur
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _locateMe();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _search(String q) {
    setState(() {
      _selectedTerrain = null;
      _routePoints = [];
      _filtered = _terrains
          .where((t) =>
              t.name.toLowerCase().contains(q.toLowerCase()) ||
              t.address.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) { setState(() => _locating = false); return; }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() { _myPosition = latlng; _locating = false; });
      _mapController.move(latlng, 13);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locating = false);
    }
  }

  Future<void> _fetchRoute(_Terrain terrain) async {
    if (_myPosition == null) return;
    setState(() { _loadingRoute = true; _routePoints = []; });
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${_myPosition!.longitude},${_myPosition!.latitude};'
          '${terrain.lng},${terrain.lat}'
          '?overview=full&geometries=geojson';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        final meters = (data['routes'][0]['distance'] as num).toDouble();
        final seconds = (data['routes'][0]['duration'] as num).toDouble();
        final pts = coords.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
        if (!mounted) return;
        setState(() {
          _routePoints = pts;
          _routeDistance = meters < 1000
              ? '${meters.round()} m'
              : '${(meters / 1000).toStringAsFixed(1)} km';
          _routeDuration = seconds < 60
              ? '${seconds.round()} sec'
              : '${(seconds / 60).round()} min';
          _loadingRoute = false;
        });
        // Fit bounds sur la route
        if (pts.isNotEmpty) {
          final lats = pts.map((p) => p.latitude);
          final lngs = pts.map((p) => p.longitude);
          final bounds = LatLngBounds(
            LatLng(lats.reduce(math.min) - 0.005, lngs.reduce(math.min) - 0.005),
            LatLng(lats.reduce(math.max) + 0.005, lngs.reduce(math.max) + 0.005),
          );
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)));
        }
      } else {
        setState(() => _loadingRoute = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRoute = false);
    }
  }

  Future<void> _openNavigation(_Terrain terrain) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${terrain.lat},${terrain.lng}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _selectTerrain(_Terrain t) {
    setState(() { _selectedTerrain = t; _routePoints = []; _routeDuration = null; _routeDistance = null; });
    _mapController.move(LatLng(t.lat, t.lng), 14);
    _fetchRoute(t);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          // ── Carte ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(14.7167, -17.4677),
              initialZoom: 12,
              backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE8E0D5),
              onTap: (_, __) => setState(() { _selectedTerrain = null; _routePoints = []; }),
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token=${dotenv.env['MAPBOX_ACCESS_TOKEN']}'
                    : 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=${dotenv.env['MAPBOX_ACCESS_TOKEN']}',
                userAgentPackageName: 'com.minifoot.app',
                tileSize: 256,
                keepBuffer: 4,
                panBuffer: 2,
                maxNativeZoom: 18,
                errorTileCallback: (tile, error, stackTrace) {},
              ),

              // Tracé de route
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: kGreenLight,
                      borderStrokeWidth: 2,
                      borderColor: kGreen.withValues(alpha: 0.6),
                    ),
                  ],
                ),

              // Marqueurs terrains
              MarkerLayer(
                markers: _filtered.map((t) {
                  final isSelected = _selectedTerrain?.name == t.name;
                  return Marker(
                    point: LatLng(t.lat, t.lng),
                    width: isSelected ? 100 : 80,
                    height: isSelected ? 100 : 80,
                    child: GestureDetector(
                      onTap: () => _selectTerrain(t),
                      child: _TerrainMarker(terrain: t, isSelected: isSelected),
                    ),
                  );
                }).toList(),
              ),

              // Position utilisateur
              if (_myPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _myPosition!,
                      width: 60,
                      height: 60,
                      child: _UserMarker(pulseAnim: _pulseAnim),
                    ),
                  ],
                ),
            ],
          ),

          // ── Overlay en haut pour lisibilité ───────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            height: 140,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? Colors.black : Colors.black).withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Barre de recherche ─────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark
                            ? kDark.withValues(alpha: 0.92)
                            : Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: kGreen.withValues(alpha: 0.4), width: 1),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _search,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un terrain...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.35),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.search_rounded, color: kGreen, size: 22),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Compteur terrains ──────────────────────────────────────────────
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 74, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: kGreen.withValues(alpha: 0.4), blurRadius: 8)],
                  ),
                  child: Text(
                    '${_filtered.length} terrain${_filtered.length > 1 ? 's' : ''}',
                    style: GoogleFonts.orbitron(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),

          // ── Boutons flottants droite ───────────────────────────────────────
          Positioned(
            right: 16,
            bottom: _selectedTerrain != null
                ? MediaQuery.of(context).padding.bottom + 72 + 210
                : MediaQuery.of(context).padding.bottom + 96,
            child: Column(
              children: [
                _FloatBtn(icon: Icons.layers_outlined, onTap: () {}, isDark: isDark),
                const SizedBox(height: 10),
                _FloatBtn(
                  icon: Icons.my_location_rounded,
                  onTap: _locating ? null : _locateMe,
                  loading: _locating,
                  active: _myPosition != null,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // ── Indicateur chargement route ────────────────────────────────────
          if (_loadingRoute)
            Positioned(
              bottom: 220,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? kDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kGreen.withValues(alpha: 0.4)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: kGreen, strokeWidth: 2)),
                      const SizedBox(width: 10),
                      Text('Calcul de l\'itinéraire...', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          // ── Popup terrain sélectionné ──────────────────────────────────────
          if (_selectedTerrain != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 72,
              left: 16,
              right: 16,
              child: _TerrainCard(
                terrain: _selectedTerrain!,
                routeDuration: _routeDuration,
                routeDistance: _routeDistance,
                hasRoute: _routePoints.isNotEmpty,
                isDark: isDark,
                onNavigate: () => _openNavigation(_selectedTerrain!),
                onDetail: () {
                  final t = terrains.firstWhere(
                    (t) => t.name == _selectedTerrain!.name,
                    orElse: () => terrains.first,
                  );
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TerrainDetailScreen(terrain: t)));
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Marqueur terrain ──────────────────────────────────────────────────────────
class _TerrainMarker extends StatelessWidget {
  final _Terrain terrain;
  final bool isSelected;
  const _TerrainMarker({required this.terrain, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Image.asset(
        'assets/images/minifoot.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

// ── Marqueur utilisateur avec pulse ──────────────────────────────────────────
class _UserMarker extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _UserMarker({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Cercle pulse externe
          Container(
            width: 60 * pulseAnim.value,
            height: 60 * pulseAnim.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.15 * (1 - pulseAnim.value + 0.5)),
            ),
          ),
          // Cercle pulse intermédiaire
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.2),
            ),
          ),
          // Point central
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 2)],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card terrain sélectionné ──────────────────────────────────────────────────
class _TerrainCard extends StatelessWidget {
  final _Terrain terrain;
  final String? routeDuration;
  final String? routeDistance;
  final bool hasRoute;
  final bool isDark;
  final VoidCallback onNavigate;
  final VoidCallback onDetail;

  const _TerrainCard({
    required this.terrain,
    required this.routeDuration,
    required this.routeDistance,
    required this.hasRoute,
    required this.isDark,
    required this.onNavigate,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? kDark : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final textSecondary = isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.45);
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
    final chipBg = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kGreen.withValues(alpha: 0.25), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15), blurRadius: 20, offset: const Offset(0, 6)),
          BoxShadow(color: kGreen.withValues(alpha: 0.08), blurRadius: 20),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kGreen.withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset('assets/images/minifoot.png', fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        terrain.name,
                        style: GoogleFonts.orbitron(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: kGreen, size: 12),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(terrain.address,
                              style: TextStyle(color: textSecondary, fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kGreen,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: kGreen.withValues(alpha: 0.4), blurRadius: 8)],
                  ),
                  child: Text(terrain.price,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                ),
              ],
            ),
          ),

          // ── Stats ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _StatChip(icon: Icons.star_rounded, color: const Color(0xFFFFD700), label: terrain.rating.toStringAsFixed(1), bg: chipBg, textColor: textSecondary),
                const SizedBox(width: 8),
                _StatChip(icon: Icons.directions_walk_rounded, color: textSecondary, label: terrain.distance, bg: chipBg, textColor: textSecondary),
                if (hasRoute && routeDuration != null) ...[
                  const SizedBox(width: 8),
                  _StatChip(icon: Icons.timer_outlined, color: kGreen, label: routeDuration!, bg: chipBg, textColor: textSecondary),
                  const SizedBox(width: 8),
                  _StatChip(icon: Icons.route_rounded, color: kGreen, label: routeDistance!, bg: chipBg, textColor: textSecondary),
                ],
              ],
            ),
          ),

          // ── Actions ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onDetail,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline_rounded, color: textSecondary, size: 16),
                          const SizedBox(width: 6),
                          Text('Détails', style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: onNavigate,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kGreen, kGreenLight],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: kGreen.withValues(alpha: 0.45), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.rotate(
                            angle: math.pi / 2,
                            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text('Démarrer',
                            style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip stat ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Color bg;
  final Color textColor;
  const _StatChip({required this.icon, required this.color, required this.label, required this.bg, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Bouton flottant ───────────────────────────────────────────────────────────
class _FloatBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final bool active;
  final bool isDark;

  const _FloatBtn({required this.icon, this.onTap, this.loading = false, this.active = false, this.isDark = true});

  @override
  Widget build(BuildContext context) {
    final bg = active ? kGreen : (isDark ? kDark : Colors.white);
    final iconColor = active ? Colors.white : (isDark ? Colors.white60 : Colors.black54);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: active ? kGreenLight : kGreen.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 3)),
            if (active) BoxShadow(color: kGreen.withValues(alpha: 0.4), blurRadius: 10),
          ],
        ),
        child: loading
            ? Padding(padding: const EdgeInsets.all(13), child: CircularProgressIndicator(color: kGreen, strokeWidth: 2))
            : Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}
