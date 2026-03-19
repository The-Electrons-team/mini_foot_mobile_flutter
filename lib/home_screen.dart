import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'terrain_map_screen.dart';
import 'terrain_list_screen.dart';
import 'terrain_detail_screen.dart';
import 'terrain_data.dart';
import 'reservations_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

const Color kGreen = Color(0xFF006F39);

// ─── Helpers thème ──────────────────────────────────────────────────────────
bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c)  => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)  => _isDark(c)
    ? const Color(0xFFF0EBE0).withValues(alpha: 0.5)
    : Colors.black.withValues(alpha: 0.45);

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
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NAVBAR
// ---------------------------------------------------------------------------

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
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
                      color: Colors.black.withValues(alpha: dark ? 0.4 : 0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(icon: Icons.home_rounded, index: 0, selected: selectedIndex == 0, onTap: onTap),
                    _NavItem(icon: Icons.chat_bubble_outline_rounded, index: 1, selected: selectedIndex == 1, onTap: onTap),
                    const SizedBox(width: 64),
                    _NavItem(icon: Icons.notifications_none_rounded, index: 3, selected: selectedIndex == 3, onTap: onTap),
                    _NavItem(icon: Icons.person_outline_rounded, index: 4, selected: selectedIndex == 4, onTap: onTap),
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
                        color: Colors.black.withValues(alpha: 0.12),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final bool selected;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? kGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 22,
          color: selected ? Colors.white : _sub(context),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAGE ACCUEIL
// ---------------------------------------------------------------------------

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header fixe
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour 👋',
                      style: TextStyle(color: _sub(context), fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'MINIFOOT',
                      style: GoogleFonts.orbitron(
                        color: kGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline_rounded, color: kGreen, size: 24),
                ),
              ],
            ),
          ),

          // Contenu scrollable
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Bannière
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              'https://images.unsplash.com/photo-1560272564-c83b66b1ad12?w=800&q=80',
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              errorBuilder: (_, e, s) => const SizedBox(),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    kGreen.withValues(alpha: 0.85),
                                    kGreen.withValues(alpha: 0.30),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.45, 0.75],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Deviens le roi\ndu terrain.',
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                ),

                // Actions rapides
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
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
                        ),
                        _QuickAction(
                          icon: Icons.sports_rounded,
                          label: 'Matchs',
                          bgColor: _isDark(context) ? const Color(0xFF2A2310) : const Color(0xFFFFF8E1),
                          iconColor: const Color(0xFFF57F17),
                        ),
                        _QuickAction(
                          icon: Icons.workspace_premium_rounded,
                          label: 'Classement',
                          bgColor: _isDark(context) ? const Color(0xFF2A1520) : const Color(0xFFFCE4EC),
                          iconColor: const Color(0xFFAD1457),
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
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
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
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
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
        children: [
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Icon(icon, color: iconColor, size: 28)),
          ),
          const SizedBox(height: 7),
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
              color: _current == i ? kGreen : Colors.black.withValues(alpha: 0.15),
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
          final t = terrains.firstWhere(
            (t) => t.name == data.title,
            orElse: () => terrains[0],
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
                color: data.accentColor.withValues(alpha: 0.25),
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
                    Container(color: data.accentColor.withValues(alpha: 0.3)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.75),
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
                            color: Colors.white.withValues(alpha: 0.15),
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
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
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
