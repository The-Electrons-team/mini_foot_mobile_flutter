import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/match_service.dart';
import 'services/team_service.dart';
import 'providers/auth_provider.dart';
import 'providers/terrain_provider.dart';
import 'terrain_data.dart';
import 'package:intl/date_symbol_data_local.dart';

const Color _kGreen = Color(0xFF006F39);

// Helpers pour le thème (identiques à match_screen.dart)
bool  _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c)    => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c)  => Theme.of(c).cardColor;
Color _txt(BuildContext c)   => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)   => _isDark(c)
    ? const Color(0xFFF0EBE0).withOpacity(0.5)
    : Colors.black.withOpacity(0.45);

class MatchesScreen extends StatefulWidget {
  /// Index de l'onglet à afficher au démarrage.
  /// 0 = Mes Matchs, 1 = Organiser, 2 = Demandes
  final int initialTab;

  const MatchesScreen({super.key, this.initialTab = 0});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final MatchService _matchService = MatchService();
  final TeamService _teamService = TeamService();
  final TextEditingController _searchCtrl = TextEditingController();
  late int _selectedTab;

  // Pagination & Filtres pour Résultats
  final ScrollController _scrollCtrl = ScrollController();
  List<dynamic> _results = [];
  int _page = 1;
  bool _isLoadingResults = false;
  bool _hasMoreResults = true;
  String? _opponentId;
  String? _dateFilter; // YYYY-MM-DD
  
  // États pour l'onglet Organiser
  List<dynamic> _searchTeams = [];
  bool _isLoadingTeams = false;
  String _teamQuery = '';
  String _selectedZone = 'Toutes';
  List<String> _zones = ['Toutes'];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    initializeDateFormatting('fr_FR', null);
    _scrollCtrl.addListener(_onScroll);
    _loadInitialData();
    _loadZones();
    _searchForTeams();
  }

  Future<void> _loadZones() async {
    try {
      final zones = await _teamService.getZones();
      setState(() => _zones = ['Toutes', ...zones]);
    } catch (e) {
      debugPrint('Erreur zones: $e');
    }
  }

  Future<void> _searchForTeams() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isLoadingTeams = true);
    try {
      final teams = await _teamService.searchTeams(
        zone: _selectedZone == 'Toutes' ? null : _selectedZone,
        query: _teamQuery,
        excludeId: auth.user?.teamId,
      );
      setState(() {
        _searchTeams = teams;
        _isLoadingTeams = false;
      });
    } catch (e) {
      setState(() => _isLoadingTeams = false);
      debugPrint('Erreur recherche teams: $e');
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_isLoadingResults && _hasMoreResults && _selectedTab == 0) {
        _loadMoreResults();
      }
    }
  }

  Future<void> _loadInitialData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user?.teamId != null) {
      _loadResults(reset: true);
    }
  }

  Future<void> _loadResults({bool reset = false}) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user?.teamId == null) return;

    if (reset) {
      setState(() {
        _page = 1;
        _results = [];
        _hasMoreResults = true;
      });
    }

    setState(() => _isLoadingResults = true);

    try {
      final newResults = await _matchService.getMyTeamMatches(
        auth.token!,
        auth.user!.teamId!,
        status: 'FINISHED',
        opponentId: _opponentId,
        date: _dateFilter,
        page: _page,
        limit: 10,
      );

      setState(() {
        _results.addAll(newResults);
        _isLoadingResults = false;
        _hasMoreResults = newResults.length == 10;
        _page++;
      });
    } catch (e) {
      setState(() => _isLoadingResults = false);
    }
  }

  void _loadMoreResults() => _loadResults();

  String _formatMatchDate(String? dateStr) {
    if (dateStr == null) return 'Date inconnue';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE d MMM', 'fr_FR').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bgColor = _bg(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildTabs(context),
            Expanded(
              child: _buildBody(auth),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _card(context),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _txt(context)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Matchs', 
                  style: GoogleFonts.orbitron(fontSize: 26, fontWeight: FontWeight.w900, color: _txt(context))),
                Text('Région de Dakar · Saison 2026', 
                  style: TextStyle(fontSize: 12, color: _sub(context), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEECEB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('LIVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final tabs = ['Mes Matchs', 'Organiser', 'Demandes'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _kGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(tabs[i], 
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : _sub(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      )),
                    if (i == 2) // Badge pour Demandes
                      _buildNotificationBadge(),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return Positioned(
      top: -2, right: 4,
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildBody(AuthProvider auth) {
    if (_selectedTab == 2) {
      return _buildDemandesView(auth);
    }
    
    if (_selectedTab == 0) {
      if (auth.user?.teamId == null) {
        return _buildNoTeamState();
      }
      return FutureBuilder<List<dynamic>>(
        future: _matchService.getMyTeamMatches(auth.token!, auth.user!.teamId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _results.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: _kGreen));
          }
          final allMatches = snapshot.data ?? [];
          final activeMatches = allMatches.where((m) => m['status'] != 'FINISHED').toList();
          return _buildMatchesList(context, activeMatches, isMesMatchs: true);
        },
      );
    }

    return _buildOrganizeTab(auth);
  }
  
  Widget _buildOrganizeTab(AuthProvider auth) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.search_rounded, color: _sub(context), size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) {
                      _teamQuery = v;
                      _searchForTeams();
                    },
                    style: TextStyle(fontSize: 14, color: _txt(context)),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une équipe...',
                      hintStyle: TextStyle(color: _sub(context), fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (_teamQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () { _searchCtrl.clear(); setState(() => _teamQuery = ''); _searchForTeams(); },
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
              final selected = _selectedZone == z;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedZone = z);
                  _searchForTeams();
                },
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
              Text('${_searchTeams.length} équipe${_searchTeams.length > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _sub(context))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // ── Liste ──
        Expanded(
          child: _isLoadingTeams 
            ? const Center(child: CircularProgressIndicator(color: _kGreen))
            : _searchTeams.isEmpty
              ? Center(child: Text('Aucune équipe trouvée', style: TextStyle(color: _sub(context))))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: _searchTeams.length,
                  itemBuilder: (_, i) => _TeamRow(
                    team: _searchTeams[i],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _TeamProfilePage(team: _searchTeams[i]))),
                    onChallenge: () => _showChallengeSheet(_searchTeams[i]),
                  ),
                ),
        ),
      ],
    );
  }

  void _showChallengeSheet(dynamic team) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChallengeSheet(opponent: team),
    );
  }

  Widget _buildNoTeamState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_rounded, size: 64, color: _sub(context).withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Vous n\'avez pas encore d\'équipe', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _sub(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandesView(AuthProvider auth) {
    return FutureBuilder<List<dynamic>>(
      future: _loadTeamChallenges(auth),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _kGreen));
        if (snapshot.hasError) return Center(child: Text('Impossible de charger les demandes.', style: TextStyle(color: _sub(context))));
        final challenges = snapshot.data ?? [];
        if (challenges.isEmpty) return const Center(child: Text('Aucune demande.'));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: challenges.length,
          itemBuilder: (context, i) => _buildChallengeCard(challenges[i], auth),
        );
      },
    );
  }

  Future<List<dynamic>> _loadTeamChallenges(AuthProvider auth) async {
    final token = auth.token;
    if (token == null || token.isEmpty) return [];

    var teamId = auth.user?.teamId;
    if (teamId == null || teamId.isEmpty) {
      final teams = await _teamService.getMyTeams(token);
      if (teams.isEmpty) return [];
      final userId = auth.user?.id;
      final captainTeams = teams.where((team) => team['captainId']?.toString() == userId).toList();
      teamId = (captainTeams.isNotEmpty ? captainTeams.first : teams.first)['id']?.toString();
    }
    if (teamId == null || teamId.isEmpty) return [];
    return _matchService.getTeamChallenges(token, teamId);
  }

  Widget _buildChallengeCard(dynamic challenge, AuthProvider auth) {
    final terrain = challenge['terrain'];
    final pricePerHour = (terrain?['pricePerHour'] as num?)?.toInt();
    final halfPrice = pricePerHour != null ? pricePerHour ~/ 2 : null;
    final myTeamId = auth.user?.teamId;
    final outgoing = challenge['direction'] == 'OUTGOING' ||
        (myTeamId != null && challenge['fromTeamId']?.toString() == myTeamId);
    final otherTeam = outgoing ? challenge['toTeam'] : challenge['fromTeam'];
    final status = challenge['status']?.toString() ?? 'PENDING';
    final canRespond = !outgoing && status == 'PENDING';
    final canPay = status == 'ACCEPTED';
    final statusLabel = _challengeStatusLabel(status);
    final statusColor = _challengeStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête équipe ──
          Row(
            children: [
              _LogoCircle(url: otherTeam?['logoUrl'] ?? '', size: 40, color: _kGreen),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(otherTeam?['name']?.toString() ?? 'Équipe',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _txt(context))),
                Text('${outgoing ? 'Défi envoyé' : 'Défie votre équipe'} · ${challenge['format']}',
                    style: TextStyle(color: _sub(context), fontSize: 11)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Date + terrain ──
          Row(children: [
            Icon(Icons.calendar_today, size: 13, color: _sub(context)),
            const SizedBox(width: 5),
            Text(_formatMatchDate(challenge['date']),
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _txt(context))),
            const SizedBox(width: 12),
            if (challenge['time'] != null) ...[
              Icon(Icons.access_time_rounded, size: 13, color: _sub(context)),
              const SizedBox(width: 4),
              Text(challenge['time'].toString(),
                  style: TextStyle(fontSize: 12, color: _sub(context))),
            ],
          ]),
          if (terrain != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.stadium_rounded, size: 13, color: _sub(context)),
              const SizedBox(width: 5),
              Expanded(child: Text(terrain['name']?.toString() ?? '',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: _sub(context)))),
            ]),
          ],
          // ── Bandeau partage 50/50 ──
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.payments_outlined, size: 14, color: _kGreen),
              const SizedBox(width: 6),
              Text(
                halfPrice != null
                    ? 'Chaque équipe paie ${halfPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} FCFA'
                    : 'Frais partagés 50/50',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kGreen),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          // ── Actions ──
          if (canRespond)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton('Refuser', Colors.red,
                    () => _respondChallenge(challenge, auth, false)),
                const SizedBox(width: 8),
                _buildActionButton('Accepter', _kGreen,
                    () => _respondChallenge(challenge, auth, true)),
              ],
            )
          else if (canPay)
            Align(
              alignment: Alignment.centerRight,
              child: _buildActionButton(
                halfPrice != null ? 'Payer ma moitié' : 'Payer',
                _kGreen,
                () => _payChallenge(challenge, auth),
              ),
            )
          else
            Text(
              status == 'PENDING'
                  ? (outgoing ? 'En attente de réponse adverse.' : 'Répondez au défi pour débloquer le paiement.')
                  : 'Paiement indisponible pour ce défi.',
              style: TextStyle(fontSize: 11, color: _sub(context), fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  String _challengeStatusLabel(String status) {
    switch (status) {
      case 'ACCEPTED':
        return 'Accepté';
      case 'REFUSED':
        return 'Refusé';
      default:
        return 'En attente';
    }
  }

  Color _challengeStatusColor(String status) {
    switch (status) {
      case 'ACCEPTED':
        return Colors.green;
      case 'REFUSED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      ),
    );
  }

  Future<void> _respondChallenge(dynamic challenge, AuthProvider auth, bool accept) async {
    try {
      await _matchService.respondChallenge(auth.token!, challenge['id'], accept);
      setState(() {});

      if (!accept) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Défi refusé.')));
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Défi accepté. Le paiement est maintenant disponible.'), backgroundColor: _kGreen));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _payChallenge(dynamic challenge, AuthProvider auth) async {
    try {
      final token = auth.token;
      if (token == null || token.isEmpty) throw Exception('Session expirée');
      final data = await _matchService.getChallengePaymentLink(token, challenge['id'].toString());
      final link = data['link']?.toString();
      if (link == null || link.isEmpty) throw Exception('Lien de paiement indisponible');
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossible d’ouvrir le paiement');
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildMatchesList(BuildContext context, List<dynamic> matches, {bool isMesMatchs = false}) {
    final upcoming = matches.where((m) => m['status'] == 'UPCOMING').toList();
    final live = matches.where((m) => m['status'] == 'LIVE').toList();
    final nextMatch = live.isNotEmpty ? live.first : (upcoming.isNotEmpty ? upcoming.first : null);

    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (nextMatch != null) ...[
          _buildSectionTitle(nextMatch['status'] == 'LIVE' ? 'Match en direct' : 'Prochain match'),
          _buildHeroMatchCard(nextMatch),
          const SizedBox(height: 25),
        ],
        if (upcoming.isNotEmpty) ...[
          _buildSectionTitle('À venir'),
          ...upcoming.skip((live.isEmpty && upcoming.isNotEmpty) ? 1 : 0).map((m) => _buildNormalMatchCard(m)),
          const SizedBox(height: 25),
        ],
        if (isMesMatchs) ...[
          _buildResultsSectionHeader(),
          if (_results.isEmpty && !_isLoadingResults) Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('Aucun résultat trouvé', style: TextStyle(color: _sub(context)))))
          else ..._results.map((m) => _buildResultMatchCard(m)),
          if (_isLoadingResults) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2))),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.w800, color: _kGreen)));
  }

  Widget _buildHeroMatchCard(dynamic match) {
    return Container(
      height: 220,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 10))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(child: Image.network('https://images.unsplash.com/photo-1551958219-acbc608c6377?w=800&q=80', fit: BoxFit.cover)),
            Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.4)], begin: Alignment.bottomCenter, end: Alignment.topCenter)))),
            Padding(padding: const EdgeInsets.all(24), child: Column(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)), child: Text(match['terrain']?['name'] ?? 'Terrain', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _buildHeroTeam(match['home']['name'], match['home']['logoUrl']),
                Column(children: [
                  Text(match['status'] == 'LIVE' ? '${match['homeScore'] ?? 0} : ${match['awayScore'] ?? 0}' : (match['time'] ?? '16:00'), style: GoogleFonts.orbitron(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(_formatMatchDate(match['date']).toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                ]),
                _buildHeroTeam(match['away']['name'], match['away']['logoUrl']),
              ]),
              const Spacer(),
            ])),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroTeam(String name, String? logo) {
    return Column(children: [
      _LogoCircle(url: logo ?? '', size: 50, color: Colors.white),
      const SizedBox(height: 8),
      SizedBox(width: 80, child: Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
    ]);
  }

  Widget _buildNormalMatchCard(dynamic match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Row(children: [
        _buildSmallTeam(match['home']['name'], match['home']['logoUrl'], true),
        Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: _bg(context).withOpacity(0.5), borderRadius: BorderRadius.circular(12)), child: Text(match['time'] ?? '10:00', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: _txt(context)))),
        _buildSmallTeam(match['away']['name'], match['away']['logoUrl'], false),
      ]),
    );
  }

  Widget _buildResultMatchCard(dynamic match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        _buildSmallTeam(match['home']['name'], match['home']['logoUrl'], true),
        Expanded(child: Text('${match['homeScore'] ?? 0} - ${match['awayScore'] ?? 0}', textAlign: TextAlign.center, style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.w900, color: _kGreen))),
        _buildSmallTeam(match['away']['name'], match['away']['logoUrl'], false),
      ]),
    );
  }

  Widget _buildSmallTeam(String name, String? logo, bool isLeft) {
    return Expanded(child: Row(
      mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: isLeft 
        ? [_LogoCircle(url: logo ?? '', size: 32, color: _kGreen), const SizedBox(width: 8), Expanded(child: Text(name, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _txt(context))))]
        : [Expanded(child: Text(name, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _txt(context)))), const SizedBox(width: 8), _LogoCircle(url: logo ?? '', size: 32, color: _kGreen)],
    ));
  }

  Widget _buildResultsSectionHeader() {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('Résultats', style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.w800, color: _kGreen)),
      Row(children: [
        _buildFilterIcon(icon: Icons.calendar_month_rounded, isActive: _dateFilter != null, onTap: _selectDate),
        const SizedBox(width: 8),
        _buildFilterIcon(icon: Icons.shield_outlined, isActive: _opponentId != null, onTap: _showFilterBottomSheet),
      ]),
    ]));
  }

  Widget _buildFilterIcon({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isActive ? _kGreen.withOpacity(0.1) : _card(context), borderRadius: BorderRadius.circular(10), border: Border.all(color: isActive ? _kGreen : _sub(context).withOpacity(0.2))), child: Icon(icon, size: 18, color: isActive ? _kGreen : _sub(context))));
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime(2027), locale: const Locale('fr', 'FR'), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: _kGreen, onPrimary: Colors.white, onSurface: Colors.black87)), child: child!));
    if (picked != null) {
      setState(() {
        _dateFilter = picked.toIso8601String().substring(0, 10);
        _loadResults(reset: true);
      });
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(
      decoration: BoxDecoration(color: _card(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: _sub(context).withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.all(20), child: Text('Filtrer par adversaire', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _txt(context)))),
        _buildFilterOption('Tous les matchs', null),
        ..._searchTeams.map((t) => _buildFilterOption(
          t['name']?.toString() ?? 'Équipe',
          t['id']?.toString(),
        )),
        if (_searchTeams.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('Aucune équipe disponible', style: TextStyle(color: _sub(context), fontSize: 13)),
          ),
        if (_dateFilter != null) ListTile(leading: const Icon(Icons.event_busy_rounded, color: Colors.redAccent), title: const Text('Réinitialiser la date', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)), onTap: () { setState(() { _dateFilter = null; _loadResults(reset: true); }); Navigator.pop(context); }),
        const SizedBox(height: 20),
      ]),
    ));
  }

  Widget _buildFilterOption(String label, String? id) {
    final isSelected = _opponentId == id;
    return ListTile(title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? _kGreen : _txt(context))), trailing: isSelected ? const Icon(Icons.check_circle, color: _kGreen, size: 20) : null, onTap: () { _opponentId = id; _loadResults(reset: true); Navigator.pop(context); });
  }
}

// ── COMPOSANTS ORGANISER ───────────────────────────────────────────────────

class _TeamRow extends StatelessWidget {
  final dynamic team;
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
            _LogoCircle(url: team['logoUrl'] ?? '', color: _kGreen, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(team['name'] ?? '',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txt(context))),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 11, color: _sub(context)),
                      const SizedBox(width: 2),
                      Text(team['zone'] ?? '', style: TextStyle(fontSize: 11, color: _sub(context))),
                      const SizedBox(width: 10),
                      Text('${team['pts'] ?? 0} pts',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kGreen)),
                      const SizedBox(width: 6),
                      Text('${team['j'] ?? 0}J ${team['g'] ?? 0}V ${team['n'] ?? 0}N ${team['p'] ?? 0}D',
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

class _TeamProfilePage extends StatefulWidget {
  final dynamic team;
  const _TeamProfilePage({required this.team});

  @override
  State<_TeamProfilePage> createState() => _TeamProfilePageState();
}

class _TeamProfilePageState extends State<_TeamProfilePage> {
  final TeamService _teamService = TeamService();
  final MatchService _matchService = MatchService();
  late Future<_TeamProfileData> _future;
  String? _selectedCompositionFormat;

  dynamic get team => widget.team;

  @override
  void initState() {
    super.initState();
    _future = _loadProfile();
  }

  Future<_TeamProfileData> _loadProfile() async {
    final auth = context.read<AuthProvider>();
    final teamId = team['id']?.toString();
    dynamic detail = team;
    List<dynamic> matches = [];
    List<dynamic> compositions = [];

    if (teamId != null && teamId.isNotEmpty && auth.token != null) {
      try {
        detail = await _teamService.getTeamDetail(auth.token!, teamId);
      } catch (e) {
        debugPrint('Erreur détail équipe: $e');
      }

      try {
        matches = await _matchService.getMyTeamMatches(
          auth.token!,
          teamId,
          status: 'FINISHED',
          page: 1,
          limit: 5,
        );
      } catch (e) {
        debugPrint('Erreur derniers matchs équipe: $e');
      }

      try {
        compositions = await _teamService.getCompositions(auth.token!, teamId);
      } catch (e) {
        debugPrint('Erreur composition équipe: $e');
      }
    }

    return _TeamProfileData(team: detail, matches: matches, compositions: compositions);
  }

  String _teamName(dynamic value) => value['name']?.toString() ?? 'Équipe';
  String _teamZone(dynamic value) => value['zone']?.toString() ?? '';
  String _teamAddress(dynamic value) => value['address']?.toString() ?? '';
  String _teamLogo(dynamic value) => value['logoUrl']?.toString() ?? '';

  Color _teamColor(dynamic value) {
    final raw = value['color']?.toString();
    if (raw == null || raw.isEmpty) return _kGreen;
    try {
      var hex = raw.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return _kGreen;
    }
  }

  int _intValue(dynamic value, String key) {
    final raw = value[key];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  List<dynamic> _activeMembers(dynamic value) {
    final members = value['members'];
    if (members is! List) return [];
    return members.where((m) => m['status'] == null || m['status'] == 'ACTIVE').toList();
  }

  dynamic _memberById(List<dynamic> members, String? memberId) {
    if (memberId == null) return null;
    for (final member in members) {
      if (member['id']?.toString() == memberId) return member;
    }
    return null;
  }

  int _compositionPlayerCount(dynamic composition) {
    final lineup = composition?['lineup'];
    if (lineup is List) {
      for (final entry in lineup) {
        if ((entry['slot'] as num?)?.toInt() == -1) {
          return (entry['playerCount'] as num?)?.toInt() ?? 5;
        }
      }
      return lineup.where((entry) => (entry['slot'] as num?)?.toInt() != -1).length;
    }
    return 0;
  }

  List<dynamic> _compositionSlots(dynamic composition) {
    final lineup = composition?['lineup'];
    if (lineup is! List) return [];
    final slots = lineup.where((entry) => (entry['slot'] as num?)?.toInt() != -1).toList();
    slots.sort((a, b) => ((a['slot'] as num?)?.toInt() ?? 0).compareTo((b['slot'] as num?)?.toInt() ?? 0));
    return slots;
  }

  dynamic _selectedComposition(List<dynamic> compositions) {
    if (compositions.isEmpty) return null;
    final sorted = [...compositions];
    sorted.sort((a, b) => _compositionPlayerCount(a).compareTo(_compositionPlayerCount(b)));
    final availableFormats = sorted.map((c) => c['format']?.toString() ?? '').where((f) => f.isNotEmpty).toList();
    final selectedFormat = availableFormats.contains(_selectedCompositionFormat)
        ? _selectedCompositionFormat!
        : availableFormats.first;
    return sorted.firstWhere(
      (c) => c['format']?.toString() == selectedFormat,
      orElse: () => sorted.first,
    );
  }

  List<dynamic> _remainingMembers(List<dynamic> members, dynamic composition) {
    final usedIds = _compositionSlots(composition)
        .map((slot) => slot['memberId']?.toString())
        .whereType<String>()
        .toSet();
    return members.where((member) => !usedIds.contains(member['id']?.toString())).toList();
  }

  String _memberName(dynamic member) {
    final user = member['user'];
    if (user is Map) {
      final firstName = user['firstName']?.toString() ?? '';
      final lastName = user['lastName']?.toString() ?? '';
      final fullName = '$firstName $lastName'.trim();
      if (fullName.isNotEmpty) return fullName;
      if (user['name'] != null) return user['name'].toString();
    }
    return 'Joueur';
  }

  String _memberAvatar(dynamic member) {
    final user = member['user'];
    if (user is Map) return user['avatarUrl']?.toString() ?? '';
    return '';
  }

  String _positionLabel(dynamic value) {
    switch (value?.toString()) {
      case 'GARDIEN':
        return 'Gardien';
      case 'DEFENSEUR':
        return 'Défenseur';
      case 'ATTAQUANT':
        return 'Attaquant';
      case 'MILIEU':
        return 'Milieu';
      default:
        return 'Joueur';
    }
  }

  String _positionShort(dynamic value) {
    switch (value?.toString()) {
      case 'GARDIEN':
        return 'GB';
      case 'DEFENSEUR':
        return 'DEF';
      case 'ATTAQUANT':
        return 'ATT';
      case 'MILIEU':
        return 'MIL';
      default:
        return 'J';
    }
  }

  Color _positionColor(dynamic value) {
    switch (value?.toString()) {
      case 'GARDIEN':
        return const Color(0xFFE6A800);
      case 'DEFENSEUR':
        return const Color(0xFF1565C0);
      case 'ATTAQUANT':
        return const Color(0xFFB71C1C);
      case 'MILIEU':
        return _kGreen;
      default:
        return _kGreen;
    }
  }

  String _statusLabel(dynamic match) {
    switch (match['status']?.toString()) {
      case 'LIVE':
        return 'En direct';
      case 'FINISHED':
        return 'Terminé';
      default:
        return 'À venir';
    }
  }

  Color _statusColor(dynamic match) {
    switch (match['status']?.toString()) {
      case 'LIVE':
        return Colors.redAccent;
      case 'FINISHED':
        return Colors.grey;
      default:
        return _kGreen;
    }
  }

  String _formatProfileMatchDate(String? dateStr) {
    if (dateStr == null) return 'Date inconnue';
    try {
      return DateFormat('EEE d MMM', 'fr_FR').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  void _showChallengeSheet(dynamic opponent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChallengeSheet(opponent: opponent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _bg(context),
        elevation: 0,
        foregroundColor: _txt(context),
        title: Text(
          _teamName(team),
          style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<_TeamProfileData>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data ?? _TeamProfileData(team: team, matches: const [], compositions: const []);
          final currentTeam = data.team;
          final members = _activeMembers(currentTeam);
          final matches = data.matches.take(5).toList();
          final selectedComposition = _selectedComposition(data.compositions);
          final remainingMembers = _remainingMembers(members, selectedComposition);

          return RefreshIndicator(
            color: _kGreen,
            onRefresh: () async {
              setState(() => _future = _loadProfile());
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _buildHeader(currentTeam, snapshot.connectionState == ConnectionState.waiting),
                const SizedBox(height: 18),
                _buildStats(currentTeam),
                const SizedBox(height: 18),
                _buildRankings(currentTeam),
                const SizedBox(height: 22),
                _buildCompositionSelector(currentTeam, members, data.compositions),
                const SizedBox(height: 22),
                _buildSectionTitle('Joueurs restants', '${remainingMembers.length} joueur${remainingMembers.length > 1 ? 's' : ''}'),
                const SizedBox(height: 10),
                if (remainingMembers.isEmpty)
                  _buildEmptyState(Icons.people_outline_rounded, 'Tous les joueurs disponibles sont dans cette composition')
                else
                  ...remainingMembers.map(_buildPlayerRow),
                const SizedBox(height: 22),
                _buildSectionTitle('5 derniers matchs', matches.isEmpty ? 'Aucun historique' : null),
                const SizedBox(height: 10),
                if (matches.isEmpty)
                  _buildEmptyState(Icons.sports_soccer_rounded, 'Aucun match récent trouvé')
                else
                  ...matches.map((m) => _buildLastMatchRow(m, currentTeam)),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => _showChallengeSheet(currentTeam),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: _kGreen,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Text(
                      'Défier ${_teamName(currentTeam)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(dynamic currentTeam, bool isLoading) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(22)),
    child: Row(children: [
      _LogoCircle(url: _teamLogo(currentTeam), size: 78, color: _kGreen),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_teamName(currentTeam), style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: _txt(context))),
        const SizedBox(height: 5),
        Row(children: [
          Icon(Icons.location_on_rounded, size: 14, color: _sub(context)),
          const SizedBox(width: 4),
          Expanded(child: Text(_teamAddress(currentTeam).isNotEmpty ? _teamAddress(currentTeam) : _teamZone(currentTeam), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: _sub(context), fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: _kGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(_teamZone(currentTeam), style: const TextStyle(fontSize: 11, color: _kGreen, fontWeight: FontWeight.w800)),
        ),
      ])),
      if (isLoading) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2)),
    ]),
  );

  Widget _buildStats(dynamic currentTeam) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _buildStatItem('Pts', '${_intValue(currentTeam, 'pts')}'),
      _buildStatItem('MJ', '${_intValue(currentTeam, 'j')}'),
      _buildStatItem('V', '${_intValue(currentTeam, 'g')}'),
      _buildStatItem('N', '${_intValue(currentTeam, 'n')}'),
      _buildStatItem('D', '${_intValue(currentTeam, 'p')}'),
    ]),
  );

  Widget _buildStatItem(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kGreen)),
    const SizedBox(height: 3),
    Text(label, style: TextStyle(fontSize: 10, color: _sub(context), fontWeight: FontWeight.w800)),
  ]);

  Widget _buildRankings(dynamic currentTeam) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _buildSectionTitle('Classements', null),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _buildRankingCard('Général', '#${currentTeam['globalRank'] ?? '-'}', Icons.public_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _buildRankingCard(_teamZone(currentTeam), '#${currentTeam['zoneRank'] ?? '-'}', Icons.map_rounded)),
    ]),
  ]);

  Widget _buildRankingCard(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: _kGreen.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 18, color: _kGreen)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.w900, color: _txt(context))),
        const SizedBox(height: 2),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _sub(context))),
      ])),
    ]),
  );

  Widget _buildCompositionSelector(dynamic currentTeam, List<dynamic> members, List<dynamic> compositions) {
    final sorted = [...compositions];
    sorted.sort((a, b) => _compositionPlayerCount(a).compareTo(_compositionPlayerCount(b)));
    if (sorted.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildSectionTitle('Composition', 'Aucun format'),
        const SizedBox(height: 10),
        _buildEmptyState(Icons.grid_view_rounded, 'Aucune composition enregistrée pour cette équipe'),
      ]);
    }

    final availableFormats = sorted.map((c) => c['format']?.toString() ?? '').where((f) => f.isNotEmpty).toList();
    final selectedFormat = availableFormats.contains(_selectedCompositionFormat)
        ? _selectedCompositionFormat!
        : availableFormats.first;
    final selected = sorted.firstWhere(
      (c) => c['format']?.toString() == selectedFormat,
      orElse: () => sorted.first,
    );
    final formation = selected?['formation']?.toString() ?? '';
    final slots = _compositionSlots(selected);
    final playerCount = _compositionPlayerCount(selected);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Composition', '$formation · ${playerCount}v$playerCount'),
      const SizedBox(height: 10),
      _buildFormatButtons(sorted, selectedFormat),
      const SizedBox(height: 10),
      if (formation.isEmpty || slots.isEmpty)
        _buildEmptyState(Icons.grid_view_rounded, 'Composition vide pour ce format')
      else
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _card(context),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: _CompositionPreview(
            formation: formation,
            slots: slots,
            members: members,
            teamColor: _teamColor(currentTeam),
            memberById: (memberId) => _memberById(members, memberId),
            memberName: _memberName,
            memberAvatar: _memberAvatar,
            isCaptain: (member) => member['isCaptain'] == true,
            positionLabel: _positionLabel,
            positionShort: _positionShort,
            positionColor: _positionColor,
          ),
        ),
    ]);
  }

  Widget _buildFormatButtons(List<dynamic> compositions, String selectedFormat) => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: compositions.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, index) {
        final composition = compositions[index];
        final format = composition['format']?.toString() ?? '';
        final formation = composition['formation']?.toString() ?? '';
        final selected = format == selectedFormat;
        return GestureDetector(
          onTap: () => setState(() => _selectedCompositionFormat = format),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? _kGreen : _card(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? _kGreen : _sub(context).withOpacity(0.2)),
              boxShadow: selected ? [BoxShadow(color: _kGreen.withOpacity(0.3), blurRadius: 6)] : null,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(format, style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.w900, color: selected ? Colors.white : _txt(context))),
              const SizedBox(height: 2),
              Text(formation, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: selected ? Colors.white.withOpacity(0.78) : _sub(context))),
            ]),
          ),
        );
      },
    ),
  );

  Widget _buildSectionTitle(String title, String? trailing) => Row(children: [
    Text(title, style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.w800, color: _kGreen)),
    const Spacer(),
    if (trailing != null) Text(trailing, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _sub(context))),
  ]);

  Widget _buildPlayerRow(dynamic member) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _card(context),
      borderRadius: BorderRadius.circular(16),
      border: member['isCaptain'] == true ? Border.all(color: const Color(0xFFE6A800).withOpacity(0.45)) : null,
    ),
    child: Row(children: [
      Stack(clipBehavior: Clip.none, children: [
        _LogoCircle(url: _memberAvatar(member), size: 42, color: member['isCaptain'] == true ? const Color(0xFFE6A800) : _kGreen),
        if (member['isCaptain'] == true)
          Positioned(
            top: -7,
            right: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 4)],
              ),
              child: const Text('C', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black)),
            ),
          ),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(_memberName(member), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context)))),
          if (member['isCaptain'] == true) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFFFD700).withOpacity(0.16), borderRadius: BorderRadius.circular(10)), child: const Text('Capitaine', style: TextStyle(fontSize: 9, color: Color(0xFFE6A800), fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 5),
        Text(_positionLabel(member['position']),
            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: _sub(context), fontWeight: FontWeight.w600)),
      ])),
    ]),
  );

  Widget _buildLastMatchRow(dynamic match, dynamic currentTeam) {
    final home = match['home'];
    final away = match['away'];
    final homeName = home?['name']?.toString() ?? 'Domicile';
    final awayName = away?['name']?.toString() ?? 'Extérieur';
    final isFinished = match['status'] == 'FINISHED';
    final score = isFinished ? '${match['homeScore'] ?? 0} - ${match['awayScore'] ?? 0}' : (match['time']?.toString() ?? '--:--');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusColor(match), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(_statusLabel(match), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _statusColor(match))),
          const Spacer(),
          Text(_formatProfileMatchDate(match['date']?.toString()), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _sub(context))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildMatchTeam(homeName, home?['logoUrl']?.toString() ?? '', true)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(score, style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.w900, color: _txt(context))),
          ),
          Expanded(child: _buildMatchTeam(awayName, away?['logoUrl']?.toString() ?? '', false)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.stadium_rounded, size: 13, color: _sub(context)),
          const SizedBox(width: 5),
          Expanded(child: Text(match['terrain']?['name']?.toString() ?? 'Terrain à confirmer', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: _sub(context)))),
        ]),
      ]),
    );
  }

  Widget _buildMatchTeam(String name, String logo, bool isLeft) => Row(
    mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
    children: isLeft
        ? [_LogoCircle(url: logo, size: 30, color: _kGreen), const SizedBox(width: 7), Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _txt(context))))]
        : [Expanded(child: Text(name, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _txt(context)))), const SizedBox(width: 7), _LogoCircle(url: logo, size: 30, color: _kGreen)],
  );

  Widget _buildEmptyState(IconData icon, String label) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      Icon(icon, size: 22, color: _sub(context)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _sub(context)))),
    ]),
  );
}

class _TeamProfileData {
  final dynamic team;
  final List<dynamic> matches;
  final List<dynamic> compositions;

  const _TeamProfileData({required this.team, required this.matches, required this.compositions});
}

class _CompositionPreview extends StatelessWidget {
  final String formation;
  final List<dynamic> slots;
  final List<dynamic> members;
  final Color teamColor;
  final dynamic Function(String? memberId) memberById;
  final String Function(dynamic member) memberName;
  final String Function(dynamic member) memberAvatar;
  final bool Function(dynamic member) isCaptain;
  final String Function(dynamic value) positionLabel;
  final String Function(dynamic value) positionShort;
  final Color Function(dynamic value) positionColor;

  const _CompositionPreview({
    required this.formation,
    required this.slots,
    required this.members,
    required this.teamColor,
    required this.memberById,
    required this.memberName,
    required this.memberAvatar,
    required this.isCaptain,
    required this.positionLabel,
    required this.positionShort,
    required this.positionColor,
  });

  List<Offset> _positions() {
    final parts = formation.split('-').map((p) => int.tryParse(p) ?? 0).where((p) => p > 0).toList();
    final positions = <Offset>[const Offset(0.5, 0.90)];
    final lineCount = parts.length;
    final step = lineCount > 1 ? 0.58 / (lineCount - 1) : 0.0;
    for (var line = 0; line < parts.length; line++) {
      final count = parts[line];
      final y = 0.72 - line * (lineCount > 1 ? step : 0.29);
      for (var i = 0; i < count; i++) {
        positions.add(Offset((i + 1) / (count + 1), y));
      }
    }
    return positions;
  }

  @override
  Widget build(BuildContext context) {
    final positions = _positions();
    return AspectRatio(
      aspectRatio: 0.70,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _ProfileGrassPainter())),
            Positioned.fill(child: CustomPaint(painter: _ProfilePitchPainter())),
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.58),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Text(
                    formation,
                    style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
            ),
            ...List.generate(positions.length, (i) {
              if (i >= slots.length) return const SizedBox.shrink();
              final pos = positions[i];
              final slot = slots[i];
              final member = memberById(slot['memberId']?.toString());
              return Positioned(
                left: pos.dx * w - 32,
                top: pos.dy * h - 44,
                child: _CompositionToken(
                  member: member,
                  fallback: i == 0 ? 'GB' : '${i + 1}',
                  teamColor: teamColor,
                  memberName: memberName,
                  memberAvatar: memberAvatar,
                  isCaptain: isCaptain,
                  positionLabel: positionLabel,
                  positionShort: positionShort,
                  positionColor: positionColor,
                ),
              );
            }),
          ]);
        }),
      ),
    );
  }
}

class _CompositionToken extends StatelessWidget {
  final dynamic member;
  final String fallback;
  final Color teamColor;
  final String Function(dynamic member) memberName;
  final String Function(dynamic member) memberAvatar;
  final bool Function(dynamic member) isCaptain;
  final String Function(dynamic value) positionLabel;
  final String Function(dynamic value) positionShort;
  final Color Function(dynamic value) positionColor;

  const _CompositionToken({
    required this.member,
    required this.fallback,
    required this.teamColor,
    required this.memberName,
    required this.memberAvatar,
    required this.isCaptain,
    required this.positionLabel,
    required this.positionShort,
    required this.positionColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasMember = member != null;
    final name = hasMember ? memberName(member) : fallback;
    final initials = hasMember
        ? name.split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join().toUpperCase()
        : fallback;
    final firstName = hasMember ? name.split(' ').first : fallback;
    final avatar = hasMember ? memberAvatar(member) : '';
    final posColor = hasMember ? positionColor(member['position']) : teamColor;

    return SizedBox(
      width: 64,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: posColor, width: 2.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.40), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: ClipOval(
                child: avatar.isNotEmpty
                    ? Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initialsWidget(initials, posColor),
                      )
                    : _initialsWidget(initials, posColor),
              ),
            ),
            if (hasMember && isCaptain(member))
              Positioned(
                top: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 4)],
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.star_rounded, size: 8, color: Colors.black),
                    SizedBox(width: 2),
                    Text('C', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black)),
                  ]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          constraints: const BoxConstraints(maxWidth: 62),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.5),
          ),
          child: Text(
            firstName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w900),
          ),
        ),
        if (hasMember) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: posColor.withOpacity(0.85), borderRadius: BorderRadius.circular(4)),
            child: Text(
              positionShort(member['position']),
              style: const TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _initialsWidget(String text, Color color) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withOpacity(0.18), color.withOpacity(0.08)],
      ),
    ),
    child: Center(
      child: Text(
        text,
        style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.w900, color: color),
      ),
    ),
  );
}

class _ProfileGrassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const stripeCount = 10;
    final width = size.width / stripeCount;
    for (var i = 0; i < stripeCount; i++) {
      final paint = Paint()
        ..color = i.isEven ? const Color(0xFF1B5E20) : const Color(0xFF1A5C1E);
      canvas.drawRect(Rect.fromLTWH(i * width, 0, width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_ProfileGrassPainter oldDelegate) => false;
}

class _ProfilePitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p);
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), p);
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.1, p);
    canvas.drawCircle(Offset(w / 2, h / 2), 2, Paint()..color = Colors.white.withOpacity(0.55));

    final boxWidth = w * 0.55;
    final boxHeight = h * 0.14;
    canvas.drawRect(Rect.fromLTWH((w - boxWidth) / 2, 0, boxWidth, boxHeight), p);
    canvas.drawRect(Rect.fromLTWH((w - boxWidth) / 2, h - boxHeight, boxWidth, boxHeight), p);

    final smallWidth = w * 0.3;
    final smallHeight = h * 0.07;
    canvas.drawRect(Rect.fromLTWH((w - smallWidth) / 2, 0, smallWidth, smallHeight), p);
    canvas.drawRect(Rect.fromLTWH((w - smallWidth) / 2, h - smallHeight, smallWidth, smallHeight), p);

    canvas.drawArc(Rect.fromCenter(center: Offset(w / 2, boxHeight), width: w * 0.3, height: h * 0.1), 3.14, 3.14, false, p);
    canvas.drawArc(Rect.fromCenter(center: Offset(w / 2, h - boxHeight), width: w * 0.3, height: h * 0.1), 0, 3.14, false, p);

    final goalWidth = w * 0.2;
    final goalHeight = h * 0.025;
    canvas.drawRect(Rect.fromLTWH((w - goalWidth) / 2, -goalHeight, goalWidth, goalHeight), p);
    canvas.drawRect(Rect.fromLTWH((w - goalWidth) / 2, h, goalWidth, goalHeight), p);
  }

  @override
  bool shouldRepaint(_ProfilePitchPainter oldDelegate) => false;
}

// ── CHALLENGE SHEET ──────────────────────────────────────────────────────────

int _playersForFormat(String fmt) {
  switch (fmt) {
    case '7v7':  return 14;
    case '11v11': return 22;
    default:     return 10; // 5v5
  }
}

int _terrainCapacity(Terrain t) {
  for (final f in t.features) {
    final m = RegExp(r'(\d+) joueurs').firstMatch(f);
    if (m != null) return int.parse(m.group(1)!);
  }
  return 22;
}

class _ChallengeSheet extends StatefulWidget {
  final dynamic opponent;
  const _ChallengeSheet({required this.opponent});
  @override
  State<_ChallengeSheet> createState() => _ChallengeSheetState();
}

class _ChallengeSheetState extends State<_ChallengeSheet> {
  DateTime _date    = DateTime.now().add(const Duration(days: 2));
  String   _format  = '5v5';
  int      _startH  = 16;
  int      _startM  = 0;
  int      _slots   = 4; // 4 × 15 min = 1h

  Terrain? _selectedTerrain;
  List<Terrain> _availableTerrains = [];
  String   _terrainQuery = '';
  final    _terrainCtrl  = TextEditingController();
  bool     _terrainError = false;
  bool     _isLoading = false;
  bool     _isFetchingTerrains = false;

  static const _formats = ['5v5', '7v7', '11v11'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAvailable());
  }

  Future<void> _fetchAvailable() async {
    if (!mounted) return;
    setState(() => _isFetchingTerrains = true);
    try {
      final dateStr = _date.toIso8601String().substring(0, 10);
      final timeStr = '${_startH.toString().padLeft(2, '0')}:${_startM.toString().padLeft(2, '0')}';
      final tp = context.read<TerrainProvider>();
      final available = await tp.loadAvailableTerrains(dateStr, timeStr, _durationMin);
      if (mounted) {
        setState(() {
          _availableTerrains = available;
          _isFetchingTerrains = false;
          // Si le terrain sélectionné n'est plus disponible, on l'enlève
          if (_selectedTerrain != null && !_availableTerrains.any((t) => t.id == _selectedTerrain!.id)) {
            _selectedTerrain = null;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFetchingTerrains = false);
    }
  }

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

  List<Terrain> _getAvailableTerrains(List<Terrain> allTerrains) {
    final needed = _playersForFormat(_format);
    return allTerrains.where((t) {
      final cap   = _terrainCapacity(t);
      final query = _terrainQuery.isEmpty ||
          t.name.toLowerCase().contains(_terrainQuery.toLowerCase()) ||
          t.address.toLowerCase().contains(_terrainQuery.toLowerCase());
      return cap >= needed && query;
    }).toList()..sort((a, b) => b.rating.compareTo(a.rating));
  }

  @override
  void dispose() { _terrainCtrl.dispose(); super.dispose(); }

  Future<void> _submit(AuthProvider auth) async {
    if (_selectedTerrain == null) {
      setState(() => _terrainError = true);
      return;
    }

    final token = auth.token;
    final fromTeamId = await _resolveFromTeamId(auth);
    final opponentTeamId = widget.opponent['id']?.toString();
    final terrainId = _selectedTerrain?.id;
    final terrainName = _selectedTerrain?.name;
    final opponentZone = widget.opponent['zone']?.toString();
    final zone = opponentZone == null || opponentZone.isEmpty ? 'DAKAR' : opponentZone;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session expirée, reconnectez-vous.'), backgroundColor: Colors.red));
      return;
    }
    if (fromTeamId == null || fromTeamId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune équipe active trouvée. Ouvrez la page Équipe puis réessayez.'), backgroundColor: Colors.red));
      return;
    }
    if (opponentTeamId == null || opponentTeamId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Équipe adverse introuvable.'), backgroundColor: Colors.red));
      return;
    }
    if (terrainId == null || terrainId.isEmpty) {
      setState(() => _terrainError = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terrain invalide, choisissez un autre terrain.'), backgroundColor: Colors.red));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final matchService = MatchService();
      final dt = DateTime(_date.year, _date.month, _date.day, _startH, _startM);
      await matchService.sendChallenge(
        token: token,
        fromTeamId: fromTeamId,
        opponentTeamId: opponentTeamId,
        date: dt.toIso8601String(),
        time: '${_startH.toString().padLeft(2, '0')}:${_startM.toString().padLeft(2, '0')}',
        zone: zone,
        format: _format,
        terrainId: terrainId,
        subTerrainId: _selectedTerrain!.subTerrainId,
        terrainName: terrainName,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Défi envoyé avec succès à ${widget.opponent['name']} !'),
          backgroundColor: _kGreen,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _resolveFromTeamId(AuthProvider auth) async {
    final currentTeamId = auth.user?.teamId;
    if (currentTeamId != null && currentTeamId.isNotEmpty) return currentTeamId;

    final token = auth.token;
    if (token == null || token.isEmpty) return null;

    try {
      final teams = await TeamService().getMyTeams(token);
      if (teams.isEmpty) return null;

      final userId = auth.user?.id;
      final captainTeam = teams.cast<dynamic>().where((team) => team['captainId']?.toString() == userId).toList();
      final team = captainTeam.isNotEmpty ? captainTeam.first : teams.first;
      final teamId = team['id']?.toString();
      debugPrint('[ChallengeSheet] teamId récupéré via /teams/mine: $teamId');
      return teamId;
    } catch (e) {
      debugPrint('[ChallengeSheet] Impossible de récupérer mes équipes: $e');
      return null;
    }
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
    final auth = context.read<AuthProvider>();
    
    // Filtrage local supplémentaire si besoin (par nom)
    final filtered = _availableTerrains.where((t) {
      if (_terrainQuery.isEmpty) return true;
      return t.name.toLowerCase().contains(_terrainQuery.toLowerCase()) || 
             t.address.toLowerCase().contains(_terrainQuery.toLowerCase());
    }).toList();

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
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _sub(context).withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                _LogoCircle(url: '', size: 48, color: _kGreen),
                Expanded(child: Column(children: [
                  Text('VS', style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.w900, color: _txt(context))),
                  Text('Challenge', style: TextStyle(fontSize: 10, color: _sub(context))),
                ])),
                _LogoCircle(url: widget.opponent['logoUrl'] ?? '', color: _kGreen, size: 48),
              ],
            ),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text('Mon Équipe', textAlign: TextAlign.left, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _txt(context)))),
              Expanded(child: Text(widget.opponent['name'], textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _txt(context)))),
            ]),
            const SizedBox(height: 20),
            _label(context, 'Format'),
            Row(
              children: _formats.map((f) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() { _format = f; _selectedTerrain = null; _fetchAvailable(); }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: _format == f ? _kGreen : _sub(context).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                    child: Text(f, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _format == f ? Colors.white : _txt(context))),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            _label(context, 'Date'),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 60)), builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _kGreen)), child: child!));
                if (d != null) { setState(() { _date = d; _selectedTerrain = null; }); _fetchAvailable(); }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(color: _sub(context).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, color: _kGreen, size: 18),
                  const SizedBox(width: 10),
                  Text(DateFormat('EEE d MMM', 'fr_FR').format(_date), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _txt(context))),
                  const Spacer(),
                  Icon(Icons.keyboard_arrow_down_rounded, color: _sub(context)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            _label(context, 'Plage horaire'),
            Text('Début', style: TextStyle(fontSize: 11, color: _sub(context))),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _allSlots.length,
                itemBuilder: (_, i) {
                  final s = _allSlots[i];
                  final h = int.parse(s.split(':')[0]);
                  final m = int.parse(s.split(':')[1]);
                  final selected = h == _startH && m == _startM;
                  return GestureDetector(
                    onTap: () => setState(() { _startH = h; _startM = m; _selectedTerrain = null; _fetchAvailable(); }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: selected ? _kGreen : _sub(context).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                      child: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : _txt(context))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text('Durée', style: TextStyle(fontSize: 11, color: _sub(context))),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [1, 2, 3, 4, 6, 8].map((s) {
                  final selected = _slots == s;
                  final label = s == 1 ? '15 min' : s % 4 == 0 ? '${s ~/ 4}h' : '${(s * 15 / 60).toStringAsFixed(2).replaceAll('.', 'h')}';
                  return GestureDetector(
                    onTap: () => setState(() { _slots = s; _selectedTerrain = null; _fetchAvailable(); }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: selected ? _kGreen : _sub(context).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : _txt(context))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: _kGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.access_time_rounded, color: _kGreen, size: 15), const SizedBox(width: 6), Text('${_startH.toString().padLeft(2,'0')}:${_startM.toString().padLeft(2,'0')} → $_endTime  ($_durationMin min)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen))])),
            const SizedBox(height: 16),
            _label(context, 'Terrain', required: true),
            if (_terrainError && _selectedTerrain == null) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('Veuillez sélectionner un terrain', style: TextStyle(fontSize: 11, color: Colors.red.shade400))),
            if (_selectedTerrain != null) GestureDetector(
              onTap: () => setState(() { _selectedTerrain = null; }),
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: _kGreen.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: _kGreen.withOpacity(0.4))),
                child: Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_selectedTerrain!.imageUrl, width: 52, height: 52, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 52, height: 52, color: _kGreen.withOpacity(0.2)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_selectedTerrain!.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _txt(context))),
                    const SizedBox(height: 2),
                    Text(_selectedTerrain!.address, style: TextStyle(fontSize: 11, color: _sub(context))),
                    const SizedBox(height: 2),
                    Text(_selectedTerrain!.priceLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kGreen)),
                  ])),
                  const Icon(Icons.check_circle_rounded, color: _kGreen, size: 20),
                ]),
              ),
            ),
            if (_selectedTerrain == null) ...[
              Container(
                height: 44,
                decoration: BoxDecoration(color: _sub(context).withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: _terrainError ? Border.all(color: Colors.red.shade300) : null),
                child: Row(children: [
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.search_rounded, color: _sub(context), size: 18)),
                  Expanded(child: TextField(controller: _terrainCtrl, onChanged: (v) => setState(() => _terrainQuery = v), style: TextStyle(fontSize: 13, color: _txt(context)), decoration: InputDecoration(hintText: 'Rechercher un terrain disponible...', hintStyle: TextStyle(color: _sub(context), fontSize: 12), border: InputBorder.none))),
                ]),
              ),
              const SizedBox(height: 8),
              Row(children: [Icon(Icons.info_outline_rounded, size: 12, color: _sub(context)), const SizedBox(width: 4), Text('Terrains ≥ ${_playersForFormat(_format)} joueurs', style: TextStyle(fontSize: 10, color: _sub(context)))]),
              const SizedBox(height: 8),
              if (_isFetchingTerrains) 
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2)))
              else if (filtered.isEmpty) 
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _sub(context).withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Center(child: Text('Aucun terrain disponible pour cette plage.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _sub(context), height: 1.5))))
              else ...filtered.map((t) => GestureDetector(
                onTap: () => setState(() { _selectedTerrain = t; _terrainError = false; _terrainCtrl.clear(); _terrainQuery = ''; }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                  child: Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(t.imageUrl, width: 52, height: 52, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 52, height: 52, color: _kGreen.withOpacity(0.15)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _txt(context))),
                      const SizedBox(height: 2),
                      Text(t.address, style: TextStyle(fontSize: 11, color: _sub(context))),
                      const SizedBox(height: 4),
                      Row(children: [Icon(Icons.group_rounded, size: 11, color: _sub(context)), const SizedBox(width: 2), Text('${_terrainCapacity(t)} max', style: TextStyle(fontSize: 10, color: _sub(context))), const SizedBox(width: 10), Text(t.priceLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kGreen))]),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Text('Libre', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.green))),
                  ]),
                ),
              )),
            ],
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _isLoading ? null : () => _submit(auth),
              child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15), decoration: BoxDecoration(color: _selectedTerrain != null ? _kGreen : _sub(context).withOpacity(0.2), borderRadius: BorderRadius.circular(14)), child: _isLoading ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))) : Text('Envoyer le challenge ⚡', textAlign: TextAlign.center, style: TextStyle(color: _selectedTerrain != null ? Colors.white : _sub(context), fontWeight: FontWeight.w800, fontSize: 15))),
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
  const _LogoCircle({required this.url, required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12)),
    child: ClipOval(
      child: url.isNotEmpty ? Image.network(url, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
              child: Text(url.split('/').last.length > 2 ? url.split('/').last.substring(0, 2).toUpperCase() : 'FC',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900,
                      fontSize: size * 0.28))))
          : Center(child: Icon(Icons.shield, color: color, size: size * 0.5)),
    ),
  );
}
