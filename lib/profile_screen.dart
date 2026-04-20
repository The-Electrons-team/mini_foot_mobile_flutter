import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'providers/auth_provider.dart';

import 'terrain_data.dart';
import 'terrain_detail_screen.dart';
import 'auth_screen.dart';

const Color _kBeige = Color(0xFFF5F0E8);
const Color _kGreen = Color(0xFF006F39);
const Color _kDark  = Color(0xFF1A1A1A);

// ── Helpers thème ──
bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c)   => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c)  => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)  => _isDark(c)
    ? const Color(0xFFF0EBE0).withValues(alpha: 0.5)
    : Colors.black.withValues(alpha: 0.45);

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _photo;

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null && mounted) setState(() => _photo = File(picked.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(source == ImageSource.camera
                ? 'Impossible d\'ouvrir la caméra'
                : 'Impossible d\'ouvrir la galerie'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Photo de profil',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _txt(context))),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _PhotoOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Caméra',
                    onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.camera); },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PhotoOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galerie',
                    onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.gallery); },
                  ),
                ),
                if (_photo != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PhotoOption(
                      icon: Icons.delete_outline_rounded,
                      label: 'Supprimer',
                      color: Colors.red.shade600,
                      onTap: () { Navigator.pop(context); setState(() => _photo = null); },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(

      backgroundColor: _bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── HEADER ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Text('Mon Profil',
                    style: GoogleFonts.orbitron(
                        fontSize: 22, fontWeight: FontWeight.w900, color: _txt(context))),
              ),

              // ── AVATAR + INFOS ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: _showPhotoSheet,
                      child: Stack(
                        children: [
                          Container(
                            width: 88, height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kGreen.withValues(alpha: 0.15),
                              border: Border.all(color: _kGreen, width: 2.5),
                            ),
                            child: ClipOval(
                              child: _photo != null
                                  ? Image.file(_photo!, fit: BoxFit.cover)
                                  : Icon(Icons.person_rounded,
                                      size: 52, color: _kGreen.withValues(alpha: 0.5)),
                            ),
                          ),
                          Positioned(
                            right: 0, bottom: 0,
                            child: Container(
                              width: 26, height: 26,
                              decoration: BoxDecoration(
                                color: _kGreen, shape: BoxShape.circle,
                                border: Border.all(color: _bg(context), width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(user != null ? '${user.firstName} ${user.lastName}' : 'Utilisateur',
                              style: GoogleFonts.orbitron(
                                  fontSize: 15, fontWeight: FontWeight.w900, color: _txt(context))),
                          const SizedBox(height: 4),
                          Text(user?.phone ?? '',
                              style: TextStyle(fontSize: 12, color: _sub(context))),

                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6, runSpacing: 6,
                            children: [
                              _PosBadge(label: 'Attaquant', color: _kGreen),
                              _PosBadge(label: 'Les Lions FC', color: const Color(0xFF1565C0)),
                              if (user?.birthDate != null)
                                Builder(
                                  builder: (context) {
                                    final birth = DateTime.tryParse(user!.birthDate!);
                                    if (birth == null) return const SizedBox.shrink();
                                    final age = DateTime.now().year - birth.year;
                                    return _PosBadge(
                                      label: '$age ans',
                                      color: const Color(0xFF6A1B9A),
                                    );
                                  },
                                ),

                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── STATS ──
              Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: _card(context),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const _StatItem(value: '47', label: 'Matchs'),
                    Container(width: 1, height: 32, color: Colors.black.withValues(alpha: 0.08)),
                    const _StatItem(value: '12', label: 'Buts'),
                    Container(width: 1, height: 32, color: Colors.black.withValues(alpha: 0.08)),
                    const _StatItem(value: '8',  label: 'Passes'),
                  ],
                ),
              ),

              // ── PROCHAINS MATCHS ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
                child: Text('Prochains matchs',
                    style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
              ),
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: const [
                    _MatchCard(day: 'Sam 22 Mars', time: '16:00', home: 'Les Lions FC', away: 'Tigres FC',      terrain: 'Dakar Arena'),
                    _MatchCard(day: 'Dim 23 Mars', time: '10:00', home: 'Les Lions FC', away: 'Plateau Stars',  terrain: 'Stade Léopold'),
                    _MatchCard(day: 'Mer 26 Mars', time: '19:00', home: 'Les Lions FC', away: 'Warriors HLM',   terrain: 'Terrain Point E'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── MENU PRINCIPAL ──
              _MenuCard(items: [
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Paramètres du compte',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _AccountSettingsScreen())),
                ),
                _MenuItem(
                  icon: Icons.favorite_border_rounded,
                  label: 'Terrains favoris',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _FavoriteTerrainsScreen())),
                ),
                _MenuItem(
                  icon: Icons.credit_card_rounded,
                  label: 'Paiements',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _PaymentsScreen())),
                ),
              ]),

              const SizedBox(height: 12),

              // ── MENU SECONDAIRE ──
              _MenuCard(items: [
                _MenuItem(
                  icon: Icons.shield_outlined,
                  label: 'Confidentialité & CGU',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _PrivacyScreen())),
                ),
                _MenuItem(
                  icon: Icons.headset_mic_outlined,
                  label: 'Aide & Support',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _HelpScreen())),
                ),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Se déconnecter',
                  isDestructive: true,
                  onTap: () => _confirmLogout(context),
                ),
              ]),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.w800, color: _txt(context))),
        content: Text('Voulez-vous vraiment vous déconnecter ?',
            style: TextStyle(color: _sub(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: _sub(context), fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (r) => false,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Déconnecter',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),

          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── PHOTO OPTION ──
class _PhotoOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _PhotoOption({required this.icon, required this.label, required this.onTap, this.color = _kGreen});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    ),
  );
}

// ── BADGE POSTE ──
class _PosBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PosBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}

// ── STAT ITEM ──
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value,
          style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.w900, color: _txt(context))),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _sub(context))),
    ],
  );
}

// ── MATCH CARD ──
class _MatchCard extends StatelessWidget {
  final String day;
  final String time;
  final String home;
  final String away;
  final String terrain;
  const _MatchCard({required this.day, required this.time, required this.home, required this.away, required this.terrain});

  @override
  Widget build(BuildContext context) => Container(
    width: 215,
    margin: const EdgeInsets.only(right: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 5))],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // Dégradé horizontal vert (gauche 70%) → noir (droite 30%)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0.0, 0.45, 1.0],
                colors: [
                  Color(0xFF006F39),
                  Color(0xFF002810),
                  Color(0xFF0A0A0A),
                ],
              ),
            ),
          ),
          // Contenu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Heure + jour
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(5)),
                      child: Text(time,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                    const Spacer(),
                    Text(day, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 8)),
                  ],
                ),
                const SizedBox(height: 6),
                // Équipes
                Text(home,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    Text('vs', style: TextStyle(color: _kGreen, fontSize: 9, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(away,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w600, fontSize: 11),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Terrain
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 9, color: _kGreen.withValues(alpha: 0.8)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(terrain,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 8),
                          overflow: TextOverflow.ellipsis),
                    ),
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

// ── MENU CARD ──
class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: _card(context),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
    ),
    child: Column(
      children: List.generate(items.length, (i) {
        final item = items[i];
        final isLast = i == items.length - 1;
        return Column(
          children: [
            GestureDetector(
              onTap: item.onTap,
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                child: Row(
                  children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: item.isDestructive
                            ? Colors.red.withValues(alpha: 0.08)
                            : _kGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, size: 18,
                          color: item.isDestructive ? Colors.red.shade600 : _kGreen),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(item.label,
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: item.isDestructive ? Colors.red.shade600 : _txt(context))),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 13,
                        color: _sub(context).withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
            if (!isLast)
              Divider(height: 1, indent: 66, endIndent: 18, color: Colors.black.withValues(alpha: 0.06)),
          ],
        );
      }),
    ),
  );
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.isDestructive = false});
}

// ─────────────────────────────────────────────────────────────────────────────
// PARAMÈTRES DU COMPTE
// ─────────────────────────────────────────────────────────────────────────────


class _AccountSettingsScreen extends StatefulWidget {
  const _AccountSettingsScreen();
  @override
  State<_AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<_AccountSettingsScreen> {
  final _prenomCtrl = TextEditingController(text: 'Mamadou');
  final _nomCtrl    = TextEditingController(text: 'Diallo');
  final _phoneCtrl  = TextEditingController(text: '77 123 45 67');
  String _poste         = 'Attaquant';
  bool   _phoneModified = false;
  DateTime? _birthDate;

  static const _postes = [
    'Attaquant', 'Milieu offensif', 'Milieu défensif',
    'Défenseur central', 'Latéral', 'Gardien de but',
  ];

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 5),
      helpText: 'Date de naissance',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: _kGreen,
            onPrimary: Colors.white,
            surface: _card(ctx),
            onSurface: _txt(ctx),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  int? get _age {
    if (_birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - _birthDate!.year;
    if (now.month < _birthDate!.month ||
        (now.month == _birthDate!.month && now.day < _birthDate!.day)) age--;
    return age;
  }

  String get _birthDateLabel {
    if (_birthDate == null) return 'Sélectionner';
    return '${_birthDate!.day.toString().padLeft(2, '0')}/'
        '${_birthDate!.month.toString().padLeft(2, '0')}/'
        '${_birthDate!.year}';
  }

  void _showPosteSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Choisir un poste',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _txt(context))),
              ),
            ),
            ..._postes.map((p) => GestureDetector(
              onTap: () {
                setState(() => _poste = p);
                Navigator.pop(context);
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _poste == p ? _kGreen.withValues(alpha: 0.1) : _sub(context).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.sports_soccer_rounded, size: 18,
                          color: _poste == p ? _kGreen : _sub(context)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(p,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: _poste == p ? FontWeight.w700 : FontWeight.w500,
                              color: _poste == p ? _kGreen : _kDark)),
                    ),
                    if (_poste == p)
                      const Icon(Icons.check_rounded, color: _kGreen, size: 20),
                  ],
                ),
              ),
            )),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  String? _validate() {
    if (_prenomCtrl.text.trim().isEmpty) return 'Le prénom est requis';
    if (_prenomCtrl.text.trim().length < 2) return 'Prénom trop court';
    if (_nomCtrl.text.trim().isEmpty) return 'Le nom est requis';
    if (_nomCtrl.text.trim().length < 2) return 'Nom trop court';
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return 'Le téléphone est requis';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) return 'Numéro invalide (min. 9 chiffres)';
    return null;
  }

  void _onSave() {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade600),
      );
      return;
    }
    if (_phoneModified) {
      _showOtpSheet(_phoneCtrl.text.trim());
    } else {
      _saveSuccess();
    }
  }

  void _showOtpSheet(String phone) {
    final controllers = List.generate(6, (_) => TextEditingController());
    final focusNodes  = List.generate(6, (_) => FocusNode());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          String getCode() => controllers.map((c) => c.text).join();
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: _card(context),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 24),
                  // Icône
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.sms_rounded, color: _kGreen, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text('Vérification',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _txt(context))),
                  const SizedBox(height: 6),
                  Text('Code envoyé au  +221 $phone',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: _sub(context))),
                  const SizedBox(height: 28),
                  // Cases OTP espacées
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) => Container(
                      width: 46, height: 56,
                      decoration: BoxDecoration(
                        color: _bg(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: controllers[i].text.isNotEmpty
                              ? _kGreen
                              : Colors.black.withValues(alpha: 0.12),
                          width: controllers[i].text.isNotEmpty ? 2 : 1,
                        ),
                      ),
                      child: TextField(
                        controller: controllers[i],
                        focusNode: focusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _txt(context)),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) {
                          setS(() {});
                          if (v.isNotEmpty && i < 5) {
                            focusNodes[i + 1].requestFocus();
                          } else if (v.isEmpty && i > 0) {
                            focusNodes[i - 1].requestFocus();
                          }
                        },
                      ),
                    )),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Renvoyer le code',
                        style: TextStyle(color: _kGreen, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _sub(context).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('Annuler', textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w700, color: _txt(context))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (getCode().length == 6) {
                              Navigator.pop(ctx);
                              _saveSuccess();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: getCode().length == 6 ? _kGreen : _sub(context).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text('Valider', textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: getCode().length == 6 ? Colors.white : _sub(context))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil mis à jour !'), backgroundColor: _kGreen),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _card(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _txt(context), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Paramètres du compte',
            style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w800, color: _txt(context))),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsField(label: 'Prénom', controller: _prenomCtrl, icon: Icons.person_rounded),
              const SizedBox(height: 14),
              _SettingsField(label: 'Nom',    controller: _nomCtrl,    icon: Icons.person_outline_rounded),
              const SizedBox(height: 14),

              // Téléphone avec indicatif fixe Sénégal
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Téléphone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _sub(context))),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: _card(context),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        // Indicatif fixe Sénégal
                        Container(
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: _kGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('🇸🇳', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 6),
                              Text('+221',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kGreen)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(fontSize: 14, color: _txt(context), fontWeight: FontWeight.w500),
                            onTap: () => _phoneCtrl.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _phoneCtrl.text.length,
                            ),
                            onChanged: (_) => _phoneModified = true,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '77 123 45 67',
                              hintStyle: TextStyle(color: _sub(context)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Select Poste
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Poste', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _sub(context))),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _showPosteSheet(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                      decoration: BoxDecoration(
                        color: _card(context),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sports_soccer_rounded, size: 18, color: _kGreen),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_poste,
                                style: TextStyle(fontSize: 14, color: _txt(context), fontWeight: FontWeight.w500)),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: _kGreen, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Date de naissance
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date de naissance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _sub(context))),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickBirthDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                      decoration: BoxDecoration(
                        color: _card(context),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cake_rounded, size: 18, color: _kGreen),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _birthDate == null ? 'Sélectionner' : '$_birthDateLabel  ·  $_age ans',
                              style: TextStyle(
                                fontSize: 14,
                                color: _birthDate == null ? _sub(context) : _txt(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: _kGreen, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              GestureDetector(
                onTap: _onSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(16)),
                  child: const Text('Enregistrer', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  const _SettingsField({required this.label, required this.controller, required this.icon});

  void _selectAll() {
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _sub(context))),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(icon, size: 18, color: _kGreen),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                onTap: _selectAll,
                style: TextStyle(fontSize: 14, color: _txt(context), fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TERRAINS FAVORIS
// ─────────────────────────────────────────────────────────────────────────────

class _FavoriteTerrainsScreen extends StatefulWidget {
  const _FavoriteTerrainsScreen();
  @override
  State<_FavoriteTerrainsScreen> createState() => _FavoriteTerrainsScreenState();
}

class _FavoriteTerrainsScreenState extends State<_FavoriteTerrainsScreen> {
  late final List favs = terrains.take(3).toList();

  void _remove(int i) => setState(() => favs.removeAt(i));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _card(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _txt(context), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Terrains favoris',
            style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w800, color: _txt(context))),
      ),
      body: favs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 48, color: _kGreen.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('Aucun favori',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: _sub(context))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: favs.length,
              itemBuilder: (_, i) {
                final t = favs[i];
                return Dismissible(
                  key: Key(t.name),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _remove(i),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 22),
                  ),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TerrainDetailScreen(terrain: t))),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: _card(context),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                            child: Image.network(t.imageUrl, width: 90, height: 80, fit: BoxFit.cover,
                                errorBuilder: (_, e, s) => Container(width: 90, height: 80, color: _kGreen.withValues(alpha: 0.2))),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _txt(context))),
                                  const SizedBox(height: 4),
                                  Text(t.address, style: TextStyle(fontSize: 12, color: _sub(context))),
                                  const SizedBox(height: 6),
                                  Text(t.price,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _kGreen)),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _remove(i),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Icon(Icons.favorite_rounded, color: Colors.red.shade400, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAIEMENTS
// ─────────────────────────────────────────────────────────────────────────────

enum _PayStatus { confirme, depasse, annule }

class _PayRecord {
  final String terrain, duration, date, amount, method, ref;
  final _PayStatus status;
  const _PayRecord({
    required this.terrain, required this.duration, required this.date,
    required this.amount, required this.method, required this.ref,
    this.status = _PayStatus.confirme,
  });
}

const _kHistory = [
  _PayRecord(terrain: 'Dakar Arena',      duration: '2h', date: '18 Mar 2026', amount: '10 000 F', method: 'Wave',         ref: 'MF-20260318-001'),
  _PayRecord(terrain: 'Stade Léopold',    duration: '1h', date: '12 Mar 2026', amount: '8 000 F',  method: 'Orange Money', ref: 'MF-20260312-002'),
  _PayRecord(terrain: 'Terrain Point E',  duration: '3h', date: '05 Mar 2026', amount: '19 500 F', method: 'Wave',         ref: 'MF-20260305-003', status: _PayStatus.depasse),
  _PayRecord(terrain: 'HLM FC Terrain',   duration: '1h', date: '28 Fév 2026', amount: '6 500 F',  method: 'Free Money',   ref: 'MF-20260228-004', status: _PayStatus.annule),
];

class _PaymentsScreen extends StatefulWidget {
  const _PaymentsScreen();
  @override
  State<_PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<_PaymentsScreen> {
  String _defaultMethod = 'Wave';

  static const _methods = [
    ('assets/images/wave.png',  'Wave',         '+221 77 123 45 67'),
    ('assets/images/om.png',    'Orange Money', '+221 76 987 65 43'),
    ('assets/images/free.png',  'Free Money',   '+221 78 111 22 33'),
  ];

  void _showPaymentDetail(_PayRecord r) {
    final isActive = r.status == _PayStatus.confirme;
    final statusLabel = r.status == _PayStatus.annule ? 'Annulé' : r.status == _PayStatus.depasse ? 'Dépassé' : 'Confirmé';
    final statusColor = r.status == _PayStatus.confirme ? _kGreen : r.status == _PayStatus.annule ? Colors.red.shade600 : Colors.orange.shade700;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(r.terrain,
                      style: GoogleFonts.orbitron(fontSize: 15, fontWeight: FontWeight.w900, color: _txt(context))),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(icon: Icons.calendar_today_rounded,    label: 'Date',          value: r.date),
            _DetailRow(icon: Icons.timer_outlined,             label: 'Durée',         value: r.duration),
            _DetailRow(icon: Icons.credit_card_rounded,        label: 'Méthode',       value: r.method),
            _DetailRow(icon: Icons.receipt_long_rounded,       label: 'Référence',     value: r.ref),
            _DetailRow(icon: Icons.payments_rounded,           label: 'Montant',       value: r.amount, valueColor: _kGreen),
            if (!isActive) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: statusColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r.status == _PayStatus.annule
                            ? 'Cette réservation a été annulée.'
                            : 'La date de cette réservation est dépassée.',
                        style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Fermer', textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, color: _kGreen)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _card(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _txt(context), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Paiements',
            style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w800, color: _txt(context))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Méthodes de paiement',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _sub(context))),
            const SizedBox(height: 8),
            Text('Appuyez pour définir par défaut',
                style: TextStyle(fontSize: 11, color: _sub(context))),
            const SizedBox(height: 12),
            ..._methods.map((m) {
              final isDefault = _defaultMethod == m.$2;
              return GestureDetector(
                onTap: () => setState(() => _defaultMethod = m.$2),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _card(context),
                    borderRadius: BorderRadius.circular(16),
                    border: isDefault ? Border.all(color: _kGreen, width: 1.5) : Border.all(color: Colors.transparent),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _kGreen.withValues(alpha: 0.08)),
                        child: ClipOval(child: Image.asset(m.$1, fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => const Icon(Icons.account_balance_wallet_rounded, color: _kGreen))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.$2, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _txt(context))),
                          const SizedBox(height: 2),
                          Text(m.$3, style: TextStyle(fontSize: 12, color: _sub(context))),
                        ]),
                      ),
                      if (isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Défaut', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kGreen)),
                        )
                      else
                        Icon(Icons.radio_button_unchecked_rounded, color: _sub(context).withValues(alpha: 0.4), size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            Text('Historique',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _sub(context))),
            const SizedBox(height: 12),
            ..._kHistory.map((r) {
              final color = r.status == _PayStatus.confirme ? _kGreen
                  : r.status == _PayStatus.annule ? Colors.red.shade600
                  : Colors.orange.shade700;
              final icon = r.status == _PayStatus.confirme ? Icons.check_circle_rounded
                  : r.status == _PayStatus.annule ? Icons.cancel_rounded
                  : Icons.schedule_rounded;
              return GestureDetector(
                onTap: () => _showPaymentDetail(r),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _card(context),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${r.terrain} · ${r.duration}',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _txt(context))),
                        const SizedBox(height: 2),
                        Text(r.date, style: TextStyle(fontSize: 11, color: _sub(context))),
                      ])),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(r.amount, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
                          const SizedBox(height: 2),
                          Icon(Icons.chevron_right_rounded, size: 16, color: _sub(context)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _DetailRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: _kGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: _kGreen),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
            style: TextStyle(fontSize: 13, color: _sub(context)))),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: valueColor ?? _txt(context))),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIDENTIALITÉ
// ─────────────────────────────────────────────────────────────────────────────

class _PrivacyScreen extends StatelessWidget {
  const _PrivacyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _card(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _txt(context), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Confidentialité & CGU',
            style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _PrivacySection(
              title: '1. Collecte des données',
              body: 'Nous collectons uniquement les informations nécessaires au bon fonctionnement de l\'application : nom, email, numéro de téléphone et historique de réservations.',
            ),
            _PrivacySection(
              title: '2. Utilisation',
              body: 'Vos données sont utilisées pour gérer vos réservations, vous envoyer des notifications liées à votre activité sur MiniFoot et améliorer notre service.',
            ),
            _PrivacySection(
              title: '3. Partage',
              body: 'Nous ne partageons jamais vos données personnelles à des tiers sans votre consentement, sauf obligation légale.',
            ),
            _PrivacySection(
              title: '4. Sécurité',
              body: 'Toutes les données sont chiffrées et stockées sur des serveurs sécurisés. Vos paiements transitent par des plateformes certifiées.',
            ),
            _PrivacySection(
              title: '5. Vos droits',
              body: 'Vous pouvez demander l\'accès, la modification ou la suppression de vos données à tout moment en nous contactant via le support.',
            ),
            _PrivacySection(
              title: '6. CGU',
              body: 'En utilisant MiniFoot, vous acceptez nos conditions générales d\'utilisation. MiniFoot se réserve le droit de modifier ces conditions avec notification préalable.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String title, body;
  const _PrivacySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _txt(context))),
        const SizedBox(height: 8),
        Text(body, style: TextStyle(fontSize: 13, color: _sub(context), height: 1.6)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AIDE & SUPPORT
// ─────────────────────────────────────────────────────────────────────────────

class _HelpScreen extends StatelessWidget {
  const _HelpScreen();

  static const _faqs = [
    ('Comment annuler une réservation ?', 'Allez dans "Mes réservations", sélectionnez la réservation concernée et appuyez sur "Annuler". L\'annulation est gratuite jusqu\'à 2h avant le début.'),
    ('Comment payer avec Wave ?', 'Sur la page de paiement, sélectionnez l\'icône Wave, entrez votre numéro et validez avec votre code PIN.'),
    ('Le terrain ne correspond pas à la description ?', 'Contactez directement le gérant via le chat, ou signalez un problème via le bouton "..." sur la fiche terrain.'),
    ('Comment partager une réservation ?', 'Depuis la page de confirmation QR, appuyez sur le bouton Partager pour envoyer le PDF ou le lien.'),
    ('Mon équipe peut-elle partager le coût ?', 'Oui ! Sur la page de paiement, choisissez le mode "Partagé" et définissez le nombre de participants.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _card(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _txt(context), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Aide & Support',
            style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w800, color: _txt(context))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact rapide
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Support MiniFoot',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 3),
                        Text('Disponible 7j/7 · 8h–22h',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.parse('https://wa.me/221777151061');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Contacter',
                          style: TextStyle(color: _kGreen, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Questions fréquentes',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _sub(context))),
            const SizedBox(height: 12),
            ..._faqs.map((faq) => _FaqTile(question: faq.$1, answer: faq.$2)),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question, answer;
  const _FaqTile({required this.question, required this.answer});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _open = !_open),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.question,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _txt(context))),
              ),
              Icon(_open ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: _kGreen, size: 20),
            ],
          ),
          if (_open) ...[
            const SizedBox(height: 10),
            Text(widget.answer,
                style: TextStyle(fontSize: 12, color: _sub(context), height: 1.5)),
          ],
        ],
      ),
    ),
  );
}








