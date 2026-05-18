import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'terrain_data.dart';
import 'booking_confirmation_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/reservation_provider.dart';
import 'app_snackbar.dart';

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
  final String? qrData;
  final String status;
  bool cancelled;

  Reservation({
    required this.id,
    required this.terrain,
    required this.date,
    required this.startSlot,
    required this.endSlot,
    required this.price,
    required this.reference,
    this.qrData,
    this.status = 'PENDING_PAYMENT',
    this.cancelled = false,
  });

  bool get isPast =>
      cancelled ||
      status == 'CANCELLED' ||
      status == 'COMPLETED' ||
      status == 'REFUNDED' ||
      status == 'PARTIALLY_REFUNDED' ||
      date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
  bool get isActive => !isPast;

  factory Reservation.fromApiJson(Map<String, dynamic> json) {
    final t = json['terrain'] as Map<String, dynamic>? ?? {};
    final images = t['images'] as List<dynamic>?;
    final imageUrl = images != null && images.isNotEmpty
        ? images.first['url'] as String? ?? ''
        : t['imageUrl'] as String? ?? '';

    final terrain = Terrain(
      id: t['id'] as String? ?? '',
      name: t['name'] as String? ?? '',
      address: t['address'] as String? ?? '',
      zone: t['zone'] as String? ?? 'DAKAR',
      pricePerHour: (t['pricePerHour'] as num?)?.toInt() ?? 0,
      rating: (t['rating'] as num?)?.toDouble() ?? 0,
      lat: (t['lat'] as num?)?.toDouble() ?? 0,
      lng: (t['lng'] as num?)?.toDouble() ?? 0,
      imageUrl: imageUrl,
    );

    final rawDate = json['date'] as String? ?? '';
    final date = rawDate.isNotEmpty ? DateTime.tryParse(rawDate) ?? DateTime.now() : DateTime.now();

    return Reservation(
      id: json['id'] as String? ?? '',
      terrain: terrain,
      date: date,
      startSlot: json['startSlot'] as String? ?? '',
      endSlot: json['endSlot'] as String? ?? '',
      price: (json['finalPrice'] as num?)?.toInt() ?? 0,
      reference: json['reference'] as String? ?? '',
      qrData: json['qrData'] as String?,
      status: json['status'] as String? ?? 'PENDING_PAYMENT',
    );
  }
}

class _CancellationPreview {
  final int penaltyPercent;
  final int penaltyAmount;
  final int refundAmount;
  final int hoursBeforeStart;

  const _CancellationPreview({
    required this.penaltyPercent,
    required this.penaltyAmount,
    required this.refundAmount,
    required this.hoursBeforeStart,
  });
}


class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  DateTime _selectedDay = DateTime.now();
  late DateTime _weekStart;
  int _filterIndex = 0; // 0 = En cours, 1 = Terminées
  List<Reservation> _reservations = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(_selectedDay);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadReservations();
    }
  }

  Future<void> _loadReservations() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final provider = context.read<ReservationProvider>();
    await provider.loadReservations(token);
    if (!mounted) return;
    setState(() {
      _reservations = provider.reservations
          .map((r) => Reservation.fromApiJson(r))
          .toList();
    });
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
    final policy = _cancellationPreview(r);
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: policy.penaltyPercent == 0
                    ? kGreen.withOpacity(0.08)
                    : Colors.orange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    policy.penaltyPercent == 0
                        ? 'Annulation sans pénalité'
                        : 'Pénalité: ${policy.penaltyPercent}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: policy.penaltyPercent == 0 ? kGreen : Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    policy.penaltyPercent == 0
                        ? 'Vous êtes à plus de 24h du match.'
                        : 'Dans les dernières 24h, chaque heure entamée retire 10%.',
                    style: TextStyle(fontSize: 11, color: _sub(ctx)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Remboursement estimé: ${_formatMoney(policy.refundAmount)} F',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Theme.of(ctx).colorScheme.onSurface),
                  ),
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
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      try {
        final result = await context.read<ReservationProvider>().cancelReservation(token, r.id);
        await _loadReservations();
        if (mounted) {
          final cancellation = result['cancellation'] as Map<String, dynamic>?;
          final refundAmount = (cancellation?['refundAmount'] as num?)?.toInt();
          final penaltyPercent = (cancellation?['penaltyPercent'] as num?)?.toInt();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                refundAmount != null && penaltyPercent != null
                    ? 'Réservation annulée · Remboursement ${_formatMoney(refundAmount)} F · Pénalité $penaltyPercent%'
                    : 'Réservation annulée',
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.error(context, 'Impossible d\'annuler cette réservation. Réessayez.');
        }
      }
    }
  }

  _CancellationPreview _cancellationPreview(Reservation r) {
    final start = _reservationStartAt(r);
    final msBeforeStart = start.difference(DateTime.now()).inMilliseconds;
    final hoursBeforeStart = msBeforeStart <= 0 ? 0 : msBeforeStart ~/ Duration.millisecondsPerHour;
    final lateHours = msBeforeStart <= 0 ? 24 : (24 - hoursBeforeStart).clamp(0, 24).toInt();
    final penaltyPercent = (lateHours * 10).clamp(0, 100).toInt();
    final penaltyAmount = (r.price * penaltyPercent ~/ 100);
    final refundAmount = (r.price - penaltyAmount).clamp(0, r.price).toInt();
    return _CancellationPreview(
      penaltyPercent: penaltyPercent,
      penaltyAmount: penaltyAmount,
      refundAmount: refundAmount,
      hoursBeforeStart: hoursBeforeStart,
    );
  }

  DateTime _reservationStartAt(Reservation r) {
    final normalized = r.startSlot.replaceAll(':', 'h');
    final parts = normalized.split('h');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return DateTime(r.date.year, r.date.month, r.date.day, hour, minute);
  }

  String _formatMoney(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
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
              child: context.watch<ReservationProvider>().isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
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
                                  reference: selected.reference,
                                  qrData: selected.qrData,
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
                                        reference: r.reference,
                                        qrData: r.qrData,
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
