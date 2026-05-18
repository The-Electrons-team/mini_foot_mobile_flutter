import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'terrain_data.dart';
import 'services/terrain_service.dart';
import 'providers/auth_provider.dart';
import 'payment_screen.dart';

const Color kGreen = Color(0xFF006F39);
const Color kDark = Color(0xFF1A1A1A);
const Color kBeige = Color(0xFFF5F0E8);

class TerrainBookingScreen extends StatefulWidget {
  final Terrain terrain;
  final SubTerrain? initialSubTerrain;
  const TerrainBookingScreen({
    super.key,
    required this.terrain,
    this.initialSubTerrain,
  });

  @override
  State<TerrainBookingScreen> createState() => _TerrainBookingScreenState();
}

class _TerrainBookingScreenState extends State<TerrainBookingScreen> {
  final TerrainService _service = TerrainService();

  late DateTime _focusedWeekStart;
  DateTime? _selectedDay;

  SubTerrain? _selectedSubTerrain;

  List<TerrainSlot> _slots = [];
  bool _slotsLoading = false;
  int _selectedDuration = 60; // en minutes
  int? _selectedStartMin;

  @override
  void initState() {
    super.initState();
    if (widget.initialSubTerrain != null) {
      _selectedSubTerrain = widget.initialSubTerrain;
    } else if (widget.terrain.subTerrains.isNotEmpty) {
      _selectedSubTerrain = widget.terrain.subTerrains.first;
    }
    final today = DateTime.now();
    _focusedWeekStart = _startOfWeek(today);
    _selectedDay = today;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSlots(today));
  }

  static DateTime _startOfWeek(DateTime d) {
    // Lundi = début de semaine
    return DateTime(d.year, d.month, d.day)
        .subtract(Duration(days: (d.weekday - 1) % 7));
  }

  static const List<int> _minutes = [0, 30];

  // Convertit heure+min en minutes (0 = minuit → 1440)
  int _toMin(int hour, int min) => hour == 0 ? 1440 + min : hour * 60 + min;

  // Affichage heure
  String _fmt(int totalMin) {
    if (totalMin == 1440) return '24h00';
    final h = (totalMin ~/ 60) % 24;
    final m = totalMin % 60;
    return '${h.toString().padLeft(2, '0')}h${m.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSlots(DateTime day) async {
    setState(() {
      _slotsLoading = true;
      _slots = [];
    });
    try {
      final date =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      _slots = await _service.fetchSlots(
        widget.terrain.id,
        date,
        token: context.read<AuthProvider>().token,
        subTerrainId: _selectedSubTerrain?.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Impossible de charger les créneaux : ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _slotsLoading = false);
    }
  }

  // Slot grisé ?
  bool _isBooked(int hour, int min) {
    if (_slots.isEmpty) return false;
    final label =
        '${hour.toString().padLeft(2, '0')}h${min.toString().padLeft(2, '0')}';
    final slot = _slots.firstWhere(
      (s) => s.slot == label,
      orElse: () => TerrainSlot(slot: label, available: true),
    );
    return !slot.available;
  }

  int get _intervals => _selectedDuration ~/ 30;

  // Prix total calculé par tranche de 30 min, comme le backend.
  int get _totalPrice {
    final start = _selectedStartMin;
    final day = _selectedDay;
    if (start == null || day == null) {
      final pricePerHour =
          _selectedSubTerrain?.pricePerHour ?? widget.terrain.pricePerHour;
      return (pricePerHour * _selectedDuration / 60).round();
    }

    var total = 0;
    for (var i = 0; i < _intervals; i++) {
      final slotMinutes = start + (i * 30);
      final hourlyPrice = _hourlyPriceForSlot(day, slotMinutes);
      total += (hourlyPrice / 2).ceil();
    }
    return total;
  }

  int _hourlyPriceForSlot(DateTime day, int slotMinutes) {
    final subTerrain = _selectedSubTerrain;
    final fallback = subTerrain?.pricePerHour ?? widget.terrain.pricePerHour;
    for (final period in subTerrain?.pricingPeriods ?? const <PricingPeriod>[]) {
      if (period.pricePerHour > 0 && period.appliesTo(day, slotMinutes)) {
        return period.pricePerHour;
      }
    }
    return fallback;
  }

  String get _durationLabel {
    final h = _selectedDuration ~/ 60;
    final min = _selectedDuration % 60;
    if (h == 0) return '${_selectedDuration}min';
    if (min == 0) return '${h}h';
    return '${h}h${min.toString().padLeft(2, '0')}';
  }

  bool get _canConfirm => _selectedStartMin != null && _selectedDay != null;

  int get _endMin => (_selectedStartMin ?? 0) + _selectedDuration;

  // ── CALENDRIER SEMAINE ──
  void _prevWeek() => setState(
    () => _focusedWeekStart =
        _focusedWeekStart.subtract(const Duration(days: 7)),
  );
  void _nextWeek() => setState(
    () =>
        _focusedWeekStart = _focusedWeekStart.add(const Duration(days: 7)),
  );

  bool _isPast(DateTime day) {
    final today = DateTime.now();
    return day.isBefore(DateTime(today.year, today.month, today.day));
  }

  String _monthName(int m) => [
    '',
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ][m];

  String _weekLabel() {
    final end = _focusedWeekStart.add(const Duration(days: 6));
    if (_focusedWeekStart.month == end.month) {
      return '${_monthName(_focusedWeekStart.month)} ${_focusedWeekStart.year}';
    }
    return '${_monthName(_focusedWeekStart.month)} – ${_monthName(end.month)} ${end.year}';
  }

  Widget _buildWeekStrip() {
    final weekDays =
        List.generate(7, (i) => _focusedWeekStart.add(Duration(days: i)));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête mois + navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _prevWeek,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: kDark,
                  ),
                ),
              ),
              Text(
                _weekLabel(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: kDark,
                ),
              ),
              GestureDetector(
                onTap: _nextWeek,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: kDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Jours de la semaine
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                .map(
                  (d) => SizedBox(
                    width: 36,
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.35),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          // Cercles des jours
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) {
              final dayOnly = DateTime(day.year, day.month, day.day);
              final past = dayOnly.isBefore(today);
              final isToday = dayOnly.isAtSameMomentAs(today);
              final selected = _selectedDay != null &&
                  _selectedDay!.year == day.year &&
                  _selectedDay!.month == day.month &&
                  _selectedDay!.day == day.day;
              return GestureDetector(
                onTap: past
                    ? null
                    : () {
                        setState(() {
                          _selectedDay = day;
                          _selectedStartMin = null;
                        });
                        _loadSlots(day);
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? kDark
                        : isToday
                            ? kGreen.withOpacity(0.12)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isToday && !selected
                        ? Border.all(color: kGreen, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected || isToday
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : past
                                ? Colors.black.withOpacity(0.2)
                                : kDark,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      body: SafeArea(
        child: Column(
          children: [
            // ── APP BAR ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F0F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: kDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Réserver',
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: kDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── SÉLECTION DU TERRAIN ──
                    if (widget.terrain.subTerrains.isNotEmpty) ...[
                      const Text(
                        'Choisir une option',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: kDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 68,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.terrain.subTerrains.length,
                          itemBuilder: (context, i) {
                            final s = widget.terrain.subTerrains[i];
                            final selected = _selectedSubTerrain?.id == s.id;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSubTerrain = s;
                                  _selectedStartMin = null;
                                });
                                if (_selectedDay != null)
                                  _loadSlots(_selectedDay!);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: selected ? kDark : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected
                                        ? kDark
                                        : const Color(0xFFEEEEEE),
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        s.reservationLabel,
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : kDark,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '${s.divisionLabel} · ${s.type}',
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.white70
                                              : Colors.black45,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],

                    // ── CALENDRIER SEMAINE COMPACT ──
                    _buildWeekStrip(),

                    const SizedBox(height: 22),

                    // ── PLAGES HORAIRES ──
                    Row(
                      children: [
                        const Text(
                          'Plage horaire',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: kDark,
                          ),
                        ),
                        const Spacer(),
                        // Légende
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E0E0),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Indisponible',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Indication de sélection
                    Text(
                      _selectedStartMin == null
                          ? 'Choisissez une heure de début'
                          : '${_fmt(_selectedStartMin!)} → ${_fmt(_endMin)}  ·  $_durationLabel  ·  $_totalPrice F',
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectedStartMin != null
                            ? kGreen
                            : Colors.black.withOpacity(0.45),
                        fontWeight: _selectedStartMin != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Grille compacte dans un conteneur scrollable
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _slotsLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 10,
                                ),
                                child: Column(children: _buildTimeRows()),
                              ),
                            ),
                    ),

                    if (_selectedStartMin != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedStartMin = null;
                          }),
                          child: Row(
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 14,
                                color: Colors.black.withOpacity(0.4),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Réinitialiser la sélection',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── BOUTON CONFIRMER ──
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: kBeige,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_canConfirm) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kGreen.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: kGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_fmt(_selectedStartMin!)} → ${_fmt(_endMin)}  ·  $_durationLabel',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kDark,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$_totalPrice F',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: kGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  GestureDetector(
                    onTap: _canConfirm
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentScreen(
                                  terrain: widget.terrain,
                                  subTerrain: _selectedSubTerrain,
                                  date: _selectedDay!,
                                  startSlot: _fmt(_selectedStartMin!),
                                  endSlot: _fmt(_endMin),
                                  totalPrice: _totalPrice,
                                  intervals: _intervals,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 54,
                      decoration: BoxDecoration(
                        color: _canConfirm ? kDark : const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 22),
                              child: Text(
                                'Confirmer la réservation',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 42,
                            height: 42,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: _canConfirm ? kGreen : Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
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

  // ── NOUVELLE UI BASÉE SUR LA DURÉE ──
  List<Widget> _buildTimeRows() {
    return [
      _buildDurationSelector(),
      const SizedBox(height: 24),
      const Text(
        'Heure de début',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: kDark,
        ),
      ),
      const SizedBox(height: 16),
      _buildStartTimeGrid(),
      const SizedBox(height: 40),
    ];
  }

  Widget _buildDurationSelector() {
    final durations = [60, 90, 120, 150]; // 1h, 1h30, 2h, 2h30
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: durations.map((d) {
          final isSel = _selectedDuration == d;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedDuration = d;
                _selectedStartMin = null; // Reset start on duration change
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _formatDuration(d),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel ? kGreen : kDark.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final min = minutes % 60;
    if (min == 0) return '${h}h';
    return '${h}h${min.toString().padLeft(2, '0')}';
  }

  Widget _buildStartTimeGrid() {
    final startTimes = _getAvailableStartTimes();
    if (startTimes.isEmpty) {
      // Différencier : jour non sélectionné vs tous les créneaux pris/bloqués
      final String msg;
      if (_selectedDay == null) {
        msg = 'Sélectionnez un jour pour voir les créneaux';
      } else if (_slots.isNotEmpty) {
        msg = 'Aucun créneau libre pour cette durée ce jour-là';
      } else {
        msg = 'Aucun créneau disponible pour cette durée';
      }
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 40,
                color: kDark.withOpacity(0.1),
              ),
              const SizedBox(height: 12),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: kDark.withOpacity(0.4), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: startTimes.map((t) {
        final isSel = _selectedStartMin == t;
        return GestureDetector(
          onTap: () => setState(() => _selectedStartMin = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: (MediaQuery.of(context).size.width - 64) / 4,
            height: 44,
            decoration: BoxDecoration(
              color: isSel ? kGreen : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel ? kGreen : const Color(0xFFE0E0E0),
              ),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: kGreen.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                _fmt(t),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                  color: isSel ? Colors.white : kDark,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<int> _getAvailableStartTimes() {
    if (_selectedDay == null) return [];
    final available = <int>[];

    // Déterminer si le jour sélectionné est aujourd'hui pour filtrer les heures passées
    final now = DateTime.now();
    final isToday = _selectedDay != null &&
        _selectedDay!.year == now.year &&
        _selectedDay!.month == now.month &&
        _selectedDay!.day == now.day;
    // En minutes depuis minuit, arrondi au prochain créneau de 30 min
    final nowMin = now.hour * 60 + now.minute;

    // On cherche de 08h à 23h30
    for (int h = 8; h < 24; h++) {
      for (int m in _minutes) {
        final start = _toMin(h, m);
        final end = start + _selectedDuration;
        if (end > 1440) continue; // Pas après minuit

        // Masquer les créneaux déjà passés si le jour est aujourd'hui
        if (isToday && start <= nowMin) continue;

        // Vérifier si toute la plage [start, end[ est libre
        bool allFree = true;
        for (int check = start; check < end; check += 30) {
          final hh = (check ~/ 60) % 24;
          final mm = check % 60;
          if (_isBooked(hh, mm)) {
            allFree = false;
            break;
          }
        }
        if (allFree) available.add(start);
      }
    }
    return available;
  }
}
