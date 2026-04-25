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
  const TerrainBookingScreen({super.key, required this.terrain});

  @override
  State<TerrainBookingScreen> createState() => _TerrainBookingScreenState();
}

class _TerrainBookingScreenState extends State<TerrainBookingScreen> {
  final TerrainService _service = TerrainService();

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  // Heure sous forme de minutes depuis minuit (08h = 480, 00h = 1440)
  int? _startMin;
  int? _endMin;

  List<TerrainSlot> _slots = [];
  bool _slotsLoading = false;

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
      _slots = await _service.fetchSlots(widget.terrain.id, date);
    } catch (_) {
      // si l'API échoue, on laisse tous les créneaux libres
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
  int get _pricePerSlot => widget.terrain.pricePerHour ~/ 2;

  int get _intervals =>
      _startMin != null && _endMin != null
          ? (_endMin! - _startMin!) ~/ 30
          : 0;

  int get _totalPrice => _intervals * _pricePerSlot;

  String get _durationLabel {
    final m = _intervals * 30;
    final h = m ~/ 60;
    final min = m % 60;
    if (h == 0) return '${m}min';
    if (min == 0) return '${h}h';
    return '${h}h${min.toString().padLeft(2,'0')}';
  }

  bool get _canConfirm => _selectedDay != null && _startMin != null && _endMin != null;

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

                    // ── CALENDRIER ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
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
                                        color: Colors.black.withValues(alpha: 0.35))),
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
                                    _startMin = null;
                                    _endMin = null;
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
                                            ? kGreen.withValues(alpha: 0.12)
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
                                                    ? Colors.black.withValues(alpha: 0.2)
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
                                  color: Colors.black.withValues(alpha: 0.4))),
                        ]),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Indication de sélection
                    Text(
                      _startMin == null
                          ? 'Touchez une plage pour le début'
                          : _endMin == null
                              ? 'Maintenant choisissez la fin  (${_fmt(_startMin!)} → ...)'
                              : '${_fmt(_startMin!)} → ${_fmt(_endMin!)}  ·  $_durationLabel  ·  $_totalPrice F',
                      style: TextStyle(
                          fontSize: 12,
                          color: _startMin != null && _endMin != null
                              ? kGreen
                              : Colors.black.withValues(alpha: 0.45),
                          fontWeight: _startMin != null && _endMin != null
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

                    if (_startMin != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _startMin = null;
                            _endMin = null;
                          }),
                          child: Row(
                            children: [
                              Icon(Icons.refresh_rounded,
                                  size: 14,
                                  color: Colors.black.withValues(alpha: 0.4)),
                              const SizedBox(width: 4),
                              Text('Réinitialiser la sélection',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black.withValues(alpha: 0.4))),
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
                    color: Colors.black.withValues(alpha: 0.06),
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
                        color: kGreen.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kGreen.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              color: kGreen, size: 16),
                          const SizedBox(width: 8),
                          Text('${_fmt(_startMin!)} → ${_fmt(_endMin!)}  ·  $_durationLabel',
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
                                date: _selectedDay!,
                                startSlot: _fmt(_startMin!),
                                endSlot: _fmt(_endMin!),
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

  // ── CONSTRUCTION DE LA GRILLE ──
  List<Widget> _buildTimeRows() {
    final rows = <Widget>[];

    // Lignes de 08h à 23h (start) + ligne 00h (fin uniquement si startMin set)
    for (int h = 8; h <= 23; h++) {
      rows.add(_buildHourRow(h));
    }
    // Ligne minuit (00h00) uniquement comme heure de fin possible
    if (_startMin != null) {
      rows.add(_buildHourRow(0, endOnly: true));
    }

    return rows;
  }

  Widget _buildHourRow(int hour, {bool endOnly = false}) {
    final label = hour == 0 ? '00h' : '${hour}h';

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.4))),
          ),
          Expanded(
            child: Row(
              children: _minutes.map((min) {
                // Pour 00h on n'affiche que 00
                if (hour == 0 && min > 0) return const Expanded(child: SizedBox());

                final totalMin = _toMin(hour, min);
                final booked = _isBooked(hour, min);

                // Logique de sélection
                final isStart = _startMin != null && _startMin == totalMin;
                final isEnd = _endMin != null && _endMin == totalMin;
                final isBetween = _startMin != null &&
                    _endMin != null &&
                    totalMin > _startMin! &&
                    totalMin < _endMin!;

                // Peut-on sélectionner ?
                bool canTap;
                if (booked) {
                  canTap = false;
                } else if (_startMin == null) {
                  // Phase 1 : sélection début (pas 00h)
                  canTap = !endOnly;
                } else if (_endMin == null) {
                  // Phase 2 : sélection fin (doit être après début)
                  canTap = totalMin > _startMin!;
                } else {
                  // Reset
                  canTap = true;
                }

                Color bgColor;
                Color textColor;
                if (booked) {
                  bgColor = const Color(0xFFEEEEEE);
                  textColor = const Color(0xFFBBBBBB);
                } else if (isStart || isEnd) {
                  bgColor = kDark;
                  textColor = Colors.white;
                } else if (isBetween) {
                  bgColor = kGreen.withValues(alpha: 0.12);
                  textColor = kGreen;
                } else {
                  bgColor = const Color(0xFFF2F2F2);
                  textColor = canTap ? Colors.black54 : const Color(0xFFCCCCCC);
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: canTap
                        ? () => setState(() {
                              if (_startMin == null || _endMin != null) {
                                // Nouveau début
                                _startMin = totalMin;
                                _endMin = null;
                              } else {
                                // Fin
                                _endMin = totalMin;
                              }
                            })
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          min.toString().padLeft(2, '0'),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: textColor),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
