import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _kGreen = Color(0xFF006F39);

// ─── Helpers thème ──────────────────────────────────────────────────────────
bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c)   => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c)  => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)  => _isDark(c)
    ? const Color(0xFFF0EBE0).withValues(alpha: 0.5)
    : Colors.black.withValues(alpha: 0.45);

// ── MODÈLE ──

enum NotifType { reservation, match, promo, system, chat }

class _Notif {
  final String id, title, body, time;
  final NotifType type;
  bool read;

  _Notif({
    required this.id, required this.title, required this.body,
    required this.time, required this.type, this.read = false,
  });
}

// ── DONNÉES ──

final List<_Notif> _notifications = [
  _Notif(id: '1', title: 'Réservation confirmée',      body: 'Votre réservation au Terrain Dakar Arena pour demain 10h est confirmée.',        time: 'Il y a 5min',  type: NotifType.reservation),
  _Notif(id: '2', title: 'Nouveau message',            body: 'Les Lions FC : "Rdv demain 10h au terrain !"',                                     time: 'Il y a 12min', type: NotifType.chat),
  _Notif(id: '3', title: 'Match proposé',              body: 'Tigres FC vous challenge ce samedi à 16h au Terrain HLM.',                         time: 'Il y a 1h',    type: NotifType.match),
  _Notif(id: '4', title: 'Offre spéciale',             body: '-20% sur toutes les réservations avant 10h. Code : MATIN20',                        time: 'Il y a 3h',    type: NotifType.promo,       read: true),
  _Notif(id: '5', title: 'Rappel de réservation',      body: 'Votre match commence dans 2h au Stade Léopold Sédar. Bonne chance !',               time: 'Hier',         type: NotifType.reservation, read: true),
  _Notif(id: '6', title: 'Invitation acceptée',        body: 'Diallo Ibra a accepté votre invitation à rejoindre Les Lions FC.',                  time: 'Hier',         type: NotifType.match,       read: true),
  _Notif(id: '7', title: 'Nouveau terrain disponible', body: "Un nouveau terrain vient d'ouvrir à Parcelles Assainies. Découvrez-le !",           time: '02 Mar',       type: NotifType.system,      read: true),
  _Notif(id: '8', title: 'Paiement reçu',              body: 'Votre paiement de 10 000 F pour Dakar Arena a bien été reçu.',                     time: '01 Mar',       type: NotifType.reservation, read: true),
  _Notif(id: '9', title: 'Tournoi ouvert',             body: 'La Coupe du Sénégal MiniFoot est ouverte aux inscriptions. 16 équipes max.',        time: '28 Fév',       type: NotifType.promo,       read: true),
];

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATIONS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_Notif> _items = List.from(_notifications);

  int get _unreadCount => _items.where((n) => !n.read).length;

  void _markAllRead() {
    setState(() { for (final n in _items) { n.read = true; } });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Toutes les notifications ont été lues'),
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _dismiss(String id) => setState(() => _items.removeWhere((n) => n.id == id));

  void _markRead(String id) => setState(() {
    final n = _items.firstWhere((n) => n.id == id);
    n.read = true;
  });

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((n) => !n.read).toList();
    final read   = _items.where((n) =>  n.read).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HEADER ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notifications',
                            style: GoogleFonts.orbitron(
                                fontSize: 20, fontWeight: FontWeight.w900,
                                color: _txt(context))),
                        if (_unreadCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text('$_unreadCount non lue${_unreadCount > 1 ? "s" : ""}',
                                style: TextStyle(fontSize: 12, color: _sub(context))),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _unreadCount > 0 ? _markAllRead : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _unreadCount > 0
                            ? _kGreen.withValues(alpha: 0.1)
                            : _sub(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _unreadCount > 0
                              ? _kGreen.withValues(alpha: 0.25)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text('Tout lire',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _unreadCount > 0 ? _kGreen : _sub(context))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _sub(context).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, size: 18, color: _sub(context)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── LISTE ──
            Expanded(
              child: _items.isEmpty
                  ? _EmptyState()
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        if (unread.isNotEmpty) ...[
                          _SectionLabel(label: 'Nouvelles'),
                          ...unread.map((n) => _NotifTile(
                                notif: n,
                                onTap: () => _markRead(n.id),
                                onDismiss: () => _dismiss(n.id),
                              )),
                        ],
                        if (read.isNotEmpty) ...[
                          _SectionLabel(label: 'Précédentes'),
                          ...read.map((n) => _NotifTile(
                                notif: n,
                                onTap: () {},
                                onDismiss: () => _dismiss(n.id),
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

// ── SECTION LABEL ──
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
    child: Text(label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: _sub(context), letterSpacing: 0.5)),
  );
}

// ── NOTIF TILE ──
class _NotifTile extends StatelessWidget {
  final _Notif notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _NotifTile({required this.notif, required this.onTap, required this.onDismiss});

  IconData get _icon {
    switch (notif.type) {
      case NotifType.reservation: return Icons.calendar_today_rounded;
      case NotifType.match:       return Icons.sports_soccer_rounded;
      case NotifType.promo:       return Icons.local_offer_rounded;
      case NotifType.system:      return Icons.info_outline_rounded;
      case NotifType.chat:        return Icons.chat_bubble_outline_rounded;
    }
  }

  Color get _color {
    switch (notif.type) {
      case NotifType.reservation: return _kGreen;
      case NotifType.match:       return const Color(0xFF1565C0);
      case NotifType.promo:       return const Color(0xFFE65100);
      case NotifType.system:      return const Color(0xFF37474F);
      case NotifType.chat:        return const Color(0xFF6A1B9A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readCardColor = _isDark(context)
        ? _card(context).withValues(alpha: 0.5)
        : Colors.white.withValues(alpha: 0.6);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.read ? readCardColor : _card(context),
            borderRadius: BorderRadius.circular(18),
            boxShadow: notif.read
                ? null
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
            border: notif.read
                ? null
                : Border.all(color: _color.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: notif.read ? 0.07 : 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_icon, color: _color.withValues(alpha: notif.read ? 0.5 : 1.0), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notif.title,
                              style: TextStyle(
                                  fontWeight: notif.read ? FontWeight.w600 : FontWeight.w800,
                                  fontSize: 13.5,
                                  color: notif.read ? _sub(context) : _txt(context))),
                        ),
                        if (!notif.read)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notif.body,
                        style: TextStyle(
                            fontSize: 12,
                            color: notif.read ? _sub(context).withValues(alpha: 0.7) : _sub(context),
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(notif.time,
                        style: TextStyle(
                            fontSize: 11,
                            color: notif.read ? _sub(context).withValues(alpha: 0.6) : _color,
                            fontWeight: notif.read ? FontWeight.w400 : FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── EMPTY STATE ──
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: _kGreen.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.notifications_none_rounded,
              size: 40, color: _kGreen.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 16),
        Text('Aucune notification',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _sub(context))),
        const SizedBox(height: 6),
        Text('Vous êtes à jour !',
            style: TextStyle(fontSize: 12, color: _sub(context).withValues(alpha: 0.6))),
      ],
    ),
  );
}

// ignore: unused_element
Color _bgUnused(BuildContext c) => _bg(c); // keep _bg referenced
