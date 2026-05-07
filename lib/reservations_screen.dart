import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'terrain_data.dart';
import 'booking_confirmation_screen.dart';

// Données mock pour l'affichage des réservations (à remplacer par l'API)
const _mockT1 = Terrain(id: '1', name: 'Terrain Dakar Arena', address: 'Diamniadio, Dakar', zone: 'DAKAR', pricePerHour: 5000, rating: 4.8, lat: 14.7645, lng: -17.3660, imageUrl: 'https://images.pexels.com/photos/12486370/pexels-photo-12486370.jpeg?auto=compress&cs=tinysrgb&w=800');
const _mockT2 = Terrain(id: '2', name: 'Stade Léopold Sédar', address: 'Plateau, Dakar', zone: 'DAKAR', pricePerHour: 8000, rating: 4.5, lat: 14.6760, lng: -17.4469, imageUrl: 'https://images.pexels.com/photos/13783930/pexels-photo-13783930.jpeg?auto=compress&cs=tinysrgb&w=800');
const _mockT3 = Terrain(id: '3', name: 'Terrain Point E', address: 'Point E, Dakar', zone: 'DAKAR', pricePerHour: 6500, rating: 4.3, lat: 14.6928, lng: -17.4571, imageUrl: 'https://images.pexels.com/photos/7160121/pexels-photo-7160121.jpeg?auto=compress&cs=tinysrgb&w=800');
const _mockT4 = Terrain(id: '4', name: 'Terrain HLM', address: 'HLM Grand Yoff, Dakar', zone: 'DAKAR', pricePerHour: 4000, rating: 4.1, lat: 14.7120, lng: -17.4620, imageUrl: 'https://images.pexels.com/photos/13890306/pexels-photo-13890306.jpeg?auto=compress&cs=tinysrgb&w=800');

const Color kGreen = Color(0xFF006F39);
const Color kDark = Color(0xFF1A1A1A);
const Color kBeige = Color(0xFFF5F0E8);

// ── Helpers thème ──
bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c)   => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c)  => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)  => _isDark(c)
    ? const Color(0xFFF0EBE0).withOpacity(0.5)
    : Colors.black.withOpacity(0.45);

// ── MODÈLE ──
class Reservation {
  final String id;
  final Terrain terrain;
  final DateTime date;
  final String startSlot;
  final String endSlot;
  final int price;
  final String reference;
  bool cancelled;

  Reservation({
    required this.id,
    required this.terrain,
    required this.date,
    required this.startSlot,
    required this.endSlot,
    required this.price,
    required this.reference,
    this.cancelled = false,
  });

  bool get isPast => cancelled || date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
  bool get isActive => !isPast;
}

final _now = DateTime.now();

List<Reservation> buildFakeReservations() => [
  Reservation(
    id: '1',
    terrain: _mockT1,
    date: _now,
    startSlot: '10h00', endSlot: '11h30',
    price: 7500, reference: 'MF-1A4892',
  ),
  Reservation(
    id: '2',
    terrain: _mockT2,
    date: _now.add(const Duration(days: 2)),
    startSlot: '13h00', endSlot: '14h00',
    price: 8000, reference: 'MF-2B5123',
  ),
  Reservation(
    id: '3',
    terrain: _mockT3,
    date: _now.add(const Duration(days: 4)),
    startSlot: '16h00', endSlot: '17h30',
    price: 9750, reference: 'MF-3C6074',
  ),
  Reservation(
    id: '4',
    terrain: _mockT4,
    date: _now.add(const Duration(days: 6)),
    startSlot: '08h00', endSlot: '09h00',
    price: 4000, reference: 'MF-4D7238',
  ),
  Reservation(
    id: '5',
    terrain: _mockT1,
    date: _now.add(const Duration(days: 9)),
    startSlot: '18h00', endSlot: '19h30',
    price: 7500, reference: 'MF-5E8341',
  ),
  Reservation(
    id: '6',
    terrain: _mockT2,
    date: _now.subtract(const Duration(days: 3)),
    startSlot: '11h00', endSlot: '12h00',
    price: 8000, reference: 'MF-6F9102',
  ),
  Reservation(
    id: '7',
    terrain: _mockT3,
    date: _now.subtract(const Duration(days: 8)),
    startSlot: '09h00', endSlot: '10h00',
    price: 6500, reference: 'MF-7G0215',
  ),
];

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  DateTime _selectedDay = DateTime.now();
  late DateTime _weekStart;
  int _filterIndex = 0; // 0 = En cours, 1 = Terminées
  late List<Reservation> _reservations;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(_selectedDay);
    _reservations = buildFakeReservations();
  }

  DateTime _mondayOf(DateTime d) =>
      d.subtract(Duration(days: d.weekday - 1));

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthLabel(DateTime d) {
    const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _dayName(int weekday) {
    const names = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return names[weekday - 1];
  }

  // Réservations filtrées selon l'onglet
  List<Reservation> get _filtered => _filterIndex == 0
      ? (_reservations.where((r) => r.isActive).toList()
          ..sort((a, b) => a.date.compareTo(b.date)))
      : (_reservations.where((r) => r.isPast).toList()
          ..sort((a, b) => b.date.compareTo(a.date)));

  // Réservation du jour sélectionné dans la liste filtrée
  Reservation? get _selectedReservation {
    try {
      return _filtered.firstWhere((r) => _sameDay(r.date, _selectedDay));
    } catch (_) {
      return null;
    }
  }

  // Réservations restantes (hors jour sélectionné)
  List<Reservation> get _otherFiltered =>
      _filtered.where((r) => !_sameDay(r.date, _selectedDay)).toList();

  bool _hasReservation(DateTime day) =>
      _filtered.any((r) => _sameDay(r.date, day));

  Future<void> _cancelReservation(Reservation r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text('Annuler la réservation',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Theme.of(ctx).colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vous êtes sur le point d\'annuler :',
                style: TextStyle(fontSize: 13, color: _sub(ctx))),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.terrain.name,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Theme.of(ctx).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('${r.startSlot} → ${r.endSlot}  ·  ${r.price} F',
                      style: TextStyle(fontSize: 12, color: _sub(ctx))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text('Cette action est irréversible.',
                style: TextStyle(fontSize: 12, color: Colors.red.withOpacity(0.7))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Garder', style: TextStyle(color: _sub(ctx), fontWeight: FontWeight.w600)),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(ctx, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Annuler la résa',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => r.cancelled = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Réservation annulée'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedReservation;
    final others = _otherFiltered;

    return Scaffold(
      backgroundColor: _bg(context),
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
                      decoration: BoxDecoration(
                        color: _card(context),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _txt(context)),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('Mes Réservations',
                          style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w800, color: _txt(context))),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── FILTRES ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _card(context),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    _FilterTab(
                      label: 'En cours',
                      count: _reservations.where((r) => r.isActive).length,
                      selected: _filterIndex == 0,
                      onTap: () => setState(() { _filterIndex = 0; }),
                    ),
                    _FilterTab(
                      label: 'Terminées',
                      count: _reservations.where((r) => r.isPast).length,
                      selected: _filterIndex == 1,
                      onTap: () => setState(() { _filterIndex = 1; }),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── CALENDRIER SEMAINE ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: _card(context),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(_monthLabel(_weekStart),
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _txt(context))),
                      const Spacer(),
                      _ArrowBtn(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7))),
                      ),
                      const SizedBox(width: 8),
                      _ArrowBtn(
                        icon: Icons.chevron_right_rounded,
                        onTap: () => setState(() => _weekStart = _weekStart.add(const Duration(days: 7))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                            color: isSelected ? kGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Text('${day.day}',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : isToday ? kGreen : _txt(context))),
                              const SizedBox(height: 3),
                              Text(_dayName(day.weekday),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.7)
                                          : _sub(context))),
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

            const SizedBox(height: 16),

            // ── LISTE ──
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy_rounded,
                              size: 48, color: _sub(context).withOpacity(0.4)),
                          const SizedBox(height: 10),
                          Text(
                            _filterIndex == 0
                                ? 'Aucune réservation en cours'
                                : 'Aucune réservation terminée',
                            style: TextStyle(fontSize: 13, color: _sub(context)),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        // Carte du jour sélectionné
                        if (selected != null) ...[
                          _ReservationCard(
                            reservation: selected,
                            highlight: true,
                            canCancel: selected.isActive,
                            onCancel: () => _cancelReservation(selected),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingConfirmationScreen(
                                  terrain: selected.terrain,
                                  date: selected.date,
                                  startSlot: selected.startSlot,
                                  endSlot: selected.endSlot,
                                  finalPrice: selected.price,
                                  paymentMethod: 'Wave',
                                  reference: selected.reference,
                                  fromReservations: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Les autres
                        if (others.isNotEmpty) ...[
                          Row(
                            children: [
                              Text(
                                selected != null ? 'Autres' : (_filterIndex == 0 ? 'En cours' : 'Terminées'),
                                style: GoogleFonts.orbitron(
                                    fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: kGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('${others.length}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...others.map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ReservationCard(
                                  reservation: r,
                                  highlight: false,
                                  canCancel: r.isActive,
                                  onCancel: () => _cancelReservation(r),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingConfirmationScreen(
                                        terrain: r.terrain,
                                        date: r.date,
                                        startSlot: r.startSlot,
                                        endSlot: r.endSlot,
                                        finalPrice: r.price,
                                        paymentMethod: 'Wave',
                                        reference: r.reference,
                                        fromReservations: true,
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ],
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
  final Reservation reservation;
  final bool highlight;
  final bool canCancel;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  const _ReservationCard({
    required this.reservation,
    required this.highlight,
    required this.canCancel,
    required this.onCancel,
    required this.onTap,
  });

  String _dateChip(DateTime d) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
        'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  // Statut visuel
  String get _statusLabel {
    if (reservation.cancelled) return 'Annulée';
    if (reservation.date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) return 'Terminée';
    final now = DateTime.now();
    final isToday = reservation.date.year == now.year &&
        reservation.date.month == now.month &&
        reservation.date.day == now.day;
    return isToday ? 'Aujourd\'hui' : 'À venir';
  }

  Color get _statusColor {
    if (reservation.cancelled) return Colors.red.shade700;
    if (reservation.date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) return Colors.grey.shade500;
    final now = DateTime.now();
    final isToday = reservation.date.year == now.year &&
        reservation.date.month == now.month &&
        reservation.date.day == now.day;
    return isToday ? kGreen : const Color(0xFFE65100);
  }

  bool get _canViewQr => reservation.isActive;

  @override
  Widget build(BuildContext context) {
    final dimmed = !_canViewQr;
    return GestureDetector(
      onTap: _canViewQr ? onTap : null,
      child: Opacity(
        opacity: dimmed ? 0.65 : 1.0,
        child: Container(
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(dimmed ? 0.03 : 0.05), blurRadius: 10)],
          border: highlight
              ? Border.all(color: kGreen.withOpacity(0.35), width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Image (grisée si non active)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColorFiltered(
                      colorFilter: dimmed
                          ? const ColorFilter.matrix([
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0.2126, 0.7152, 0.0722, 0, 0,
                              0,      0,      0,      1, 0,
                            ])
                          : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                      child: Image.network(
                        reservation.terrain.imageUrl,
                        width: 80, height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                            width: 80, height: 80,
                            color: kGreen.withOpacity(0.10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chips + badge statut
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6, runSpacing: 4,
                                children: [
                                  _SmallChip(label: _dateChip(reservation.date), dark: false),
                                  _SmallChip(label: '${reservation.startSlot}-${reservation.endSlot}', dark: true),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(_statusLabel,
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: _statusColor)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(reservation.terrain.name,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _txt(context))),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.location_on_rounded, size: 11, color: _sub(context)),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(reservation.terrain.address,
                                style: TextStyle(fontSize: 11, color: _sub(context)),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text('${reservation.price} F',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: highlight ? kGreen : _txt(context))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Flèche si actif, cadenas si non
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: _canViewQr
                          ? (highlight ? kGreen : const Color(0xFFF0F0F0))
                          : const Color(0xFFEEEEEE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _canViewQr
                          ? Icons.arrow_forward_ios_rounded
                          : Icons.lock_outline_rounded,
                      size: 13,
                      color: _canViewQr
                          ? (highlight ? Colors.white : _sub(context))
                          : _sub(context).withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            // ── BOUTON ANNULER (seulement si actif) ──
            if (canCancel)
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                    border: Border(
                      top: BorderSide(color: Colors.red.withOpacity(0.12)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel_outlined, size: 15, color: Colors.red.shade700),
                      const SizedBox(width: 6),
                      Text('Annuler la réservation',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade700)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── FILTRE TAB ──
class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({required this.label, required this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? _txt(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? _card(context) : _sub(context))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? kGreen : _sub(context).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : _sub(context))),
            ),
          ],
        ),
      ),
    ),
  );
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
      color: dark ? _txt(context) : _card(context),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
            color: dark ? _card(context) : _txt(context))),
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
        color: _card(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: _txt(context)),
    ),
  );
}
