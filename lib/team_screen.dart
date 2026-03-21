import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'match_screen.dart';
import 'ranking_screen.dart';
import 'team_publications_screen.dart';
import 'team_tournaments_screen.dart';
import 'team_roster_screen.dart';
import 'team_composition_screen.dart';

const Color _kGreen = Color(0xFF006F39);
bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c) => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c) => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c) => _isDark(c)
    ? const Color(0xFFF0EBE0).withValues(alpha: 0.5)
    : Colors.black.withValues(alpha: 0.45);

enum MemberStatus { active, pending }
enum PlayerPosition { gardien, defenseur, milieu, attaquant }

extension PlayerPositionLabel on PlayerPosition {
  String get label {
    switch (this) {
      case PlayerPosition.gardien:   return 'Gardien';
      case PlayerPosition.defenseur: return 'Defenseur';
      case PlayerPosition.milieu:    return 'Milieu';
      case PlayerPosition.attaquant: return 'Attaquant';
    }
  }
  String get short {
    switch (this) {
      case PlayerPosition.gardien:   return 'GB';
      case PlayerPosition.defenseur: return 'DEF';
      case PlayerPosition.milieu:    return 'MIL';
      case PlayerPosition.attaquant: return 'ATT';
    }
  }
  Color get color {
    switch (this) {
      case PlayerPosition.gardien:   return const Color(0xFFE6A800);
      case PlayerPosition.defenseur: return const Color(0xFF1565C0);
      case PlayerPosition.milieu:    return const Color(0xFF006F39);
      case PlayerPosition.attaquant: return const Color(0xFFB71C1C);
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
    required this.id, required this.name, this.avatarUrl = '',
    this.isCaptain = false, this.status = MemberStatus.active,
    this.age = 22, this.goals = 0, this.assists = 0, this.matchesPlayed = 0,
    this.position = PlayerPosition.milieu,
  });
}

class TeamData {
  String name, zone, address;
  LatLng? location;
  Color color;
  String? logoPath;
  String inviteCode;
  List<TeamMember> members;
  TeamData({
    required this.name, required this.zone, this.address = '',
    this.location, required this.color, this.logoPath,
    required this.inviteCode, required this.members,
  });
}

final teamNotifier = ValueNotifier<TeamData?>(null);
String _generateCode(String name) =>
    'minifoot.app/join/${name.replaceAll(' ', '').toLowerCase()}-${DateTime.now().millisecondsSinceEpoch % 10000}';

final mockPlayers = [
  TeamMember(id:'p1',  name:'Ibrahima Diallo',  isCaptain:true,  age:26, goals:12, assists:5,  matchesPlayed:18, position:PlayerPosition.milieu,    avatarUrl:'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=200'),
  TeamMember(id:'p2',  name:'Moussa Ndiaye',                      age:22, goals:8,  assists:3,  matchesPlayed:16, position:PlayerPosition.attaquant, avatarUrl:'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=200'),
  TeamMember(id:'p3',  name:'Cheikh Fall',                        age:24, goals:0,  assists:1,  matchesPlayed:17, position:PlayerPosition.gardien,   avatarUrl:'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=200'),
  TeamMember(id:'p4',  name:'Omar Sow',                           age:23, goals:3,  assists:7,  matchesPlayed:15, position:PlayerPosition.defenseur,  avatarUrl:'https://images.pexels.com/photos/1300402/pexels-photo-1300402.jpeg?auto=compress&cs=tinysrgb&w=200'),
  TeamMember(id:'p5',  name:'Aliou Badji',                        age:21, goals:5,  assists:4,  matchesPlayed:14, position:PlayerPosition.milieu,    avatarUrl:'https://images.pexels.com/photos/1043474/pexels-photo-1043474.jpeg?auto=compress&cs=tinysrgb&w=200'),
  TeamMember(id:'p6',  name:'Pape Gueye',                         age:25, goals:2,  assists:6,  matchesPlayed:18, position:PlayerPosition.defenseur,  avatarUrl:'https://images.pexels.com/photos/1516680/pexels-photo-1516680.jpeg?auto=compress&cs=tinysrgb&w=200'),
  TeamMember(id:'p7',  name:'Lamine Camara',                      age:20, goals:9,  assists:2,  matchesPlayed:13, position:PlayerPosition.attaquant, avatarUrl:'https://images.pexels.com/photos/1212984/pexels-photo-1212984.jpeg?auto=compress&cs=tinysrgb&w=200'),
  TeamMember(id:'p8',  name:'Seydou Sarr',                        age:19, goals:6,  assists:3,  matchesPlayed:12, position:PlayerPosition.attaquant, avatarUrl:'https://images.pexels.com/photos/1484794/pexels-photo-1484794.jpeg?auto=compress&cs=tinysrgb&w=200'),
  TeamMember(id:'p9',  name:'Mamadou Diop',                       age:27, goals:1,  assists:0,  matchesPlayed:10, position:PlayerPosition.defenseur,  avatarUrl:'https://images.pexels.com/photos/1040880/pexels-photo-1040880.jpeg?auto=compress&cs=tinysrgb&w=200'),
  TeamMember(id:'p10', name:'Abdou Diatta',                       age:23, goals:0,  assists:2,  matchesPlayed:11, position:PlayerPosition.defenseur,  avatarUrl:'https://images.pexels.com/photos/1559486/pexels-photo-1559486.jpeg?auto=compress&cs=tinysrgb&w=200'),
  TeamMember(id:'p11', name:'Boubacar Traore',                    age:22, goals:4,  assists:5,  matchesPlayed:16, position:PlayerPosition.milieu,    avatarUrl:'https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=200'),
  TeamMember(id:'p12', name:'Ismaila Sarr',                       age:24, goals:7,  assists:4,  matchesPlayed:15, position:PlayerPosition.attaquant, avatarUrl:'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=200'),
  TeamMember(id:'p13', name:'Nicolas Faye',                       age:21, goals:0,  assists:0,  matchesPlayed:8,  position:PlayerPosition.gardien,   avatarUrl:'https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=200'),
  TeamMember(id:'p14', name:'Krepin Diatta',                      age:25, goals:5,  assists:3,  matchesPlayed:14, position:PlayerPosition.milieu,    avatarUrl:'https://images.pexels.com/photos/1300402/pexels-photo-1300402.jpeg?auto=compress&cs=tinysrgb&w=200'),
  TeamMember(id:'p15', name:'Bamba Dieng',                        age:23, goals:11, assists:2,  matchesPlayed:17, position:PlayerPosition.attaquant, avatarUrl:'https://images.pexels.com/photos/1043474/pexels-photo-1043474.jpeg?auto=compress&cs=tinysrgb&w=200'),
];

//  ENTRY POINT 
class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TeamData?>(
      valueListenable: teamNotifier,
      builder: (_, team, __) =>
          team == null ? const _NoTeamPage() : _MyTeamPage(team: team),
    );
  }
}

//  PAGE : PAS D EQUIPE 
class _NoTeamPage extends StatelessWidget {
  const _NoTeamPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: _card(context), shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8)]),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _txt(context))),
            ),
            const SizedBox(width: 14),
            Text('Mon equipe', style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.w900, color: _txt(context))),
          ]),
        ),
        const Spacer(),
        Container(width: 110, height: 110,
          decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: Icon(Icons.shield_outlined, size: 52, color: _kGreen.withValues(alpha: 0.5))),
        const SizedBox(height: 24),
        Text("Tu n'as pas encore d'equipe",
            style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.w800, color: _txt(context))),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text('Cree ton equipe, invite tes joueurs via un lien et commence a defier les autres equipes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _sub(context), height: 1.5)),
        ),
        const SizedBox(height: 36),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _CreateTeamPage())),
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(16)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Creer mon equipe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ])),
          ),
        ),
        const Spacer(),
      ])),
    );
  }
}

//  COULEURS EQUIPE 
final _teamColors = [
  const Color(0xFF006F39), const Color(0xFF2E7D32), const Color(0xFF00695C),
  const Color(0xFF558B2F), const Color(0xFF33691E), const Color(0xFF1B5E20),
  const Color(0xFF0D47A1), const Color(0xFF1565C0), const Color(0xFF1A237E),
  const Color(0xFF006064), const Color(0xFF01579B), const Color(0xFF283593),
  const Color(0xFFB71C1C), const Color(0xFFC62828), const Color(0xFFE65100),
  const Color(0xFFBF360C), const Color(0xFF880E4F), const Color(0xFF4A148C),
  const Color(0xFF212121), const Color(0xFF37474F), const Color(0xFF263238),
  const Color(0xFF4E342E), const Color(0xFF3E2723), const Color(0xFF1A1A2E),
  const Color(0xFFAD1457), const Color(0xFF6A1B9A), const Color(0xFF4527A0),
  const Color(0xFF00838F), const Color(0xFF2E86AB), const Color(0xFFD84315),
];

//  PAGE : CREER UNE EQUIPE 
class _CreateTeamPage extends StatefulWidget {
  const _CreateTeamPage();
  @override
  State<_CreateTeamPage> createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<_CreateTeamPage> {
  final _nameCtrl = TextEditingController();
  Color  _color   = const Color(0xFF006F39);
  String? _logoPath;
  bool   _nameError = false;
  String  _address  = '';
  LatLng? _location;
  bool    _locating = false;

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _useGPS() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) { if (mounted) setState(() => _locating = false); return; }
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (!mounted) return;
      final ll = LatLng(pos.latitude, pos.longitude);
      final result = await Navigator.push<_LocationResult>(context, MaterialPageRoute(builder: (_) => _LocationPickerPage(initial: ll)));
      if (result != null && mounted) setState(() { _location = result.latlng; _address = result.address; });
    } catch (_) {} finally { if (mounted) setState(() => _locating = false); }
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _ColorPickerSheet(initial: _color, onChanged: (c) => setState(() => _color = c)));
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<_LocationResult>(context, MaterialPageRoute(builder: (_) => const _LocationPickerPage()));
    if (result != null && mounted) setState(() { _location = result.latlng; _address = result.address; });
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 400);
    if (picked != null) setState(() => _logoPath = picked.path);
  }

  void _create() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _nameError = true); return; }
    teamNotifier.value = TeamData(
      name: name, zone: 'Dakar', color: _color,
      address: _address, location: _location, logoPath: _logoPath,
      inviteCode: _generateCode(name),
      members: mockPlayers.map((p) => TeamMember(
        id: p.id, name: p.name, isCaptain: p.isCaptain,
        age: p.age, goals: p.goals, assists: p.assists,
        matchesPlayed: p.matchesPlayed, position: p.position,
        avatarUrl: p.avatarUrl, status: MemberStatus.active,
      )).toList(),
    );
    Navigator.pop(context);
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _sub(context))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: _card(context), shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8)]),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _txt(context)))),
            const SizedBox(width: 14),
            Text('Creer mon equipe', style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.w900, color: _txt(context))),
          ]),
        ),
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
          _sectionTitle('Logo'),
          Center(child: GestureDetector(onTap: _pickLogo,
            child: Stack(children: [
              Container(width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _color.withValues(alpha: 0.12),
                    border: Border.all(color: _color.withValues(alpha: 0.4), width: 2)),
                child: _logoPath != null
                    ? ClipOval(child: Image.file(File(_logoPath!), fit: BoxFit.cover))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate_rounded, color: _color, size: 32),
                        const SizedBox(height: 4),
                        Text('Logo', style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600)),
                      ])),
              if (_logoPath != null)
                Positioned(bottom: 0, right: 0,
                  child: Container(width: 28, height: 28,
                    decoration: BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14))),
            ]))),
          _sectionTitle('Nom *'),
          Container(
            decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(14),
                border: _nameError ? Border.all(color: Colors.red.shade300) : null),
            child: TextField(controller: _nameCtrl, onChanged: (_) => setState(() => _nameError = false),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _txt(context)),
              decoration: InputDecoration(hintText: 'Ex: Les Lions FC',
                hintStyle: TextStyle(color: _sub(context), fontSize: 14),
                border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14))),
          ),
          if (_nameError) Padding(padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text('Le nom est obligatoire', style: TextStyle(fontSize: 11, color: Colors.red.shade400))),
          _sectionTitle('Couleur'),
          GestureDetector(onTap: () => _showColorPicker(context),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _sub(context).withValues(alpha: 0.15))),
              child: Row(children: [
                Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: _color, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.4), blurRadius: 8)])),
                const SizedBox(width: 12),
                Expanded(child: Text('#${_color.value.toRadixString(16).substring(2).toUpperCase()}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _txt(context), fontFamily: 'monospace'))),
                Icon(Icons.colorize_rounded, color: _sub(context), size: 18),
              ]))),
          _sectionTitle('Localisation'),
          Row(children: [
            Expanded(child: GestureDetector(onTap: _locating ? null : _useGPS,
              child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kGreen.withValues(alpha: 0.3))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _locating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _kGreen))
                      : const Icon(Icons.my_location_rounded, color: _kGreen, size: 16),
                  const SizedBox(width: 6),
                  const Text('Ma position', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGreen)),
                ])))),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(onTap: _openMapPicker,
              child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _sub(context).withValues(alpha: 0.2))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.map_rounded, color: _sub(context), size: 16),
                  const SizedBox(width: 6),
                  Text('Sur la carte', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _sub(context))),
                ])))),
          ]),
          const SizedBox(height: 10),
          if (_location != null)
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGreen.withValues(alpha: 0.25))),
              child: Row(children: [
                const Icon(Icons.location_on_rounded, color: _kGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_address.isNotEmpty ? _address : '${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _txt(context)))),
                GestureDetector(onTap: () => setState(() { _location = null; _address = ''; }),
                    child: Icon(Icons.close_rounded, color: _sub(context), size: 16)),
              ]))
          else
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: _sub(context).withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.location_off_rounded, color: _sub(context), size: 15),
                const SizedBox(width: 8),
                Text('Aucune localisation', style: TextStyle(fontSize: 12, color: _sub(context))),
              ])),
          const SizedBox(height: 24),
          GestureDetector(onTap: _create,
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(16)),
              child: const Text('Creer l equipe', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)))),
        ])),
      ])),
    );
  }
}

//  COLOR PICKER 
class _ColorPickerSheet extends StatefulWidget {
  final Color initial;
  final ValueChanged<Color> onChanged;
  const _ColorPickerSheet({required this.initial, required this.onChanged});
  @override State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}
class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late HSVColor _hsv;
  @override void initState() { super.initState(); _hsv = HSVColor.fromColor(widget.initial); }
  Color get _current => _hsv.toColor();
  void _emit(Color c) => widget.onChanged(c);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: _card(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: _sub(context).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Row(children: [
          AnimatedContainer(duration: const Duration(milliseconds: 100), width: 52, height: 52,
            decoration: BoxDecoration(color: _current, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _current.withValues(alpha: 0.5), blurRadius: 12)])),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Couleur', style: TextStyle(fontSize: 12, color: _sub(context))),
            Text('#${_current.value.toRadixString(16).substring(2).toUpperCase()}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _txt(context), fontFamily: 'monospace')),
          ])),
          GestureDetector(onTap: () => Navigator.pop(context),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(12)),
              child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)))),
        ]),
        const SizedBox(height: 20),
        Row(children: [Text('Teinte', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _sub(context))), const Spacer()]),
        SizedBox(height: 36, child: Stack(children: [
          Positioned(left: 10, right: 10, top: 10, bottom: 10,
            child: ClipRRect(borderRadius: BorderRadius.circular(5), child: CustomPaint(painter: _RainbowPainter()))),
          SliderTheme(data: SliderTheme.of(context).copyWith(
            trackHeight: 16, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            activeTrackColor: Colors.transparent, inactiveTrackColor: Colors.transparent,
            thumbColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
            overlayColor: HSVColor.fromAHSV(0.2, _hsv.hue, 1, 1).toColor()),
            child: Slider(value: _hsv.hue, min: 0, max: 360,
              onChanged: (h) { setState(() => _hsv = _hsv.withHue(h)); _emit(_current); })),
        ])),
        const SizedBox(height: 10),
        Row(children: [Text('Saturation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _sub(context))), const Spacer(),
          Text('${(_hsv.saturation * 100).round()}%', style: TextStyle(fontSize: 11, color: _sub(context)))]),
        SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 10,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          activeTrackColor: _current, inactiveTrackColor: _sub(context).withValues(alpha: 0.15), thumbColor: Colors.white),
          child: Slider(value: _hsv.saturation,
            onChanged: (v) { setState(() => _hsv = _hsv.withSaturation(v)); _emit(_current); })),
        Row(children: [Text('Luminosite', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _sub(context))), const Spacer(),
          Text('${(_hsv.value * 100).round()}%', style: TextStyle(fontSize: 11, color: _sub(context)))]),
        SliderTheme(data: SliderTheme.of(context).copyWith(trackHeight: 10,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          activeTrackColor: _current, inactiveTrackColor: _sub(context).withValues(alpha: 0.15), thumbColor: Colors.white),
          child: Slider(value: _hsv.value,
            onChanged: (v) { setState(() => _hsv = _hsv.withValue(v)); _emit(_current); })),
        const SizedBox(height: 10),
        Text('Couleurs predefinies', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _sub(context))),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _teamColors.map((c) {
          final sel = c.value == _current.value;
          return GestureDetector(onTap: () { setState(() => _hsv = HSVColor.fromColor(c)); _emit(c); },
            child: AnimatedContainer(duration: const Duration(milliseconds: 150), width: 30, height: 30,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle,
                border: sel ? Border.all(color: _txt(context), width: 2.5) : null,
                boxShadow: sel ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)] : null),
              child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null));
        }).toList()),
      ]),
    );
  }
}

class _RainbowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(colors: List.generate(7, (i) => HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor()));
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }
  @override bool shouldRepaint(_) => false;
}

//  LOCATION PICKER 
class _LocationResult {
  final LatLng latlng;
  final String address;
  const _LocationResult({required this.latlng, required this.address});
}

class _LocationPickerPage extends StatefulWidget {
  final LatLng? initial;
  const _LocationPickerPage({this.initial});
  @override State<_LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<_LocationPickerPage> {
  late final MapController _mapCtrl;
  LatLng _picked = const LatLng(14.7167, -17.4677);
  bool _locating = false;

  @override
  void initState() { super.initState(); _mapCtrl = MapController(); if (widget.initial != null) _picked = widget.initial!; }
  @override
  void dispose() { _mapCtrl.dispose(); super.dispose(); }

  Future<void> _goToGPS() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (!mounted) return;
      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() => _picked = ll);
      _mapCtrl.move(ll, 15);
    } catch (_) {} finally { if (mounted) setState(() => _locating = false); }
  }

  String _coordsToAddress(LatLng ll) {
    if (ll.latitude > 14.75) return 'Guediawaye / Pikine, Dakar';
    if (ll.latitude > 14.72) return 'Grand Yoff / HLM, Dakar';
    if (ll.latitude > 14.70) return 'Parcelles Assainies, Dakar';
    if (ll.latitude > 14.68) return 'Medina / Point E, Dakar';
    if (ll.longitude < -17.46) return 'Plateau, Dakar';
    if (ll.latitude < 14.65) return 'Rufisque, Dakar';
    return 'Dakar, Senegal';
  }

  void _confirm() => Navigator.pop(context, _LocationResult(latlng: _picked, address: _coordsToAddress(_picked)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: Stack(children: [
        FlutterMap(mapController: _mapCtrl,
          options: MapOptions(initialCenter: _picked, initialZoom: 14,
              onTap: (_, ll) => setState(() => _picked = ll)),
          children: [
            TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd']),
            MarkerLayer(markers: [Marker(point: _picked, width: 48, height: 48,
              child: Column(children: [
                Container(width: 32, height: 32,
                  decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18)),
                CustomPaint(size: const Size(12, 8), painter: _TrianglePainter()),
              ]))]),
          ]),
        Positioned(top: MediaQuery.of(context).padding.top + 12, left: 16, right: 16,
          child: Row(children: [
            GestureDetector(onTap: () => Navigator.pop(context),
              child: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: _card(context), shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)]),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _txt(context)))),
            const SizedBox(width: 10),
            Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]),
              child: Row(children: [
                const Icon(Icons.location_on_rounded, color: _kGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_coordsToAddress(_picked),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _txt(context)),
                    overflow: TextOverflow.ellipsis)),
              ]))),
          ])),
        Positioned(top: MediaQuery.of(context).padding.top + 72, left: 0, right: 0,
          child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(20)),
            child: const Text('Appuie sur la carte pour placer le marqueur',
                style: TextStyle(color: Colors.white, fontSize: 11))))),
        Positioned(right: 16, bottom: 120,
          child: GestureDetector(onTap: _locating ? null : _goToGPS,
            child: Container(width: 46, height: 46,
              decoration: BoxDecoration(color: _card(context), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)]),
              child: _locating
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: _kGreen))
                  : const Icon(Icons.my_location_rounded, color: _kGreen, size: 22)))),
        Positioned(bottom: MediaQuery.of(context).padding.bottom + 24, left: 20, right: 20,
          child: GestureDetector(onTap: _confirm,
            child: Container(padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Flexible(child: Text('Confirmer - ${_coordsToAddress(_picked)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                    overflow: TextOverflow.ellipsis)),
              ])))),
      ]),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()..moveTo(0, 0)..lineTo(size.width, 0)..lineTo(size.width / 2, size.height)..close();
    canvas.drawPath(path, Paint()..color = _kGreen);
  }
  @override bool shouldRepaint(_) => false;
}

//  PAGE : MON EQUIPE 
class _MyTeamPage extends StatefulWidget {
  final TeamData team;
  const _MyTeamPage({required this.team});
  @override State<_MyTeamPage> createState() => _MyTeamPageState();
}

class _MyTeamPageState extends State<_MyTeamPage> {
  TeamData get team => widget.team;
  List<TeamMember> get _active => team.members.where((m) => m.status == MemberStatus.active).toList();

  void _simulateRequest() {
    final names = ['Ibrahima Diallo', 'Moussa Ndiaye', 'Cheikh Fall', 'Omar Sow'];
    final positions = [PlayerPosition.attaquant, PlayerPosition.defenseur, PlayerPosition.milieu, PlayerPosition.gardien];
    final idx = team.members.length % names.length;
    team.members.add(TeamMember(id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      name: names[idx], status: MemberStatus.pending,
      age: 19 + idx * 2, goals: idx * 2, assists: idx,
      matchesPlayed: idx * 3, position: positions[idx]));
    // Forcer la notification en créant un nouveau TeamData
    teamNotifier.value = TeamData(
      name: team.name, zone: team.zone, address: team.address,
      location: team.location, color: team.color, logoPath: team.logoPath,
      inviteCode: team.inviteCode, members: List.from(team.members),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverToBoxAdapter(child: _buildGrid(context)),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(children: [
        Positioned.fill(child: Image.network(
          'https://images.pexels.com/photos/12486370/pexels-photo-12486370.jpeg?auto=compress&cs=tinysrgb&w=800',
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black87))),
        Positioned.fill(child: Container(decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xCC000000), Color(0x99000000), Color(0xDD000000)], stops: [0.0, 0.45, 1.0])))),
        Padding(padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25))),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white))),
              const Spacer(),
              GestureDetector(onTap: _simulateRequest,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.person_add_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Simuler demande', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ]))),
              const SizedBox(width: 8),
              GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _CreateTeamPage())),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25))),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Modifier', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]))),
            ]),
            const SizedBox(height: 22),
            Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              Container(width: 88, height: 88,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(color: team.color, width: 3),
                  boxShadow: [BoxShadow(color: team.color.withValues(alpha: 0.5), blurRadius: 16)]),
                child: team.logoPath != null
                    ? ClipOval(child: Image.file(File(team.logoPath!), fit: BoxFit.cover))
                    : Center(child: Text(team.name.split(' ').map((w) => w[0]).take(2).join(),
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)))),
              Positioned(bottom: -2, right: -2,
                child: Container(width: 22, height: 22,
                  decoration: BoxDecoration(color: team.color, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)))),
            ]),
            const SizedBox(height: 12),
            Text(team.name, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.location_on_rounded, color: Colors.white.withValues(alpha: 0.65), size: 13),
              const SizedBox(width: 3),
              Flexible(child: Text(team.address.isNotEmpty ? team.address : team.zone,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
                  overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
              child: Row(children: [
                Expanded(flex: 2, child: Column(children: [
                  Text('#3', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 28, fontWeight: FontWeight.w900)),
                  Text('18 pts', style: TextStyle(color: const Color(0xFFFFD700).withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w700)),
                  Text('Rang', style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 9, fontWeight: FontWeight.w600)),
                ])),
                _StatDivider(),
                Expanded(child: _StatPill('Joueurs', '${_active.length}')),
                _StatDivider(),
                Expanded(child: _StatPill('Matchs', '0')),
                _StatDivider(),
                Expanded(child: _StatPill('Victoires', '0')),
                _StatDivider(),
                Expanded(child: _StatPill('Defaites', '0')),
              ])),
          ])),
      ]),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final dark = _isDark(context);
    final pending = team.members.where((m) => m.status == MemberStatus.pending).length;
    final items = [
      _GridItem(icon: Icons.grid_view_rounded, label: 'Compositions',
        color: const Color(0xFF6A1B9A), bgColor: dark ? const Color(0xFF1E1228) : const Color(0xFFF3E5F5),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CompositionPage(team: team)))),
      _GridItem(icon: Icons.people_rounded, label: 'Effectif', badge: pending,
        color: const Color(0xFF2E7D32), bgColor: dark ? const Color(0xFF0D1F0D) : const Color(0xFFE8F5E9),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RosterPage(team: team)))),
      _GridItem(icon: Icons.workspace_premium_rounded, label: 'Classement',
        color: const Color(0xFFE6A800), bgColor: dark ? const Color(0xFF1F1A00) : const Color(0xFFFFF8E1),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RankingScreen()))),
      _GridItem(icon: Icons.sports_rounded, label: 'Matchs',
        color: const Color(0xFFF57F17), bgColor: dark ? const Color(0xFF2A2310) : const Color(0xFFFFF8E1),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchScreen()))),
      _GridItem(icon: Icons.photo_library_rounded, label: 'Publications',
        color: const Color(0xFF1565C0), bgColor: dark ? const Color(0xFF071428) : const Color(0xFFE3F2FD),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicationsPage(team: team)))),
      _GridItem(icon: Icons.emoji_events_rounded, label: 'Tournois',
        color: const Color(0xFFAD1457), bgColor: dark ? const Color(0xFF1F0A14) : const Color(0xFFFCE4EC),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentsPage(team: team)))),
    ];
    return Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GridView.count(crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85,
        children: items.map((item) => GestureDetector(onTap: item.onTap,
          child: Stack(clipBehavior: Clip.none, children: [
            Column(children: [
              Container(height: 58,
                decoration: BoxDecoration(color: item.bgColor, borderRadius: BorderRadius.circular(16)),
                child: Center(child: Icon(item.icon, color: item.color, size: 28))),
              const SizedBox(height: 7),
              Text(item.label, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _sub(context)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
            if (item.badge > 0)
              Positioned(top: 0, right: 0,
                child: Container(width: 16, height: 16,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Center(child: Text('${item.badge}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))))),
          ]))).toList()));
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  const _StatPill(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 9, fontWeight: FontWeight.w600)),
  ]);
}

class _StatDivider extends StatelessWidget {
  @override Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.15));
}

class _GridItem {
  final IconData icon;
  final String label;
  final Color color, bgColor;
  final int badge;
  final VoidCallback onTap;
  const _GridItem({required this.icon, required this.label, required this.color,
      required this.bgColor, required this.onTap, this.badge = 0});
}

//  INVITE CARD 
class InviteCard extends StatelessWidget {
  final String inviteCode;
  const InviteCard({super.key, required this.inviteCode});

  void _share(BuildContext context) {
    Share.share('Rejoins mon equipe sur Minifoot !\n\n$inviteCode', subject: 'Invitation equipe Minifoot');
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Lien copie'), backgroundColor: _kGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.link_rounded, color: _kGreen, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Lien d invitation', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
            Text('Partage pour inviter des joueurs', style: TextStyle(fontSize: 11, color: _sub(context))),
          ])),
        ]),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: _sub(context).withValues(alpha: 0.07), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Expanded(child: Text(inviteCode,
                style: TextStyle(fontSize: 11, color: _sub(context), fontFamily: 'monospace'),
                overflow: TextOverflow.ellipsis)),
            GestureDetector(onTap: () => _copy(context),
                child: Icon(Icons.copy_rounded, color: _sub(context), size: 16)),
          ])),
        const SizedBox(height: 12),
        GestureDetector(onTap: () => _share(context),
          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _kGreen.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))]),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.share_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Partager le lien', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            ]))),
      ]),
    );
  }
}
