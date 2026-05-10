import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'terrain_data.dart';
import 'booking_confirmation_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/reservation_provider.dart';
import 'player_experience_helpers.dart';

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
  int _filterIndex = 0; // 0 = En cours, 1 = Terminées
  List<Reservation> _reservations = [];
  bool _loaded = false;

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
      if (!mounted) return;
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      try {
        if (!mounted) return;
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
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
    final provider = context.watch<ReservationProvider>();
    final sections = buildReservationSections(reservations: _reservations);
    final activeCount = sections.today.length + sections.upcoming.length;
    final nextReservation = sections.nextReservation;

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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ReservationsOverviewCard(
                upcomingCount: activeCount,
                pastCount: sections.past.length,
                nextReservation: nextReservation,
              ),
            ),

            const SizedBox(height: 14),

            // ── LISTE ──
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _reservations.isEmpty
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
                  : RefreshIndicator(
                      onRefresh: _loadReservations,
                      child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        if (_filterIndex == 0 && nextReservation != null) ...[
                          const _ReservationSectionHeader(
                            title: 'Prochaine réservation',
                            accent: kGreen,
                          ),
                          const SizedBox(height: 12),
                          _ReservationCard(
                            reservation: nextReservation,
                            highlight: true,
                            canCancel: nextReservation.isActive,
                            onCancel: () => _cancelReservation(nextReservation),
                            onTap: () => _openReservation(nextReservation),
                          ),
                          const SizedBox(height: 18),
                        ],
                        if (_filterIndex == 0 && sections.today.isNotEmpty) ...[
                          _ReservationSectionHeader(
                            title: 'Aujourd\'hui',
                            count: sections.today.length,
                            accent: const Color(0xFFE65100),
                          ),
                          const SizedBox(height: 12),
                          ...sections.today
                              .where((reservation) => reservation.id != nextReservation?.id)
                              .map((reservation) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ReservationCard(
                                      reservation: reservation,
                                      highlight: false,
                                      canCancel: reservation.isActive,
                                      onCancel: () => _cancelReservation(reservation),
                                      onTap: () => _openReservation(reservation),
                                    ),
                                  )),
                          if (sections.today.where((reservation) => reservation.id != nextReservation?.id).isNotEmpty)
                            const SizedBox(height: 6),
                        ],
                        if (_filterIndex == 0 && sections.upcoming.isNotEmpty) ...[
                          _ReservationSectionHeader(
                            title: 'À venir',
                            count: sections.upcoming.length,
                            accent: kGreen,
                          ),
                          const SizedBox(height: 12),
                          ...sections.upcoming.map((reservation) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ReservationCard(
                                  reservation: reservation,
                                  highlight: false,
                                  canCancel: reservation.isActive,
                                  onCancel: () => _cancelReservation(reservation),
                                  onTap: () => _openReservation(reservation),
                                ),
                              )),
                        ],
                        if (_filterIndex == 1 && sections.past.isNotEmpty) ...[
                          _ReservationSectionHeader(
                            title: 'Historique',
                            count: sections.past.length,
                            accent: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          ...sections.past.map((reservation) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ReservationCard(
                                  reservation: reservation,
                                  highlight: false,
                                  canCancel: false,
                                  onCancel: () {},
                                  onTap: () => _openReservation(reservation),
                                ),
                              )),
                        ],
                        if (_filterIndex == 0 && activeCount == 0)
                          _InlineEmptyState(
                            icon: Icons.event_available_rounded,
                            title: 'Aucune réservation active',
                            subtitle: 'Explore les terrains pour réserver ton prochain créneau.',
                          ),
                        if (_filterIndex == 1 && sections.past.isEmpty)
                          _InlineEmptyState(
                            icon: Icons.history_rounded,
                            title: 'Pas encore d’historique',
                            subtitle: 'Tes réservations terminées apparaîtront ici.',
                          ),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _openReservation(Reservation reservation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          terrain: reservation.terrain,
          date: reservation.date,
          startSlot: reservation.startSlot,
          endSlot: reservation.endSlot,
          finalPrice: reservation.price,
          reference: reservation.reference,
          qrData: reservation.qrData,
          fromReservations: true,
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

  bool get _canViewQr => true;

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

class _ReservationsOverviewCard extends StatelessWidget {
  final int upcomingCount;
  final int pastCount;
  final Reservation? nextReservation;

  const _ReservationsOverviewCard({
    required this.upcomingCount,
    required this.pastCount,
    required this.nextReservation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nextReservation == null ? 'Aucun créneau actif' : 'Ta prochaine sortie est prête',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _txt(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nextReservation == null
                ? 'Dès que tu réserves un terrain, on le met ici pour y revenir vite.'
                : '${nextReservation!.terrain.name} · ${nextReservation!.startSlot} à ${nextReservation!.endSlot}',
            style: TextStyle(fontSize: 12, color: _sub(context), height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  label: 'Actives',
                  value: '$upcomingCount',
                  accent: kGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewMetric(
                  label: 'Historique',
                  value: '$pastCount',
                  accent: const Color(0xFFE65100),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _txt(context)),
          ),
        ],
      ),
    );
  }
}

class _ReservationSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Color accent;

  const _ReservationSectionHeader({
    required this.title,
    this.count,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.orbitron(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: _txt(context),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ],
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InlineEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: _card(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: _sub(context)),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _txt(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _sub(context), height: 1.4),
          ),
        ],
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
