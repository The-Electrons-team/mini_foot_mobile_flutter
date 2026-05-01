import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _kGreen  = Color(0xFF006F39);
const Color _kGold   = Color(0xFFFFD700);
const Color _kSilver = Color(0xFFB0BEC5);
const Color _kBronze = Color(0xFFCD7F32);

bool  _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c)    => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c)  => Theme.of(c).cardColor;
Color _txt(BuildContext c)   => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)   => _isDark(c)
    ? const Color(0xFFF0EBE0).withOpacity(0.5)
    : Colors.black.withOpacity(0.45);

// ── MODÈLE ───────────────────────────────────────────────────────────────────

class _Team {
  final String name, dept, logoUrl;
  final Color  color;
  final int pts, j, g, n, p, bp, bc;
  const _Team({
    required this.name, required this.dept,
    required this.logoUrl, required this.color,
    required this.pts, required this.j,
    required this.g, required this.n,
    required this.p, required this.bp, required this.bc,
  });
  int get diff => bp - bc;
}

const _cdn = 'https://cdn.jsdelivr.net/npm/club-icons@1.0.0/icons';

const _allTeams = <_Team>[
  _Team(name:'Les Lions FC',      dept:'Dakar',      logoUrl:'$_cdn/barcelona.png',        color:Color(0xFF006F39), pts:34,j:14,g:11,n:1,p:2,bp:38,bc:14),
  _Team(name:'Plateau Stars',     dept:'Dakar',      logoUrl:'$_cdn/real-madrid.png',       color:Color(0xFF1565C0), pts:28,j:14,g:8, n:4,p:2,bp:30,bc:16),
  _Team(name:'Almadies FC',       dept:'Dakar',      logoUrl:'$_cdn/ac-milan.png',          color:Color(0xFFB71C1C), pts:24,j:14,g:7, n:3,p:4,bp:26,bc:20),
  _Team(name:'Médina United',     dept:'Dakar',      logoUrl:'$_cdn/liverpool.png',         color:Color(0xFFB71C1C), pts:20,j:14,g:6, n:2,p:6,bp:22,bc:24),
  _Team(name:'Yoff Ballers',      dept:'Dakar',      logoUrl:'$_cdn/borussia-dortmund.png', color:Color(0xFFF9A825), pts:16,j:14,g:4, n:4,p:6,bp:18,bc:26),
  _Team(name:'Ouakam City',       dept:'Dakar',      logoUrl:'$_cdn/atletico-madrid.png',   color:Color(0xFFB71C1C), pts:13,j:14,g:3, n:4,p:7,bp:15,bc:29),
  _Team(name:'Fann FC',           dept:'Dakar',      logoUrl:'$_cdn/chelsea.png',           color:Color(0xFF0D47A1), pts:10,j:14,g:2, n:4,p:8,bp:12,bc:32),
  _Team(name:'Gueule Tapée SC',   dept:'Dakar',      logoUrl:'$_cdn/arsenal.png',           color:Color(0xFFAD1457), pts: 7,j:14,g:1, n:4,p:9,bp: 9,bc:36),
  _Team(name:'Guédiawaye FC',     dept:'Guédiawaye', logoUrl:'$_cdn/manchester-city.png',   color:Color(0xFF1565C0), pts:32,j:14,g:10,n:2,p:2,bp:35,bc:15),
  _Team(name:'Sam Notaire Elite', dept:'Guédiawaye', logoUrl:'$_cdn/psg.png',               color:Color(0xFF1A237E), pts:27,j:14,g:8, n:3,p:3,bp:29,bc:18),
  _Team(name:'Golf Sud Stars',    dept:'Guédiawaye', logoUrl:'$_cdn/juventus.png',          color:Color(0xFF212121), pts:22,j:14,g:6, n:4,p:4,bp:24,bc:21),
  _Team(name:'Wakhinane FC',      dept:'Guédiawaye', logoUrl:'$_cdn/inter-milan.png',       color:Color(0xFF1A237E), pts:18,j:14,g:5, n:3,p:6,bp:20,bc:24),
  _Team(name:'Ndiarème United',   dept:'Guédiawaye', logoUrl:'$_cdn/manchester-united.png', color:Color(0xFFB71C1C), pts:14,j:14,g:3, n:5,p:6,bp:16,bc:27),
  _Team(name:'Médina Gounass SC', dept:'Guédiawaye', logoUrl:'$_cdn/tottenham.png',         color:Color(0xFF37474F), pts:11,j:14,g:2, n:5,p:7,bp:13,bc:30),
  _Team(name:'Daroukhane FC',     dept:'Guédiawaye', logoUrl:'$_cdn/ajax.png',              color:Color(0xFFB71C1C), pts: 8,j:14,g:1, n:5,p:8,bp:10,bc:34),
  _Team(name:'Nimzatt Ballers',   dept:'Guédiawaye', logoUrl:'$_cdn/porto.png',             color:Color(0xFF1565C0), pts: 5,j:14,g:0, n:5,p:9,bp: 7,bc:40),
  _Team(name:'Aigles de Pikine',  dept:'Pikine',     logoUrl:'$_cdn/napoli.png',            color:Color(0xFF1A237E), pts:31,j:14,g:10,n:1,p:3,bp:33,bc:16),
  _Team(name:'Thiaroye FC',       dept:'Pikine',     logoUrl:'$_cdn/sevilla.png',           color:Color(0xFFB71C1C), pts:26,j:14,g:8, n:2,p:4,bp:28,bc:19),
  _Team(name:'Yeumbeul Stars',    dept:'Pikine',     logoUrl:'$_cdn/valencia.png',          color:Color(0xFFE65100), pts:22,j:14,g:6, n:4,p:4,bp:25,bc:22),
  _Team(name:'Keur Massar Elite', dept:'Pikine',     logoUrl:'$_cdn/benfica.png',           color:Color(0xFFB71C1C), pts:19,j:14,g:5, n:4,p:5,bp:21,bc:23),
  _Team(name:'Dalifort FC',       dept:'Pikine',     logoUrl:'$_cdn/sporting-cp.png',       color:Color(0xFF006F39), pts:15,j:14,g:4, n:3,p:7,bp:17,bc:27),
  _Team(name:'Mbao United',       dept:'Pikine',     logoUrl:'$_cdn/celtic.png',            color:Color(0xFF006F39), pts:12,j:14,g:3, n:3,p:8,bp:14,bc:30),
  _Team(name:'Tivaouane Peul SC', dept:'Pikine',     logoUrl:'$_cdn/rangers.png',           color:Color(0xFF1565C0), pts: 9,j:14,g:2, n:3,p:9,bp:11,bc:33),
  _Team(name:'Pikine Nord FC',    dept:'Pikine',     logoUrl:'$_cdn/feyenoord.png',         color:Color(0xFFB71C1C), pts: 6,j:14,g:1, n:3,p:10,bp:8,bc:38),
  _Team(name:'Rufisque City',     dept:'Rufisque',   logoUrl:'$_cdn/psv.png',               color:Color(0xFF006F39), pts:30,j:14,g:9, n:3,p:2,bp:32,bc:17),
  _Team(name:'Bargny FC',         dept:'Rufisque',   logoUrl:'$_cdn/lyon.png',              color:Color(0xFF1565C0), pts:25,j:14,g:7, n:4,p:3,bp:27,bc:20),
  _Team(name:'Sangalkam Elite',   dept:'Rufisque',   logoUrl:'$_cdn/marseille.png',         color:Color(0xFF1565C0), pts:21,j:14,g:6, n:3,p:5,bp:23,bc:22),
  _Team(name:'Diamniadio FC',     dept:'Rufisque',   logoUrl:'$_cdn/monaco.png',            color:Color(0xFFB71C1C), pts:17,j:14,g:5, n:2,p:7,bp:19,bc:25),
  _Team(name:'Sébikotane SC',     dept:'Rufisque',   logoUrl:'$_cdn/lille.png',             color:Color(0xFFB71C1C), pts:14,j:14,g:4, n:2,p:8,bp:16,bc:28),
  _Team(name:'Bambilor United',   dept:'Rufisque',   logoUrl:'$_cdn/rennes.png',            color:Color(0xFFB71C1C), pts:10,j:14,g:2, n:4,p:8,bp:13,bc:31),
  _Team(name:'Jaxaay FC',         dept:'Rufisque',   logoUrl:'$_cdn/nantes.png',            color:Color(0xFFF9A825), pts: 7,j:14,g:1, n:4,p:9,bp:10,bc:35),
  _Team(name:'Tivaouane FC',      dept:'Rufisque',   logoUrl:'$_cdn/strasbourg.png',        color:Color(0xFF1565C0), pts: 4,j:14,g:0, n:4,p:10,bp:7,bc:42),
];

const _depts = ['Toutes', 'Dakar', 'Guédiawaye', 'Pikine', 'Rufisque'];

// ─────────────────────────────────────────────────────────────────────────────
// RANKING SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});
  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _depts.length, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  List<_Team> _teamsFor(String dept) {
    final list = dept == 'Toutes'
        ? List<_Team>.from(_allTeams)
        : _allTeams.where((t) => t.dept == dept).toList();
    list.sort((a, b) {
      final pts = b.pts.compareTo(a.pts);
      if (pts != 0) return pts;
      final diff = b.diff.compareTo(a.diff);
      if (diff != 0) return diff;
      return b.bp.compareTo(a.bp);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);
    return Scaffold(
      backgroundColor: _bg(context),
      body: Column(
        children: [
          _HeroHeader(onBack: () => Navigator.pop(context), dark: dark),
          // ── ONGLETS ──
          Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            height: 42,
            decoration: BoxDecoration(
              color: _card(context),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
            ),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: _sub(context),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.all(4),
              tabs: _depts.map((d) => Tab(text: d)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: _depts.map((dept) =>
                  _DeptRanking(teams: _teamsFor(dept), dept: dept)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── HERO HEADER ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final VoidCallback onBack;
  final bool dark;
  const _HeroHeader({required this.onBack, required this.dark});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Stack(children: [
        // ── Image de fond ──
        Positioned.fill(
          child: Image.network(
            'https://images.pexels.com/photos/46798/the-ball-stadion-football-the-pitch-46798.jpeg?auto=compress&cs=tinysrgb&w=800',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFF003A1A)),
          ),
        ),
        // ── Overlay dégradé ──
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.75),
                  Colors.black.withOpacity(0.50),
                  Colors.black.withOpacity(0.72),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // ── Contenu ──
        Padding(
          padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top row
            Row(children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(text: 'Leader',
                          style: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.w300, color: Colors.white)),
                      TextSpan(text: 'board',
                          style: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.w900, color: _kGold)),
                    ]),
                  ),
                  const SizedBox(height: 2),
                  Text('Région de Dakar · Saison 2026',
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _kGold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kGold.withOpacity(0.45)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.emoji_events_rounded, color: _kGold, size: 16),
                  const SizedBox(width: 5),
                  const Text('2026', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _kGold)),
                ]),
              ),
            ]),
            const SizedBox(height: 22),
            // Stats row
            Row(children: [
              _StatPill(icon: Icons.shield_rounded,      label: 'Équipes', value: '${_allTeams.length}'),
              const SizedBox(width: 10),
              _StatPill(icon: Icons.location_on_rounded, label: 'Zones',   value: '4'),
              const SizedBox(width: 10),
              _StatPill(icon: Icons.sports_rounded,      label: 'Matchs',  value: '${_allTeams.fold(0, (s, t) => s + t.j) ~/ 2}'),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _StatPill({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, height: 1)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w600)),
        ]),
      ]),
    ),
  );
}

// ── VUE DÉPARTEMENT ──────────────────────────────────────────────────────────

class _DeptRanking extends StatelessWidget {
  final List<_Team> teams;
  final String dept;
  const _DeptRanking({required this.teams, required this.dept});

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) {
      return Center(child: Text('Aucune équipe', style: TextStyle(color: _sub(context))));
    }
    final top3 = teams.take(3).toList();
    final rest = teams.skip(3).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        // ── PODIUM ──
        _Podium(teams: top3),
        const SizedBox(height: 20),

        // ── LÉGENDE COLONNES ──
        if (rest.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Row(children: [
              const SizedBox(width: 36),
              const SizedBox(width: 10),
              const SizedBox(width: 36),
              const SizedBox(width: 10),
              Expanded(child: Text('Équipe',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _sub(context)))),
              _ColHeader('J'),
              _ColHeader('G'),
              _ColHeader('N'),
              _ColHeader('P'),
              _ColHeader('Diff'),
              _ColHeaderPts('Pts'),
            ]),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 1,
            color: _sub(context).withOpacity(0.1),
          ),
          const SizedBox(height: 4),
          ...rest.asMap().entries.map((e) => _TeamRow(rank: e.key + 4, team: e.value)),
        ],
      ],
    );
  }
}

Widget _ColHeader(String t) => SizedBox(
  width: 26,
  child: Text(t, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF888888))),
);

Widget _ColHeaderPts(String t) => SizedBox(
  width: 34,
  child: Text(t, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF888888))),
);

// ── PODIUM ────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<_Team> teams;
  const _Podium({required this.teams});

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);
    final first  = teams[0];
    final second = teams.length > 1 ? teams[1] : null;
    final third  = teams.length > 2 ? teams[2] : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [const Color(0xFF111E11), const Color(0xFF0D180D)]
              : [const Color(0xFFF0FAF4), const Color(0xFFE8F5E9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _kGreen.withOpacity(dark ? 0.2 : 0.15)),
        boxShadow: [BoxShadow(
          color: _kGreen.withOpacity(dark ? 0.12 : 0.08),
          blurRadius: 20, offset: const Offset(0, 4),
        )],
      ),
      child: Column(children: [
        // ── Titre podium ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            const Icon(Icons.workspace_premium_rounded, color: _kGold, size: 18),
            const SizedBox(width: 8),
            Text('Top 3', style: GoogleFonts.orbitron(
                fontSize: 13, fontWeight: FontWeight.w800,
                color: dark ? Colors.white : const Color(0xFF1A1A1A))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kGreen.withOpacity(0.25)),
              ),
              child: Text('Meilleurs de la zone',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _kGreen)),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        // ── Podium items ──
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (second != null)
                _PodiumItem(team: second, rank: 2, barHeight: 72, medalColor: _kSilver)
              else const SizedBox(width: 100),
              _PodiumItem(team: first, rank: 1, barHeight: 100, medalColor: _kGold),
              if (third != null)
                _PodiumItem(team: third, rank: 3, barHeight: 56, medalColor: _kBronze)
              else const SizedBox(width: 100),
            ],
          ),
        ),
      ]),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final _Team team;
  final int rank;
  final double barHeight;
  final Color medalColor;
  const _PodiumItem({required this.team, required this.rank,
      required this.barHeight, required this.medalColor});

  @override
  Widget build(BuildContext context) {
    final dark = _isDark(context);
    final avatarSize = rank == 1 ? 72.0 : 58.0;
    final barWidth   = rank == 1 ? 90.0 : 76.0;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      // ── Avatar ──
      Stack(clipBehavior: Clip.none, children: [
        Container(
          width: avatarSize, height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: team.color.withOpacity(0.12),
            border: Border.all(color: medalColor, width: rank == 1 ? 3 : 2.5),
            boxShadow: [BoxShadow(
              color: medalColor.withOpacity(0.5),
              blurRadius: rank == 1 ? 18 : 12,
              spreadRadius: rank == 1 ? 2 : 0,
            )],
          ),
          child: ClipOval(child: Image.network(
            team.logoUrl, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(child: Text(
              team.name.substring(0, 2).toUpperCase(),
              style: TextStyle(color: team.color, fontWeight: FontWeight.w900,
                  fontSize: rank == 1 ? 18 : 14),
            )),
          )),
        ),
        // Rank badge
        Positioned(
          bottom: -4, right: -4,
          child: Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: medalColor, shape: BoxShape.circle,
              border: Border.all(color: dark ? const Color(0xFF111E11) : Colors.white, width: 2),
              boxShadow: [BoxShadow(color: medalColor.withOpacity(0.4), blurRadius: 6)],
            ),
            child: Center(child: Text('$rank',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white))),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      // ── Nom ──
      SizedBox(
        width: barWidth,
        child: Text(team.name,
            textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rank == 1 ? 12 : 11,
              fontWeight: rank == 1 ? FontWeight.w800 : FontWeight.w600,
              color: _txt(context),
            )),
      ),
      const SizedBox(height: 6),
      // ── Badge pts ──
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: medalColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: medalColor.withOpacity(0.4), blurRadius: 8)],
        ),
        child: Text('${team.pts} pts',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      const SizedBox(height: 10),
      // ── Barre podium ──
      Container(
        width: barWidth, height: barHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              medalColor.withOpacity(dark ? 0.35 : 0.25),
              medalColor.withOpacity(dark ? 0.15 : 0.08),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          border: Border(
            top:   BorderSide(color: medalColor.withOpacity(0.6), width: 2),
            left:  BorderSide(color: medalColor.withOpacity(0.3), width: 1),
            right: BorderSide(color: medalColor.withOpacity(0.3), width: 1),
          ),
        ),
        child: Center(child: Text(
          rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
          style: TextStyle(fontSize: rank == 1 ? 26 : 20),
        )),
      ),
    ]);
  }
}

// ── LIGNE TABLEAU ─────────────────────────────────────────────────────────────

class _TeamRow extends StatelessWidget {
  final int rank;
  final _Team team;
  const _TeamRow({required this.rank, required this.team});

  static const _myTeam = 'Les Lions FC';

  Color _rankColor(int r) {
    if (r <= 3) return _kGold;
    if (r <= 6) return _kGreen;
    return const Color(0xFF888888);
  }

  @override
  Widget build(BuildContext context) {
    final dark  = _isDark(context);
    final isMe  = team.name == _myTeam;
    final rColor = _rankColor(rank);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      decoration: BoxDecoration(
        color: isMe
            ? _kGreen.withOpacity(dark ? 0.15 : 0.07)
            : rank.isEven
                ? _card(context).withOpacity(0.6)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isMe ? Border.all(color: _kGreen.withOpacity(0.35), width: 1.5) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(children: [
          // ── Rang ──
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: rColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text('$rank',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: rColor))),
          ),
          const SizedBox(width: 10),
          // ── Logo ──
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: team.color.withOpacity(0.1),
              border: Border.all(color: team.color.withOpacity(0.3), width: 1.5),
            ),
            child: ClipOval(child: Image.network(
              team.logoUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(child: Text(
                team.name.substring(0, 2).toUpperCase(),
                style: TextStyle(color: team.color, fontWeight: FontWeight.w900, fontSize: 11),
              )),
            )),
          ),
          const SizedBox(width: 10),
          // ── Nom ──
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(team.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                  color: isMe ? _kGreen : _txt(context),
                )),
            if (team.dept.isNotEmpty)
              Text(team.dept,
                  style: TextStyle(fontSize: 9, color: _sub(context), fontWeight: FontWeight.w500)),
          ])),
          // ── Stats ──
          _Cell('${team.j}'),
          _Cell('${team.g}'),
          _Cell('${team.n}'),
          _Cell('${team.p}'),
          // Diff coloré
          SizedBox(
            width: 34,
            child: Text(
              team.diff >= 0 ? '+${team.diff}' : '${team.diff}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: team.diff > 0
                    ? _kGreen
                    : team.diff < 0
                        ? Colors.red.shade400
                        : _sub(context),
              ),
            ),
          ),
          // ── Pts badge ──
          Container(
            width: 34,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: isMe ? _kGreen : rColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${team.pts}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w900,
                  color: isMe ? Colors.white : rColor,
                )),
          ),
        ]),
      ),
    );
  }
}

Widget _Cell(String v) => SizedBox(
  width: 26,
  child: Text(v, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF888888))),
);
