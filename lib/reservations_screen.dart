import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'terrain_data.dart';
import 'booking_confirmation_screen.dart';

const Color kGreen = Color(0xFF006F39);
const Color kDark = Color(0xFF1A1A1A);
const Color kBeige = Color(0xFFF5F0E8);

// ── MODÈLE RÉSERVATION FICTIVE ──
class _Reservation {
  final Terrain terrain;
  final DateTime date;
  final String startSlot;
  final String endSlot;
  final int price;
  final String reference;
  final String status; // 'active' | 'upcoming' | 'past'

  const _Reservation({
    required this.terrain,
    required this.date,
    required this.startSlot,
    required this.endSlot,
    required this.price,
    required this.reference,
    required this.status,
  });
}

final _now = DateTime.now();

final List<_Reservation> _fakeReservations = [
  _Reservation(
    terrain: terrains[0],
    date: _now,
    startSlot: '10h00',
    endSlot: '11h30',
    price: 7500,
    reference: 'MF-1A4892',
    status: 'active',
  ),
  _Reservation(
    terrain: terrains[1],
    date: _now.add(const Duration(days: 2)),
    startSlot: '13h00',
    endSlot: '14h00',
    price: 8000,
    reference: 'MF-2B5123',
    status: 'upcoming',
  ),
  _Reservation(
    terrain: terrains[2],
    date: _now.add(const Duration(days: 4)),
    startSlot: '16h00',
    endSlot: '17h30',
    price: 9750,
    reference: 'MF-3C6074',
    status: 'upcoming',
  ),
  _Reservation(
    terrain: terrains[3],
    date: _now.add(const Duration(days: 6)),
    startSlot: '08h00',
    endSlot: '09h00',
    price: 4000,
    reference: 'MF-4D7238',
    status: 'upcoming',
  ),
  _Reservation(
    terrain: terrains[0],
    date: _now.add(const Duration(days: 9)),
    startSlot: '18h00',
    endSlot: '19h30',
    price: 7500,
    reference: 'MF-5E8341',
    status: 'upcoming',
  ),
  _Reservation(
    terrain: terrains[1],
    date: _now.subtract(const Duration(days: 3)),
    startSlot: '11h00',
    endSlot: '12h00',
    price: 8000,
    reference: 'MF-6F9102',
    status: 'past',
  ),
];

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  DateTime _selectedDay = DateTime.now();
  // Semaine affichée: lundi de la semaine courante
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(_selectedDay);
  }

  DateTime _mondayOf(DateTime d) {
    return d.subtract(Duration(days: d.weekday - 1));
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthLabel(DateTime d) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _dayName(int weekday) {
    const names = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return names[weekday - 1];
  }

  // Réservation du jour sélectionné (la première trouvée)
  _Reservation? get _selectedReservation {
    try {
      return _fakeReservations.firstWhere((r) => _sameDay(r.date, _selectedDay));
    } catch (_) {
      return null;
    }
  }

  // Réservations à venir (pas le jour sélectionné)
  List<_Reservation> get _upcoming => _fakeReservations
      .where((r) =>
          !_sameDay(r.date, _selectedDay) &&
          !r.date.isBefore(DateTime.now().subtract(const Duration(days: 1))))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  // Jours avec réservation (pour le point indicateur)
  bool _hasReservation(DateTime day) =>
      _fakeReservations.any((r) => _sameDay(r.date, day));

  @override
  Widget build(BuildContext context) {
    final selected = _selectedReservation;
    final upcoming = _upcoming;

    return Scaffold(
      backgroundColor: kBeige,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kDark),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Mes Réservations',
                          style: GoogleFonts.orbitron(
                              fontSize: 14, fontWeight: FontWeight.w800, color: kDark)),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── CALENDRIER SEMAINE ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  // Mois + flèches
                  Row(
                    children: [
                      Text(_monthLabel(_weekStart),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15, color: kDark)),
                      const Spacer(),
                      _ArrowBtn(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => setState(() {
                          _weekStart = _weekStart.subtract(const Duration(days: 7));
                        }),
                      ),
                      const SizedBox(width: 8),
                      _ArrowBtn(
                        icon: Icons.chevron_right_rounded,
                        onTap: () => setState(() {
                          _weekStart = _weekStart.add(const Duration(days: 7));
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Jours
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _weekDays.map((day) {
                      final isSelected = _sameDay(day, _selectedDay);
                      final isToday = _sameDay(day, DateTime.now());
                      final hasDot = _hasReservation(day);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDay = day),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? kDark : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text('${day.day}',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : isToday
                                              ? kGreen
                                              : kDark)),
                              const SizedBox(height: 3),
                              Text(_dayName(day.weekday),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : Colors.black.withValues(alpha: 0.4))),
                              const SizedBox(height: 5),
                              Container(
                                width: 5, height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hasDot
                                      ? (isSelected ? Colors.white : kGreen)
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── LISTE ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carte du jour sélectionné
                    if (selected != null) ...[
                      _ReservationCard(reservation: selected, highlight: true),
                      const SizedBox(height: 20),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.event_busy_rounded,
                                size: 36, color: Colors.black.withValues(alpha: 0.2)),
                            const SizedBox(height: 8),
                            Text('Aucune réservation ce jour',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black.withValues(alpha: 0.35))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // À venir
                    if (upcoming.isNotEmpty) ...[
                      Row(
                        children: [
                          Text('À venir',
                              style: GoogleFonts.orbitron(
                                  fontSize: 14, fontWeight: FontWeight.w800, color: kDark)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${upcoming.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...upcoming.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ReservationCard(reservation: r, highlight: false),
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CARTE RÉSERVATION ──
class _ReservationCard extends StatelessWidget {
  final _Reservation reservation;
  final bool highlight;

  const _ReservationCard({required this.reservation, required this.highlight});

  String _dateChip(DateTime d) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
        'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(
            terrain: reservation.terrain,
            date: reservation.date,
            startSlot: reservation.startSlot,
            endSlot: reservation.endSlot,
            finalPrice: reservation.price,
            paymentMethod: 'Wave',
            reference: reservation.reference,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
          ],
          border: highlight
              ? Border.all(color: kGreen.withValues(alpha: 0.3), width: 1.5)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  reservation.terrain.imageUrl,
                  width: 80, height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                      width: 80, height: 80,
                      color: kGreen.withValues(alpha: 0.10)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chips
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: [
                        _SmallChip(label: _dateChip(reservation.date), dark: false),
                        _SmallChip(label: '${reservation.startSlot}-${reservation.endSlot}', dark: true),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(reservation.terrain.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13, color: kDark)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 11, color: Colors.black38),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(reservation.terrain.address,
                            style: const TextStyle(fontSize: 11, color: Colors.black38),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text('${reservation.price} F',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: highlight ? kGreen : kDark)),
                  ],
                ),
              ),
              // Flèche
              const SizedBox(width: 6),
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: highlight ? kGreen : const Color(0xFFF0F0F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: highlight ? Colors.white : Colors.black38),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── CHIP ──
class _SmallChip extends StatelessWidget {
  final String label;
  final bool dark;
  const _SmallChip({required this.label, required this.dark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: dark ? kDark : const Color(0xFFF0F0F0),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: dark ? Colors.white : kDark)),
  );
}

// ── BOUTON FLÈCHE ──
class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: kDark),
    ),
  );
}
