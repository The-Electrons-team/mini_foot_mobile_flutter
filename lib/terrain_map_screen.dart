import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'terrain_data.dart';
import 'terrain_detail_screen.dart';

const Color kGreen = Color(0xFF006F39);

final List<_Terrain> _terrains = [
  _Terrain(name: 'Terrain Dakar Arena',  address: 'Diamniadio, Dakar',    price: '5 000 F/h', rating: 4.8, distance: '4.0 km', lat: 14.7645, lng: -17.3660),
  _Terrain(name: 'Stade Léopold Sédar', address: 'Plateau, Dakar',        price: '8 000 F/h', rating: 4.5, distance: '2.1 km', lat: 14.6760, lng: -17.4469),
  _Terrain(name: 'Terrain Point E',      address: 'Point E, Dakar',        price: '6 500 F/h', rating: 4.7, distance: '1.3 km', lat: 14.6928, lng: -17.4571),
  _Terrain(name: 'Terrain HLM',          address: 'HLM Grand Yoff, Dakar', price: '4 000 F/h', rating: 4.2, distance: '3.5 km', lat: 14.7120, lng: -17.4620),
];

class TerrainMapScreen extends StatefulWidget {
  const TerrainMapScreen({super.key});

  @override
  State<TerrainMapScreen> createState() => _TerrainMapScreenState();
}

class _TerrainMapScreenState extends State<TerrainMapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<_Terrain> _filtered = List.from(_terrains);
  LatLng? _myPosition;
  bool _locating = false;
  _Terrain? _selectedTerrain;

  void _search(String q) {
    setState(() {
      _selectedTerrain = null;
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
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _myPosition = latlng;
        _locating = false;
      });
      _mapController.move(latlng, 14);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locating = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _locateMe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Carte Mapbox ──────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(14.7167, -17.4677),
              initialZoom: 12,
              onTap: (_, __) => setState(() => _selectedTerrain = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.minifoot.app',
              ),

              // Ma position
              if (_myPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _myPosition!,
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.5),
                              blurRadius: 14,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),

              // Marqueurs terrains
              MarkerLayer(
                markers: _filtered.map((t) {
                  final isSelected = _selectedTerrain?.name == t.name;
                  return Marker(
                    point: LatLng(t.lat, t.lng),
                    width: isSelected ? 79 : 62,
                    height: isSelected ? 79 : 62,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTerrain = t);
                        _mapController.move(LatLng(t.lat, t.lng), 14);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Image.asset(
                          'assets/images/minifoot.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── Popup info terrain (style image) ─────────────────────────────
          if (_selectedTerrain != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _TerrainPopup(
                terrain: _selectedTerrain!,
                onTap: () {
                  final terrain = terrains.firstWhere(
                    (t) => t.name == _selectedTerrain!.name,
                    orElse: () => terrains.first,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TerrainDetailScreen(terrain: terrain),
                    ),
                  );
                },
              ),
            ),

          // ── Barre de recherche ────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _search,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un terrain...',
                          hintStyle: TextStyle(
                            color: Colors.black.withValues(alpha: 0.35),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: Colors.black45, size: 22),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Boutons flottants droite ──────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                _FloatBtn(
                  icon: Icons.explore_outlined,
                  onTap: () {},
                ),
                const SizedBox(height: 10),
                _FloatBtn(
                  icon: Icons.my_location_rounded,
                  onTap: _locating ? null : _locateMe,
                  loading: _locating,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Popup info ──────────────────────────────────────────────────────────────

class _TerrainPopup extends StatelessWidget {
  final _Terrain terrain;
  final VoidCallback onTap;

  const _TerrainPopup({required this.terrain, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFB5A642), size: 16),
                const SizedBox(width: 4),
                Text(
                  terrain.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.directions_walk_rounded,
                    color: Colors.white54, size: 16),
                const SizedBox(width: 4),
                Text(
                  terrain.distance,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              terrain.name,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: Colors.white54, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    terrain.address,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bouton flottant ─────────────────────────────────────────────────────────

class _FloatBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  const _FloatBtn({required this.icon, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    color: kGreen, strokeWidth: 2),
              )
            : Icon(icon, color: Colors.black54, size: 22),
      ),
    );
  }
}

// ── Bottom sheet réservation ─────────────────────────────────────────────────

class _TerrainBottomSheet extends StatefulWidget {
  final _Terrain terrain;
  const _TerrainBottomSheet({required this.terrain});

  @override
  State<_TerrainBottomSheet> createState() => _TerrainBottomSheetState();
}

class _TerrainBottomSheetState extends State<_TerrainBottomSheet> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;

  final List<String> _slots = [
    '08:00 - 09:00', '09:00 - 10:00', '10:00 - 11:00',
    '14:00 - 15:00', '15:00 - 16:00', '18:00 - 19:00',
    '19:00 - 20:00', '20:00 - 21:00',
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx)
            .copyWith(colorScheme: const ColorScheme.light(primary: kGreen)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(widget.terrain.name,
                    style: GoogleFonts.orbitron(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(widget.terrain.price,
                    style: const TextStyle(
                        color: kGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_rounded, color: kGreen, size: 14),
            const SizedBox(width: 4),
            Text(widget.terrain.address,
                style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.45), fontSize: 13)),
          ]),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kGreen.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    color: kGreen, size: 18),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day.toString().padLeft(2, '0')}/'
                  '${_selectedDate.month.toString().padLeft(2, '0')}/'
                  '${_selectedDate.year}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.black45),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Text('Créneaux disponibles',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.55))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _slots.map((slot) {
              final selected = _selectedSlot == slot;
              return GestureDetector(
                onTap: () => setState(() => _selectedSlot = slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? kGreen : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(slot,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.black54,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedSlot == null ? null : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                disabledBackgroundColor: Colors.black12,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('Confirmer la réservation',
                  style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Terrain {
  final String name, address, price;
  final double lat, lng, rating;
  final String distance;
  const _Terrain({
    required this.name,
    required this.address,
    required this.price,
    required this.lat,
    required this.lng,
    this.rating = 4.5,
    this.distance = '2.0 km',
  });
}
