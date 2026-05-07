import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'terrain_map_screen.dart';
import 'terrain_list_screen.dart';
import 'terrain_detail_screen.dart';
import 'terrain_data.dart';
import 'providers/terrain_provider.dart';
import 'reservations_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'team_screen.dart';
import 'social_feed_screen.dart';
import 'shop_screen.dart';
import 'ranking_screen.dart';
import 'main.dart';

const Color kGreen = Color(0xFF006F39);

// ─── Helpers thème ──────────────────────────────────────────────────────────
bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c)  => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)  => _isDark(c)
    ? const Color(0xFFF0EBE0).withOpacity(0.5)
    : Colors.black.withOpacity(0.45);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _HomePage(),
    const ChatListScreen(),
    const TerrainMapScreen(),
    const ShopScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) {
          setState(() => _selectedIndex = i);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NAVBAR
// ---------------------------------------------------------------------------

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);
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
                  color: _card(context),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(dark ? 0.4 : 0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    NavItem(icon: Icons.home_rounded, index: 0, selected: selectedIndex == 0, onTap: onTap),
                    NavItem(icon: Icons.chat_bubble_outline_rounded, index: 1, selected: selectedIndex == 1, onTap: onTap),
                    const SizedBox(width: 64),
                    NavItem(icon: Icons.storefront_rounded, index: 3, selected: selectedIndex == 3, onTap: onTap),
                    NavItem(icon: Icons.person_outline_rounded, index: 4, selected: selectedIndex == 4, onTap: onTap),
                  ],
                ),
              ),
            ),

            // Bouton central surélevé
            Positioned(
              bottom: 20,
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _card(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedIndex == 2 ? kGreen : Colors.black12,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'assets/images/ballon.png',
                      fit: BoxFit.contain,
                    ),
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

class NavItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final bool selected;
  final ValueChanged<int> onTap;
  final int badge;

  const NavItem({
    required this.icon,
    required this.index,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected ? kGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: selected ? Colors.white : _sub(context)),
          ),
          if (badge > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: _card(context), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    badge > 9 ? '9+' : '$badge',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAGE ACCUEIL
// ---------------------------------------------------------------------------

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tp = context.read<TerrainProvider>();
      tp.loadTerrains();
      tp.updateLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final terrains = context.watch<TerrainProvider>().terrains;
    final topPadding = MediaQuery.of(context).padding.top;
    return Column(
        children: [
          // ── HEADER HERO (bords arrondis en bas) ──────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  // Image de fond
                  Positioned.fill(
                    child: Image.network(
                      'https://images.unsplash.com/photo-1560272564-c83b66b1ad12?w=800&q=80',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, e, s) => Container(color: kGreen),
                    ),
                  ),
                  // Dégradé vert
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kGreen.withOpacity(0.92),
                            kGreen.withOpacity(0.55),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 0.85],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  // Contenu
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo + toggle thème
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bonjour 👋',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'MINIFOOT',
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: themeNotifier,
                              builder: (_, mode, __) {
                                final isDark = mode == ThemeMode.dark;
                                return Row(
                                  children: [
                            // Icône notifications
                            Consumer2<NotificationProvider, AuthProvider>(
                              builder: (ctx, notifProv, authProv, __) {
                                final count = notifProv.unreadCount;
                                return GestureDetector(
                                  onTap: () {
                                    final token = authProv.token;
                                    if (token != null) {
                                      notifProv.markAllAsRead(token);
                                    }
                                    Navigator.push(ctx,
                                        MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 42, height: 42,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.notifications_none_rounded, color: kGreen, size: 22),
                                      ),
                                      if (count > 0)
                                        Positioned(
                                          top: -1, right: -1,
                                          child: Container(
                                            width: 14, height: 14,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 1.5),
                                            ),
                                            child: Center(
                                              child: Text(
                                                count > 9 ? '9+' : '$count',
                                                style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                                    const SizedBox(width: 8),
                                    // Toggle thème
                                    GestureDetector(
                                      onTap: () => themeNotifier.value =
                                          isDark ? ThemeMode.light : ThemeMode.dark,
                                      child: Container(
                                        width: 42,
                                        height: 42,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                          color: kGreen,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Texte hero
                        Text(
                          'Deviens le roi\ndu terrain.',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Réserver',
                            style: TextStyle(
                              color: kGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenu scrollable
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Actions rapides
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: Text(
                      'Actions rapides',
                      style: GoogleFonts.orbitron(
                        color: _txt(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _QuickAction(
                          icon: Icons.map_outlined,
                          label: 'Terrains',
                          bgColor: _isDark(context) ? const Color(0xFF1A2E1A) : const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF2E7D32),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const TerrainListScreen())),
                        ),
                        _QuickAction(
                          icon: Icons.shield_outlined,
                          label: 'Mon équipe',
                          bgColor: _isDark(context) ? const Color(0xFF1A1D2E) : const Color(0xFFE8EAF6),
                          iconColor: const Color(0xFF283593),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const TeamScreen())),
                        ),
                        _QuickAction(
                          icon: Icons.dynamic_feed_rounded,
                          label: 'Terrain+',
                          bgColor: _isDark(context) ? const Color(0xFF2A2310) : const Color(0xFFFFF8E1),
                          iconColor: const Color(0xFFF57F17),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SocialFeedScreen())),
                        ),
                        _QuickAction(
                          icon: Icons.receipt_long_rounded,
                          label: 'Réservations',
                          bgColor: _isDark(context) ? const Color(0xFF12272A) : const Color(0xFFE0F2F1),
                          iconColor: const Color(0xFF00695C),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ReservationsScreen())),
                        ),
                      ],
                    ),
                  ),
                ),

                // À la une
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                    child: Row(
                      children: [
                        Text('À la une',
                            style: GoogleFonts.orbitron(
                                color: _txt(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('PUB',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: _PromoBannerCarousel()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Terrains populaires
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Terrains populaires',
                            style: GoogleFonts.orbitron(
                                color: _txt(context), fontSize: 15, fontWeight: FontWeight.w800)),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const TerrainListScreen())),
                          child: const Text('Voir tout',
                              style: TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: _TerrainHorizontalList()),


                // Boutique foot
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                    child: Row(
                      children: [
                        Text('Boutique foot',
                            style: GoogleFonts.orbitron(
                                color: _txt(context), fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE65100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('PUB',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: _ShopSection()),

                // Offres flash
                const SliverToBoxAdapter(child: _FlashDealsSection()),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
    );
  }
}

// ---------------------------------------------------------------------------
// TERRAIN HORIZONTAL LIST
// ---------------------------------------------------------------------------

class _TerrainHorizontalList extends StatefulWidget {
  const _TerrainHorizontalList();

  @override
  State<_TerrainHorizontalList> createState() => _TerrainHorizontalListState();
}

class _TerrainHorizontalListState extends State<_TerrainHorizontalList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TerrainProvider>().loadTerrains();
    });
  }

  @override
  Widget build(BuildContext context) {
    final terrainList = context.watch<TerrainProvider>().terrains;
    final isLoading = context.watch<TerrainProvider>().isLoading;

    if (isLoading && terrainList.isEmpty) {
      return const SizedBox(
        height: 190,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (terrainList.isEmpty) {
      return const SizedBox(height: 190, child: Center(child: Text("Aucun terrain disponible")));
    }

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: terrainList.length,
        itemBuilder: (_, i) {
          final t = terrainList[i];
          return GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => TerrainDetailScreen(terrain: t))),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(t.imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: kGreen.withOpacity(0.2))),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 11),
                            const SizedBox(width: 3),
                            Text('${t.rating}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10, right: 10, bottom: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)),
                          const SizedBox(height: 2),
                          Text(t.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10.5)),
                          if (context.read<TerrainProvider>().userPosition != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '${(context.read<TerrainProvider>().distanceTo(t) / 1000).toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  color: kGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(t.priceLabel,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 58,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Icon(icon, color: iconColor, size: 28)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _sub(context),
            ),
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// FEED PREVIEW (kept for reference, not used in home)
// ---------------------------------------------------------------------------

class _FeedPreview extends StatelessWidget {
  const _FeedPreview();

  static const _items = [
    _FeedItem(
      initials: 'LF', color: Color(0xFF006F39), author: 'Les Lions FC',
      caption: 'Victoire 5-2 contre les Tigres FC hier soir ! Merci à tous les supporters ⚽🏆',
      imageUrl: 'https://images.pexels.com/photos/13890306/pexels-photo-13890306.jpeg?auto=compress&cs=tinysrgb&w=600',
      likes: 124, comments: 3, time: 'Il y a 1h',
    ),
    _FeedItem(
      initials: 'TF', color: Color(0xFFE65100), author: 'Tigres FC',
      caption: 'Tournoi inter-quartiers ce samedi à HLM Grand Yoff ! Inscriptions ouvertes 🏆',
      imageUrl: 'https://images.pexels.com/photos/13783930/pexels-photo-13783930.jpeg?auto=compress&cs=tinysrgb&w=600',
      likes: 89, comments: 0, time: 'Il y a 3h',
    ),
    _FeedItem(
      initials: 'BP', color: Color(0xFF212121), author: 'Black Panthers',
      caption: 'Séance d\'entraînement au Terrain Dakar Arena 🔥 On prépare le prochain tournoi !',
      imageUrl: 'https://images.pexels.com/photos/12486370/pexels-photo-12486370.jpeg?auto=compress&cs=tinysrgb&w=600',
      likes: 56, comments: 1, time: 'Il y a 5h',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _items.length,
        itemBuilder: (_, i) => _FeedPreviewCard(item: _items[i]),
      ),
    );
  }
}

class _FeedItem {
  final String initials, author, caption, imageUrl, time;
  final Color color;
  final int likes, comments;
  const _FeedItem({
    required this.initials, required this.color, required this.author,
    required this.caption, required this.imageUrl, required this.time,
    required this.likes, required this.comments,
  });
}

class _FeedPreviewCard extends StatelessWidget {
  final _FeedItem item;
  const _FeedPreviewCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SocialFeedScreen())),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isDark(context) ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Image.network(
                    item.imageUrl,
                    width: 200, height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 200, height: 140,
                      color: item.color.withOpacity(0.2),
                    ),
                  ),
                ),
                // Badge likes en haut à droite
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_rounded, color: Colors.red, size: 12),
                        const SizedBox(width: 4),
                        Text('${item.likes}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
                // Avatar équipe en bas à gauche chevauchant l'image
                Positioned(
                  bottom: -16, left: 12,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: _card(context), width: 2.5),
                    ),
                    child: Center(
                      child: Text(item.initials,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            // Contenu texte
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.author,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 12.5, color: _txt(context))),
                      ),
                      Text(item.time,
                          style: TextStyle(fontSize: 10, color: _sub(context))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: _sub(context), height: 1.35)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 13, color: _sub(context)),
                      const SizedBox(width: 4),
                      Text('${item.comments} commentaire${item.comments > 1 ? "s" : ""}',
                          style: TextStyle(fontSize: 10.5, color: _sub(context))),
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
// ---------------------------------------------------------------------------
// SHOP SECTION — Boutique foot
// ---------------------------------------------------------------------------

class _ShopProduct {
  final String vendor, name, price, oldPrice, tag, imageUrl;
  final Color accentColor;
  final IconData categoryIcon;
  const _ShopProduct({
    required this.vendor, required this.name, required this.price,
    required this.oldPrice, required this.tag, required this.imageUrl,
    required this.accentColor, required this.categoryIcon,
  });
}

const _shopProducts = [
  _ShopProduct(
    vendor: 'DakarSport', name: 'Maillot Pro\nLions FC', price: '12 500 F',
    oldPrice: '18 000 F', tag: '-30%',
    imageUrl: 'https://images.pexels.com/photos/3621104/pexels-photo-3621104.jpeg?auto=compress&cs=tinysrgb&w=400',
    accentColor: Color(0xFF006F39), categoryIcon: Icons.checkroom_rounded,
  ),
  _ShopProduct(
    vendor: 'FootShop SN', name: 'Ballon Match\nFIFA Quality', price: '8 000 F',
    oldPrice: '11 000 F', tag: '-27%',
    imageUrl: 'https://images.pexels.com/photos/47730/the-ball-stadion-football-the-pitch-47730.jpeg?auto=compress&cs=tinysrgb&w=400',
    accentColor: Color(0xFF1565C0), categoryIcon: Icons.sports_soccer_rounded,
  ),
  _ShopProduct(
    vendor: 'SportZone DK', name: 'Crampons\nNike Mercurial', price: '35 000 F',
    oldPrice: '52 000 F', tag: '-33%',
    imageUrl: 'https://images.pexels.com/photos/2385477/pexels-photo-2385477.jpeg?auto=compress&cs=tinysrgb&w=400',
    accentColor: Color(0xFFE65100), categoryIcon: Icons.directions_run_rounded,
  ),
  _ShopProduct(
    vendor: 'KitFoot SN', name: 'Protège-tibias\nAdidas', price: '3 500 F',
    oldPrice: '5 000 F', tag: '-30%',
    imageUrl: 'https://images.pexels.com/photos/1884574/pexels-photo-1884574.jpeg?auto=compress&cs=tinysrgb&w=400',
    accentColor: Color(0xFF6A1B9A), categoryIcon: Icons.shield_rounded,
  ),
];

class _ShopSection extends StatelessWidget {
  const _ShopSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _shopProducts.length,
        itemBuilder: (_, i) {
          final p = _shopProducts[i];
          return Container(
            width: 148,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _card(context),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDark(context) ? 0.3 : 0.07),
                  blurRadius: 10, offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image avec badge promo
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Image.network(
                        p.imageUrl, width: 148, height: 110, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 148, height: 110,
                          color: p.accentColor.withOpacity(0.15),
                          child: Icon(p.categoryIcon, color: p.accentColor, size: 36),
                        ),
                      ),
                    ),
                    // Badge réduction
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(p.tag,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    // Icône catégorie
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(p.categoryIcon, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
                // Infos produit
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.vendor,
                          style: TextStyle(fontSize: 9.5, color: p.accentColor, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(p.name,
                          maxLines: 2, style: TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w700,
                              color: _txt(context), height: 1.2)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(p.price,
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w900, color: p.accentColor)),
                          const SizedBox(width: 6),
                          Text(p.oldPrice,
                              style: TextStyle(
                                  fontSize: 10, color: _sub(context),
                                  decoration: TextDecoration.lineThrough)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FLASH DEALS SECTION
// ---------------------------------------------------------------------------

class _FlashDealsSection extends StatelessWidget {
  const _FlashDealsSection();

  static const _deals = [
    _DealData(
      vendor: 'DakarSport Pro',
      title: 'Kit complet équipe',
      subtitle: '10 maillots + shorts + chaussettes · Toutes tailles',
      price: '85 000 F', oldPrice: '130 000 F',
      accentColor: Color(0xFF006F39),
      icon: Icons.checkroom_rounded,
    ),
    _DealData(
      vendor: 'FootShop SN',
      title: 'Pack entraînement',
      subtitle: '5 ballons match + filet de rangement inclus',
      price: '32 000 F', oldPrice: '50 000 F',
      accentColor: Color(0xFF1565C0),
      icon: Icons.sports_soccer_rounded,
    ),
    _DealData(
      vendor: 'SportZone DK',
      title: 'Chaussures terrain',
      subtitle: 'Adidas Copa · Gazon synthétique · Tailles 38-46',
      price: '28 000 F', oldPrice: '45 000 F',
      accentColor: Color(0xFFE65100),
      icon: Icons.directions_run_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header flash
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('OFFRES FLASH',
                        style: GoogleFonts.orbitron(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('PUB',
                    style: TextStyle(
                        color: Color(0xFFE65100), fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Liste deals
          ..._deals.map((d) => _DealTile(deal: d)),
        ],
      ),
    );
  }
}

class _DealData {
  final String vendor, title, subtitle, price, oldPrice;
  final Color accentColor;
  final IconData icon;
  const _DealData({
    required this.vendor, required this.title, required this.subtitle,
    required this.price, required this.oldPrice,
    required this.accentColor, required this.icon,
  });
}

class _DealTile extends StatelessWidget {
  final _DealData deal;
  const _DealTile({required this.deal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: deal.accentColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: deal.accentColor.withOpacity(0.06),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône catégorie
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: deal.accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(deal.icon, color: deal.accentColor, size: 26),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deal.vendor,
                    style: TextStyle(
                        fontSize: 10, color: deal.accentColor, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(deal.title,
                    style: TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w800, color: _txt(context))),
                const SizedBox(height: 2),
                Text(deal.subtitle,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: _sub(context))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Prix
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(deal.price,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w900, color: deal.accentColor)),
              Text(deal.oldPrice,
                  style: TextStyle(
                      fontSize: 10, color: _sub(context),
                      decoration: TextDecoration.lineThrough)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: deal.accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Voir',
                    style: TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PROMO BANNER CAROUSEL
// ---------------------------------------------------------------------------

class _PromoBannerCarousel extends StatefulWidget {
  const _PromoBannerCarousel();

  @override
  State<_PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<_PromoBannerCarousel> {
  final _controller = PageController();
  int _current = 0;

  static const _banners = [
    _BannerData(
      type: 'terrain',
      tag: 'FEATURED',
      title: 'Terrain Dakar Arena',
      subtitle: 'Diamniadio · Gazon synthétique LED',
      detail: '5 000 F/h',
      badgeIcon: Icons.star_rounded,
      badgeLabel: '4.8',
      imageUrl: 'https://images.pexels.com/photos/12486370/pexels-photo-12486370.jpeg?auto=compress&cs=tinysrgb&w=800',
      accentColor: Color(0xFF006F39),
      cta: 'Réserver',
    ),
    _BannerData(
      type: 'tournament',
      tag: 'TOURNOI',
      title: 'Coupe du Sénégal',
      subtitle: '16 équipes · Éliminatoires directes',
      detail: 'Prix : 150 000 F',
      badgeIcon: Icons.emoji_events_rounded,
      badgeLabel: 'Ouvert',
      imageUrl: 'https://images.pexels.com/photos/13783930/pexels-photo-13783930.jpeg?auto=compress&cs=tinysrgb&w=800',
      accentColor: Color(0xFF1A1A1A),
      cta: 'Participer',
    ),
    _BannerData(
      type: 'promo',
      tag: 'PROMO',
      title: '-20% avant 10h',
      subtitle: 'Réservez tôt et économisez sur tous les terrains partenaires',
      detail: 'Code : MATIN20',
      badgeIcon: Icons.timer_rounded,
      badgeLabel: 'Limité',
      imageUrl: 'https://images.pexels.com/photos/7160121/pexels-photo-7160121.jpeg?auto=compress&cs=tinysrgb&w=800',
      accentColor: Color(0xFFE65100),
      cta: 'En profiter',
    ),
    _BannerData(
      type: 'terrain',
      tag: 'POPULAIRE',
      title: 'Stade Léopold Sédar',
      subtitle: 'Plateau, Dakar · Gazon naturel',
      detail: '8 000 F/h',
      badgeIcon: Icons.star_rounded,
      badgeLabel: '4.5',
      imageUrl: 'https://images.pexels.com/photos/13890306/pexels-photo-13890306.jpeg?auto=compress&cs=tinysrgb&w=800',
      accentColor: Color(0xFF006F39),
      cta: 'Réserver',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 10));
      if (!mounted) return false;
      final next = (_current + 1) % _banners.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      return true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 210,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: _banners.length,
            itemBuilder: (_, i) => _BannerCard(data: _banners[i]),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _current == i ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: _current == i ? kGreen : Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ),
      ],
    );
  }
}

class _BannerData {
  final String type, tag, title, subtitle, detail, badgeLabel, imageUrl, cta;
  final IconData badgeIcon;
  final Color accentColor;

  const _BannerData({
    required this.type, required this.tag, required this.title,
    required this.subtitle, required this.detail, required this.badgeIcon,
    required this.badgeLabel, required this.imageUrl,
    required this.accentColor, required this.cta,
  });
}

class _BannerCard extends StatelessWidget {
  final _BannerData data;
  const _BannerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (data.type == 'terrain') {
          final list = context.read<TerrainProvider>().terrains;
          if (list.isEmpty) return;
          final t = list.firstWhere(
            (t) => t.name == data.title,
            orElse: () => list.first,
          );
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => TerrainDetailScreen(terrain: t)));
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: data.accentColor.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                data.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) =>
                    Container(color: data.accentColor.withOpacity(0.3)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: data.accentColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(data.tag,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9,
                                  fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(data.badgeIcon, color: Colors.white, size: 11),
                              const SizedBox(width: 3),
                              Text(data.badgeLabel,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(data.title,
                        style: GoogleFonts.orbitron(
                            color: Colors.white, fontSize: 17,
                            fontWeight: FontWeight.w900, height: 1.2)),
                    const SizedBox(height: 4),
                    Text(data.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(data.detail,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(data.cta,
                              style: TextStyle(
                                  color: data.accentColor == const Color(0xFF1A1A1A)
                                      ? Colors.black
                                      : data.accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
