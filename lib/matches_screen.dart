import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final MatchService _matchService = MatchService();
  final TeamService _teamService = TeamService();
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedTab = 0;

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
        zone: _selectedZone == 'Toutes' ? '' : _selectedZone,
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tabs = ['Mes Matchs', 'Organiser'];
    if (auth.user?.isCaptain == true) {
      tabs.add('Demandes');
    }
    
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
    if (auth.user?.teamId == null) {
      return const Center(child: Text('Vous devez avoir une équipe pour voir les demandes.'));
    }
    return FutureBuilder<List<dynamic>>(
      future: _matchService.getPendingChallenges(auth.token!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _kGreen));
        final challenges = snapshot.data ?? [];
        if (challenges.isEmpty) return const Center(child: Text('Aucune demande en attente.'));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: challenges.length,
          itemBuilder: (context, i) => _buildChallengeCard(challenges[i], auth),
        );
      },
    );
  }

  Widget _buildChallengeCard(dynamic challenge, AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _LogoCircle(url: challenge['fromTeam']['logoUrl'] ?? '', size: 50, color: _kGreen),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge['fromTeam']['name'],
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _txt(context)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Format: ${challenge['format']} · ${challenge['zone'] ?? 'Dakar'}',
                      style: TextStyle(color: _sub(context), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bg(context).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: _kGreen),
                const SizedBox(width: 8),
                Text(
                  _formatMatchDate(challenge['date']),
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _txt(context)),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time_rounded, size: 16, color: _kGreen),
                const SizedBox(width: 6),
                Text(
                  challenge['time'] ?? '16:00',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _txt(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Refuser',
                  Colors.redAccent,
                  () => _respondChallenge(challenge['id'], auth, false),
                  isOutline: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Accepter',
                  _kGreen,
                  () => _respondChallenge(challenge['id'], auth, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap, {bool isOutline = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isOutline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(14),
          border: isOutline ? Border.all(color: color.withOpacity(0.3), width: 2) : null,
          boxShadow: isOutline ? null : [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isOutline ? color : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _respondChallenge(String id, AuthProvider auth, bool accept) async {
    try {
      await _matchService.respondChallenge(auth.token!, id, accept);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(accept ? 'Défi accepté !' : 'Défi refusé.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
        _buildFilterOption('Tigres FC', '3759eb5a-dc92-4958-afd6-7e7c0624bf7e'),
        _buildFilterOption('Plateau Stars', 'c84d2cd8-1552-49bc-be97-b9f13b152b87'),
        _buildFilterOption('Aigles de Pikine', '5ea4fffb-b7b0-4556-a943-cbf524992a20'),
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
            if (Provider.of<AuthProvider>(context, listen: false).user?.isCaptain == true)
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

class _TeamProfilePage extends StatelessWidget {
  final dynamic team;
  const _TeamProfilePage({required this.team});

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _bg(context), appBar: AppBar(title: Text(team['name'], style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.w800)), centerTitle: true), body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      Center(child: _LogoCircle(url: team['logoUrl'] ?? '', size: 100, color: _kGreen)),
      const SizedBox(height: 16),
      Text(team['name'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _txt(context))),
      Text(team['zone'], style: TextStyle(color: _sub(context), fontSize: 14)),
      const SizedBox(height: 32),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _buildStatItem(context, 'Pts', '${team['pts'] ?? 0}'),
        _buildStatItem(context, 'MJ', '${team['j'] ?? 0}'),
        _buildStatItem(context, 'V', '${team['g'] ?? 0}'),
        _buildStatItem(context, 'D', '${team['p'] ?? 0}'),
      ]),
      const SizedBox(height: 40),
      Text('Historique des matchs à venir...', style: TextStyle(color: _sub(context), fontStyle: FontStyle.italic)),
    ])));
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _kGreen)),
      Text(label, style: TextStyle(fontSize: 11, color: _sub(context), fontWeight: FontWeight.w700)),
    ]);
  }
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
    
    setState(() => _isLoading = true);
    try {
      final matchService = MatchService();
      final dt = DateTime(_date.year, _date.month, _date.day, _startH, _startM);
      await matchService.sendChallenge(
        token: auth.token!,
        fromTeamId: auth.user!.teamId!,
        opponentTeamId: widget.opponent['id'],
        date: dt.toIso8601String(),
        format: _format,
        terrainId: _selectedTerrain!.id,
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
