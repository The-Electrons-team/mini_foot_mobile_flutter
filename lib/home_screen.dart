import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'terrain_map_screen.dart';
import 'terrain_list_screen.dart';
import 'terrain_detail_screen.dart';
import 'terrain_data.dart';

const Color kGreen = Color(0xFF006F39);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _HomePage(),
    _PlaceholderPage(label: 'Messages'),
    TerrainMapScreen(),
    _PlaceholderPage(label: 'Notifications'),
    _PlaceholderPage(label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
    return SafeArea(
      child: SizedBox(
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Barre blanche
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
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(icon: Icons.home_rounded, index: 0, selected: selectedIndex == 0, onTap: onTap),
                    _NavItem(icon: Icons.chat_bubble_outline_rounded, index: 1, selected: selectedIndex == 1, onTap: onTap),
                    const SizedBox(width: 64), // espace pour le bouton central
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
                    color: Colors.white,
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
          color: selected ? Colors.white : Colors.black38,
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
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.50),
                        fontSize: 14,
                      ),
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
                  child: const Icon(Icons.person_outline_rounded,
                      color: kGreen, size: 24),
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
                    // Image joueur style PES plein écran
                    Positioned.fill(
                      child: Image.network(
                        'https://images.unsplash.com/photo-1560272564-c83b66b1ad12?w=800&q=80',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, _, _) => const SizedBox(),
                      ),
                    ),
                    // Dégradé vert depuis la gauche
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                  color: const Color(0xFF111111),
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
                mainAxisSpacing: 0,
                childAspectRatio: 0.85,
                children: [
                  _QuickAction(
                    icon: Icons.map_outlined,
                    label: 'Terrains',
                    bgColor: const Color(0xFFE8F5E9),
                    iconColor: const Color(0xFF2E7D32),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const TerrainListScreen())),
                  ),
                  const _QuickAction(
                    icon: Icons.shield_outlined,
                    label: 'Mon équipe',
                    bgColor: Color(0xFFE8EAF6),
                    iconColor: Color(0xFF283593),
                  ),
                  const _QuickAction(
                    icon: Icons.sports_rounded,
                    label: 'Matchs',
                    bgColor: Color(0xFFFFF8E1),
                    iconColor: Color(0xFFF57F17),
                  ),
                  const _QuickAction(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Classement',
                    bgColor: Color(0xFFFCE4EC),
                    iconColor: Color(0xFFAD1457),
                  ),
                ],
              ),
            ),
          ),

          // Terrains à proximité
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Text(
                'Terrains à proximité',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF111111),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _TerrainCard(index: i),
              childCount: 3,
            ),
          ),

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
          child: Center(
            child: Icon(icon, color: iconColor, size: 28),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.65),
          ),
        ),
      ],
      ),
    );
  }
}

class _TerrainCard extends StatelessWidget {
  final int index;
  const _TerrainCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final t = terrains[index];

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TerrainDetailScreen(terrain: t))),
      child: Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: kGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset('assets/images/ballon.png',
                width: 10, height: 10),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: kGreen, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      t.distance,
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                t.price,
                style: const TextStyle(
                  color: kGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'par heure',
                style: TextStyle(fontSize: 10, color: Colors.black38),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PLACEHOLDER PAGES
// ---------------------------------------------------------------------------

class _PlaceholderPage extends StatelessWidget {
  final String label;
  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: GoogleFonts.orbitron(
          color: kGreen,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
