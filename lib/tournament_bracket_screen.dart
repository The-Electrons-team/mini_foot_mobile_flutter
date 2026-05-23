import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/tournament_service.dart';

const Color _kGreen = Color(0xFF006F39);
const Color _kGold  = Color(0xFFE6A800);

Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c)  => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)  => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFFF0EBE0).withOpacity(0.5)
    : Colors.black.withOpacity(0.45);

class TournamentBracketScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final String myTeamName;

  const TournamentBracketScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.myTeamName = '',
  });

  @override
  State<TournamentBracketScreen> createState() => _TournamentBracketScreenState();
}

class _TournamentBracketScreenState extends State<TournamentBracketScreen> {
  final TournamentService _service = TournamentService();
  Map<String, List<dynamic>> _rounds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBracket();
  }

  Future<void> _loadBracket() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _service.getBracket(widget.tournamentId);
      final rawRounds = data['rounds'] as Map<String, dynamic>? ?? {};
      setState(() {
        _rounds = rawRounds.map((key, value) =>
            MapEntry(key, List<dynamic>.from(value as List)));
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kGreen.withOpacity(0.9), _kGreen.withOpacity(0.7)],
        ),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.tournamentName,
            style: GoogleFonts.orbitron(
              fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kGreen));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.withOpacity(0.6)),
        const SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: _sub(context), fontSize: 13)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadBracket,
          style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white),
          child: const Text('Réessayer'),
        ),
      ]));
    }
    if (_rounds.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.sports_soccer_rounded, size: 48, color: _sub(context).withOpacity(0.4)),
        const SizedBox(height: 12),
        Text('Aucun match programmé', style: TextStyle(color: _sub(context), fontSize: 14)),
      ]));
    }

    final roundOrder = _rounds.keys.toList();
    final me = widget.myTeamName;

    const double matchH = 72.0;
    const double matchW = 160.0;
    const double colGap = 40.0;

    final maxMatchesInRound = _rounds.values
        .map((list) => list.length)
        .reduce((a, b) => a > b ? a : b);
    final totalH = maxMatchesInRound * (matchH + 12) + 60;
    final totalW = roundOrder.length * (matchW + colGap);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: SizedBox(
          width: totalW,
          height: totalH,
          child: Stack(
            children: [
              // Round labels
              ...roundOrder.asMap().entries.map((entry) {
                final col = entry.key;
                final roundName = entry.value;
                return Positioned(
                  left: col * (matchW + colGap),
                  top: 0,
                  width: matchW,
                  child: Center(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kGreen.withOpacity(0.2)),
                    ),
                    child: Text(roundName, style: GoogleFonts.orbitron(
                      fontSize: 9, fontWeight: FontWeight.w800, color: _kGreen)),
                  )),
                );
              }),
              // Match cards
              ...roundOrder.asMap().entries.expand((entry) {
                final col = entry.key;
                final matches = _rounds[entry.value]!;
                final spacing = _spacingForRound(col, matchH);
                final colTotalH = matches.length * matchH + (matches.length - 1) * spacing;
                final offsetY = (totalH - 40 - colTotalH) / 2 + 40;

                return matches.asMap().entries.map((mEntry) {
                  final idx = mEntry.key;
                  final match = mEntry.value as Map<String, dynamic>;
                  final y = offsetY + idx * (matchH + spacing);

                  final home = match['home'] as Map<String, dynamic>?;
                  final away = match['away'] as Map<String, dynamic>?;
                  final homeName = home?['name'] ?? 'TBD';
                  final awayName = away?['name'] ?? 'TBD';
                  final homeScore = match['homeScore'] as int?;
                  final awayScore = match['awayScore'] as int?;
                  final played = homeScore != null && awayScore != null;

                  return Positioned(
                    left: col * (matchW + colGap),
                    top: y,
                    child: _BracketCard(
                      homeName: homeName,
                      awayName: awayName,
                      homeScore: homeScore,
                      awayScore: awayScore,
                      played: played,
                      myTeam: me,
                      width: matchW,
                      height: matchH,
                    ),
                  );
                });
              }),
            ],
          ),
        ),
      ),
    );
  }

  double _spacingForRound(int col, double matchH) {
    if (col == 0) return 8.0;
    return matchH * col + 8.0 * (col + 1);
  }
}

class _BracketCard extends StatelessWidget {
  final String homeName, awayName;
  final int? homeScore, awayScore;
  final bool played;
  final String myTeam;
  final double width, height;

  const _BracketCard({
    required this.homeName,
    required this.awayName,
    this.homeScore,
    this.awayScore,
    required this.played,
    required this.myTeam,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final hasMe = homeName == myTeam || awayName == myTeam;
    final homeWin = played && homeScore != null && awayScore != null && homeScore! > awayScore!;
    final awayWin = played && homeScore != null && awayScore != null && awayScore! > homeScore!;

    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasMe ? _kGreen.withOpacity(0.6) : _sub(context).withOpacity(0.12),
          width: hasMe ? 1.5 : 1),
        boxShadow: [BoxShadow(
          color: hasMe ? _kGreen.withOpacity(0.12) : Colors.black.withOpacity(0.07),
          blurRadius: hasMe ? 10 : 6, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        _TeamRow(
          name: homeName, score: homeScore,
          isWinner: homeWin, isMyTeam: homeName == myTeam, isTop: true),
        Container(height: 1, color: _sub(context).withOpacity(0.08)),
        _TeamRow(
          name: awayName, score: awayScore,
          isWinner: awayWin, isMyTeam: awayName == myTeam, isTop: false),
      ]),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String name;
  final int? score;
  final bool isWinner, isMyTeam, isTop;
  const _TeamRow({required this.name, required this.score, required this.isWinner, required this.isMyTeam, required this.isTop});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isWinner ? _kGreen.withOpacity(0.1) : isMyTeam ? _kGreen.withOpacity(0.04) : null,
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
                  ? _sub(context).withOpacity(0.07)
                  : _sub(context).withOpacity(0.1),
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
