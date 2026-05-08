import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import 'team_composition_screen.dart';
import 'matches_screen.dart';
import 'ranking_screen.dart';
import 'team_publications_screen.dart';
import 'team_tournaments_screen.dart';
import 'team_roster_screen.dart';
import 'create_team_screen.dart';
import 'providers/team_provider.dart';
import 'providers/auth_provider.dart';

const Color _kGreen = Color(0xFF006F39);
bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c) => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c) => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c) => _isDark(c)
    ? const Color(0xFFF0EBE0).withOpacity(0.5)
    : Colors.black.withOpacity(0.45);

enum MemberStatus { active, pending }

enum PlayerPosition { gardien, defenseur, milieu, attaquant }

extension PlayerPositionLabel on PlayerPosition {
  String get label {
    switch (this) {
      case PlayerPosition.gardien:
        return 'Gardien';
      case PlayerPosition.defenseur:
        return 'Defenseur';
      case PlayerPosition.milieu:
        return 'Milieu';
      case PlayerPosition.attaquant:
        return 'Attaquant';
    }
  }

  String get short {
    switch (this) {
      case PlayerPosition.gardien:
        return 'GB';
      case PlayerPosition.defenseur:
        return 'DEF';
      case PlayerPosition.milieu:
        return 'MIL';
      case PlayerPosition.attaquant:
        return 'ATT';
    }
  }

  Color get color {
    switch (this) {
      case PlayerPosition.gardien:
        return const Color(0xFFE6A800);
      case PlayerPosition.defenseur:
        return const Color(0xFF1565C0);
      case PlayerPosition.milieu:
        return const Color(0xFF006F39);
      case PlayerPosition.attaquant:
        return const Color(0xFFB71C1C);
    }
  }
}

class TeamMember {
  final String id, name, avatarUrl;
  bool isCaptain;
  MemberStatus status;
  int age, goals, assists, matchesPlayed;
  PlayerPosition position;
  TeamMember({
    required this.id,
    required this.name,
    this.avatarUrl = '',
    this.isCaptain = false,
    this.status = MemberStatus.active,
    this.age = 22,
    this.goals = 0,
    this.assists = 0,
    this.matchesPlayed = 0,
    this.position = PlayerPosition.milieu,
  });
}

class TeamData {
  String id;
  String name, zone, address;
  LatLng? location;
  Color color;
  String? logoPath;
  String inviteCode;
  List<TeamMember> members;
  TeamData({
    required this.id,
    required this.name,
    required this.zone,
    this.address = '',
    this.location,
    required this.color,
    this.logoPath,
    required this.inviteCode,
    required this.members,
  });
}

final teamNotifier = ValueNotifier<TeamData?>(null);

final mockPlayers = [
  TeamMember(
    id: 'p1',
    name: 'Ibrahima Diallo',
    isCaptain: true,
    age: 26,
    goals: 12,
    assists: 5,
    matchesPlayed: 18,
    position: PlayerPosition.milieu,
    avatarUrl:
        'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
  TeamMember(
    id: 'p2',
    name: 'Moussa Ndiaye',
    age: 22,
    goals: 8,
    assists: 3,
    matchesPlayed: 16,
    position: PlayerPosition.attaquant,
    avatarUrl:
        'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
  TeamMember(
    id: 'p3',
    name: 'Cheikh Fall',
    age: 24,
    goals: 0,
    assists: 1,
    matchesPlayed: 17,
    position: PlayerPosition.gardien,
    avatarUrl:
        'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
  TeamMember(
    id: 'p4',
    name: 'Omar Sow',
    age: 23,
    goals: 3,
    assists: 7,
    matchesPlayed: 15,
    position: PlayerPosition.defenseur,
    avatarUrl:
        'https://images.pexels.com/photos/1300402/pexels-photo-1300402.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
  TeamMember(
    id: 'p5',
    name: 'Aliou Badji',
    age: 21,
    goals: 5,
    assists: 4,
    matchesPlayed: 14,
    position: PlayerPosition.milieu,
    avatarUrl:
        'https://images.pexels.com/photos/1043474/pexels-photo-1043474.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
  TeamMember(
    id: 'p6',
    name: 'Pape Gueye',
    age: 25,
    goals: 2,
    assists: 6,
    matchesPlayed: 18,
    position: PlayerPosition.defenseur,
    avatarUrl:
        'https://images.pexels.com/photos/1516680/pexels-photo-1516680.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
  TeamMember(
    id: 'p7',
    name: 'Lamine Camara',
    age: 20,
    goals: 9,
    assists: 2,
    matchesPlayed: 13,
    position: PlayerPosition.attaquant,
    avatarUrl:
        'https://images.pexels.com/photos/1212984/pexels-photo-1212984.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
  TeamMember(
    id: 'p8',
    name: 'Seydou Sarr',
    age: 19,
    goals: 6,
    assists: 3,
    matchesPlayed: 12,
    position: PlayerPosition.attaquant,
    avatarUrl:
        'https://images.pexels.com/photos/1484794/pexels-photo-1484794.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
  TeamMember(
    id: 'p9',
    name: 'Mamadou Diop',
    age: 27,
    goals: 1,
    assists: 0,
    matchesPlayed: 10,
    position: PlayerPosition.defenseur,
    avatarUrl:
        'https://images.pexels.com/photos/1040880/pexels-photo-1040880.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
  TeamMember(
    id: 'p10',
    name: 'Abdou Diatta',
    age: 23,
    goals: 0,
    assists: 2,
    matchesPlayed: 11,
    position: PlayerPosition.defenseur,
    avatarUrl:
        'https://images.pexels.com/photos/1559486/pexels-photo-1559486.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
  TeamMember(
    id: 'p11',
    name: 'Boubacar Traore',
    age: 22,
    goals: 4,
    assists: 5,
    matchesPlayed: 16,
    position: PlayerPosition.milieu,
    avatarUrl:
        'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
  TeamMember(
    id: 'p12',
    name: 'Ismaila Sarr',
    age: 24,
    goals: 7,
    assists: 4,
    matchesPlayed: 15,
    position: PlayerPosition.attaquant,
    avatarUrl:
        'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
  TeamMember(
    id: 'p13',
    name: 'Nicolas Faye',
    age: 21,
    goals: 0,
    assists: 0,
    matchesPlayed: 8,
    position: PlayerPosition.gardien,
    avatarUrl:
        'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
  TeamMember(
    id: 'p14',
    name: 'Krepin Diatta',
    age: 25,
    goals: 5,
    assists: 3,
    matchesPlayed: 14,
    position: PlayerPosition.milieu,
    avatarUrl:
        'https://images.pexels.com/photos/1300402/pexels-photo-1300402.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
  TeamMember(
    id: 'p15',
    name: 'Bamba Dieng',
    age: 23,
    goals: 11,
    assists: 2,
    matchesPlayed: 17,
    position: PlayerPosition.attaquant,
    avatarUrl:
        'https://images.pexels.com/photos/1043474/pexels-photo-1043474.jpeg?auto=compress&cs=tinysrgb&w=200',
  ),
];

//  ENTRY POINT
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = Provider.of<AuthProvider>(context, listen: false);
      final teamProv = Provider.of<TeamProvider>(context, listen: false);

      if (authProv.token != null) {
        teamProv.loadMyTeams(authProv.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamProv = Provider.of<TeamProvider>(context);

    if (teamProv.isLoading && !teamProv.hasLoaded) {
      return const _NoTeamPage(isLoading: true);
    }

    Widget content;
    if (teamProv.myTeams.isEmpty) {
      content = const _NoTeamPage();
    } else {
      content = _MyTeamPage(team: teamProv.myTeams.first);
    }

    return content;
  }
}

//  PAGE : PAS D EQUIPE
class _NoTeamPage extends StatelessWidget {
  final bool isLoading;
  const _NoTeamPage({this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _card(context),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: _txt(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Mon equipe',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _txt(context),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (isLoading)
              const CircularProgressIndicator(color: _kGreen)
            else ...[
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 52,
                  color: _kGreen.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Tu n'as pas encore d'equipe",
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _txt(context),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Cree ton equipe, invite tes joueurs via un lien et commence a defier les autres equipes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: _sub(context),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateTeamScreen()),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: _kGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Creer mon equipe',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

//  PAGE : MON EQUIPE
Color _colorFromHex(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}

PlayerPosition _mapPosition(String? pos) {
  if (pos == null) return PlayerPosition.milieu;
  switch (pos.toUpperCase()) {
    case 'GARDIEN':
      return PlayerPosition.gardien;
    case 'DEFENSEUR':
      return PlayerPosition.defenseur;
    case 'ATTAQUANT':
      return PlayerPosition.attaquant;
    default:
      return PlayerPosition.milieu;
  }
}

class _MyTeamPage extends StatefulWidget {
  final Map<String, dynamic> team;
  const _MyTeamPage({required this.team});
  @override
  State<_MyTeamPage> createState() => _MyTeamPageState();
}

class _MyTeamPageState extends State<_MyTeamPage> {
  Map<String, dynamic> get team => widget.team;

  List<dynamic> get _members => team['members'] ?? [];
  List<dynamic> get _active =>
      _members.where((m) => m['status'] == 'ACTIVE').toList();

  TeamData _toTeamData() {
    final members = _members.map((m) {
      final user = m['user'] ?? m;
      return TeamMember(
        id: m['id'] ?? '',
        name:
            '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                .trim()
                .isNotEmpty
            ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()
            : user['phone'] ?? 'Joueur',
        isCaptain: m['isCaptain'] == true,
        status: m['status'] == 'ACTIVE'
            ? MemberStatus.active
            : MemberStatus.pending,
        avatarUrl: user['avatarUrl'] ?? '',
        goals: m['goals'] ?? 0,
        assists: m['assists'] ?? 0,
        matchesPlayed: m['matchesPlayed'] ?? 0,
        position: _mapPosition(m['position'] ?? user['position']),
      );
    }).toList();

    return TeamData(
      id: team['id'] ?? '',
      name: team['name'] ?? '',
      zone: team['zone'] ?? 'DAKAR',
      address: team['address'] ?? '',
      color: _colorFromHex(team['color'] ?? '#006F39'),
      logoPath: team['logoUrl'],
      inviteCode: team['inviteCode'] ?? '',
      members: members,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: RefreshIndicator(
        onRefresh: () => Provider.of<TeamProvider>(
          context,
          listen: false,
        ).loadMyTeams(Provider.of<AuthProvider>(context, listen: false).token!),
        color: _kGreen,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildGrid(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InviteCard(inviteCode: team['inviteCode'] ?? '---'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final teamColor = _colorFromHex(team['color'] ?? '#006F39');
    final logoUrl = team['logoUrl'];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.pexels.com/photos/12486370/pexels-photo-12486370.jpeg?auto=compress&cs=tinysrgb&w=800',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black87),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC000000),
                    Color(0x99000000),
                    Color(0xDD000000),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateTeamScreen(team: team),
                          ),
                        );
                        if (updated == true && context.mounted) {
                          final auth = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          if (auth.token != null) {
                            await Provider.of<TeamProvider>(
                              context,
                              listen: false,
                            ).loadMyTeams(auth.token!);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Modifier',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                        border: Border.all(color: teamColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: teamColor.withOpacity(0.5),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: logoUrl != null
                          ? ClipOval(
                              child: Image.network(logoUrl, fit: BoxFit.cover),
                            )
                          : Center(
                              child: Text(
                                (team['name'] as String)
                                    .split(' ')
                                    .map((w) => w[0])
                                    .take(2)
                                    .join(),
                                style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: teamColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  team['name'] ?? '',
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Colors.white.withOpacity(0.65),
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        team['address'] ?? team['zone'] ?? 'Dakar',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            Text(
                              '#${team['globalRank'] ?? '-'}',
                              style: GoogleFonts.orbitron(
                                color: const Color(0xFFFFD700),
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${team['pts'] ?? 0} pts',
                              style: TextStyle(
                                color: const Color(
                                  0xFFFFD700,
                                ).withOpacity(0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Rang National',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatDivider(),
                      Expanded(
                        child: _StatPill('Joueurs', '${_active.length}'),
                      ),
                      _StatDivider(),
                      Expanded(child: _StatPill('Matchs', '${team['j'] ?? 0}')),
                      _StatDivider(),
                      Expanded(
                        child: _StatPill('Victoires', '${team['g'] ?? 0}'),
                      ),
                      _StatDivider(),
                      Expanded(
                        child: _StatPill('Défaites', '${team['p'] ?? 0}'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final dark = _isDark(context);
    final pending = _members.where((m) => m['status'] == 'PENDING').length;
    final teamData = _toTeamData();
    final items = [
      _GridItem(
        icon: Icons.grid_view_rounded,
        label: 'Compositions',
        color: const Color(0xFF6A1B9A),
        bgColor: dark ? const Color(0xFF1E1228) : const Color(0xFFF3E5F5),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CompositionPage(team: teamData)),
        ),
      ),
      _GridItem(
        icon: Icons.people_rounded,
        label: 'Effectif',
        badge: pending,
        color: const Color(0xFF2E7D32),
        bgColor: dark ? const Color(0xFF0D1F0D) : const Color(0xFFE8F5E9),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RosterPage(team: teamData)),
        ),
      ),
      _GridItem(
        icon: Icons.workspace_premium_rounded,
        label: 'Classement',
        color: const Color(0xFFE6A800),
        bgColor: dark ? const Color(0xFF1F1A00) : const Color(0xFFFFF8E1),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RankingScreen()),
        ),
      ),
      _GridItem(
        icon: Icons.sports_rounded,
        label: 'Matchs',
        color: const Color(0xFFF57F17),
        bgColor: dark ? const Color(0xFF2A2310) : const Color(0xFFFFF8E1),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MatchesScreen()),
        ),
      ),
      _GridItem(
        icon: Icons.photo_library_rounded,
        label: 'Publications',
        color: const Color(0xFF1565C0),
        bgColor: dark ? const Color(0xFF071428) : const Color(0xFFE3F2FD),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PublicationsPage(team: teamData)),
        ),
      ),
      _GridItem(
        icon: Icons.emoji_events_rounded,
        label: 'Tournois',
        color: const Color(0xFFAD1457),
        bgColor: dark ? const Color(0xFF1F0A14) : const Color(0xFFFCE4EC),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TournamentsPage(team: teamData)),
        ),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
        children: items
            .map(
              (item) => GestureDetector(
                onTap: item.onTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      children: [
                        Container(
                          height: 58,
                          decoration: BoxDecoration(
                            color: item.bgColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(item.icon, color: item.color, size: 28),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          item.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _sub(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    if (item.badge > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${item.badge}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  const _StatPill(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.65),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: Colors.white.withOpacity(0.15));
}

class _GridItem {
  final IconData icon;
  final String label;
  final Color color, bgColor;
  final int badge;
  final VoidCallback onTap;
  const _GridItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.badge = 0,
  });
}

//  INVITE CARD
class InviteCard extends StatelessWidget {
  final String inviteCode;
  const InviteCard({super.key, required this.inviteCode});

  void _share(BuildContext context) {
    Share.share(
      'Rejoins mon equipe sur Minifoot !\n\n$inviteCode',
      subject: 'Invitation equipe Minifoot',
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Lien copie'),
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGreen.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.link_rounded, color: _kGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lien d invitation',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _txt(context),
                      ),
                    ),
                    Text(
                      'Partage pour inviter des joueurs',
                      style: TextStyle(fontSize: 11, color: _sub(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _sub(context).withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    inviteCode,
                    style: TextStyle(
                      fontSize: 11,
                      color: _sub(context),
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => _copy(context),
                  child: Icon(
                    Icons.copy_rounded,
                    color: _sub(context),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _share(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _kGreen.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Partager le lien',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
