import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'terrain_data.dart';
import 'services/terrain_service.dart';
import 'payment_screen.dart';

const Color kGreen = Color(0xFF006F39);
const Color kDark = Color(0xFF1A1A1A);
const Color kBeige = Color(0xFFF5F0E8);

class TerrainBookingScreen extends StatefulWidget {
  final Terrain terrain;
  final SubTerrain? initialSubTerrain;
  const TerrainBookingScreen({super.key, required this.terrain, this.initialSubTerrain});

  @override
  State<TerrainBookingScreen> createState() => _TerrainBookingScreenState();
}

class _TerrainBookingScreenState extends State<TerrainBookingScreen> {
  final TerrainService _service = TerrainService();

  DateTime _focusedMonth = DateTime.now();
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
  }

  static const List<int> _minutes = [0, 30];

  // Convertit heure+min en minutes (0 = minuit → 1440)
  int _toMin(int hour, int min) => hour == 0 ? 1440 + min : hour * 60 + min;

  // Affichage heure
  String _fmt(int totalMin) {
    final h = (totalMin ~/ 60) % 24;
    final m = totalMin % 60;
    return '${h.toString().padLeft(2,'0')}h${m.toString().padLeft(2,'0')}';
  }

  Future<void> _loadSlots(DateTime day) async {
    setState(() { _slotsLoading = true; _slots = []; });
    try {
      final date = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      _slots = await _service.fetchSlots(
        widget.terrain.id,
        date,
        subTerrainId: _selectedSubTerrain?.id
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de charger les créneaux : ${e.toString().replaceFirst('Exception: ', '')}'),
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
    final label = '${hour.toString().padLeft(2,'0')}h${min.toString().padLeft(2,'0')}';
    final slot = _slots.firstWhere(
      (s) => s.slot == label,
      orElse: () => TerrainSlot(slot: label, available: true),
    );
    return !slot.available;
  }

  // Prix par 30 min
  int get _pricePerSlot {
    final price = _selectedSubTerrain?.pricePerHour ?? widget.terrain.pricePerHour;
    return price ~/ 2;
  }

  int get _intervals => _selectedDuration ~/ 30;

  int get _totalPrice => _intervals * _pricePerSlot;

  String get _durationLabel {
    final h = _selectedDuration ~/ 60;
    final min = _selectedDuration % 60;
    if (h == 0) return '${_selectedDuration}min';
    if (min == 0) return '${h}h';
    return '${h}h${min.toString().padLeft(2, '0')}';
  }

  bool get _canConfirm => _selectedStartMin != null && _selectedDay != null;

  int get _endMin => (_selectedStartMin ?? 0) + _selectedDuration;

  // ── CALENDRIER ──
  List<DateTime> _daysInMonth() {
    final last = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    return List.generate(last.day,
        (i) => DateTime(_focusedMonth.year, _focusedMonth.month, i + 1));
  }

  void _prevMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));
  void _nextMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  bool _isPast(DateTime day) =>
      day.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  String _monthName(int m) => [
        '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ][m];

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth();
    final firstWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;

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
                      width: 40, height: 40,
                      decoration: const BoxDecoration(
                          color: Color(0xFFF0F0F0), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: kDark),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Réserver',
                          style: GoogleFonts.orbitron(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: kDark)),
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
                      const Text('Choisir un terrain',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kDark)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 54,
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
                                if (_selectedDay != null) _loadSlots(_selectedDay!);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: selected ? kDark : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: selected ? kDark : const Color(0xFFEEEEEE)),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(s.name, style: TextStyle(
                                        color: selected ? Colors.white : kDark,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12
                                      )),
                                      Text('${s.type} · ${s.capacity} pers', style: TextStyle(
                                        color: selected ? Colors.white70 : Colors.black45,
                                        fontSize: 10
                                      )),
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

                    // ── CALENDRIER ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10)],
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: _prevMonth,
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.chevron_left_rounded,
                                      size: 20, color: kDark),
                                ),
                              ),
                              Text(
                                '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: kDark),
                              ),
                              GestureDetector(
                                onTap: _nextMonth,
                                child: Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.chevron_right_rounded,
                                      size: 20, color: kDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: ['D','L','M','M','J','V','S'].map((d) =>
                              SizedBox(
                                width: 34,
                                child: Text(d,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black.withOpacity(0.35))),
                              )).toList(),
                          ),
                          const SizedBox(height: 6),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7, childAspectRatio: 1),
                            itemCount: days.length + firstWeekday,
                            itemBuilder: (_, i) {
                              if (i < firstWeekday) return const SizedBox();
                              final day = days[i - firstWeekday];
                              final past = _isPast(day);
                              final selected = _selectedDay != null &&
                                  _selectedDay!.day == day.day &&
                                  _selectedDay!.month == day.month;
                              final isToday = day.day == DateTime.now().day &&
                                  day.month == DateTime.now().month &&
                                  day.year == DateTime.now().year;
                              return GestureDetector(
                                onTap: past ? null : () {
                                  setState(() {
                                    _selectedDay = day;
                                    _selectedStartMin = null;
                                  });
                                  _loadSlots(day);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? kDark
                                        : isToday
                                            ? kGreen.withOpacity(0.12)
                                            : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${day.day}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: selected || isToday
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                            color: selected
                                                ? Colors.white
                                                : past
                                                    ? Colors.black.withOpacity(0.2)
                                                    : kDark)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── PLAGES HORAIRES ──
                    Row(
                      children: [
                        const Text('Plage horaire',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: kDark)),
                        const Spacer(),
                        // Légende
                        Row(children: [
                          Container(width: 10, height: 10,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(3))),
                          const SizedBox(width: 4),
                          Text('Indisponible',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black.withOpacity(0.4))),
                        ]),
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
                              : FontWeight.normal),
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
                                    vertical: 8, horizontal: 10),
                                child: Column(
                                  children: _buildTimeRows(),
                                ),
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
                              Icon(Icons.refresh_rounded,
                                  size: 14,
                                  color: Colors.black.withOpacity(0.4)),
                              const SizedBox(width: 4),
                              const Text('Réinitialiser la sélection',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54)),
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
                  20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: kBeige,
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_canConfirm) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kGreen.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              color: kGreen, size: 16),
                          const SizedBox(width: 8),
                          Text('${_fmt(_selectedStartMin!)} → ${_fmt(_endMin)}  ·  $_durationLabel',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kDark)),
                          const Spacer(),
                          Text('$_totalPrice F',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: kGreen)),
                        ],
                      ),
                    ),
                  ],
                  GestureDetector(
                    onTap: _canConfirm
                        ? () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                terrain: widget.terrain,
                                subTerrain: _selectedSubTerrain,
                                date: _selectedDay!,
                                startSlot: _fmt(_selectedStartMin!),
                                endSlot: _fmt(_endMin),
                                totalPrice: _totalPrice,
                                intervals: _intervals,
                              ),
                            ));
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
                              child: Text('Confirmer la réservation',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                          ),
                          Container(
                            width: 42, height: 42,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: _canConfirm ? kGreen : Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
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
      const Text('Heure de début', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kDark)),
      const SizedBox(height: 16),
      _buildStartTimeGrid(),
      const SizedBox(height: 40),
    ];
  }

  Widget _buildDurationSelector() {
    final durations = [60, 90, 120];
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
                  boxShadow: isSel ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
                ),
                child: Center(
                  child: Text(
                    '${d} min',
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

  Widget _buildStartTimeGrid() {
    final startTimes = _getAvailableStartTimes();
    if (startTimes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_busy_rounded, size: 40, color: kDark.withOpacity(0.1)),
              const SizedBox(height: 12),
              Text('Aucun créneau disponible pour cette durée', 
                  style: TextStyle(color: kDark.withOpacity(0.4), fontSize: 13)),
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
              border: Border.all(color: isSel ? kGreen : const Color(0xFFE0E0E0)),
              boxShadow: isSel ? [BoxShadow(color: kGreen.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
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
    final available = <int>[];
    // On cherche de 08h à 23h30
    for (int h = 8; h < 24; h++) {
      for (int m in _minutes) {
        final start = _toMin(h, m);
        final end = start + _selectedDuration;
        if (end > 1440) continue; // Pas après minuit

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
