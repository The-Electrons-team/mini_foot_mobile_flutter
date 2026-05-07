import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'package:intl/intl.dart';

const Color _kGreen = Color(0xFF006F39);

// ─── Helpers thème ──────────────────────────────────────────────────────────
bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c)   => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c)  => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)  => _isDark(c)
    ? const Color(0xFFF0EBE0).withOpacity(0.5)
    : Colors.black.withOpacity(0.45);

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATIONS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.token != null) {
        context.read<NotificationProvider>().loadNotifications(auth.token!);
      }
    });
  }

  void _markAllRead() {
    final auth = context.read<AuthProvider>();
    if (auth.token != null) {
      context.read<NotificationProvider>().markAllAsRead(auth.token!);
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
  }

  @override
  Widget build(BuildContext context) {
    final notifProv = context.watch<NotificationProvider>();
    final authProv = context.watch<AuthProvider>();
    final items = notifProv.notifications;
    final unreadCount = notifProv.unreadCount;
    final isLoading = notifProv.isLoading;

    final unread = items.where((n) => !n.read).toList();
    final read   = items.where((n) =>  n.read).toList();

    return Scaffold(
      backgroundColor: _bg(context),
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
                        if (unreadCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text('$unreadCount non lue${unreadCount > 1 ? "s" : ""}',
                                style: TextStyle(fontSize: 12, color: _sub(context))),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: unreadCount > 0 ? _markAllRead : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: unreadCount > 0
                            ? _kGreen.withOpacity(0.1)
                            : _sub(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: unreadCount > 0
                              ? _kGreen.withOpacity(0.25)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text('Tout lire',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: unreadCount > 0 ? _kGreen : _sub(context))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _sub(context).withOpacity(0.1),
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
              child: isLoading && items.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: _kGreen))
                  : items.isEmpty
                      ? _EmptyState()
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            if (unread.isNotEmpty) ...[
                              const _SectionLabel(label: 'Nouvelles'),
                              ...unread.map((n) => _NotifTile(
                                    notif: n,
                                    onTap: () {
                                      if (authProv.token != null) {
                                        notifProv.markAsRead(authProv.token!, n.id);
                                      }
                                    },
                                  )),
                            ],
                            if (read.isNotEmpty) ...[
                              const _SectionLabel(label: 'Précédentes'),
                              ...read.map((n) => _NotifTile(
                                    notif: n,
                                    onTap: () {},
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
  final NotificationModel notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  IconData get _icon {
    switch (notif.type) {
      case NotifType.RESERVATION:
      case NotifType.RESERVATION_CONFIRMED:
      case NotifType.RESERVATION_CANCELLED:
      case NotifType.MATCH_REMINDER:
        return Icons.calendar_today_rounded;
      case NotifType.MATCH:
      case NotifType.TEAM_INVITATION:
      case NotifType.TEAM_JOIN_REQUEST:
      case NotifType.TEAM_MEMBER_JOINED:
      case NotifType.CHALLENGE_RECEIVED:
      case NotifType.CHALLENGE_RESPONSE:
      case NotifType.SCORE_SUBMITTED:
        return Icons.sports_soccer_rounded;
      case NotifType.PROMO:
        return Icons.local_offer_rounded;
      case NotifType.SYSTEM:
        return Icons.info_outline_rounded;
      case NotifType.CHAT:
      case NotifType.CHAT_MESSAGE:
        return Icons.chat_bubble_outline_rounded;
      case NotifType.SOCIAL_LIKE:
        return Icons.favorite_rounded;
      case NotifType.SOCIAL_COMMENT:
        return Icons.comment_rounded;
    }
  }

  Color get _color {
    switch (notif.type) {
      case NotifType.RESERVATION:
      case NotifType.RESERVATION_CONFIRMED:
      case NotifType.RESERVATION_CANCELLED:
      case NotifType.MATCH_REMINDER:
        return _kGreen;
      default:
        return const Color(0xFF1565C0);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return DateFormat('dd MMM', 'fr_FR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final readCardColor = _isDark(context)
        ? _card(context).withOpacity(0.5)
        : Colors.white.withOpacity(0.6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.read ? readCardColor : _card(context),
          borderRadius: BorderRadius.circular(18),
          boxShadow: notif.read
              ? null
              : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
          border: notif.read
              ? null
              : Border.all(color: _color.withOpacity(0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _color.withOpacity(notif.read ? 0.07 : 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(_icon, color: _color.withOpacity(notif.read ? 0.5 : 1.0), size: 20),
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
                          color: notif.read ? _sub(context).withOpacity(0.7) : _sub(context),
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(_formatDate(notif.createdAt),
                      style: TextStyle(
                          fontSize: 11,
                          color: notif.read ? _sub(context).withOpacity(0.6) : _color,
                          fontWeight: notif.read ? FontWeight.w400 : FontWeight.w600)),
                ],
              ),
            ),
          ],
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
            color: _kGreen.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.notifications_none_rounded,
              size: 40, color: _kGreen.withOpacity(0.4)),
        ),
        const SizedBox(height: 16),
        Text('Aucune notification',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _sub(context))),
        const SizedBox(height: 6),
        Text('Vous êtes à jour !',
            style: TextStyle(fontSize: 12, color: _sub(context).withOpacity(0.6))),
      ],
    ),
  );
}
