import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'terrain_data.dart';
import 'terrain_booking_screen.dart';
import 'terrain_map_screen.dart';
import 'services/terrain_service.dart';
import 'providers/auth_provider.dart';
import 'providers/terrain_provider.dart';
import 'chat_screen.dart';
import 'providers/chat_provider.dart';
import 'app_snackbar.dart';

const Color kGreen = Color(0xFF006F39);
const Color kDark = Color(0xFF1A1A1A);
const Color kBeige = Color(0xFFF5F0E8);

// ── Helpers thème ──
bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c) => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c) => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c) => _isDark(c)
    ? const Color(0xFFF0EBE0).withOpacity(0.5)
    : Colors.black.withOpacity(0.45);

class TerrainDetailScreen extends StatefulWidget {
  final Terrain terrain;
  const TerrainDetailScreen({super.key, required this.terrain});

  @override
  State<TerrainDetailScreen> createState() => _TerrainDetailScreenState();
}

class _TerrainDetailScreenState extends State<TerrainDetailScreen> {
  SubTerrain? _selectedSub;

  int _selectedTab = 0;
  int _selectedImageIndex = 0;
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.terrain.rating;
    // Si un seul terrain, on le sélectionne par défaut
    if (widget.terrain.subTerrains.length == 1) {
      _selectedSub = widget.terrain.subTerrains.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.terrain;
    final List<String> images = t.imageUrls.isNotEmpty ? t.imageUrls : [t.imageUrl];

    return Scaffold(
      backgroundColor: _bg(context),
      bottomNavigationBar: _buildBottomBar(context, t),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: _bg(context),
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _card(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded, color: kGreen, size: 18),
                ),
              ),
            ),
            actions: [
              Consumer2<TerrainProvider, AuthProvider>(
                builder: (context, terrainProv, authProv, _) {
                  final isFav = terrainProv.favorites.any((fav) => fav.id == t.id);
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        final token = authProv.token;
                        if (token != null) terrainProv.toggleFavorite(token, t.id);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _bg(context).withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: isFav ? kGreen : _txt(context),
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _selectedImageIndex = i),
                    itemBuilder: (context, index) {
                      final img = images[index];
                      if (img.isEmpty) return Container(color: kGreen.withOpacity(0.12));
                      return Image.network(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: kGreen.withOpacity(0.12)),
                      );
                    },
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.0, 0.2, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 30,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${_selectedImageIndex + 1} / ${images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: _bg(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              transform: Matrix4.translationValues(0, -24, 0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            t.name,
                            style: GoogleFonts.orbitron(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: _txt(context),
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFD4AF37), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _currentRating.toStringAsFixed(1),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFFD4AF37)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: _sub(context), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            t.address,
                            style: TextStyle(fontSize: 13, color: _sub(context), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        _Tab(label: 'À propos', index: 0, selected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                        _Tab(label: 'Avis', index: 1, selected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                        _Tab(label: 'Carte', index: 2, selected: _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2)),
                      ],
                    ),
                    Container(height: 1, color: _isDark(context) ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05)),
                    const SizedBox(height: 24),
                    if (_selectedTab == 0) _AboutTab(terrain: t, selectedSub: _selectedSub, onSelect: (s) => setState(() => _selectedSub = s)),
                    if (_selectedTab == 1) _ReviewTab(terrain: t, onRatingUpdated: (r) => setState(() => _currentRating = r)),
                    if (_selectedTab == 2) _MapTab(terrain: t),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Terrain t) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: _card(context),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(_isDark(context) ? 0.3 : 0.08), blurRadius: 24, offset: const Offset(0, -6)),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Prix à partir de', style: TextStyle(fontSize: 12, color: _sub(context), fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _selectedSub != null ? '${_selectedSub!.pricePerHour ?? t.pricePerHour} F' : t.priceLabel,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _txt(context)),
                  ),
                  Text(' /h', style: TextStyle(fontSize: 12, color: _sub(context), fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const Spacer(),
          if (t.managerId != null) ...[
            GestureDetector(
              onTap: () async {
                final chatProvider = context.read<ChatProvider>();
                final auth = context.read<AuthProvider>();
                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: kGreen)));
                try {
                  final convData = await chatProvider.getOrCreateDirectConversation(t.managerId!);
                  if (!mounted) return;
                  Navigator.pop(context);
                  final chat = ChatPreview.fromJson(convData, auth.user?.id ?? '');
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatConversationScreen(chat: chat)));
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  AppSnackbar.error(context, 'Impossible d\'ouvrir le chat. Réessayez.');
                }
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kGreen.withOpacity(0.3)),
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: kGreen, size: 24),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: GestureDetector(
              onTap: (_selectedSub != null || t.subTerrains.isEmpty)
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => TerrainBookingScreen(terrain: widget.terrain, initialSubTerrain: _selectedSub)))
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: (_selectedSub != null || t.subTerrains.isEmpty)
                        ? [kGreen, const Color(0xFF00C264)]
                        : [Colors.grey[400]!, Colors.grey[500]!],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: (_selectedSub != null || t.subTerrains.isEmpty)
                      ? [BoxShadow(color: kGreen.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 4))]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _selectedSub != null ? 'Réserver' : 'Choisir terrain',
                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
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
  const _Tab({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? _txt(context) : _sub(context),
          ),
        ),
      ),
    );
  }
}

// ── ONGLET À PROPOS ──
class _AboutTab extends StatelessWidget {
  final Terrain terrain;
  final SubTerrain? selectedSub;
  final Function(SubTerrain) onSelect;
  const _AboutTab({
    required this.terrain,
    required this.selectedSub,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _txt(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          terrain.description,
          style: TextStyle(fontSize: 13, height: 1.65, color: _sub(context)),
        ),

        const SizedBox(height: 20),

        if (terrain.subTerrains.length > 1) ...[
          Text(
            'Options de réservation',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _txt(context),
            ),
          ),
          const SizedBox(height: 12),
          ...terrain.subTerrains.map((s) {
            final isSelected = selectedSub?.id == s.id;
            return InkWell(
              onTap: () => onSelect(s),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? kGreen.withOpacity(0.05) : _card(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? kGreen : kGreen.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.sports_soccer_rounded,
                        color: kGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.reservationLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _txt(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${s.divisionLabel} • ${s.type} • ${s.capacity} joueurs • ${s.surface ?? 'Synthétique'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: _sub(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (s.pricePerHour != null)
                      Text(
                        '${s.pricePerHour} F',
                        style: const TextStyle(
                          color: kGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 20),
        ],

        if (terrain.contactPhones.isNotEmpty) ...[
          Text(
            'Contacts',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _txt(context),
            ),
          ),
          const SizedBox(height: 12),
          ...terrain.contactPhones.map((phone) => GestureDetector(
            onTap: () async {
              final Uri url = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Impossible de lancer l\'appel')),
                  );
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _card(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone_rounded, color: kGreen, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      phone,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _txt(context),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _sub(context)),
                ],
              ),
            ),
          )),
          const SizedBox(height: 20),
        ],

        Text(
          'Équipements',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _txt(context),
          ),
        ),
        const SizedBox(height: 12),

        // Grille 2 colonnes de cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3.2,
          children: terrain.featureIcons
              .map(
                (f) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _card(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(f.icon, size: 18, color: kGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _txt(context),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ── ONGLET AVIS DYNAMIQUE ──
class _ReviewTab extends StatefulWidget {
  final Terrain terrain;
  final Function(double)? onRatingUpdated;
  const _ReviewTab({required this.terrain, this.onRatingUpdated});

  @override
  State<_ReviewTab> createState() => _ReviewTabState();
}

class _ReviewTabState extends State<_ReviewTab> {
  final TerrainService _service = TerrainService();
  List<TerrainReview> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final list = await _service.fetchReviews(
      widget.terrain.id,
      token: context.read<AuthProvider>().token,
    );
    if (mounted) {
      setState(() {
        _reviews = list;
        _isLoading = false;
      });
    }
  }

  void _showAddReviewSheet() {
    int rating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 30,
          ),
          decoration: BoxDecoration(
            color: _card(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _sub(context).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Votre avis',
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _txt(context),
                ),
              ),
              const SizedBox(height: 20),
              // Étoiles
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      onPressed: () => setDialogState(() => rating = i + 1),
                      icon: Icon(
                        i < rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFFFB300),
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: commentController,
                maxLines: 3,
                style: TextStyle(color: _txt(context), fontSize: 14),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Partagez votre expérience sur ce terrain...',
                  hintStyle: TextStyle(color: _sub(context)),
                  filled: true,
                  fillColor: _bg(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final token = context.read<AuthProvider>().token;
                    if (token == null) return;

                    final result = await _service.addReview(
                      token,
                      widget.terrain.id,
                      rating,
                      commentController.text,
                    );
                    if (result != null && mounted) {
                      Navigator.pop(context);
                      await _loadReviews();

                      // Calculer la nouvelle moyenne locale
                      if (_reviews.isNotEmpty) {
                        final avg =
                            _reviews
                                .map((r) => r.rating)
                                .reduce((a, b) => a + b) /
                            _reviews.length;
                        widget.onRatingUpdated?.call(avg);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Avis ajouté avec succès !',
                                style: GoogleFonts.orbitron(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: kGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          margin: const EdgeInsets.all(20),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Publier l\'avis',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Note globale + Bouton Ajout
        Row(
          children: [
            Text(
              '${widget.terrain.rating.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: _txt(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < widget.terrain.rating.floor()
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFFFB300),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_reviews.length} avis',
                    style: TextStyle(fontSize: 13, color: _sub(context)),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _showAddReviewSheet,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: kGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: kGreen))
        else if (_reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Aucun avis pour le moment.',
                style: TextStyle(color: _sub(context)),
              ),
            ),
          )
        else
          ..._reviews.map((r) => _ReviewCard(review: r)),
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
  final TerrainReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    // Calcul de la date relative
    final diff = DateTime.now().difference(review.createdAt);
    String dateStr;
    if (diff.inDays > 0)
      dateStr = 'Il y a ${diff.inDays}j';
    else if (diff.inHours > 0)
      dateStr = 'Il y a ${diff.inHours}h';
    else
      dateStr = 'À l\'instant';

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
                backgroundColor: kGreen.withOpacity(0.1),
                backgroundImage: review.userAvatar != null
                    ? NetworkImage(review.userAvatar!)
                    : null,
                child: review.userAvatar == null
                    ? Text(
                        review.userName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: kGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _txt(context),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 11, color: _sub(context)),
                    ),
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
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: TextStyle(fontSize: 12, height: 1.5, color: _sub(context)),
            ),
          ],
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
        Text(
          'Localisation',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _txt(context),
          ),
        ),
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
                      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=${dotenv.env['MAPBOX_ACCESS_TOKEN']}',
                  fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.minifoot.app',
                  tileSize: 512,
                  zoomOffset: -1,
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
                              color: kGreen.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_soccer_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
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
                child: Text(
                  terrain.address,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _txt(context),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Bouton ouvrir carte complète
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TerrainMapScreen()),
          ),
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
                Text(
                  'Voir sur la carte complète',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
