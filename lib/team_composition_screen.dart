import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'team_screen.dart' show TeamData, TeamMember, MemberStatus, PlayerPositionLabel, mockPlayers;

const Color _kGreen = Color(0xFF006F39);
bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c) => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c) => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFFF0EBE0).withOpacity(0.5)
    : Colors.black.withOpacity(0.45);

// ── PAGE : COMPOSITIONS ───────────────────────────────────────────────────────

class CompositionPage extends StatefulWidget {
  final TeamData team;
  const CompositionPage({super.key, required this.team});
  @override
  State<CompositionPage> createState() => _CompositionPageState();
}

class _CompositionPageState extends State<CompositionPage> {
  static const _formations = [
    '4-3-3', '4-4-2', '4-2-3-1', '3-5-2', '5-3-2',
    '4-1-4-1', '3-4-3', '5-4-1', '4-3-2-1', '4-5-1',
    '3-6-1', '4-4-1-1', '3-3-3-1',
  ];
  String _formation = '4-3-3';
  List<int?> _lineup = [];
  int? _selectedSlot;
  late List<TeamMember> _cachedPlayers; // liste fixe calculée une fois

  TeamData get team => widget.team;
  List<TeamMember> get _allPlayers => _cachedPlayers;

  void _buildPlayerList() {
    final active = team.members.where((m) => m.status == MemberStatus.active).toList();
    if (active.isNotEmpty) {
      _cachedPlayers = active.asMap().entries.map((e) {
        final m = e.value;
        final mockIdx = e.key % mockPlayers.length;
        return TeamMember(
          id: m.id, name: m.name, isCaptain: m.isCaptain,
          age: m.age, goals: m.goals, assists: m.assists,
          matchesPlayed: m.matchesPlayed, position: m.position,
          status: m.status,
          avatarUrl: m.avatarUrl.isNotEmpty ? m.avatarUrl : mockPlayers[mockIdx].avatarUrl,
        );
      }).toList();
    } else {
      // Pas de membres → afficher les mocks directement
      _cachedPlayers = List.from(mockPlayers);
    }
  }

  int get _slotCount {
    final parts = _formation.split('-').map(int.parse).toList();
    return 1 + parts.fold(0, (a, b) => a + b);
  }

  List<int> get _benchIndices {
    if (_lineup.isEmpty) return [];
    final used = _lineup.whereType<int>().toSet();
    return List.generate(_allPlayers.length, (i) => i)
        .where((i) => !used.contains(i))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _buildPlayerList();
    _initLineup();
  }

  void _initLineup() {
    final count = _slotCount;
    final players = _allPlayers;
    _lineup = List.generate(count, (i) => i < players.length ? i : null);
  }

  void _changeFormation(String f) {
    setState(() {
      _formation = f;
      _selectedSlot = null;
      _initLineup();
    });
  }

  List<Offset> _getPositions() {
    final parts = _formation.split('-').map(int.parse).toList();
    final positions = <Offset>[const Offset(0.5, 0.90)]; // GB
    final yLines = [0.73, 0.54, 0.34, 0.14];
    for (int li = 0; li < parts.length; li++) {
      final count = parts[li];
      final y = yLines[li < yLines.length ? li : yLines.length - 1];
      for (int pi = 0; pi < count; pi++) {
        positions.add(Offset((pi + 1) / (count + 1), y));
      }
    }
    return positions;
  }

  void _onSlotTap(int slotIdx) {
    if (_selectedSlot == null) {
      // Premier tap : sélectionner ce slot
      setState(() => _selectedSlot = slotIdx);
    } else if (_selectedSlot == slotIdx) {
      // Re-tap sur le même : désélectionner
      setState(() => _selectedSlot = null);
    } else {
      // Deuxième tap sur un autre slot du terrain : swap
      setState(() {
        final tmp = _lineup[_selectedSlot!];
        _lineup[_selectedSlot!] = _lineup[slotIdx];
        _lineup[slotIdx] = tmp;
        _selectedSlot = null;
      });
    }
  }

  void _onSlotLongPress(int slotIdx) {
    setState(() => _selectedSlot = slotIdx);
    _showSubSheet(slotIdx);
  }

  void _showSubSheet(int slotIdx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SubstitutionSheet(
        bench: _benchIndices.map((i) => _allPlayers[i]).toList(),
        currentPlayer: _lineup[slotIdx] != null ? _allPlayers[_lineup[slotIdx]!] : null,
        teamColor: team.color,
        onSelect: (member) {
          final newIdx = _allPlayers.indexOf(member);
          setState(() {
            final existingSlot = _lineup.indexOf(newIdx);
            if (existingSlot != -1) _lineup[existingSlot] = _lineup[slotIdx];
            _lineup[slotIdx] = newIdx;
            _selectedSlot = null;
          });
          Navigator.pop(context);
        },
      ),
    ).whenComplete(() => setState(() => _selectedSlot = null));
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final positions = _getPositions();

    return Scaffold(
      backgroundColor: _bg(context),
      body: Column(children: [

        // ── Header ──
        Container(
          padding: EdgeInsets.fromLTRB(16, topPad + 14, 16, 14),
          decoration: BoxDecoration(
            color: _bg(context),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _card(context), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: _txt(context)),
              ),
            ),
            const Spacer(),
            Text('Composition',
                style: GoogleFonts.orbitron(fontSize: 17, fontWeight: FontWeight.w900, color: _txt(context))),
            const Spacer(),
            // Dropdown formation compact
            GestureDetector(
              onTap: () => _showFormationPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _kGreen,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.35), blurRadius: 8)],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_formation,
                      style: GoogleFonts.orbitron(
                          fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                ]),
              ),
            ),
          ]),
        ),

        // ── Terrain ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LayoutBuilder(builder: (ctx, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Stack(children: [
                  Positioned.fill(child: CustomPaint(painter: _GrassPainter())),
                  Positioned.fill(child: CustomPaint(painter: _ModernPitchPainter())),
                  // Hint swap
                  if (_selectedSlot != null)
                    Positioned(
                      top: 10, left: 0, right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Tape sur un autre joueur pour échanger',
                              style: GoogleFonts.orbitron(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ...List.generate(positions.length, (i) {
                    if (i >= _lineup.length) return const SizedBox.shrink();
                    final pos = positions[i];
                    final memberIdx = _lineup[i];
                    final member = memberIdx != null ? _allPlayers[memberIdx] : null;
                    final isSel = _selectedSlot == i;
                    return Positioned(
                      left: pos.dx * w - 32,
                      top: pos.dy * h - 44,
                      child: GestureDetector(
                        onTap: () => _onSlotTap(i),
                        onLongPress: () => _onSlotLongPress(i),
                        child: _PlayerToken(
                          member: member,
                          teamColor: team.color,
                          isSelected: isSel,
                        ),
                      ),
                    );
                  }),
                ]);
              }),
            ),
          ),
        ),

        // ── Banc ──
        Container(
          decoration: BoxDecoration(
            color: _card(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(children: [
                Container(width: 4, height: 14,
                    decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Text('Banc de touche',
                    style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.w800, color: _txt(context))),
                const Spacer(),
                Text('${_benchIndices.length} joueurs  •  appui long = remplacer',
                    style: TextStyle(fontSize: 9, color: _sub(context), fontWeight: FontWeight.w600)),
              ]),
            ),
            SizedBox(
              height: 82,
              child: _benchIndices.isEmpty
                  ? Center(child: Text('Tous les joueurs sont titulaires',
                      style: TextStyle(fontSize: 11, color: _sub(context))))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      itemCount: _benchIndices.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final m = _allPlayers[_benchIndices[i]];
                        return GestureDetector(
                          onTap: () {
                            // Trouver un slot vide ou le premier slot
                            final emptySlot = _lineup.indexWhere((s) => s == null);
                            if (emptySlot != -1) {
                              setState(() {
                                _lineup[emptySlot] = _benchIndices[i];
                              });
                            }
                          },
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            _MiniAvatar(member: m, teamColor: team.color, size: 46),
                            const SizedBox(height: 4),
                            Text(m.name.split(' ').first,
                                style: GoogleFonts.orbitron(
                                    fontSize: 8, color: _sub(context), fontWeight: FontWeight.w700)),
                          ]),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _showFormationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: _sub(context).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Choisir une formation',
              style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w900, color: _txt(context))),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.75,
              ),
              itemCount: _formations.length,
              itemBuilder: (_, i) {
                final f = _formations[i];
                final sel = f == _formation;
                return GestureDetector(
                  onTap: () { _changeFormation(f); Navigator.pop(context); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: sel ? _kGreen : _bg(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sel ? _kGreen : _sub(context).withOpacity(0.2),
                        width: sel ? 2 : 1,
                      ),
                      boxShadow: sel ? [BoxShadow(color: _kGreen.withOpacity(0.3), blurRadius: 10)] : null,
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      // Mini terrain
                      SizedBox(
                        width: 52, height: 68,
                        child: CustomPaint(painter: _MiniPitchPainter(formation: f, selected: sel)),
                      ),
                      const SizedBox(height: 6),
                      Text(f, style: GoogleFonts.orbitron(
                          fontSize: 11, fontWeight: FontWeight.w900,
                          color: sel ? Colors.white : _txt(context))),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Token joueur sur le terrain ───────────────────────────────────────────────

class _PlayerToken extends StatelessWidget {
  final TeamMember? member;
  final Color teamColor;
  final bool isSelected;
  const _PlayerToken({this.member, required this.teamColor, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final initials = member != null
        ? member!.name.split(' ').map((w) => w[0]).take(2).join()
        : '?';
    final firstName = member?.name.split(' ').first ?? '—';
    final posColor = member?.position.color ?? teamColor;

    return SizedBox(
      width: 64,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 54 : 48,
          height: isSelected ? 54 : 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: isSelected ? const Color(0xFFFFD700) : posColor,
              width: isSelected ? 3.5 : 2.5,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.7),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: member?.avatarUrl.isNotEmpty == true
                ? Image.network(
                    member!.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initialsWidget(initials, posColor),
                  )
                : _initialsWidget(initials, posColor),
          ),
        ),
        const SizedBox(height: 5),
        // Nom + badge position
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 62),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFD700)
                  : Colors.black.withOpacity(0.72),
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? null
                  : Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
            ),
            child: Text(
              firstName,
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 7.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (member != null) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: posColor.withOpacity(0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                member!.position.short,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 6,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _initialsWidget(String txt, Color color) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withOpacity(0.3), color.withOpacity(0.15)],
      ),
    ),
    child: Center(child: Text(txt,
        style: GoogleFonts.orbitron(
            fontSize: 13, fontWeight: FontWeight.w900, color: color))),
  );
}

// ── Sheet remplacement ────────────────────────────────────────────────────────

class _SubstitutionSheet extends StatelessWidget {
  final List<TeamMember> bench;
  final TeamMember? currentPlayer;
  final Color teamColor;
  final ValueChanged<TeamMember> onSelect;
  const _SubstitutionSheet({
    required this.bench, required this.currentPlayer,
    required this.teamColor, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20,
          MediaQuery.of(context).padding.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(child: Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: _sub(context).withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        )),
        const SizedBox(height: 16),

        // Titre avec joueur actuel
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: _kGreen.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.swap_horiz_rounded, color: _kGreen, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Remplacement',
                  style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.w900, color: _txt(context))),
              if (currentPlayer != null)
                Text('Remplacer ${currentPlayer!.name.split(' ').first}',
                    style: TextStyle(fontSize: 11, color: _sub(context))),
            ]),
          ),
          if (currentPlayer != null)
            _MiniAvatar(member: currentPlayer!, teamColor: teamColor, size: 40),
        ]),
        const SizedBox(height: 16),

        if (bench.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(children: [
              Icon(Icons.sports_soccer_rounded, size: 36, color: _sub(context).withOpacity(0.3)),
              const SizedBox(height: 8),
              Text('Aucun joueur disponible sur le banc',
                  style: TextStyle(color: _sub(context), fontSize: 13)),
            ]),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: bench.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = bench[i];
                return GestureDetector(
                  onTap: () => onSelect(m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: _bg(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _sub(context).withOpacity(0.1)),
                    ),
                    child: Row(children: [
                      // Avatar
                      _MiniAvatar(member: m, teamColor: teamColor, size: 48),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.name,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txt(context))),
                        const SizedBox(height: 3),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: m.position.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(m.position.label,
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: m.position.color)),
                          ),
                          const SizedBox(width: 8),
                          Text('${m.age} ans', style: TextStyle(fontSize: 11, color: _sub(context))),
                        ]),
                      ])),
                      // Stats
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Row(children: [
                          Icon(Icons.sports_soccer_rounded, size: 11, color: _sub(context)),
                          const SizedBox(width: 3),
                          Text('${m.goals}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _txt(context))),
                        ]),
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(Icons.assistant_rounded, size: 11, color: _sub(context)),
                          const SizedBox(width: 3),
                          Text('${m.assists}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _txt(context))),
                        ]),
                      ]),
                      const SizedBox(width: 10),
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
      ]),
    );
  }
}

// Mini avatar réutilisable
class _MiniAvatar extends StatelessWidget {
  final TeamMember member;
  final Color teamColor;
  final double size;
  const _MiniAvatar({required this.member, required this.teamColor, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final initials = member.name.split(' ').map((w) => w[0]).take(2).join();
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: member.position.color.withOpacity(0.5), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
      ),
      child: ClipOval(
        child: member.avatarUrl.isNotEmpty
            ? Image.network(member.avatarUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(initials))
            : _fallback(initials),
      ),
    );
  }

  Widget _fallback(String initials) => Container(
    color: teamColor.withOpacity(0.15),
    child: Center(child: Text(initials,
        style: GoogleFonts.orbitron(fontSize: size * 0.25, fontWeight: FontWeight.w900, color: teamColor))),
  );
}

// ── _MiniPitchPainter ─────────────────────────────────────────────────────────
class _MiniPitchPainter extends CustomPainter {
  final String formation;
  final bool selected;
  const _MiniPitchPainter({required this.formation, required this.selected});

  static const Map<String, List<List<double>>> _fDots = {
    '4-3-3': [[.5,.92],[.2,.72],[.4,.72],[.6,.72],[.8,.72],[.25,.5],[.5,.5],[.75,.5],[.2,.2],[.5,.15],[.8,.2]],
    '4-4-2': [[.5,.92],[.2,.72],[.4,.72],[.6,.72],[.8,.72],[.15,.48],[.38,.48],[.62,.48],[.85,.48],[.35,.18],[.65,.18]],
    '4-2-3-1': [[.5,.92],[.2,.72],[.4,.72],[.6,.72],[.8,.72],[.35,.55],[.65,.55],[.2,.32],[.5,.28],[.8,.32],[.5,.1]],
    '3-5-2': [[.5,.92],[.25,.72],[.5,.68],[.75,.72],[.1,.45],[.3,.42],[.5,.4],[.7,.42],[.9,.45],[.35,.15],[.65,.15]],
    '3-4-3': [[.5,.92],[.25,.72],[.5,.68],[.75,.72],[.15,.48],[.4,.45],[.6,.45],[.85,.48],[.2,.18],[.5,.12],[.8,.18]],
    '5-3-2': [[.5,.92],[.1,.7],[.3,.68],[.5,.65],[.7,.68],[.9,.7],[.25,.45],[.5,.42],[.75,.45],[.35,.15],[.65,.15]],
    '5-4-1': [[.5,.92],[.1,.7],[.3,.68],[.5,.65],[.7,.68],[.9,.7],[.15,.45],[.38,.42],[.62,.42],[.85,.45],[.5,.1]],
    '4-1-4-1': [[.5,.92],[.2,.72],[.4,.72],[.6,.72],[.8,.72],[.5,.58],[.1,.4],[.35,.38],[.65,.38],[.9,.4],[.5,.1]],
    '4-3-2-1': [[.5,.92],[.2,.72],[.4,.72],[.6,.72],[.8,.72],[.25,.52],[.5,.5],[.75,.52],[.35,.28],[.65,.28],[.5,.1]],
    '4-5-1': [[.5,.92],[.2,.72],[.4,.72],[.6,.72],[.8,.72],[.1,.45],[.3,.42],[.5,.4],[.7,.42],[.9,.45],[.5,.1]],
    '3-6-1': [[.5,.92],[.25,.72],[.5,.68],[.75,.72],[.1,.45],[.28,.42],[.46,.4],[.54,.4],[.72,.42],[.9,.45],[.5,.1]],
    '4-4-1-1': [[.5,.92],[.2,.72],[.4,.72],[.6,.72],[.8,.72],[.15,.5],[.38,.48],[.62,.48],[.85,.5],[.5,.28],[.5,.1]],
    '4-2-4': [[.5,.92],[.2,.72],[.4,.72],[.6,.72],[.8,.72],[.35,.52],[.65,.52],[.15,.2],[.38,.18],[.62,.18],[.85,.2]],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = selected ? const Color(0xFF145A32) : const Color(0xFF1B5E20);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)), bg);

    final line = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), line);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.height * 0.1, line);

    final gw = size.width * 0.35;
    final gh = size.height * 0.06;
    canvas.drawRect(Rect.fromLTWH((size.width - gw) / 2, 0, gw, gh), line);
    canvas.drawRect(Rect.fromLTWH((size.width - gw) / 2, size.height - gh, gw, gh), line);

    final dots = _fDots[formation] ?? _fDots['4-3-3']!;
    final dot = Paint()..color = selected ? Colors.white : Colors.white.withOpacity(0.85);
    for (final d in dots) {
      canvas.drawCircle(Offset(d[0] * size.width, d[1] * size.height), 2.2, dot);
    }
  }

  @override
  bool shouldRepaint(_MiniPitchPainter old) => old.formation != formation || old.selected != selected;
}

// ── _GrassPainter ─────────────────────────────────────────────────────────────
class _GrassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const stripeCount = 10;
    final w = size.width / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      final paint = Paint()
        ..color = i.isEven ? const Color(0xFF1B5E20) : const Color(0xFF1A5C1E);
      canvas.drawRect(Rect.fromLTWH(i * w, 0, w, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_GrassPainter _) => false;
}

// ── _ModernPitchPainter ───────────────────────────────────────────────────────
class _ModernPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Bordure
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p);

    // Ligne médiane
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), p);

    // Cercle central
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.1, p);
    canvas.drawCircle(Offset(w / 2, h / 2), 2, Paint()..color = Colors.white.withOpacity(0.55));

    // Surface de réparation haut
    final bw = w * 0.55;
    final bh = h * 0.14;
    canvas.drawRect(Rect.fromLTWH((w - bw) / 2, 0, bw, bh), p);

    // Surface de réparation bas
    canvas.drawRect(Rect.fromLTWH((w - bw) / 2, h - bh, bw, bh), p);

    // Petite surface haut
    final sw = w * 0.3;
    final sh = h * 0.07;
    canvas.drawRect(Rect.fromLTWH((w - sw) / 2, 0, sw, sh), p);

    // Petite surface bas
    canvas.drawRect(Rect.fromLTWH((w - sw) / 2, h - sh, sw, sh), p);

    // Arc surface haut
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w / 2, bh), width: w * 0.3, height: h * 0.1),
      3.14, 3.14, false, p,
    );

    // Arc surface bas
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w / 2, h - bh), width: w * 0.3, height: h * 0.1),
      0, 3.14, false, p,
    );

    // Buts haut
    final gw = w * 0.2;
    final gh = h * 0.025;
    canvas.drawRect(Rect.fromLTWH((w - gw) / 2, -gh, gw, gh), p);

    // Buts bas
    canvas.drawRect(Rect.fromLTWH((w - gw) / 2, h, gw, gh), p);

    // Coins
    for (final corner in [
      Offset(0, 0), Offset(w, 0), Offset(0, h), Offset(w, h)
    ]) {
      final startAngle = corner == Offset(0, 0) ? 0.0
          : corner == Offset(w, 0) ? 1.57
          : corner == Offset(0, h) ? -1.57
          : 3.14;
      canvas.drawArc(
        Rect.fromCenter(center: corner, width: w * 0.06, height: w * 0.06),
        startAngle, 1.57, false, p,
      );
    }
  }

  @override
  bool shouldRepaint(_ModernPitchPainter _) => false;
}
