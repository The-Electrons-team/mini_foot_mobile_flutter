import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/team_provider.dart';
import 'app_snackbar.dart';

const Color _kGreen = Color(0xFF006F39);

bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c) => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c) => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c) => _isDark(c)
    ? const Color(0xFFF0EBE0).withOpacity(0.5)
    : Colors.black.withOpacity(0.45);

const _teamColors = [
  Color(0xFFB71C1C),
  Color(0xFF880E4F),
  Color(0xFF4A148C),
  Color(0xFF311B92),
  Color(0xFF1A237E),
  Color(0xFF0D47A1),
  Color(0xFF01579B),
  Color(0xFF006064),
  Color(0xFF004D40),
  Color(0xFF006F39),
  Color(0xFF33691E),
  Color(0xFF827717),
  Color(0xFFF57F17),
  Color(0xFFFF6F00),
  Color(0xFFE65100),
  Color(0xFFBF360C),
  Color(0xFF3E2723),
  Color(0xFF212121),
  Color(0xFF263238),
  Color(0xFF000000),
  Color(0xFF1B5E20),
  Color(0xFF4E342E),
  Color(0xFF8D6E63),
  Color(0xFF757575),
  Color(0xFF00838F),
  Color(0xFF2E86AB),
  Color(0xFFD84315),
];

//  PAGE : CREER UNE EQUIPE
class CreateTeamScreen extends StatefulWidget {
  final Map<String, dynamic>? team;

  const CreateTeamScreen({super.key, this.team});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _nameCtrl = TextEditingController();
  Color _color = const Color(0xFF006F39);
  XFile? _logoFile;
  Uint8List? _logoBytes;
  String? _logoUrl;
  bool _nameError = false;
  String _address = '';
  LatLng? _location;
  bool _locating = false;
  bool _isSubmitting = false;
  bool get _isEditing => widget.team != null;

  Color _parseColor(String? value) {
    final fallback = const Color(0xFF006F39);
    if (value == null || value.isEmpty) return fallback;
    var hex = value.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }

  double? _doubleValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _determineZone(LatLng? location, String address) {
    final lowerAddress = address.toLowerCase();
    if (lowerAddress.contains('thiès') || lowerAddress.contains('thies'))
      return 'THIES';
    if (lowerAddress.contains('saint-louis') ||
        lowerAddress.contains('saint louis'))
      return 'SAINT_LOUIS';
    if (lowerAddress.contains('diourbel')) return 'DIOURBEL';
    if (lowerAddress.contains('kaolack')) return 'KAOLACK';
    if (lowerAddress.contains('fatick')) return 'FATICK';
    if (lowerAddress.contains('ziguinchor')) return 'ZIGUINCHOR';
    return 'DAKAR';
  }

  @override
  void initState() {
    super.initState();
    final team = widget.team;
    if (team != null) {
      _nameCtrl.text = team['name']?.toString() ?? '';
      _address = team['address']?.toString() ?? '';
      _color = _parseColor(team['color']?.toString());
      _logoUrl = team['logoUrl']?.toString();
      final lat = _doubleValue(team['lat']);
      final lng = _doubleValue(team['lng']);
      if (lat != null && lng != null) {
        _location = LatLng(lat, lng);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _useGPS() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final ll = LatLng(pos.latitude, pos.longitude);
      final result = await Navigator.push<_LocationResult>(
        context,
        MaterialPageRoute(builder: (_) => _LocationPickerPage(initial: ll)),
      );
      if (result != null && mounted)
        setState(() {
          _location = result.latlng;
          _address = result.address;
        });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ColorPickerSheet(
        initial: _color,
        onChanged: (c) => setState(() => _color = c),
      ),
    );
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<_LocationResult>(
      context,
      MaterialPageRoute(builder: (_) => const _LocationPickerPage()),
    );
    if (result != null && mounted)
      setState(() {
        _location = result.latlng;
        _address = result.address;
      });
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 400,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _logoFile = picked;
        _logoBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }

    setState(() => _isSubmitting = true);

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final teamProv = Provider.of<TeamProvider>(context, listen: false);

    if (authProv.token == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      List<int>? logoBytes;
      String? logoName;
      if (_logoFile != null) {
        logoBytes = await _logoFile!.readAsBytes();
        logoName = _logoFile!.name;
      }

      final color =
          '#${_color.value.toRadixString(16).substring(2).toUpperCase()}';
      final zone = _determineZone(_location, _address);

      if (_isEditing) {
        await teamProv.updateTeam(
          token: authProv.token!,
          teamId: widget.team!['id'].toString(),
          name: name,
          zone: zone,
          address: _address,
          color: color,
          lat: _location?.latitude,
          lng: _location?.longitude,
          logoBytes: logoBytes,
          logoFilename: logoName,
        );
      } else {
        await teamProv.createTeam(
          token: authProv.token!,
          name: name,
          zone: zone,
          address: _address,
          color: color,
          lat: _location?.latitude,
          lng: _location?.longitude,
          logoBytes: logoBytes,
          logoFilename: logoName,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Equipe modifiee avec succes !'
                  : 'Equipe cree avec succes !',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Impossible de créer l\'équipe. Réessayez.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: _sub(context),
      ),
    ),
  );

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
                    _isEditing ? 'Modifier equipe' : 'Creer mon equipe',
                    style: GoogleFonts.orbitron(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _txt(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _sectionTitle('Logo'),
                  Center(
                    child: GestureDetector(
                      onTap: _pickLogo,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _color.withOpacity(0.12),
                              border: Border.all(
                                color: _color.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                            child: _logoBytes != null
                                ? ClipOval(
                                    child: Image.memory(
                                      _logoBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _logoUrl != null && _logoUrl!.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      _logoUrl!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_rounded,
                                        color: _color,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Logo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          if (_logoBytes != null ||
                              (_logoUrl != null && _logoUrl!.isNotEmpty))
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: _kGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  _sectionTitle('Nom de l\'équipe'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _card(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _nameError
                            ? Colors.red.shade300
                            : _sub(context).withOpacity(0.15),
                      ),
                    ),
                    child: TextField(
                      controller: _nameCtrl,
                      onChanged: (_) => setState(() => _nameError = false),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _txt(context),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ex: Les Lions FC',
                        hintStyle: TextStyle(
                          color: _sub(context),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  if (_nameError)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        'Le nom est obligatoire',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),

                  _sectionTitle('Couleur'),
                  GestureDetector(
                    onTap: () => _showColorPicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _card(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _sub(context).withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _color.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '#${_color.value.toRadixString(16).substring(2).toUpperCase()}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _txt(context),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Icon(
                            Icons.colorize_rounded,
                            color: _sub(context),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _sectionTitle('Localisation'),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _locating ? null : _useGPS,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _kGreen.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _kGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _locating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _kGreen,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.my_location_rounded,
                                        color: _kGreen,
                                        size: 16,
                                      ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Ma position',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _kGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _openMapPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _card(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _sub(context).withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map_rounded,
                                  color: _sub(context),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Sur la carte',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _sub(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_location != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _kGreen.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kGreen.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: _kGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _address.isNotEmpty
                                  ? _address
                                  : '${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _txt(context),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() {
                              _location = null;
                              _address = '';
                            }),
                            child: Icon(
                              Icons.close_rounded,
                              color: _sub(context),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _sub(context).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_off_rounded,
                            color: _sub(context),
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Aucune localisation',
                            style: TextStyle(
                              fontSize: 12,
                              color: _sub(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _isSubmitting ? null : _save,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: _isSubmitting
                            ? _kGreen.withOpacity(0.5)
                            : _kGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _isSubmitting
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Text(
                              _isEditing
                                  ? 'Enregistrer les modifications'
                                  : 'Creer l equipe',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                    ),
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

//  COLOR PICKER
class _ColorPickerSheet extends StatefulWidget {
  final Color initial;
  final ValueChanged<Color> onChanged;
  const _ColorPickerSheet({required this.initial, required this.onChanged});
  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late HSVColor _hsv;
  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
  }

  Color get _current => _hsv.toColor();
  void _emit(Color c) => widget.onChanged(c);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _sub(context).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _current,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _current.withOpacity(0.5), blurRadius: 12),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Couleur',
                      style: TextStyle(fontSize: 12, color: _sub(context)),
                    ),
                    Text(
                      '#${_current.value.toRadixString(16).substring(2).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _txt(context),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: _kGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Teinte',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _sub(context),
                ),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(
            height: 36,
            child: Stack(
              children: [
                Positioned(
                  left: 10,
                  right: 10,
                  top: 10,
                  bottom: 10,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: CustomPaint(painter: _RainbowPainter()),
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 16,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 18,
                    ),
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
                    overlayColor: HSVColor.fromAHSV(
                      0.2,
                      _hsv.hue,
                      1,
                      1,
                    ).toColor(),
                  ),
                  child: Slider(
                    value: _hsv.hue,
                    min: 0,
                    max: 360,
                    onChanged: (h) {
                      setState(() => _hsv = _hsv.withHue(h));
                      _emit(_current);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Saturation',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _sub(context),
                ),
              ),
              const Spacer(),
              Text(
                '${(_hsv.saturation * 100).round()}%',
                style: TextStyle(fontSize: 11, color: _sub(context)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 10,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: _current,
              inactiveTrackColor: _sub(context).withOpacity(0.15),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: _hsv.saturation,
              onChanged: (v) {
                setState(() => _hsv = _hsv.withSaturation(v));
                _emit(_current);
              },
            ),
          ),
          Row(
            children: [
              Text(
                'Luminosite',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _sub(context),
                ),
              ),
              const Spacer(),
              Text(
                '${(_hsv.value * 100).round()}%',
                style: TextStyle(fontSize: 11, color: _sub(context)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 10,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: _current,
              inactiveTrackColor: _sub(context).withOpacity(0.15),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: _hsv.value,
              onChanged: (v) {
                setState(() => _hsv = _hsv.withValue(v));
                _emit(_current);
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Couleurs predefinies',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _sub(context),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _teamColors.map((c) {
              final sel = c.value == _current.value;
              return GestureDetector(
                onTap: () {
                  setState(() => _hsv = HSVColor.fromColor(c));
                  _emit(c);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: sel
                        ? Border.all(color: _txt(context), width: 2.5)
                        : null,
                    boxShadow: sel
                        ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)]
                        : null,
                  ),
                  child: sel
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RainbowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      colors: List.generate(
        7,
        (i) => HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor(),
      ),
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(_) => false;
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
  @override
  State<_LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<_LocationPickerPage> {
  late final MapController _mapCtrl;
  LatLng _picked = const LatLng(14.7167, -17.4677);
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
    if (widget.initial != null) _picked = widget.initial!;
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  Future<void> _goToGPS() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final ll = LatLng(pos.latitude, pos.longitude);
      setState(() => _picked = ll);
      _mapCtrl.move(ll, 15);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _locating = false);
    }
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

  void _confirm() => Navigator.pop(
    context,
    _LocationResult(latlng: _picked, address: _coordsToAddress(_picked)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _picked,
              initialZoom: 14,
              onTap: (_, ll) => setState(() => _picked = ll),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=${dotenv.env['MAPBOX_ACCESS_TOKEN']}',
                userAgentPackageName: 'com.minifoot.app',
                tileSize: 512,
                zoomOffset: -1,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _picked,
                    width: 48,
                    height: 48,
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: _kGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        CustomPaint(
                          size: const Size(12, 8),
                          painter: _TrianglePainter(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
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
                          color: Colors.black.withOpacity(0.12),
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
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _card(context),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: _kGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _coordsToAddress(_picked),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _txt(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Appuie sur la carte pour placer le marqueur',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 120,
            child: GestureDetector(
              onTap: _locating ? null : _goToGPS,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _card(context),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: _locating
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kGreen,
                        ),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        color: _kGreen,
                        size: 22,
                      ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 20,
            right: 20,
            child: GestureDetector(
              onTap: _confirm,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: _kGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Confirmer - ${_coordsToAddress(_picked)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = _kGreen);
  }

  @override
  bool shouldRepaint(_) => false;
}
