import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'terrain_data.dart';
import 'providers/terrain_provider.dart';

const Color _kGreen  = Color(0xFF006F39);
const Color _kDark   = Color(0xFF1A1A1A);

bool  _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c)    => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c)  => Theme.of(c).cardColor;
Color _txt(BuildContext c)   => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)   => _isDark(c)
    ? const Color(0xFFF0EBE0).withOpacity(0.5)
    : Colors.black.withOpacity(0.45);

// ── MODÈLES ──────────────────────────────────────────────────────────────────

enum MatchStatus { upcoming, live, finished }

class _Match {
  final String id, home, away, homeInitials, awayInitials;
  final Color homeColor, awayColor;
  final String homeLogo, awayLogo;
  final DateTime date;
  final String time;
  final MatchStatus status;
  final int? homeScore, awayScore;
  final String terrain, zone;
  final bool isMyTeam;
  const _Match({
    required this.id, required this.home, required this.away,
    required this.homeInitials, required this.awayInitials,
    required this.homeColor, required this.awayColor,
    required this.homeLogo, required this.awayLogo,
    required this.date, required this.time,
    required this.status,
    this.homeScore, this.awayScore,
    required this.terrain, required this.zone,
    this.isMyTeam = false,
  });
}

class _Team {
  final String name, zone, initials;
  final Color color;
  final String logo;
  final int pts, j, g, n, p;
  const _Team({required this.name, required this.zone, required this.initials,
      required this.color, required this.logo,
      required this.pts, required this.j, required this.g, required this.n, required this.p});
}

// ── DONNÉES ──────────────────────────────────────────────────────────────────

const _cdn = 'https://cdn.jsdelivr.net/npm/club-icons@1.0.0/icons';

final _now = DateTime.now();

final _matches = <_Match>[
  // Mes matchs
  _Match(id:'1', home:'Les Lions FC', away:'Tigres FC',
    homeInitials:'LF', awayInitials:'TF',
    homeColor:_kGreen, awayColor:const Color(0xFFE65100),
    homeLogo:'$_cdn/barcelona.png', awayLogo:'$_cdn/real-madrid.png',
    date:_now, time:'16:00', status:MatchStatus.upcoming,
    terrain:'Terrain Dakar Arena', zone:'Dakar', isMyTeam:true),
  _Match(id:'2', home:'Les Lions FC', away:'Plateau Stars',
    homeInitials:'LF', awayInitials:'PS',
    homeColor:_kGreen, awayColor:const Color(0xFF1565C0),
    homeLogo:'$_cdn/barcelona.png', awayLogo:'$_cdn/manchester-city.png',
    date:_now.add(const Duration(days:2)), time:'10:00', status:MatchStatus.upcoming,
    terrain:'Stade Léopold Sédar', zone:'Dakar', isMyTeam:true),
  _Match(id:'3', home:'Black Panthers', away:'Les Lions FC',
    homeInitials:'BP', awayInitials:'LF',
    homeColor:const Color(0xFF212121), awayColor:_kGreen,
    homeLogo:'$_cdn/juventus.png', awayLogo:'$_cdn/barcelona.png',
    date:_now.subtract(const Duration(days:3)), time:'18:00', status:MatchStatus.finished,
    homeScore:1, awayScore:3,
    terrain:'Terrain HLM', zone:'Dakar', isMyTeam:true),
  _Match(id:'4', home:'Les Lions FC', away:'FC Médina',
    homeInitials:'LF', awayInitials:'FM',
    homeColor:_kGreen, awayColor:const Color(0xFFB71C1C),
    homeLogo:'$_cdn/barcelona.png', awayLogo:'$_cdn/liverpool.png',
    date:_now.subtract(const Duration(days:7)), time:'15:00', status:MatchStatus.finished,
    homeScore:2, awayScore:2,
    terrain:'Terrain Point E', zone:'Dakar', isMyTeam:true),
  // Matchs du jour (autres)
  _Match(id:'5', home:'Tigres FC', away:'Aigles Pikine',
    homeInitials:'TF', awayInitials:'AP',
    homeColor:const Color(0xFFE65100), awayColor:const Color(0xFF1A237E),
    homeLogo:'$_cdn/real-madrid.png', awayLogo:'$_cdn/napoli.png',
    date:_now, time:'14:00', status:MatchStatus.live,
    homeScore:2, awayScore:1,
    terrain:'Terrain Dakar Arena', zone:'Dakar'),
  _Match(id:'6', home:'Guédiawaye FC', away:'Sam Notaire',
    homeInitials:'GF', awayInitials:'SN',
    homeColor:const Color(0xFF1565C0), awayColor:const Color(0xFF1A237E),
    homeLogo:'$_cdn/manchester-city.png', awayLogo:'$_cdn/psg.png',
    date:_now, time:'17:00', status:MatchStatus.upcoming,
    terrain:'Stade Léopold Sédar', zone:'Guédiawaye'),
  _Match(id:'7', home:'Rufisque City', away:'Bargny FC',
    homeInitials:'RC', awayInitials:'BF',
    homeColor:_kGreen, awayColor:const Color(0xFF1565C0),
    homeLogo:'$_cdn/psv.png', awayLogo:'$_cdn/lyon.png',
    date:_now, time:'19:00', status:MatchStatus.upcoming,
    terrain:'Terrain Rufisque', zone:'Rufisque'),
  _Match(id:'8', home:'Thiaroye FC', away:'Yeumbeul Stars',
    homeInitials:'TH', awayInitials:'YS',
    homeColor:const Color(0xFFB71C1C), awayColor:const Color(0xFFE65100),
    homeLogo:'$_cdn/sevilla.png', awayLogo:'$_cdn/valencia.png',
    date:_now.subtract(const Duration(days:1)), time:'16:00', status:MatchStatus.finished,
    homeScore:0, awayScore:2,
    terrain:'Terrain Pikine', zone:'Pikine'),
  _Match(id:'9', home:'Warriors HLM', away:'Dakar United',
    homeInitials:'WH', awayInitials:'DU',
    homeColor:const Color(0xFFAD1457), awayColor:const Color(0xFF0D47A1),
    homeLogo:'$_cdn/arsenal.png', awayLogo:'$_cdn/chelsea.png',
    date:_now.add(const Duration(days:1)), time:'20:00', status:MatchStatus.upcoming,
    terrain:'Terrain HLM', zone:'Dakar'),
  _Match(id:'10', home:'Golf Sud Stars', away:'Wakhinane FC',
    homeInitials:'GS', awayInitials:'WK',
    homeColor:const Color(0xFF212121), awayColor:const Color(0xFF1A237E),
    homeLogo:'$_cdn/juventus.png', awayLogo:'$_cdn/inter-milan.png',
    date:_now.subtract(const Duration(days:2)), time:'15:00', status:MatchStatus.finished,
    homeScore:3, awayScore:1,
    terrain:'Terrain Guédiawaye', zone:'Guédiawaye'),
];

const _searchableTeams = <_Team>[
  _Team(name:'Tigres FC',          zone:'Dakar',      initials:'TF', color:Color(0xFFE65100), logo:'$_cdn/real-madrid.png',       pts:29,j:14,g:9,n:2,p:3),
  _Team(name:'Étoiles Plateau',    zone:'Dakar',      initials:'EP', color:Color(0xFF1565C0), logo:'$_cdn/manchester-city.png',   pts:26,j:14,g:8,n:2,p:4),
  _Team(name:'Black Panthers',     zone:'Dakar',      initials:'BP', color:Color(0xFF212121), logo:'$_cdn/juventus.png',          pts:23,j:14,g:7,n:2,p:5),
  _Team(name:'FC Médina',          zone:'Dakar',      initials:'FM', color:Color(0xFFB71C1C), logo:'$_cdn/liverpool.png',         pts:21,j:14,g:6,n:3,p:5),
  _Team(name:'Aigles Pikine',      zone:'Pikine',     initials:'AP', color:Color(0xFF1A237E), logo:'$_cdn/napoli.png',            pts:19,j:14,g:5,n:4,p:5),
  _Team(name:'Warriors HLM',       zone:'Dakar',      initials:'WH', color:Color(0xFFAD1457), logo:'$_cdn/arsenal.png',           pts:17,j:14,g:5,n:2,p:7),
  _Team(name:'Guédiawaye FC',      zone:'Guédiawaye', initials:'GF', color:Color(0xFF1565C0), logo:'$_cdn/manchester-city.png',   pts:32,j:14,g:10,n:2,p:2),
  _Team(name:'Sam Notaire Elite',  zone:'Guédiawaye', initials:'SN', color:Color(0xFF1A237E), logo:'$_cdn/psg.png',               pts:27,j:14,g:8,n:3,p:3),
  _Team(name:'Rufisque City',      zone:'Rufisque',   initials:'RC', color:_kGreen,           logo:'$_cdn/psv.png',               pts:30,j:14,g:9,n:3,p:2),
  _Team(name:'Thiaroye FC',        zone:'Pikine',     initials:'TH', color:Color(0xFFB71C1C), logo:'$_cdn/sevilla.png',           pts:26,j:14,g:8,n:2,p:4),
  _Team(name:'Yeumbeul Stars',     zone:'Pikine',     initials:'YS', color:Color(0xFFE65100), logo:'$_cdn/valencia.png',          pts:22,j:14,g:6,n:4,p:4),
  _Team(name:'Dakar United',       zone:'Dakar',      initials:'DU', color:Color(0xFF0D47A1), logo:'$_cdn/chelsea.png',           pts:15,j:14,g:4,n:3,p:7),
];

// ─────────────────────────────────────────────────────────────────────────────
// MATCH SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── HEADER ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: _card(context), shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _txt(context)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Matchs', style: GoogleFonts.orbitron(
                          fontSize: 20, fontWeight: FontWeight.w900, color: _txt(context))),
                      Text('Région de Dakar · Saison 2026',
                          style: TextStyle(fontSize: 11, color: _sub(context))),
                    ],
                  ),
                  const Spacer(),
                  // Live badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6,
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── ONGLETS ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 42,
              decoration: BoxDecoration(
                color: _card(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabCtrl,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(10)),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: _sub(context),
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                padding: const EdgeInsets.all(4),
                tabs: [
                  const Tab(text: 'Mes Matchs'),
                  const Tab(text: 'Tous'),
                  const Tab(text: 'Organiser'),
                  Tab(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Center(
                          child: Text('Demandes',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        Positioned(
                          top: 0, right: -6,
                          child: Container(
                            width: 7, height: 7,
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _MyMatchesTab(),
                  _AllMatchesTab(),
                  _OrganizeTab(),
                  _RequestsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ONGLET MES MATCHS ────────────────────────────────────────────────────────

class _MyMatchesTab extends StatelessWidget {
  final _mine = _matches.where((m) => m.isMyTeam).toList();

  _MyMatchesTab();

  @override
  Widget build(BuildContext context) {
    final upcoming = _mine.where((m) => m.status == MatchStatus.upcoming).toList();
    final past     = _mine.where((m) => m.status == MatchStatus.finished).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        // Prochain match hero
        if (upcoming.isNotEmpty) ...[
          _SectionLabel('Prochain match'),
          _HeroMatchCard(match: upcoming.first),
          const SizedBox(height: 8),
          if (upcoming.length > 1) ...[
            _SectionLabel('À venir'),
            ...upcoming.skip(1).map((m) => _MatchCard(match: m)),
          ],
        ],
        if (past.isNotEmpty) ...[
          _SectionLabel('Résultats'),
          ...past.map((m) => _MatchCard(match: m)),
        ],
      ],
    );
  }
}

// ── ONGLET TOUS LES MATCHS ───────────────────────────────────────────────────

class _AllMatchesTab extends StatelessWidget {
  final _live     = _matches.where((m) => m.status == MatchStatus.live).toList();
  final _today    = _matches.where((m) => m.status == MatchStatus.upcoming &&
      _sameDay(m.date, DateTime.now())).toList();
  final _finished = _matches.where((m) => m.status == MatchStatus.finished).toList();

  _AllMatchesTab();

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        if (_live.isNotEmpty) ...[
          _SectionLabel('En direct 🔴'),
          ..._live.map((m) => _MatchCard(match: m, showLive: true)),
        ],
        if (_today.isNotEmpty) ...[
          _SectionLabel('Aujourd\'hui'),
          ..._today.map((m) => _MatchCard(match: m)),
        ],
        if (_finished.isNotEmpty) ...[
          _SectionLabel('Résultats récents'),
          ..._finished.map((m) => _MatchCard(match: m)),
        ],
      ],
    );
  }
}

// ── ONGLET DEMANDES ──────────────────────────────────────────────────────────

enum _RequestStatus { pending, accepted, refused }

class _ChallengeRequest {
  final String id;
  final String fromTeam, fromLogo;
  final Color fromColor;
  final String format, terrain, zone, time;
  final DateTime date;
  _RequestStatus status;

  _ChallengeRequest({
    required this.id, required this.fromTeam, required this.fromLogo,
    required this.fromColor, required this.format, required this.terrain,
    required this.zone, required this.time, required this.date,
    this.status = _RequestStatus.pending,
  });
}

final _requests = <_ChallengeRequest>[
  _ChallengeRequest(
    id: 'r1', fromTeam: 'Tigres FC', fromLogo: '$_cdn/real-madrid.png',
    fromColor: Color(0xFFE65100), format: '5v5',
    terrain: 'Terrain Dakar Arena', zone: 'Dakar',
    time: '16:00', date: DateTime.now().add(const Duration(days: 3)),
  ),
  _ChallengeRequest(
    id: 'r2', fromTeam: 'Black Panthers', fromLogo: '$_cdn/juventus.png',
    fromColor: Color(0xFF212121), format: '7v7',
    terrain: 'Stade Léopold Sédar', zone: 'Dakar',
    time: '10:00', date: DateTime.now().add(const Duration(days: 5)),
  ),
  _ChallengeRequest(
    id: 'r3', fromTeam: 'Guédiawaye FC', fromLogo: '$_cdn/manchester-city.png',
    fromColor: Color(0xFF1565C0), format: '5v5',
    terrain: 'Terrain HLM', zone: 'Guédiawaye',
    time: '18:00', date: DateTime.now().subtract(const Duration(days: 1)),
    status: _RequestStatus.accepted,
  ),
  _ChallengeRequest(
    id: 'r4', fromTeam: 'FC Médina', fromLogo: '$_cdn/liverpool.png',
    fromColor: Color(0xFFB71C1C), format: '11v11',
    terrain: 'Terrain Point E', zone: 'Dakar',
    time: '14:00', date: DateTime.now().subtract(const Duration(days: 2)),
    status: _RequestStatus.refused,
  ),
];

class _RequestsTab extends StatefulWidget {
  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  // copie locale pour gérer l'état
  late final List<_ChallengeRequest> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(_requests);
  }

  void _respond(String id, _RequestStatus status) {
    setState(() {
      final r = _items.firstWhere((r) => r.id == id);
      r.status = status;
    });
    final msg = status == _RequestStatus.accepted ? 'Challenge accepté ✅' : 'Challenge refusé';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: status == _RequestStatus.accepted ? _kGreen : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pending  = _items.where((r) => r.status == _RequestStatus.pending).toList();
    final archived = _items.where((r) => r.status != _RequestStatus.pending).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        if (pending.isEmpty && archived.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Column(children: [
              Icon(Icons.inbox_rounded, size: 52, color: _sub(context).withOpacity(0.4)),
              const SizedBox(height: 12),
              Text('Aucune demande', style: TextStyle(color: _sub(context), fontSize: 14)),
            ]),
          ),

        if (pending.isNotEmpty) ...[
          _SectionLabel('En attente (${pending.length})'),
          ...pending.map((r) => _RequestCard(
            request: r,
            onAccept: () => _respond(r.id, _RequestStatus.accepted),
            onRefuse: () => _respond(r.id, _RequestStatus.refused),
          )),
        ],

        if (archived.isNotEmpty) ...[
          _SectionLabel('Archivées'),
          ...archived.map((r) => _RequestCard(request: r)),
        ],
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final _ChallengeRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onRefuse;

  const _RequestCard({required this.request, this.onAccept, this.onRefuse});

  @override
  Widget build(BuildContext context) {
    final isPending  = request.status == _RequestStatus.pending;
    final isAccepted = request.status == _RequestStatus.accepted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(18),
        border: isPending
            ? Border.all(color: _kGreen.withOpacity(0.25), width: 1.5)
            : null,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // ── Header équipe ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                _LogoCircle(url: request.fromLogo, color: request.fromColor, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(request.fromTeam,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                                  color: _txt(context))),
                        ),
                        _StatusBadge(request.status),
                      ]),
                      const SizedBox(height: 3),
                      Text('vous défie en ${request.format}',
                          style: TextStyle(fontSize: 12, color: _sub(context))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Infos match ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _sub(context).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _InfoChip(Icons.calendar_today_rounded, _formatDate(request.date)),
                const SizedBox(width: 10),
                _InfoChip(Icons.access_time_rounded, request.time),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoChip(Icons.location_on_rounded, request.terrain,
                      overflow: true),
                ),
              ],
            ),
          ),

          // ── Boutons (seulement si pending) ──
          if (isPending) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onRefuse,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.25)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded, color: Colors.red, size: 16),
                            SizedBox(width: 6),
                            Text('Refuser',
                                style: TextStyle(color: Colors.red,
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: onAccept,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _kGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Accepter',
                                style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _RequestStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _RequestStatus.accepted => ('Accepté', Colors.green),
      _RequestStatus.refused  => ('Refusé',  Colors.red),
      _RequestStatus.pending  => ('En attente', Colors.orange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool overflow;
  const _InfoChip(this.icon, this.label, {this.overflow = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: overflow ? MainAxisSize.min : MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: _kGreen),
      const SizedBox(width: 4),
      overflow
          ? Flexible(child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: _sub(context))))
          : Text(label, style: TextStyle(fontSize: 11, color: _sub(context))),
    ],
  );
}

// ── ONGLET ORGANISER ─────────────────────────────────────────────────────────

const _zones = ['Toutes', 'Dakar', 'Guédiawaye', 'Pikine', 'Rufisque'];

class _OrganizeTab extends StatefulWidget {
  @override
  State<_OrganizeTab> createState() => _OrganizeTabState();
}

class _OrganizeTabState extends State<_OrganizeTab> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _zone  = 'Toutes';

  List<_Team> get _filtered => _searchableTeams.where((t) {
    final matchZone  = _zone == 'Toutes' || t.zone == _zone;
    final matchQuery = _query.isEmpty ||
        t.name.toLowerCase().contains(_query.toLowerCase()) ||
        t.zone.toLowerCase().contains(_query.toLowerCase());
    return matchZone && matchQuery;
  }).toList();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _openTeam(BuildContext context, _Team team) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _TeamProfilePage(team: team),
    ));
  }

  void _sendChallenge(_Team team) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChallengeSheet(team: team),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teams = _filtered;
    return Column(
      children: [
        // ── Barre recherche ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: _card(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.search_rounded, color: _sub(context), size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(fontSize: 14, color: _txt(context)),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une équipe...',
                      hintStyle: TextStyle(color: _sub(context), fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  GestureDetector(
                    onTap: () { _ctrl.clear(); setState(() => _query = ''); },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(Icons.close_rounded, color: _sub(context), size: 18),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Filtres zone ──
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _zones.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final z = _zones[i];
              final selected = _zone == z;
              return GestureDetector(
                onTap: () => setState(() => _zone = z),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _kGreen : _card(context),
                    borderRadius: BorderRadius.circular(20),
                    border: selected ? null : Border.all(color: _sub(context).withOpacity(0.2)),
                  ),
                  child: Text(z,
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _sub(context),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // ── Compteur ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('${teams.length} équipe${teams.length > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _sub(context))),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Liste ──
        Expanded(
          child: teams.isEmpty
              ? Center(child: Text('Aucune équipe trouvée', style: TextStyle(color: _sub(context))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: teams.length,
                  itemBuilder: (_, i) => _TeamRow(
                    team: teams[i],
                    onTap: () => _openTeam(context, teams[i]),
                    onChallenge: () => _sendChallenge(teams[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── WIDGETS ──────────────────────────────────────────────────────────────────

Widget _SectionLabel(String label) => Padding(
  padding: const EdgeInsets.only(top: 16, bottom: 10),
  child: Text(label, style: GoogleFonts.orbitron(
      fontSize: 12, fontWeight: FontWeight.w800,
      color: const Color(0xFF006F39))),
);

// Hero card pour le prochain match
class _HeroMatchCard extends StatelessWidget {
  final _Match match;
  const _HeroMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Image de fond terrain
            Positioned.fill(
              child: Image.network(
                'https://images.pexels.com/photos/13783930/pexels-photo-13783930.jpeg?auto=compress&cs=tinysrgb&w=800',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF003D1F)),
              ),
            ),
            // Overlay sombre
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.72),
                      Colors.black.withOpacity(0.55),
                      Colors.black.withOpacity(0.72),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kGreen.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(match.zone,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(match.terrain,
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Équipe domicile
                      Expanded(
                        child: Column(
                          children: [
                            _LogoCircle(url: match.homeLogo, color: match.homeColor, size: 60),
                            const SizedBox(height: 8),
                            Text(match.home,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      // Score / heure
                      Column(
                        children: [
                          if (match.status == MatchStatus.finished && match.homeScore != null)
                            Text('${match.homeScore} - ${match.awayScore}',
                                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900))
                          else ...[
                            Text(match.time,
                                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(_formatDate(match.date),
                                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
                            ),
                          ],
                        ],
                      ),
                      // Équipe extérieure
                      Expanded(
                        child: Column(
                          children: [
                            _LogoCircle(url: match.awayLogo, color: match.awayColor, size: 60),
                            const SizedBox(height: 8),
                            Text(match.away,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_rounded, color: Colors.white.withOpacity(0.6), size: 13),
                      const SizedBox(width: 4),
                      Text(match.terrain,
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
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

// Carte match standard
class _MatchCard extends StatelessWidget {
  final _Match match;
  final bool showLive;
  const _MatchCard({required this.match, this.showLive = false});

  @override
  Widget build(BuildContext context) {
    final isLive     = match.status == MatchStatus.live;
    final isFinished = match.status == MatchStatus.finished;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(18),
        border: isLive ? Border.all(color: Colors.red.withOpacity(0.4), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(match.zone,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _kGreen)),
              ),
              const SizedBox(width: 6),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 5, height: 5,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
              const Spacer(),
              Text(match.terrain,
                  style: TextStyle(fontSize: 9, color: _sub(context)),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
          const SizedBox(height: 12),
          // Équipes + score
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _LogoCircle(url: match.homeLogo, color: match.homeColor, size: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(match.home,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _txt(context)),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              // Centre
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isFinished
                      ? _kGreen.withOpacity(0.1)
                      : isLive
                          ? Colors.red.withOpacity(0.1)
                          : _sub(context).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isFinished && match.homeScore != null
                    ? Text('${match.homeScore}  -  ${match.awayScore}',
                        style: GoogleFonts.orbitron(
                            fontSize: 15, fontWeight: FontWeight.w900,
                            color: isFinished ? _kGreen : _txt(context)))
                    : isLive && match.homeScore != null
                        ? Text('${match.homeScore}  -  ${match.awayScore}',
                            style: GoogleFonts.orbitron(
                                fontSize: 15, fontWeight: FontWeight.w900, color: Colors.red))
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(match.time,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
                              Text(_formatDate(match.date),
                                  style: TextStyle(fontSize: 9, color: _sub(context))),
                            ],
                          ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(match.away,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _txt(context)),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 10),
                    _LogoCircle(url: match.awayLogo, color: match.awayColor, size: 38),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Ligne équipe dans la liste
class _TeamRow extends StatelessWidget {
  final _Team team;
  final VoidCallback onTap;
  final VoidCallback onChallenge;
  const _TeamRow({required this.team, required this.onTap, required this.onChallenge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            _LogoCircle(url: team.logo, color: team.color, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team.name,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txt(context))),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 11, color: _sub(context)),
                      const SizedBox(width: 2),
                      Text(team.zone, style: TextStyle(fontSize: 11, color: _sub(context))),
                      const SizedBox(width: 10),
                      Text('${team.pts} pts',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kGreen)),
                      const SizedBox(width: 6),
                      Text('${team.j}J ${team.g}V ${team.n}N ${team.p}D',
                          style: TextStyle(fontSize: 10, color: _sub(context))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onChallenge,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _kGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Défier',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── TEAM PROFILE PAGE ────────────────────────────────────────────────────────

class _TeamProfilePage extends StatelessWidget {
  final _Team team;
  const _TeamProfilePage({required this.team});

  // Matchs de cette équipe
  List<_Match> get _teamMatches => _matches
      .where((m) => m.home == team.name || m.away == team.name)
      .toList();

  @override
  Widget build(BuildContext context) {
    final matches = _teamMatches;
    final wins   = matches.where((m) => m.status == MatchStatus.finished &&
        ((m.home == team.name && (m.homeScore ?? 0) > (m.awayScore ?? 0)) ||
         (m.away == team.name && (m.awayScore ?? 0) > (m.homeScore ?? 0)))).length;
    final draws  = matches.where((m) => m.status == MatchStatus.finished &&
        m.homeScore != null && m.homeScore == m.awayScore).length;
    final losses = matches.where((m) => m.status == MatchStatus.finished).length - wins - draws;

    return Scaffold(
      backgroundColor: _bg(context),
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [team.color, team.color.withOpacity(0.6)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 28),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(team.zone,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _LogoCircle(url: team.logo, color: Colors.white, size: 80),
                  const SizedBox(height: 14),
                  Text(team.name,
                      style: GoogleFonts.orbitron(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),
                  // Stats rapides
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatPill(label: 'Pts', value: '${team.pts}'),
                      _StatPill(label: 'Matchs', value: '${team.j}'),
                      _StatPill(label: 'Victoires', value: '$wins'),
                      _StatPill(label: 'Nuls', value: '$draws'),
                      _StatPill(label: 'Défaites', value: '$losses'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Matchs récents ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: Text('Matchs récents',
                  style: GoogleFonts.orbitron(
                      fontSize: 13, fontWeight: FontWeight.w800, color: _kGreen)),
            ),
          ),

          matches.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(child: Text('Aucun match enregistré',
                        style: TextStyle(color: _sub(context)))),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _MatchCard(match: matches[i]),
                    ),
                    childCount: matches.length,
                  ),
                ),

          // ── Bouton défier ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => _ChallengeSheet(team: team),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: _kGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sports_soccer_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Défier ${team.name}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
    ],
  );
}

// ── CHALLENGE SHEET ──────────────────────────────────────────────────────────

// Nombre de joueurs par format
int _playersForFormat(String fmt) {
  switch (fmt) {
    case '7v7':  return 14;
    case '11v11': return 22;
    default:     return 10; // 5v5
  }
}

// Capacité max extraite du label feature '14 joueurs max'
int _terrainCapacity(Terrain t) {
  for (final f in t.features) {
    final m = RegExp(r'(\d+) joueurs').firstMatch(f);
    if (m != null) return int.parse(m.group(1)!);
  }
  return 22;
}

class _ChallengeSheet extends StatefulWidget {
  final _Team team;
  const _ChallengeSheet({required this.team});
  @override
  State<_ChallengeSheet> createState() => _ChallengeSheetState();
}

class _ChallengeSheetState extends State<_ChallengeSheet> {
  DateTime _date    = DateTime.now().add(const Duration(days: 2));
  String   _format  = '5v5';
  // Plage : heure de début + durée en slots de 15 min
  int      _startH  = 16;
  int      _startM  = 0;
  int      _slots   = 4; // 4 × 15 min = 1h

  Terrain? _selectedTerrain;
  String   _terrainQuery = '';
  final    _terrainCtrl  = TextEditingController();
  bool     _showTerrains = false;
  bool     _terrainError = false;

  static const _formats = ['5v5', '7v7', '11v11'];

  // Génère les créneaux de 08:00 à 22:00 par pas de 15 min
  List<String> get _allSlots {
    final slots = <String>[];
    for (int h = 8; h <= 22; h++) {
      for (int m = 0; m < 60; m += 15) {
        if (h == 22 && m > 0) break;
        slots.add('${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}');
      }
    }
    return slots;
  }

  int get _startMinutes => _startH * 60 + _startM;
  int get _durationMin  => _slots * 15;

  String get _endTime {
    final end = _startMinutes + _durationMin;
    return '${(end ~/ 60).toString().padLeft(2,'0')}:${(end % 60).toString().padLeft(2,'0')}';
  }

  // Terrains filtrés par capacité et nom
  List<Terrain> _getAvailableTerrains(List<Terrain> allTerrains) {
    final needed = _playersForFormat(_format);
    return allTerrains.where((t) {
      final cap   = _terrainCapacity(t);
      final query = _terrainQuery.isEmpty ||
          t.name.toLowerCase().contains(_terrainQuery.toLowerCase()) ||
          t.address.toLowerCase().contains(_terrainQuery.toLowerCase());
      return cap >= needed && query;
    }).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  @override
  void dispose() { _terrainCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (_selectedTerrain == null) {
      setState(() => _terrainError = true);
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Challenge envoyé à ${widget.team.name} · ${_selectedTerrain!.name}'),
      backgroundColor: _kGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _label(BuildContext context, String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _sub(context))),
      if (required) const Text(' *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final allTerrains = context.read<TerrainProvider>().terrains;
    final available = _getAvailableTerrains(allTerrains);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: sc,
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 32),
          children: [
            // Handle
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: _sub(context).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            // ── VS header ──
            Row(
              children: [
                _LogoCircle(url: '$_cdn/barcelona.png', color: _kGreen, size: 48),
                Expanded(child: Column(children: [
                  Text('VS', style: GoogleFonts.orbitron(
                      fontSize: 18, fontWeight: FontWeight.w900, color: _txt(context))),
                  Text('Challenge', style: TextStyle(fontSize: 10, color: _sub(context))),
                ])),
                _LogoCircle(url: widget.team.logo, color: widget.team.color, size: 48),
              ],
            ),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text('Les Lions FC', textAlign: TextAlign.left,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _txt(context)))),
              Expanded(child: Text(widget.team.name, textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _txt(context)))),
            ]),
            const SizedBox(height: 20),

            // ── Format ──
            _label(context, 'Format'),
            Row(
              children: _formats.map((f) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() { _format = f; _selectedTerrain = null; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _format == f ? _kGreen : _sub(context).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(f, textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                            color: _format == f ? Colors.white : _txt(context))),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // ── Date ──
            _label(context, 'Date'),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(primary: _kGreen)),
                    child: child!,
                  ),
                );
                if (d != null) setState(() { _date = d; _selectedTerrain = null; });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _sub(context).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, color: _kGreen, size: 18),
                  const SizedBox(width: 10),
                  Text(_formatDate(_date),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _txt(context))),
                  const Spacer(),
                  Icon(Icons.keyboard_arrow_down_rounded, color: _sub(context)),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // ── Plage horaire ──
            _label(context, 'Plage horaire'),
            // Heure de début
            Text('Début', style: TextStyle(fontSize: 11, color: _sub(context))),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _allSlots.length,
                itemBuilder: (_, i) {
                  final s = _allSlots[i];
                  final parts = s.split(':');
                  final h = int.parse(parts[0]);
                  final m = int.parse(parts[1]);
                  final selected = h == _startH && m == _startM;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _startH = h; _startM = m; _selectedTerrain = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? _kGreen : _sub(context).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(s,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : _txt(context))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // Durée
            Text('Durée', style: TextStyle(fontSize: 11, color: _sub(context))),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [1, 2, 3, 4, 6, 8].map((s) {
                  final selected = _slots == s;
                  final label = s == 1 ? '15 min'
                      : s % 4 == 0 ? '${s ~/ 4}h'
                      : '${(s * 15 / 60).toStringAsFixed(2).replaceAll('.', 'h')}';
                  return GestureDetector(
                    onTap: () => setState(() { _slots = s; _selectedTerrain = null; }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? _kGreen : _sub(context).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(label,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : _txt(context))),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Résumé plage
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.access_time_rounded, color: _kGreen, size: 15),
                const SizedBox(width: 6),
                Text(
                  '${_startH.toString().padLeft(2,'0')}:${_startM.toString().padLeft(2,'0')} → $_endTime  ($_durationMin min)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // ── Terrain (obligatoire) ──
            _label(context, 'Terrain', required: true),
            if (_terrainError && _selectedTerrain == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('Veuillez sélectionner un terrain',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade400)),
              ),

            // Terrain sélectionné
            if (_selectedTerrain != null)
              GestureDetector(
                onTap: () => setState(() { _selectedTerrain = null; _showTerrains = true; }),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: _kGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kGreen.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_selectedTerrain!.imageUrl,
                          width: 52, height: 52, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              width: 52, height: 52, color: _kGreen.withOpacity(0.2))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_selectedTerrain!.name,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _txt(context))),
                      const SizedBox(height: 2),
                      Text(_selectedTerrain!.address,
                          style: TextStyle(fontSize: 11, color: _sub(context))),
                      const SizedBox(height: 2),
                      Text(_selectedTerrain!.priceLabel,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kGreen)),
                    ])),
                    const Icon(Icons.check_circle_rounded, color: _kGreen, size: 20),
                  ]),
                ),
              ),

            // Barre recherche terrain
            if (_selectedTerrain == null) ...[
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _sub(context).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: _terrainError
                      ? Border.all(color: Colors.red.shade300)
                      : null,
                ),
                child: Row(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search_rounded, color: _sub(context), size: 18),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _terrainCtrl,
                      onChanged: (v) => setState(() {
                        _terrainQuery = v;
                        _showTerrains = true;
                        _terrainError = false;
                      }),
                      onTap: () => setState(() => _showTerrains = true),
                      style: TextStyle(fontSize: 13, color: _txt(context)),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un terrain disponible...',
                        hintStyle: TextStyle(color: _sub(context), fontSize: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_terrainQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () { _terrainCtrl.clear(); setState(() => _terrainQuery = ''); },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Icon(Icons.close_rounded, color: _sub(context), size: 16),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 8),

              // Info filtre actif
              Row(children: [
                Icon(Icons.info_outline_rounded, size: 12, color: _sub(context)),
                const SizedBox(width: 4),
                Text(
                  'Terrains ≥ ${_playersForFormat(_format)} joueurs · disponibles ${_startH.toString().padLeft(2,'0')}:${_startM.toString().padLeft(2,'0')}→$_endTime',
                  style: TextStyle(fontSize: 10, color: _sub(context)),
                ),
              ]),
              const SizedBox(height: 8),

              // Liste terrains
              if (available.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _sub(context).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(
                    'Aucun terrain disponible pour cette plage.\nEssayez un autre horaire ou format.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: _sub(context), height: 1.5),
                  )),
                )
              else
                ...available.map((t) => GestureDetector(
                  onTap: () => setState(() {
                    _selectedTerrain = t;
                    _terrainError    = false;
                    _showTerrains    = false;
                    _terrainCtrl.clear();
                    _terrainQuery    = '';
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _card(context),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                    ),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(t.imageUrl,
                            width: 52, height: 52, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 52, height: 52,
                                color: _kGreen.withOpacity(0.15))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                  color: _txt(context))),
                          const SizedBox(height: 2),
                          Text(t.address,
                              style: TextStyle(fontSize: 11, color: _sub(context))),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.group_rounded, size: 11, color: _sub(context)),
                            const SizedBox(width: 2),
                            Text('${_terrainCapacity(t)} max',
                                style: TextStyle(fontSize: 10, color: _sub(context))),
                            const SizedBox(width: 10),
                            Text(t.priceLabel,
                                style: const TextStyle(fontSize: 10,
                                    fontWeight: FontWeight.w700, color: _kGreen)),
                          ]),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Libre',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: Colors.green)),
                      ),
                    ]),
                  ),
                )),
            ],

            const SizedBox(height: 24),

            // ── Bouton envoyer ──
            GestureDetector(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _selectedTerrain != null ? _kGreen : _sub(context).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('Envoyer le challenge ⚡',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _selectedTerrain != null ? Colors.white : _sub(context),
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HELPERS ──────────────────────────────────────────────────────────────────

class _LogoCircle extends StatelessWidget {
  final String url;
  final Color color;
  final double size;
  const _LogoCircle({required this.url, required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12)),
    child: ClipOval(
      child: Image.network(url, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
              child: Text(url.split('/').last.substring(0, 2).toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900,
                      fontSize: size * 0.28)))),
    ),
  );
}

String _formatDate(DateTime d) {
  const months = ['Jan','Fév','Mar','Avr','Mai','Juin','Juil','Août','Sep','Oct','Nov','Déc'];
  const days   = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];
  return '${days[d.weekday-1]} ${d.day} ${months[d.month-1]}';
}
