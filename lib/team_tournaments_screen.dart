import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'team_screen.dart' show TeamData;

const Color _kGreen = Color(0xFF006F39);
const Color _kGold  = Color(0xFFE6A800);

Color _bg(BuildContext c)   => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c)  => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)  => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFFF0EBE0).withValues(alpha: 0.5)
    : Colors.black.withValues(alpha: 0.45);

// ─── Modèles ──────────────────────────────────────────────────────────────────
enum TournamentStatus { ongoing, finished, upcoming }

class TournamentModel {
  final String name, phase, location, image;
  final int teams;
  final int? myPosition;
  final int? prize;
  final TournamentStatus status;
  final bool hasQualified;
  const TournamentModel({
    required this.name, required this.phase, required this.location,
    required this.teams, required this.status, required this.image,
    this.myPosition, this.prize, this.hasQualified = false,
  });
}

final _mockTournaments = [
  TournamentModel(
    name: 'Coupe de Dakar 2025', phase: 'Demi-finales',
    location: 'Stade Léopold Sédar Senghor', teams: 16,
    status: TournamentStatus.ongoing, myPosition: 3,
    prize: 150000, hasQualified: true,
    image: 'assets/images/terrain.webp',
  ),
  TournamentModel(
    name: 'Ligue Pikine Saison 3', phase: 'Terminé – Vainqueur',
    location: 'Terrain Pikine Est', teams: 8,
    status: TournamentStatus.finished, myPosition: 1,
    prize: 80000, hasQualified: true,
    image: 'assets/images/free.png',
  ),
  TournamentModel(
    name: 'Tournoi Ramadan 2025', phase: 'Phase de groupes',
    location: 'Terrain HLM Grand Yoff', teams: 12,
    status: TournamentStatus.upcoming, prize: 50000,
    image: 'assets/images/ballon.png',
  ),
  TournamentModel(
    name: 'Coupe Guédiawaye', phase: 'Phase de groupes',
    location: 'Stade Municipal Guédiawaye', teams: 8,
    status: TournamentStatus.upcoming, prize: 30000,
    image: 'assets/images/wave.png',
  ),
];

// ─── TournamentsPage ──────────────────────────────────────────────────────────
class TournamentsPage extends StatefulWidget {
  final TeamData team;
  const TournamentsPage({super.key, required this.team});
  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() { super.initState(); _tab = TabController(length: 4, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  List<TournamentModel> get _ongoing  => _mockTournaments.where((t) => t.status == TournamentStatus.ongoing).toList();
  List<TournamentModel> get _upcoming => _mockTournaments.where((t) => t.status == TournamentStatus.upcoming).toList();
  List<TournamentModel> get _finished => _mockTournaments.where((t) => t.status == TournamentStatus.finished).toList();
  // Tournois en attente = inscrit mais pas encore démarré (mock : subset des upcoming)
  List<TournamentModel> get _pending  => [_mockTournaments[2]]; // Tournoi Ramadan inscrit

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: Column(
        children: [
          _TournamentsHeader(team: widget.team, tabController: _tab),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _TournamentList(tournaments: _ongoing,  team: widget.team),
                _TournamentList(tournaments: _pending,  team: widget.team, isPending: true),
                _TournamentList(tournaments: _upcoming, team: widget.team),
                _TournamentList(tournaments: _finished, team: widget.team),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header stats ─────────────────────────────────────────────────────────────
class _TournamentsHeader extends StatelessWidget {
  final TeamData team;
  final TabController tabController;
  const _TournamentsHeader({required this.team, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Banner image ──
        SizedBox(
          height: 270,
          child: Stack(children: [
            Positioned.fill(
              child: Image.asset('assets/images/terrain.webp', fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      team.color.withValues(alpha: 0.75),
                      team.color.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text('Tournois', style: GoogleFonts.orbitron(
                          fontSize: 22, fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8)])),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Row(children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(color: team.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(team.name, style: const TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ]),
                      const Spacer(),
                      Row(children: [
                        _StatBadge(value: '4', label: 'Tournois', icon: Icons.sports_soccer_rounded),
                        const SizedBox(width: 10),
                        _StatBadge(value: '1', label: 'Trophée', icon: Icons.emoji_events_rounded, color: _kGold),
                        const SizedBox(width: 10),
                        _StatBadge(value: '2', label: 'Top 3', icon: Icons.military_tech_rounded),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
        // ── TabBar collée au banner, arrondie en bas ──
        Container(
          decoration: BoxDecoration(
            color: _card(context),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            child: TabBar(
              controller: tabController,
              labelColor: _kGreen,
              unselectedLabelColor: _sub(context),
              indicatorColor: _kGreen,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              tabs: const [
                Tab(text: 'En cours'),
                Tab(text: 'En attente'),
                Tab(text: 'À venir'),
                Tab(text: 'Terminés'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatBadge({required this.value, required this.label, required this.icon, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(
            color: color, fontSize: 20, fontWeight: FontWeight.w900,
            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4)],
          )),
          Text(label, style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ─── Tab delegate ─────────────────────────────────────────────────────────────
class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bg;
  const _TabDelegate(this.tabBar, this.bg);
  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override bool shouldRebuild(_) => false;
  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlapsContent) {
    return Container(color: bg, child: tabBar);
  }
}

// ─── Liste tournois ───────────────────────────────────────────────────────────
class _TournamentList extends StatelessWidget {
  final List<TournamentModel> tournaments;
  final TeamData team;
  final bool isPending;
  const _TournamentList({required this.tournaments, required this.team, this.isPending = false});

  @override
  Widget build(BuildContext context) {
    if (tournaments.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.sports_soccer_rounded, size: 48, color: _sub(context).withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text('Aucun tournoi', style: TextStyle(color: _sub(context), fontSize: 14)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: tournaments.length,
      itemBuilder: (ctx, i) => _TournamentCard(t: tournaments[i], team: team, isPending: isPending),
    );
  }
}

// ─── Card tournoi ─────────────────────────────────────────────────────────────
class _TournamentCard extends StatelessWidget {
  final TournamentModel t;
  final TeamData team;
  final bool isPending;
  const _TournamentCard({required this.t, required this.team, this.isPending = false});

  Color get _statusColor {
    switch (t.status) {
      case TournamentStatus.ongoing:  return _kGreen;
      case TournamentStatus.finished: return Colors.grey;
      case TournamentStatus.upcoming: return _kGold;
    }
  }

  String get _statusLabel {
    switch (t.status) {
      case TournamentStatus.ongoing:  return 'En cours';
      case TournamentStatus.finished: return 'Terminé';
      case TournamentStatus.upcoming: return 'À venir';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => _TournamentDetailPage(t: t, team: team),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
            color: _statusColor.withValues(alpha: 0.2),
            blurRadius: 16, offset: const Offset(0, 6),
          )],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(children: [
            // ── Image de fond terrain ──
            Positioned.fill(
              child: Image.asset(
                t.image,
                fit: BoxFit.cover,
              ),
            ),
            // ── Overlay dégradé sombre ──
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
            ),
            // ── Overlay couleur statut subtil ──
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _statusColor.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // ── Bande couleur statut en haut ──
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_statusColor, _statusColor.withValues(alpha: 0.4)],
                  ),
                ),
              ),
            ),
            // ── Contenu ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Statut + phase
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _statusColor.withValues(alpha: 0.6)),
                    ),
                    child: Text(_statusLabel, style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800, color: _statusColor)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t.phase, style: TextStyle(
                      fontSize: 11, color: Colors.white.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic)),
                  ),
                ]),
                const SizedBox(height: 10),
                // Nom tournoi
                Text(t.name, style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                )),
                const SizedBox(height: 8),
                // Lieu
                Row(children: [
                  Icon(Icons.location_on_rounded, size: 13,
                      color: Colors.white.withValues(alpha: 0.65)),
                  const SizedBox(width: 4),
                  Expanded(child: Text(t.location, style: TextStyle(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.65)),
                    overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 6),
                // Équipes + prize
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.groups_rounded, size: 12,
                          color: Colors.white.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text('${t.teams} équipes', style: TextStyle(
                        fontSize: 11, color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kGold.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.emoji_events_rounded, size: 12, color: _kGold),
                      const SizedBox(width: 4),
                      Text('${t.prize != null ? '${(t.prize! / 1000).round()}k' : '–'} FCFA',
                          style: const TextStyle(
                            fontSize: 11, color: _kGold, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
                if (t.myPosition != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (t.myPosition == 1 ? _kGold : _kGreen).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (t.myPosition == 1 ? _kGold : _kGreen).withValues(alpha: 0.5)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(t.myPosition == 1 ? Icons.emoji_events_rounded : Icons.star_rounded,
                          size: 14, color: t.myPosition == 1 ? _kGold : _kGreen),
                      const SizedBox(width: 6),
                      Text(
                        t.myPosition == 1 ? 'Vainqueur 🏆' : 'Position : ${t.myPosition}ème',
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: t.myPosition == 1 ? _kGold : _kGreen,
                        ),
                      ),
                    ]),
                  ),
                ],
                if (t.status == TournamentStatus.ongoing) ...[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _showForfaitDialog(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.flag_rounded, size: 14, color: Colors.red),
                        SizedBox(width: 6),
                        Text('Déclarer forfait', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800, color: Colors.red)),
                      ]),
                    ),
                  ),
                ],
                if (t.status == TournamentStatus.upcoming) ...[
                  const SizedBox(height: 14),
                  if (isPending) ...[
                    // Inscrit en attente → badge + bouton forfait
                    Row(children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kGold.withValues(alpha: 0.4)),
                          ),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.hourglass_top_rounded, size: 14, color: _kGold),
                            SizedBox(width: 6),
                            Text('En attente', style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800, color: _kGold)),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showForfaitDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                            ),
                            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.flag_rounded, size: 14, color: Colors.red),
                              SizedBox(width: 6),
                              Text('Déclarer forfait', style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800, color: Colors.red)),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showJoinDialog(context),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: const Text('Participer',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rejoindre le tournoi', style: GoogleFonts.orbitron(
          fontSize: 14, fontWeight: FontWeight.w800, color: _txt(context))),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.name, style: TextStyle(fontWeight: FontWeight.w700, color: _txt(context))),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.groups_rounded, label: '${t.teams} équipes'),
          _InfoRow(icon: Icons.location_on_rounded, label: t.location),
          if (t.prize != null)
            _InfoRow(icon: Icons.emoji_events_rounded, label: 'Prix : ${t.prize} FCFA', color: _kGold),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: _sub(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Inscription confirmée pour ${t.name} !'),
                backgroundColor: _kGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showForfaitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Déclarer forfait', style: GoogleFonts.orbitron(
          fontSize: 14, fontWeight: FontWeight.w800, color: Colors.red)),
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Vous allez quitter "${t.name}". Cette action est irréversible.',
              style: TextStyle(fontSize: 12, color: _txt(context)),
            )),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: _sub(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Forfait déclaré pour ${t.name}.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmer le forfait', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: color ?? _sub(context)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: TextStyle(
          fontSize: 12, color: color ?? _sub(context)))),
      ]),
    );
  }
}

// ─── Page détail tournoi ──────────────────────────────────────────────────────
class _TournamentDetailPage extends StatefulWidget {
  final TournamentModel t;
  final TeamData team;
  const _TournamentDetailPage({required this.t, required this.team});
  @override
  State<_TournamentDetailPage> createState() => _TournamentDetailPageState();
}

class _TournamentDetailPageState extends State<_TournamentDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: widget.t.hasQualified ? 2 : 1, vsync: this);
  }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;

    // Tournoi à venir : pas de poules ni bracket, juste la page d'inscription
    if (t.status == TournamentStatus.upcoming) {
      return Scaffold(
        backgroundColor: _bg(context),
        body: _UpcomingDetailView(t: t, team: widget.team),
      );
    }

    // Tournoi terminé : podium + historique des rencontres
    if (t.status == TournamentStatus.finished) {
      return Scaffold(
        backgroundColor: _bg(context),
        body: _FinishedDetailView(t: t, team: widget.team),
      );
    }

    return Scaffold(
      backgroundColor: _bg(context),
      body: Column(
        children: [
          _DetailHeader(t: t, team: widget.team),
          Container(
            decoration: BoxDecoration(
              color: _card(context),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              child: TabBar(
                controller: _tab,
                labelColor: _kGreen,
                unselectedLabelColor: _sub(context),
                indicatorColor: _kGreen,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                tabs: t.hasQualified
                    ? const [Tab(text: 'Poules'), Tab(text: 'Bracket')]
                    : const [Tab(text: 'Poules')],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: t.hasQualified
                  ? [_GroupsView(team: widget.team), _BracketView(team: widget.team)]
                  : [_GroupsView(team: widget.team)],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page détail tournoi À venir ─────────────────────────────────────────────
class _UpcomingDetailView extends StatefulWidget {
  final TournamentModel t;
  final TeamData team;
  const _UpcomingDetailView({required this.t, required this.team});
  @override
  State<_UpcomingDetailView> createState() => _UpcomingDetailViewState();
}

class _UpcomingDetailViewState extends State<_UpcomingDetailView> {
  bool _isRegistered = false;

  static const _registeredTeams = [
    'AS Pikine', 'FC Médina', 'US Ouakam', 'Jaraaf FC',
    'Teungueth FC', 'Casa Sports', 'RC Parcelles',
  ];

  void _showJoinDialog() {
    final t = widget.t;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rejoindre le tournoi', style: GoogleFonts.orbitron(
          fontSize: 14, fontWeight: FontWeight.w800, color: _txt(context))),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.name, style: TextStyle(fontWeight: FontWeight.w700, color: _txt(context))),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.groups_rounded, label: '${t.teams} équipes max'),
          _InfoRow(icon: Icons.location_on_rounded, label: t.location),
          if (t.prize != null)
            _InfoRow(icon: Icons.emoji_events_rounded, label: 'Prix : ${t.prize} FCFA', color: _kGold),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: _sub(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isRegistered = true);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Inscription confirmée pour ${t.name} !'),
                backgroundColor: _kGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showForfaitDialog() {
    final t = widget.t;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Déclarer forfait', style: GoogleFonts.orbitron(
          fontSize: 14, fontWeight: FontWeight.w800, color: Colors.red)),
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Vous allez quitter "${t.name}". Cette action est irréversible.',
              style: TextStyle(fontSize: 12, color: _txt(context)),
            )),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: _sub(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isRegistered = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Forfait déclaré pour ${t.name}.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmer le forfait', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _DetailHeader(t: t, team: widget.team)),

        // ── Infos tournoi ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 4, height: 18,
                  decoration: BoxDecoration(color: _kGold, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('Informations', style: GoogleFonts.orbitron(
                  fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card(context),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  _InfoTile(icon: Icons.location_on_rounded, label: 'Lieu', value: t.location, color: _kGreen),
                  const SizedBox(height: 12),
                  _InfoTile(icon: Icons.groups_rounded, label: 'Équipes', value: '${t.teams} équipes maximum', color: _kGreen),
                  const SizedBox(height: 12),
                  _InfoTile(icon: Icons.emoji_events_rounded, label: 'Prix total', value: '${t.prize} FCFA', color: _kGold),
                  const SizedBox(height: 12),
                  _InfoTile(icon: Icons.calendar_today_rounded, label: 'Début prévu', value: 'Avril 2025', color: _kGold),
                ]),
              ),
            ]),
          ),
        ),

        // ── Équipes inscrites ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 4, height: 18,
                  decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('Équipes inscrites', style: GoogleFonts.orbitron(
                  fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                  child: Text('${_registeredTeams.length}/${t.teams}',
                    style: const TextStyle(fontSize: 11, color: _kGreen, fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: _card(context),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: _registeredTeams.asMap().entries.map((e) {
                    final isLast = e.key == _registeredTeams.length - 1;
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: _kGreen.withValues(alpha: 0.12),
                              shape: BoxShape.circle),
                            child: Center(child: Text('${e.key + 1}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _kGreen))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(e.value,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _txt(context)))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8)),
                            child: const Text('Inscrit', style: TextStyle(
                              fontSize: 10, color: _kGreen, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                      ),
                      if (!isLast) Divider(height: 1, indent: 60, color: _sub(context).withValues(alpha: 0.08)),
                    ]);
                  }).toList(),
                ),
              ),
            ]),
          ),
        ),

        // ── Statut + Forfait (déjà inscrit) ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kGold.withValues(alpha: 0.3)),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.hourglass_top_rounded, size: 16, color: _kGold),
                  SizedBox(width: 8),
                  Text('Inscription en attente de validation',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kGold)),
                ]),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _showForfaitDialog,
                  icon: const Icon(Icons.flag_rounded, size: 16, color: Colors.red),
                  label: const Text('Déclarer forfait',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Page détail tournoi Terminé ─────────────────────────────────────────────
class _FinishedDetailView extends StatefulWidget {
  final TournamentModel t;
  final TeamData team;
  const _FinishedDetailView({required this.t, required this.team});
  @override
  State<_FinishedDetailView> createState() => _FinishedDetailViewState();
}

class _FinishedDetailViewState extends State<_FinishedDetailView> {
  String? _filterTeam; // null = toutes les équipes

  static const _podium = [
    {'pos': 1, 'name': 'Jaraaf FC',    'icon': Icons.emoji_events_rounded},
    {'pos': 2, 'name': 'Casa Sports',  'icon': Icons.military_tech_rounded},
    {'pos': 3, 'name': 'US Ouakam',    'icon': Icons.workspace_premium_rounded},
  ];

  static const _history = [
    // Finale
    {'round': 'Finale',       'h': 'Jaraaf FC',   'a': 'Casa Sports',  'sh': 2, 'sa': 0},
    // Demi-finales
    {'round': 'Demi-finale',  'h': 'Jaraaf FC',   'a': 'US Ouakam',    'sh': 3, 'sa': 1},
    {'round': 'Demi-finale',  'h': 'Casa Sports', 'a': 'FC Médina',    'sh': 2, 'sa': 1},
    // Quarts
    {'round': 'Quart',        'h': 'Jaraaf FC',   'a': 'RC Parcelles', 'sh': 2, 'sa': 0},
    {'round': 'Quart',        'h': 'US Ouakam',   'a': 'Teungueth FC', 'sh': 1, 'sa': 0},
    {'round': 'Quart',        'h': 'Casa Sports', 'a': 'Linguère',     'sh': 3, 'sa': 2},
    {'round': 'Quart',        'h': 'FC Médina',   'a': 'Ndiambour',    'sh': 2, 'sa': 1},
    // Phase de groupes — mes matchs
    {'round': 'Groupe A – J3', 'h': 'Ligue Pikine', 'a': 'Étoile Dakar', 'sh': 1, 'sa': 0},
    {'round': 'Groupe A – J2', 'h': 'Ligue Pikine', 'a': 'AS Pikine',    'sh': 3, 'sa': 0},
    {'round': 'Groupe A – J1', 'h': 'Ligue Pikine', 'a': 'FC Médina',    'sh': 2, 'sa': 1},
  ];

  @override
  Widget build(BuildContext context) {
    final me = widget.team.name;
    final t = widget.t;

    // Toutes les équipes présentes dans l'historique
    final allTeams = <String>{};
    for (final m in _history) {
      allTeams.add(m['h'] as String);
      allTeams.add(m['a'] as String);
    }
    final teamList = allTeams.toList()..sort();

    final filtered = _filterTeam == null
        ? _history
        : _history.where((m) => m['h'] == _filterTeam || m['a'] == _filterTeam).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _DetailHeader(t: t, team: widget.team)),

        // ── Podium ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 4, height: 18,
                  decoration: BoxDecoration(color: _kGold, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('Podium', style: GoogleFonts.orbitron(
                  fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
              ]),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: _PodiumSlot(
                    pos: 2, name: _podium[1]['name'] as String,
                    height: 90, color: const Color(0xFFC0C0C0), isMe: _podium[1]['name'] == me)),
                  const SizedBox(width: 8),
                  Expanded(child: _PodiumSlot(
                    pos: 1, name: _podium[0]['name'] as String,
                    height: 120, color: _kGold, isMe: _podium[0]['name'] == me)),
                  const SizedBox(width: 8),
                  Expanded(child: _PodiumSlot(
                    pos: 3, name: _podium[2]['name'] as String,
                    height: 70, color: const Color(0xFFCD7F32), isMe: _podium[2]['name'] == me)),
                ],
              ),
            ]),
          ),
        ),

        // ── Historique des rencontres ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Titre + filtre
              Row(children: [
                Container(width: 4, height: 18,
                  decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('Historique', style: GoogleFonts.orbitron(
                  fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
                const Spacer(),
                // Bouton filtre
                GestureDetector(
                  onTap: () => _showFilterSheet(context, teamList),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _filterTeam != null ? _kGreen.withValues(alpha: 0.15) : _card(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _filterTeam != null ? _kGreen : _sub(context).withValues(alpha: 0.2)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.filter_list_rounded, size: 14,
                        color: _filterTeam != null ? _kGreen : _sub(context)),
                      const SizedBox(width: 5),
                      Text(
                        _filterTeam ?? 'Filtrer',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: _filterTeam != null ? _kGreen : _sub(context)),
                      ),
                      if (_filterTeam != null) ...[
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () => setState(() => _filterTeam = null),
                          child: Icon(Icons.close_rounded, size: 13, color: _kGreen),
                        ),
                      ],
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                Center(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text('Aucune rencontre pour cette équipe',
                    style: TextStyle(color: _sub(context), fontSize: 13)),
                ))
              else
                ...filtered.map((m) {
                  final h  = m['h'] as String;
                  final a  = m['a'] as String;
                  final sh = m['sh'] as int;
                  final sa = m['sa'] as int;
                  final round = m['round'] as String;
                  final isMe = h == me || a == me;
                  final hWin = sh > sa;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? _kGreen.withValues(alpha: 0.07) : _card(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isMe ? _kGreen.withValues(alpha: 0.3) : _sub(context).withValues(alpha: 0.08)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(round, style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: isMe ? _kGreen : _sub(context))),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: Text(h,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: h == me ? FontWeight.w900 : FontWeight.w600,
                            color: h == me ? _kGreen : hWin ? _txt(context) : _sub(context)))),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: isMe ? _kGreen.withValues(alpha: 0.15) : _sub(context).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8)),
                          child: Text('$sh – $sa', style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w900,
                            color: isMe ? _kGreen : _txt(context),
                            fontFamily: 'monospace'))),
                        const SizedBox(width: 10),
                        Expanded(child: Text(a,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: a == me ? FontWeight.w900 : FontWeight.w600,
                            color: a == me ? _kGreen : !hWin ? _txt(context) : _sub(context)))),
                      ]),
                    ]),
                  );
                }),
            ]),
          ),
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, List<String> teams) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _card(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: [
            Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _sub(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            Text('Filtrer par équipe', style: GoogleFonts.orbitron(
              fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _filterTeam == null ? _kGreen.withValues(alpha: 0.15) : _sub(context).withValues(alpha: 0.08),
                        shape: BoxShape.circle),
                      child: Icon(Icons.sports_soccer_rounded, size: 16,
                        color: _filterTeam == null ? _kGreen : _sub(context))),
                    title: Text('Toutes les équipes', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: _filterTeam == null ? _kGreen : _txt(context))),
                    trailing: _filterTeam == null ? const Icon(Icons.check_rounded, color: _kGreen, size: 18) : null,
                    onTap: () { setState(() => _filterTeam = null); Navigator.pop(ctx); },
                  ),
                  Divider(height: 1, color: _sub(context).withValues(alpha: 0.08)),
                  ...teams.expand((team) => [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: _filterTeam == team ? _kGreen.withValues(alpha: 0.15) : _sub(context).withValues(alpha: 0.08),
                          shape: BoxShape.circle),
                        child: Center(child: Text(team[0], style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800,
                          color: _filterTeam == team ? _kGreen : _sub(context))))),
                      title: Text(team, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: _filterTeam == team ? _kGreen : _txt(context))),
                      trailing: _filterTeam == team ? const Icon(Icons.check_rounded, color: _kGreen, size: 18) : null,
                      onTap: () { setState(() => _filterTeam = team); Navigator.pop(ctx); },
                    ),
                    Divider(height: 1, color: _sub(context).withValues(alpha: 0.08)),
                  ]),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Slot podium ──────────────────────────────────────────────────────────────
class _PodiumSlot extends StatelessWidget {
  final int pos;
  final String name;
  final double height;
  final Color color;
  final bool isMe;
  const _PodiumSlot({required this.pos, required this.name, required this.height, required this.color, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Médaille
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)],
        ),
        child: Center(child: Text('$pos', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w900, color: color))),
      ),
      const SizedBox(height: 8),
      // Nom
      Text(name, textAlign: TextAlign.center,
        maxLines: 2, overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11, fontWeight: isMe ? FontWeight.w900 : FontWeight.w600,
          color: isMe ? _kGreen : _txt(context))),
      const SizedBox(height: 6),
      // Barre podium
      Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0.3)]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          border: isMe ? Border.all(color: _kGreen, width: 2) : null,
        ),
        child: isMe
            ? Center(child: Icon(Icons.star_rounded, color: Colors.white.withValues(alpha: 0.8), size: 20))
            : null,
      ),
    ]);
  }
}

// ─── Tuile info ───────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: _sub(context), fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 13, color: _txt(context), fontWeight: FontWeight.w700)),
      ]),
    ]);
  }
}

// ─── Header page détail ───────────────────────────────────────────────────────
class _DetailHeader extends StatelessWidget {
  final TournamentModel t;
  final TeamData team;
  const _DetailHeader({required this.t, required this.team});

  Color get _statusColor {
    switch (t.status) {
      case TournamentStatus.ongoing:  return _kGreen;
      case TournamentStatus.finished: return Colors.grey;
      case TournamentStatus.upcoming: return _kGold;
    }
  }
  String get _statusLabel {
    switch (t.status) {
      case TournamentStatus.ongoing:  return 'En cours';
      case TournamentStatus.finished: return 'Terminé';
      case TournamentStatus.upcoming: return 'À venir';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: SizedBox(
        height: 200,
        child: Stack(children: [
          Positioned.fill(child: Image.asset(t.image, fit: BoxFit.cover)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 15, color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor.withValues(alpha: 0.7)),
                      ),
                      child: Text(_statusLabel, style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800, color: _statusColor)),
                    ),
                  ]),
                  const Spacer(),
                  Text(t.name, style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  )),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.location_on_rounded, size: 13,
                        color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Expanded(child: Text(t.location, style: TextStyle(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                      overflow: TextOverflow.ellipsis)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    _MiniChip(icon: Icons.groups_rounded, label: '${t.teams} équipes'),
                    const SizedBox(width: 8),
                    _MiniChip(icon: Icons.emoji_events_rounded,
                        label: '${t.prize != null ? '${(t.prize! / 1000).round()}k' : '–'} FCFA',
                        color: _kGold),
                    const SizedBox(width: 8),
                    _MiniChip(icon: Icons.sports_soccer_rounded, label: t.phase),
                  ]),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniChip({required this.icon, required this.label, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
          fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── Vue Poules ───────────────────────────────────────────────────────────────
class _GroupsView extends StatelessWidget {
  final TeamData team;
  const _GroupsView({required this.team});

  @override
  Widget build(BuildContext context) {
    final me = team.name;
    final groups = [
      {
        'name': 'Groupe A',
        'teams': [
          {'name': me,              'pts': 7, 'j': 3, 'g': 2, 'n': 1, 'd': 0, 'bp': 6, 'bc': 2},
          {'name': 'FC Médina',     'pts': 4, 'j': 3, 'g': 1, 'n': 1, 'd': 1, 'bp': 3, 'bc': 3},
          {'name': 'AS Pikine',     'pts': 3, 'j': 3, 'g': 1, 'n': 0, 'd': 2, 'bp': 2, 'bc': 4},
          {'name': 'Étoile Dakar',  'pts': 1, 'j': 3, 'g': 0, 'n': 1, 'd': 2, 'bp': 1, 'bc': 5},
        ],
        'matches': [
          {'h': me,           'a': 'FC Médina',    'sh': 2, 'sa': 1, 'date': 'J1'},
          {'h': 'AS Pikine',  'a': 'Étoile Dakar', 'sh': 1, 'sa': 1, 'date': 'J1'},
          {'h': me,           'a': 'AS Pikine',    'sh': 3, 'sa': 0, 'date': 'J2'},
          {'h': 'FC Médina',  'a': 'Étoile Dakar', 'sh': 2, 'sa': 0, 'date': 'J2'},
          {'h': me,           'a': 'Étoile Dakar', 'sh': 1, 'sa': 0, 'date': 'J3'},
          {'h': 'FC Médina',  'a': 'AS Pikine',    'sh': 1, 'sa': 1, 'date': 'J3'},
        ],
      },
      {
        'name': 'Groupe B',
        'teams': [
          {'name': 'US Ouakam',     'pts': 7, 'j': 3, 'g': 2, 'n': 1, 'd': 0, 'bp': 5, 'bc': 1},
          {'name': 'RC Parcelles',  'pts': 5, 'j': 3, 'g': 1, 'n': 2, 'd': 0, 'bp': 4, 'bc': 3},
          {'name': 'AS Guédiawaye', 'pts': 2, 'j': 3, 'g': 0, 'n': 2, 'd': 1, 'bp': 2, 'bc': 4},
          {'name': 'FC Yoff',       'pts': 0, 'j': 3, 'g': 0, 'n': 0, 'd': 3, 'bp': 1, 'bc': 7},
        ],
        'matches': [
          {'h': 'US Ouakam',     'a': 'RC Parcelles',  'sh': 2, 'sa': 2, 'date': 'J1'},
          {'h': 'AS Guédiawaye', 'a': 'FC Yoff',       'sh': 1, 'sa': 0, 'date': 'J1'},
          {'h': 'US Ouakam',     'a': 'AS Guédiawaye', 'sh': 2, 'sa': 0, 'date': 'J2'},
          {'h': 'RC Parcelles',  'a': 'FC Yoff',       'sh': 1, 'sa': 1, 'date': 'J2'},
          {'h': 'US Ouakam',     'a': 'FC Yoff',       'sh': 1, 'sa': 0, 'date': 'J3'},
          {'h': 'RC Parcelles',  'a': 'AS Guédiawaye', 'sh': 1, 'sa': 1, 'date': 'J3'},
        ],
      },
      {
        'name': 'Groupe C',
        'teams': [
          {'name': 'Jaraaf FC',     'pts': 9, 'j': 3, 'g': 3, 'n': 0, 'd': 0, 'bp': 8, 'bc': 2},
          {'name': 'Teungueth FC',  'pts': 6, 'j': 3, 'g': 2, 'n': 0, 'd': 1, 'bp': 5, 'bc': 3},
          {'name': 'Génération FC', 'pts': 3, 'j': 3, 'g': 1, 'n': 0, 'd': 2, 'bp': 3, 'bc': 5},
          {'name': 'Diambars',      'pts': 0, 'j': 3, 'g': 0, 'n': 0, 'd': 3, 'bp': 0, 'bc': 9},
        ],
        'matches': [
          {'h': 'Jaraaf FC',     'a': 'Génération FC', 'sh': 3, 'sa': 1, 'date': 'J1'},
          {'h': 'Teungueth FC',  'a': 'Diambars',      'sh': 2, 'sa': 0, 'date': 'J1'},
          {'h': 'Jaraaf FC',     'a': 'Teungueth FC',  'sh': 2, 'sa': 1, 'date': 'J2'},
          {'h': 'Génération FC', 'a': 'Diambars',      'sh': 2, 'sa': 0, 'date': 'J2'},
          {'h': 'Jaraaf FC',     'a': 'Diambars',      'sh': 3, 'sa': 0, 'date': 'J3'},
          {'h': 'Teungueth FC',  'a': 'Génération FC', 'sh': 2, 'sa': 2, 'date': 'J3'},
        ],
      },
      {
        'name': 'Groupe D',
        'teams': [
          {'name': 'Casa Sports', 'pts': 7, 'j': 3, 'g': 2, 'n': 1, 'd': 0, 'bp': 6, 'bc': 2},
          {'name': 'Linguère',    'pts': 4, 'j': 3, 'g': 1, 'n': 1, 'd': 1, 'bp': 4, 'bc': 4},
          {'name': 'Ndiambour',   'pts': 3, 'j': 3, 'g': 1, 'n': 0, 'd': 2, 'bp': 3, 'bc': 5},
          {'name': 'Sonacos',     'pts': 1, 'j': 3, 'g': 0, 'n': 1, 'd': 2, 'bp': 2, 'bc': 6},
        ],
        'matches': [
          {'h': 'Casa Sports', 'a': 'Linguère',  'sh': 2, 'sa': 2, 'date': 'J1'},
          {'h': 'Ndiambour',   'a': 'Sonacos',   'sh': 2, 'sa': 1, 'date': 'J1'},
          {'h': 'Casa Sports', 'a': 'Ndiambour', 'sh': 3, 'sa': 0, 'date': 'J2'},
          {'h': 'Linguère',    'a': 'Sonacos',   'sh': 2, 'sa': 1, 'date': 'J2'},
          {'h': 'Casa Sports', 'a': 'Sonacos',   'sh': 1, 'sa': 0, 'date': 'J3'},
          {'h': 'Linguère',    'a': 'Ndiambour', 'sh': 0, 'sa': 1, 'date': 'J3'},
        ],
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: groups.map((g) => _GroupTable(group: g, myTeam: me)).toList(),
    );
  }
}

class _GroupTable extends StatefulWidget {
  final Map<String, dynamic> group;
  final String myTeam;
  const _GroupTable({required this.group, required this.myTeam});
  @override
  State<_GroupTable> createState() => _GroupTableState();
}

class _GroupTableState extends State<_GroupTable> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final teams = widget.group['teams'] as List;
    final allMatches = (widget.group['matches'] as List?) ?? [];
    final myTeam = widget.myTeam;
    final maxPts = teams.map((t) => (t as Map)['pts'] as int).reduce((a, b) => a > b ? a : b);

    final myMatches = allMatches.where((m) {
      final match = m as Map<String, dynamic>;
      return match['h'] == myTeam || match['a'] == myTeam;
    }).toList();
    final otherMatches = allMatches.where((m) {
      final match = m as Map<String, dynamic>;
      return match['h'] != myTeam && match['a'] != myTeam;
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_kGreen.withValues(alpha: 0.15), _kGreen.withValues(alpha: 0.03)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Container(width: 28, height: 28,
              decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.sports_soccer_rounded, size: 14, color: _kGreen)),
            const SizedBox(width: 10),
            Text(widget.group['name'] as String, style: GoogleFonts.orbitron(
              fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Text('J3/J3', style: TextStyle(fontSize: 10, color: _kGreen, fontWeight: FontWeight.w700))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(children: [
            const SizedBox(width: 38),
            const Expanded(child: SizedBox()),
            for (final h in ['J', 'G', 'N', 'D', 'Pts'])
              SizedBox(width: 32, child: Text(h, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _sub(context)))),
          ]),
        ),
        Divider(height: 1, color: _sub(context).withValues(alpha: 0.08)),
        ...teams.asMap().entries.map((e) {
          final t = e.value as Map<String, dynamic>;
          final isMe = t['name'] == myTeam;
          final isQualified = e.key < 2;
          final pts = t['pts'] as int;
          final progress = maxPts > 0 ? pts / maxPts : 0.0;
          return Container(
            decoration: BoxDecoration(
              color: isMe ? _kGreen.withValues(alpha: 0.06) : null,
              border: isMe ? const Border(left: BorderSide(color: _kGreen, width: 3)) : null,
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: isQualified
                        ? (e.key == 0 ? _kGold.withValues(alpha: 0.2) : _kGreen.withValues(alpha: 0.15))
                        : _sub(context).withValues(alpha: 0.08),
                    shape: BoxShape.circle),
                  child: Center(child: Text('${e.key + 1}', style: TextStyle(
                    fontSize: 10,
                    color: isQualified ? (e.key == 0 ? _kGold : _kGreen) : _sub(context),
                    fontWeight: FontWeight.w800)))),
                const SizedBox(width: 10),
                Expanded(child: Text(t['name'] as String, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13,
                    fontWeight: isMe ? FontWeight.w900 : FontWeight.w600,
                    color: isMe ? _kGreen : _txt(context)))),
                for (final k in ['j', 'g', 'n', 'd'])
                  SizedBox(width: 32, child: Text('${t[k]}', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: _sub(context), fontWeight: FontWeight.w500))),
                SizedBox(width: 32, child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: isMe ? _kGreen : _sub(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6)),
                  child: Text('${t['pts']}', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
                      color: isMe ? Colors.white : _txt(context))))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const SizedBox(width: 32),
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress, minHeight: 3,
                    backgroundColor: _sub(context).withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                      isMe ? _kGreen : (isQualified
                          ? _kGreen.withValues(alpha: 0.5)
                          : _sub(context).withValues(alpha: 0.3))),
                  ))),
                const SizedBox(width: 32 * 5),
              ]),
            ]),
          );
        }),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(children: [
            _LegendDot(color: _kGold, label: '1er'),
            const SizedBox(width: 12),
            _LegendDot(color: _kGreen, label: '2ème qualifié'),
            const SizedBox(width: 12),
            _LegendDot(color: _sub(context), label: 'Éliminé'),
          ]),
        ),
        if (allMatches.isNotEmpty) ...[
          Divider(height: 1, color: _sub(context).withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              const Icon(Icons.sports_soccer_rounded, size: 13, color: _kGreen),
              const SizedBox(width: 6),
              Text('Rencontres', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _txt(context))),
              const Spacer(),
              if (myMatches.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('${myMatches.length} mes matchs', style: TextStyle(fontSize: 10, color: _kGreen, fontWeight: FontWeight.w700))),
            ]),
          ),
          ...myMatches.map((m) => _MatchRow(match: m as Map<String, dynamic>, myTeam: myTeam, isHighlighted: true)),
          if (otherMatches.isNotEmpty) ...[
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: otherMatches.map((m) => _MatchRow(
                  match: m as Map<String, dynamic>, myTeam: myTeam, isHighlighted: false)).toList()),
            ),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _sub(context).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _sub(context).withValues(alpha: 0.12))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    _expanded ? 'Masquer les autres rencontres' : 'Voir les ${otherMatches.length} autres rencontres',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _sub(context))),
                  const SizedBox(width: 6),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 16, color: _sub(context)),
                ]),
              ),
            ),
          ] else
            const SizedBox(height: 12),
        ],
      ]),
    );
  }
}

// ─── LegendDot ────────────────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 10, color: _sub(context))),
    ]);
  }
}

// ─── Ligne de match ───────────────────────────────────────────────────────────
class _MatchRow extends StatelessWidget {
  final Map<String, dynamic> match;
  final String myTeam;
  final bool isHighlighted;
  const _MatchRow({required this.match, required this.myTeam, required this.isHighlighted});

  @override
  Widget build(BuildContext context) {
    final h    = match['h'] as String;
    final a    = match['a'] as String;
    final sh   = match['sh'] as int?;
    final sa   = match['sa'] as int?;
    final date = match['date'] as String;
    final played = sh != null && sa != null;
    final hWin = played && sh > sa!;
    final aWin = played && sa > sh!;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? _kGreen.withValues(alpha: 0.06)
            : _sub(context).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? _kGreen.withValues(alpha: 0.25)
              : _sub(context).withValues(alpha: 0.07)),
      ),
      child: Row(children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: isHighlighted
                ? _kGreen.withValues(alpha: 0.15)
                : _sub(context).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6)),
          child: Center(child: Text(date, style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w800,
            color: isHighlighted ? _kGreen : _sub(context))))),
        const SizedBox(width: 10),
        Expanded(child: Text(h,
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: h == myTeam ? FontWeight.w800 : FontWeight.w500,
            color: h == myTeam ? _kGreen : hWin ? _txt(context) : _sub(context)))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isHighlighted
                ? _kGreen.withValues(alpha: 0.12)
                : _sub(context).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8)),
          child: played
              ? Text('$sh – $sa', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w900,
                  color: isHighlighted ? _kGreen : _txt(context),
                  fontFamily: 'monospace'))
              : Text('VS', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: _sub(context)))),
        const SizedBox(width: 8),
        Expanded(child: Text(a,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: a == myTeam ? FontWeight.w800 : FontWeight.w500,
            color: a == myTeam ? _kGreen : aWin ? _txt(context) : _sub(context)))),
      ]),
    );
  }
}

// ─── _GCell (conservé pour compatibilité) ────────────────────────────────────
class _GCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool highlight;
  const _GCell({required this.text, required this.isHeader, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(
        fontSize: 11,
        fontWeight: isHeader || highlight ? FontWeight.w800 : FontWeight.w500,
        color: highlight ? _kGreen : isHeader ? _sub(context) : _txt(context),
      )),
    );
  }
}

// ─── Modèle match bracket ─────────────────────────────────────────────────────
class _BMatch {
  final String t1, t2;
  final int? s1, s2;
  final bool played;
  const _BMatch({required this.t1, required this.t2, this.s1, this.s2, this.played = false});
  String? get winner {
    if (!played || s1 == null || s2 == null) return null;
    return s1! > s2! ? t1 : t2;
  }
}

// ─── Vue Bracket ──────────────────────────────────────────────────────────────
class _BracketView extends StatelessWidget {
  final TeamData team;
  const _BracketView({required this.team});

  @override
  Widget build(BuildContext context) {
    final me = team.name;

    final r16 = [
      _BMatch(t1: me,              t2: 'Sonacos',       s1: 3, s2: 0, played: true),
      _BMatch(t1: 'FC Médina',     t2: 'Ndiambour',     s1: 2, s2: 1, played: true),
      _BMatch(t1: 'US Ouakam',     t2: 'Génération FC', s1: 1, s2: 0, played: true),
      _BMatch(t1: 'RC Parcelles',  t2: 'Diambars',      s1: 2, s2: 0, played: true),
      _BMatch(t1: 'Jaraaf FC',     t2: 'AS Guédiawaye', s1: 4, s2: 1, played: true),
      _BMatch(t1: 'Teungueth FC',  t2: 'FC Yoff',       s1: 3, s2: 0, played: true),
      _BMatch(t1: 'Casa Sports',   t2: 'Étoile Dakar',  s1: 2, s2: 1, played: true),
      _BMatch(t1: 'Linguère',      t2: 'AS Pikine',     s1: 1, s2: 0, played: true),
    ];
    final qf = [
      _BMatch(t1: me,             t2: 'FC Médina',    s1: 2, s2: 0, played: true),
      _BMatch(t1: 'US Ouakam',    t2: 'RC Parcelles', s1: 1, s2: 0, played: true),
      _BMatch(t1: 'Jaraaf FC',    t2: 'Teungueth FC', s1: 2, s2: 1, played: true),
      _BMatch(t1: 'Casa Sports',  t2: 'Linguère',     s1: 3, s2: 2, played: true),
    ];
    final sf = [
      _BMatch(t1: me,           t2: 'US Ouakam',   s1: 2, s2: 1, played: true),
      _BMatch(t1: 'Jaraaf FC',  t2: 'Casa Sports', s1: 1, s2: 0, played: true),
    ];
    final finale = [
      _BMatch(t1: me, t2: 'Jaraaf FC', played: false),
    ];

    const double matchH = 72.0;
    const double matchW = 150.0;
    const double colGap = 40.0;
    const double hPad   = 16.0;

    final spacings = [
      8.0,
      matchH + 8 + 8,
      (matchH + 8) * 3 + 8,
      0.0,
    ];

    double colHeight(int round) {
      final count = [8, 4, 2, 1][round];
      final sp = spacings[round];
      return count * matchH + (count - 1) * sp + 32;
    }

    final maxH = colHeight(0) + 32;
    final totalW = 4 * matchW + 3 * colGap + 2 * hPad;

    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: SingleChildScrollView(
            child: SizedBox(
              width: totalW - 2 * hPad,
              height: maxH + 36,
              child: Stack(children: [
                Positioned(
                  top: 0, left: 0,
                  width: totalW - 2 * hPad,
                  child: Row(children: [
                    for (final entry in {
                      '8es de finale': 0, 'Quarts': 1, 'Demi-finales': 2, 'Finale': 3,
                    }.entries)
                      SizedBox(
                        width: matchW + (entry.value < 3 ? colGap : 0),
                        child: Center(child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kGreen.withValues(alpha: 0.2))),
                          child: Text(entry.key, style: GoogleFonts.orbitron(
                            fontSize: 8, fontWeight: FontWeight.w800, color: _kGreen)),
                        )),
                      ),
                  ]),
                ),
                Positioned(
                  top: 36, left: 0,
                  width: totalW - 2 * hPad,
                  height: maxH,
                  child: CustomPaint(
                    painter: _BracketPainter(
                      rounds: [r16, qf, sf, finale],
                      matchH: matchH, matchW: matchW, colGap: colGap,
                      lineColor: _sub(context).withValues(alpha: 0.3),
                      spacings: spacings,
                    ),
                  ),
                ),
                ..._buildColumn(context, r16,    0, matchW, matchH, colGap, spacings, me, offsetTop: 36),
                ..._buildColumn(context, qf,     1, matchW, matchH, colGap, spacings, me, offsetTop: 36),
                ..._buildColumn(context, sf,     2, matchW, matchH, colGap, spacings, me, offsetTop: 36),
                ..._buildColumn(context, finale, 3, matchW, matchH, colGap, spacings, me, offsetTop: 36),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  List<Widget> _buildColumn(
    BuildContext context,
    List<_BMatch> matches,
    int col,
    double matchW,
    double matchH,
    double colGap,
    List<double> spacings,
    String me, {
    double offsetTop = 0,
  }) {
    final x = col * (matchW + colGap);
    final sp = spacings[col];
    final totalH = matches.length * matchH + (matches.length - 1) * sp + 32;
    final maxH = 8 * matchH + 7 * spacings[0] + 32;
    final offsetY = (maxH - totalH) / 2;
    return matches.asMap().entries.map((e) {
      final y = offsetTop + offsetY + e.key * (matchH + sp);
      return Positioned(
        left: x, top: y,
        child: _BracketMatchCard(match: e.value, myTeam: me, width: matchW, height: matchH),
      );
    }).toList();
  }
}

// ─── Card match bracket ───────────────────────────────────────────────────────
class _BracketMatchCard extends StatelessWidget {
  final _BMatch match;
  final String myTeam;
  final double width, height;
  const _BracketMatchCard({required this.match, required this.myTeam, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final hasMe = match.t1 == myTeam || match.t2 == myTeam;
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasMe ? _kGreen.withValues(alpha: 0.6) : _sub(context).withValues(alpha: 0.12),
          width: hasMe ? 1.5 : 1),
        boxShadow: [BoxShadow(
          color: hasMe ? _kGreen.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.07),
          blurRadius: hasMe ? 10 : 6, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        _BTeamRow(name: match.t1, score: match.s1,
          isWinner: match.winner == match.t1, isMyTeam: match.t1 == myTeam, isTop: true),
        Container(height: 1, color: _sub(context).withValues(alpha: 0.08)),
        _BTeamRow(name: match.t2, score: match.s2,
          isWinner: match.winner == match.t2, isMyTeam: match.t2 == myTeam, isTop: false),
      ]),
    );
  }
}

class _BTeamRow extends StatelessWidget {
  final String name;
  final int? score;
  final bool isWinner, isMyTeam, isTop;
  const _BTeamRow({required this.name, required this.score, required this.isWinner, required this.isMyTeam, required this.isTop});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isWinner ? _kGreen.withValues(alpha: 0.1) : isMyTeam ? _kGreen.withValues(alpha: 0.04) : null,
          borderRadius: BorderRadius.vertical(
            top: isTop ? const Radius.circular(12) : Radius.zero,
            bottom: !isTop ? const Radius.circular(12) : Radius.zero),
        ),
        child: Row(children: [
          if (isMyTeam)
            Container(width: 3, height: 22, margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(2)))
          else
            const SizedBox(width: 9),
          Expanded(child: Text(name, overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isMyTeam ? FontWeight.w900 : FontWeight.w500,
              color: isMyTeam ? _kGreen : isWinner ? _txt(context) : _sub(context)))),
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: isWinner ? _kGreen : score == null
                  ? _sub(context).withValues(alpha: 0.07)
                  : _sub(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7)),
            child: Center(child: Text(
              score != null ? '$score' : '–',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                color: isWinner ? Colors.white : _sub(context))))),
        ]),
      ),
    );
  }
}

// ─── CustomPainter lignes bracket ────────────────────────────────────────────
class _BracketPainter extends CustomPainter {
  final List<List<_BMatch>> rounds;
  final double matchH, matchW, colGap;
  final Color lineColor;
  final List<double> spacings;

  _BracketPainter({required this.rounds, required this.matchH, required this.matchW,
    required this.colGap, required this.lineColor, required this.spacings});

  double _topY(int col, int idx) {
    final sp = spacings[col];
    final count = rounds[col].length;
    final totalH = count * matchH + (count - 1) * sp + 32;
    final maxH = 8 * matchH + 7 * spacings[0] + 32;
    final offsetY = (maxH - totalH) / 2;
    return offsetY + idx * (matchH + sp);
  }

  double _midY(int col, int idx) => _topY(col, idx) + matchH / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int col = 0; col < rounds.length - 1; col++) {
      final nextCount = rounds[col + 1].length;
      for (int ni = 0; ni < nextCount; ni++) {
        final i1 = ni * 2;
        final i2 = ni * 2 + 1;
        final x1 = col * (matchW + colGap) + matchW;
        final x2 = (col + 1) * (matchW + colGap);
        final y1 = _midY(col, i1);
        final y2 = _midY(col, i2);
        final yNext = _midY(col + 1, ni);
        final xMid = x1 + colGap / 2;
        canvas.drawLine(Offset(x1, y1), Offset(xMid, y1), paint);
        canvas.drawLine(Offset(x1, y2), Offset(xMid, y2), paint);
        canvas.drawLine(Offset(xMid, y1), Offset(xMid, y2), paint);
        canvas.drawLine(Offset(xMid, yNext), Offset(x2, yNext), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.lineColor != lineColor;
}
