import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/team_service.dart';
import 'team_screen.dart' show TeamData, TeamMember, MemberStatus, PlayerPositionLabel, InviteCard;

const Color _kGreen = Color(0xFF006F39);
Color _bg(BuildContext c) => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c) => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFFF0EBE0).withOpacity(0.5)
    : Colors.black.withOpacity(0.45);

// ── PAGE : EFFECTIF ───────────────────────────────────────────────────────────

class RosterPage extends StatefulWidget {
  final TeamData team;
  const RosterPage({super.key, required this.team});
  @override
  State<RosterPage> createState() => _RosterPageState();
}

class _RosterPageState extends State<RosterPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  TeamData get team => widget.team;

  List<TeamMember> get _active =>
      team.members.where((m) => m.status == MemberStatus.active).toList();
  List<TeamMember> get _pending =>
      team.members.where((m) => m.status == MemberStatus.pending).toList();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _accept(TeamMember m) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _kGreen)),
    );

    try {
      final auth = context.read<AuthProvider>();
      final teamService = TeamService();
      
      // Appel au Backend pour accepter le membre
      await teamService.acceptMember(team.id, m.id, auth.token!);

      if (mounted) {
        Navigator.pop(context); // Fermer loader
        setState(() {
          m.status = MemberStatus.active;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${m.name} a rejoint l\'équipe !'), backgroundColor: _kGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _refuse(TeamMember m) => setState(() {
    team.members.remove(m);
  });

  void _remove(TeamMember m) {
    if (m.isCaptain) return;
    setState(() {
      team.members.remove(m);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending.length;
    return Scaffold(
      backgroundColor: _bg(context),
      body: SafeArea(
        child: Column(children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: _card(context), shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)]),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _txt(context)),
                ),
              ),
              const SizedBox(width: 14),
              Text('Effectif', style: GoogleFonts.orbitron(
                  fontSize: 18, fontWeight: FontWeight.w900, color: _txt(context))),
            ]),
          ),
          const SizedBox(height: 16),
          // ── Onglets ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 42,
            decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(14)),
            child: TabBar(
              controller: _tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: _sub(context),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              padding: const EdgeInsets.all(4),
              tabs: [
                const Tab(text: 'Effectif'),
                Tab(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Demandes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    if (pending > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Center(child: Text('$pending',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
                      ),
                    ],
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // ── Contenu ──
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // ── Onglet Effectif ──
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    InviteCard(inviteCode: team.inviteCode),
                    const SizedBox(height: 20),
                    Text('Membres actifs (${_active.length})',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
                    const SizedBox(height: 10),
                    ..._active.map((m) => _memberTile(context, m)),
                  ],
                ),
                // ── Onglet Demandes ──
                _pending.isEmpty
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.inbox_rounded, size: 48, color: _sub(context).withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text('Aucune demande en attente',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _sub(context))),
                        ]),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        children: [
                          Text('${_pending.length} demande${_pending.length > 1 ? 's' : ''} en attente',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
                          const SizedBox(height: 10),
                          ..._pending.map((m) => _requestTile(context, m)),
                        ],
                      ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _memberTile(BuildContext context, TeamMember m) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => _PlayerDetailPage(member: m, teamColor: team.color))),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card(context), borderRadius: BorderRadius.circular(14),
        border: m.isCaptain ? Border.all(color: _kGreen.withOpacity(0.35)) : null,
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: team.color.withOpacity(0.15)),
          child: Center(child: Text(m.name.split(' ').map((w) => w[0]).take(2).join(),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: team.color))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(m.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txt(context))),
            if (m.isCaptain) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _kGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: const Text('Capitaine', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _kGreen)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: m.position.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(m.position.short,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: m.position.color)),
            ),
            const SizedBox(width: 6),
            Text('${m.age} ans', style: TextStyle(fontSize: 11, color: _sub(context))),
          ]),
        ])),
        Row(children: [
          Icon(Icons.sports_soccer_rounded, size: 13, color: _sub(context)),
          const SizedBox(width: 3),
          Text('${m.goals}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _txt(context))),
          const SizedBox(width: 10),
          Icon(Icons.assistant_rounded, size: 13, color: _sub(context)),
          const SizedBox(width: 3),
          Text('${m.assists}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _txt(context))),
          const SizedBox(width: 10),
          if (m.isCaptain)
            const Icon(Icons.star_rounded, color: Colors.amber, size: 18)
          else
            GestureDetector(
              onTap: () => _remove(m),
              child: Icon(Icons.remove_circle_outline_rounded, color: _sub(context), size: 20),
            ),
        ]),
      ]),
    ),
    );
  }

  Widget _requestTile(BuildContext context, TeamMember m) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => _PlayerDetailPage(member: m, teamColor: team.color))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card(context), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kGreen.withOpacity(0.2), width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _sub(context).withOpacity(0.1)),
            child: Center(child: Text(m.name.split(' ').map((w) => w[0]).take(2).join(),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _sub(context)))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txt(context))),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: m.position.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(m.position.short,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: m.position.color)),
              ),
              const SizedBox(width: 6),
              Text('${m.age} ans', style: TextStyle(fontSize: 11, color: _sub(context))),
            ]),
          ])),
          const SizedBox(width: 8),
          // Refuser
          GestureDetector(
            onTap: () => _refuse(m),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.withOpacity(0.25))),
              child: const Icon(Icons.close_rounded, color: Colors.red, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          // Accepter
          GestureDetector(
            onTap: () => _accept(m),
            child: Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── PAGE : DÉTAIL JOUEUR ──────────────────────────────────────────────────────

// Image joueur par défaut
const _kPlayerImageUrl =
    'https://images.pexels.com/photos/1884574/pexels-photo-1884574.jpeg?auto=compress&cs=tinysrgb&w=600';

class _PlayerDetailPage extends StatelessWidget {
  final TeamMember member;
  final Color teamColor;
  const _PlayerDetailPage({required this.member, required this.teamColor});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final firstName = member.name.split(' ').first;
    final lastName = member.name.split(' ').skip(1).join(' ');

    return Scaffold(
      backgroundColor: _bg(context),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [

          // ── HEADER image joueur ──
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            child: SizedBox(
              height: 340 + topPad,
              child: Stack(children: [
                // Photo joueur
                Positioned.fill(
                  child: Image.network(
                    _kPlayerImageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [teamColor, Color.lerp(teamColor, Colors.black, 0.5)!],
                        ),
                      ),
                    ),
                  ),
                ),
                // Overlay dégradé
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                // Bouton retour
                Positioned(
                  top: topPad + 12, left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 15, color: Colors.white),
                    ),
                  ),
                ),
                // Infos en bas
                Positioned(
                  left: 20, right: 20, bottom: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badges poste + capitaine
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: member.position.color,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(member.position.label,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ),
                        if (member.isCaptain) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.withOpacity(0.7)),
                            ),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                              SizedBox(width: 4),
                              Text('Capitaine', style: TextStyle(color: Colors.amber,
                                  fontSize: 10, fontWeight: FontWeight.w800)),
                            ]),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 10),
                      // Prénom
                      Text(firstName,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 14, fontWeight: FontWeight.w400)),
                      // Nom
                      Text(lastName.isNotEmpty ? lastName : firstName,
                          style: GoogleFonts.orbitron(
                              color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('${member.age} ans',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.55), fontSize: 12)),
                    ],
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 20),

          // ── STATS ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: _card(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 12)],
            ),
            child: Row(children: [
              _HStatCol(label: 'Buts', value: '${member.goals}'),
              _vLine(context),
              _HStatCol(label: 'Passes D.', value: '${member.assists}'),
              _vLine(context),
              _HStatCol(label: 'Moy. buts', value: member.matchesPlayed > 0
                  ? (member.goals / member.matchesPlayed).toStringAsFixed(1) : '0.0'),
              _vLine(context),
              _HStatCol(label: 'Âge', value: '${member.age}'),
            ]),
          ),

          const SizedBox(height: 20),

          // ── PERFORMANCES ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _card(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 12)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PERFORMANCES',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900,
                      color: _sub(context), letterSpacing: 1.2)),
              const SizedBox(height: 18),
              _perfBar(context, label: 'J1',
                  value: member.goals > 0 ? 0.72 : 0.3,
                  color: const Color(0xFFFFB300)),
              const SizedBox(height: 14),
              _perfBar(context, label: 'J2',
                  value: member.assists > 0 ? 0.85 : 0.5,
                  color: _kGreen),
              const SizedBox(height: 14),
              _perfBar(context, label: 'J3',
                  value: 0.6, color: teamColor),
            ]),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _vLine(BuildContext context) => Container(
    width: 1, height: 36,
    color: _sub(context).withOpacity(0.15),
  );

  Widget _perfBar(BuildContext context, {
    required String label, required double value, required Color color,
  }) {
    return Row(children: [
      SizedBox(
        width: 28,
        child: Text(label,
            style: TextStyle(fontSize: 11, color: _sub(context), fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(children: [
            Container(
              height: 10,
              color: _sub(context).withOpacity(0.1),
            ),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(height: 10, color: color),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 28,
        child: Text((value * 10).toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _txt(context))),
      ),
    ]);
  }
}

class _HStatCol extends StatelessWidget {
  final String label, value;
  const _HStatCol({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(label, style: TextStyle(fontSize: 9, color: _sub(context), fontWeight: FontWeight.w600)),
      const SizedBox(height: 5),
      Text(value, style: GoogleFonts.orbitron(
          fontSize: 16, fontWeight: FontWeight.w900, color: _txt(context))),
    ]),
  );
}
