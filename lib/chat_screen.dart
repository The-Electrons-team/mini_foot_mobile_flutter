import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _kBeige  = Color(0xFFF5F0E8);
const Color _kGreen  = Color(0xFF006F39);
const Color _kDark   = Color(0xFF1A1A1A);

// ── Helpers thème ──
bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c)   => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c)  => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)  => _isDark(c)
    ? const Color(0xFFF0EBE0).withValues(alpha: 0.5)
    : Colors.black.withValues(alpha: 0.45);

// ── CONTACTS FAKE DATA ──

class _Contact {
  final String name;
  final String sub;
  final String initials;
  final Color color;
  const _Contact({required this.name, required this.sub, required this.initials, required this.color});
}

const _teamsContacts = [
  _Contact(name: 'Tigres FC',           sub: '11 membres · Dakar',    initials: 'TF', color: Color(0xFFE65100)),
  _Contact(name: 'Étoiles du Plateau',  sub: '8 membres · Plateau',   initials: 'EP', color: Color(0xFF1565C0)),
  _Contact(name: 'Black Panthers',      sub: '10 membres · Parcelles',initials: 'BP', color: Color(0xFF212121)),
  _Contact(name: 'FC Médina',           sub: '9 membres · Médina',    initials: 'FM', color: Color(0xFF006F39)),
  _Contact(name: 'Aigles de Pikine',    sub: '12 membres · Pikine',   initials: 'AP', color: Color(0xFF6A1B9A)),
  _Contact(name: 'Warriors HLM',        sub: '7 membres · HLM',       initials: 'WH', color: Color(0xFFAD1457)),
];

const _managersContacts = [
  _Contact(name: 'Gérant Dakar Arena',     sub: 'Diamniadio · 4 terrains', initials: 'DA', color: Color(0xFF1565C0)),
  _Contact(name: 'Gérant Stade Léopold',   sub: 'Plateau · 2 terrains',    initials: 'SL', color: Color(0xFF006F39)),
  _Contact(name: 'Gérant Terrain Point E', sub: 'Point E · 1 terrain',     initials: 'PE', color: Color(0xFF37474F)),
  _Contact(name: 'Gérant HLM Complex',     sub: 'HLM · 3 terrains',        initials: 'HC', color: Color(0xFF6A1B9A)),
  _Contact(name: 'Gérant Parcelles Arena', sub: 'Parcelles · 2 terrains',  initials: 'PA', color: Color(0xFFE65100)),
];

const _playersContacts = [
  _Contact(name: 'Ibrahima Diallo', sub: 'Attaquant · 4.8 ★', initials: 'ID', color: Color(0xFF00695C)),
  _Contact(name: 'Ousmane Seck',    sub: 'Milieu · 4.5 ★',    initials: 'OS', color: Color(0xFFAD1457)),
  _Contact(name: 'Moussa Ndiaye',   sub: 'Défenseur · 4.7 ★', initials: 'MN', color: Color(0xFF1A237E)),
  _Contact(name: 'Cheikh Fall',     sub: 'Gardien · 4.6 ★',   initials: 'CF', color: Color(0xFFE65100)),
  _Contact(name: 'Aliou Badji',     sub: 'Attaquant · 4.4 ★', initials: 'AB', color: Color(0xFF006F39)),
  _Contact(name: 'Pape Sarr',       sub: 'Milieu · 4.9 ★',    initials: 'PS', color: Color(0xFF6A1B9A)),
  _Contact(name: 'Lamine Koné',     sub: 'Défenseur · 4.3 ★', initials: 'LK', color: Color(0xFF1565C0)),
];

// ── MODÈLES ──

enum ChatType { team, manager, direct }

class ChatPreview {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final ChatType type;
  final String initials;
  final Color avatarColor;
  final bool isOnline;
  final bool isSentByMe;

  const ChatPreview({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.type,
    required this.initials,
    required this.avatarColor,
    this.isOnline = false,
    this.isSentByMe = false,
  });
}

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  const ChatMessage({required this.text, required this.isMe, required this.time});
}

// ── DONNÉES ──

final List<ChatPreview> _chats = [
  const ChatPreview(
    id: '1', name: 'Les Lions FC',
    lastMessage: 'Rdv demain 10h au terrain !',
    time: 'Maintenant', unread: 5, type: ChatType.team,
    initials: 'LF', avatarColor: Color(0xFF006F39), isOnline: true,
  ),
  const ChatPreview(
    id: '2', name: 'Gérant Dakar Arena',
    lastMessage: 'Oui le terrain est disponible ce soir',
    time: 'Il y a 2min', unread: 1, type: ChatType.manager,
    initials: 'DA', avatarColor: Color(0xFF1565C0), isOnline: true,
  ),
  const ChatPreview(
    id: '3', name: 'Équipe Plateau Stars',
    lastMessage: 'On vous challenge ce samedi !',
    time: '08:32', unread: 3, type: ChatType.team,
    initials: 'PS', avatarColor: Color(0xFFE65100),
  ),
  const ChatPreview(
    id: '4', name: 'Gérant Stade Léopold',
    lastMessage: 'Votre réservation est confirmée',
    time: '16:15', unread: 0, type: ChatType.manager,
    initials: 'SL', avatarColor: Color(0xFF6A1B9A), isSentByMe: true,
  ),
  const ChatPreview(
    id: '5', name: 'Ibrahima Diallo',
    lastMessage: 'T\'es dispo ce soir pour jouer ?',
    time: 'Hier', unread: 0, type: ChatType.direct,
    initials: 'ID', avatarColor: Color(0xFF00695C),
  ),
  const ChatPreview(
    id: '6', name: 'Ousmane Seck',
    lastMessage: 'On cherche 2 joueurs pour compléter',
    time: 'Hier', unread: 0, type: ChatType.direct,
    initials: 'OS', avatarColor: Color(0xFFAD1457), isSentByMe: true,
  ),
  const ChatPreview(
    id: '7', name: 'Gérant Terrain Point E',
    lastMessage: 'Le tarif de nuit est 6 500 F/h',
    time: '02/12', unread: 0, type: ChatType.manager,
    initials: 'PE', avatarColor: Color(0xFF37474F),
  ),
  const ChatPreview(
    id: '8', name: 'Moussa Ndiaye',
    lastMessage: 'Super match hier',
    time: '02/10', unread: 0, type: ChatType.direct,
    initials: 'MN', avatarColor: Color(0xFF1A237E), isSentByMe: true,
  ),
];

final Map<String, List<ChatMessage>> _messages = {
  '1': [
    const ChatMessage(text: 'Salut l\'équipe ! Rdv demain 10h au Terrain Dakar Arena', isMe: false, time: '09:00'),
    const ChatMessage(text: 'Je serai là', isMe: true, time: '09:02'),
    const ChatMessage(text: 'Moi aussi, on ramène le ballon ?', isMe: false, time: '09:05'),
    const ChatMessage(text: 'Oui le terrain en fournit un mais amenez quand même', isMe: false, time: '09:06'),
    const ChatMessage(text: 'OK top ! On se retrouve là-bas', isMe: true, time: '09:10'),
    const ChatMessage(text: 'Rdv demain 10h au terrain !', isMe: false, time: 'Maintenant'),
  ],
  '2': [
    const ChatMessage(text: 'Bonjour, est-ce que le terrain est disponible ce soir entre 18h et 20h ?', isMe: true, time: '14:30'),
    const ChatMessage(text: 'Bonjour ! Oui le terrain est disponible ce soir', isMe: false, time: '14:35'),
    const ChatMessage(text: 'Parfait ! Je fais la réservation sur l\'app', isMe: true, time: '14:36'),
    const ChatMessage(text: 'Très bien, à ce soir !', isMe: false, time: '14:37'),
  ],
  '3': [
    const ChatMessage(text: 'Salut ! On vous challenge ce samedi au terrain HLM', isMe: false, time: '08:30'),
    const ChatMessage(text: 'Quel format ? 5v5 ou 7v7 ?', isMe: true, time: '08:31'),
    const ChatMessage(text: 'On vous challenge ce samedi !', isMe: false, time: '08:32'),
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// CHAT LIST SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  final _invitations = [
    _InvitationData(name: 'Tigres FC',   message: 'Veut jouer contre votre équipe',     time: 'Maintenant', color: const Color(0xFFE65100)),
    _InvitationData(name: 'Diallo Ibra', message: 'Vous invite à rejoindre son équipe',  time: 'Il y a 1h',  color: const Color(0xFF1565C0)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.animation!.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ChatPreview> get _filtered => _chats
      .where((c) =>
          c.name.toLowerCase().contains(_query.toLowerCase()) ||
          c.lastMessage.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  int get _totalUnread => _chats.fold(0, (s, c) => s + c.unread);
  int get _tabIndex => _tabController.index.clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatSheet(context),
        backgroundColor: _kGreen,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HEADER ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Tab Chats
                  GestureDetector(
                    onTap: () => _tabController.animateTo(0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chats${_totalUnread > 0 ? "($_totalUnread)" : ""}',
                          style: GoogleFonts.orbitron(
                            fontSize: _tabIndex == 0 ? 22 : 15,
                            fontWeight: FontWeight.w900,
                            color: _tabIndex == 0 ? _txt(context) : _sub(context),
                          ),
                        ),
                        if (_tabIndex == 0)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            height: 3,
                            width: 32,
                            decoration: BoxDecoration(
                              color: _kGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Tab Invitations
                  GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Invites',
                              style: GoogleFonts.orbitron(
                                fontSize: _tabIndex == 1 ? 22 : 15,
                                fontWeight: FontWeight.w900,
                                color: _tabIndex == 1 ? _txt(context) : _sub(context),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_invitations.length}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        if (_tabIndex == 1)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            height: 3,
                            width: 32,
                            decoration: BoxDecoration(
                              color: _kGreen,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Tab Terrain+ — supprimé
                  const Spacer(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── SEARCH ──
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: _card(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Icon(Icons.search_rounded, color: _sub(context), size: 20),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _query = v),
                          style: TextStyle(fontSize: 14, color: _txt(context)),
                          decoration: InputDecoration(
                            hintText: 'Search Message',
                            hintStyle: TextStyle(color: _sub(context), fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

            // ── LISTE ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Discussions
                  _filtered.isEmpty
                      ? Center(
                          child: Text('Aucun résultat',
                              style: TextStyle(color: _sub(context))),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _ChatTile(
                            chat: _filtered[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatConversationScreen(chat: _filtered[i]),
                              ),
                            ),
                          ),
                        ),
                  // Invitations
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: _invitations.length,
                    itemBuilder: (_, i) => _InvitationTile(data: _invitations[i]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouvelle conversation',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _txt(context))),
            const SizedBox(height: 20),
            _NewChatOption(
              icon: Icons.shield_rounded,
              label: 'Contacter une équipe',
              sub: 'Proposer un match ou rejoindre',
              color: _kGreen,
              onTap: () {
                Navigator.pop(context);
                _showContactPicker(context,
                    title: 'Choisir une équipe',
                    contacts: _teamsContacts,
                    type: ChatType.team,
                    color: _kGreen);
              },
            ),
            const SizedBox(height: 12),
            _NewChatOption(
              icon: Icons.sports_soccer_rounded,
              label: 'Contacter un gérant',
              sub: 'Poser une question sur un terrain',
              color: const Color(0xFF1565C0),
              onTap: () {
                Navigator.pop(context);
                _showContactPicker(context,
                    title: 'Choisir un gérant',
                    contacts: _managersContacts,
                    type: ChatType.manager,
                    color: const Color(0xFF1565C0));
              },
            ),
            const SizedBox(height: 12),
            _NewChatOption(
              icon: Icons.person_rounded,
              label: 'Message direct',
              sub: 'Écrire à un joueur',
              color: const Color(0xFF6A1B9A),
              onTap: () {
                Navigator.pop(context);
                _showContactPicker(context,
                    title: 'Choisir un joueur',
                    contacts: _playersContacts,
                    type: ChatType.direct,
                    color: const Color(0xFF6A1B9A));
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _showContactPicker(
    BuildContext context, {
    required String title,
    required List<_Contact> contacts,
    required ChatType type,
    required Color color,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ContactPickerSheet(
        title: title,
        contacts: contacts,
        type: type,
        color: color,
        onSelect: (contact) {
          Navigator.pop(context);
          final chat = ChatPreview(
            id: 'new_${contact.name}',
            name: contact.name,
            lastMessage: contact.sub,
            time: '',
            unread: 0,
            type: type,
            initials: contact.initials,
            avatarColor: contact.color,
          );
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChatConversationScreen(chat: chat)));
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT TILE
// ─────────────────────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final ChatPreview chat;
  final VoidCallback onTap;
  const _ChatTile({required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = chat.unread > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: hasUnread ? _card(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: hasUnread
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: chat.avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(chat.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ),
                ),
                if (chat.isOnline)
                  Positioned(
                    right: 1, bottom: 1,
                    child: Container(
                      width: 13, height: 13,
                      decoration: BoxDecoration(
                        color: _kGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: hasUnread ? _card(context) : _bg(context), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 13),
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          style: TextStyle(
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 14.5,
                            color: _txt(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        chat.time,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread ? _kGreen : _sub(context),
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (chat.isSentByMe && !hasUnread) ...[
                        Icon(Icons.done_all_rounded, size: 14, color: _sub(context)),
                        const SizedBox(width: 3),
                      ],
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread ? _txt(context).withValues(alpha: 0.65) : _sub(context),
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: _kGreen,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: Text('${chat.unread}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATION SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ChatConversationScreen extends StatefulWidget {
  final ChatPreview chat;
  const ChatConversationScreen({super.key, required this.chat});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final _msgController  = TextEditingController();
  final _scrollController = ScrollController();
  late List<ChatMessage> _msgs;

  @override
  void initState() {
    super.initState();
    _msgs = List.from(_messages[widget.chat.id] ?? [
      ChatMessage(text: 'Bonjour, comment puis-je vous aider ?', isMe: false, time: _timeNow()),
    ]);
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _send() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _msgs.add(ChatMessage(text: text, isMe: true, time: _timeNow()));
      _msgController.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      appBar: AppBar(
        backgroundColor: _card(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: _txt(context), size: 18),
              ),
              const SizedBox(width: 12),
              Stack(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: widget.chat.avatarColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(widget.chat.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ),
                  ),
                  if (widget.chat.isOnline)
                    Positioned(
                      right: 1, bottom: 1,
                      child: Container(
                        width: 11, height: 11,
                        decoration: BoxDecoration(
                          color: _kGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.chat.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _txt(context)),
                        overflow: TextOverflow.ellipsis),
                    Text(
                      widget.chat.type == ChatType.team
                          ? 'Groupe · équipe'
                          : widget.chat.type == ChatType.manager
                              ? 'Gérant de terrain'
                              : widget.chat.isOnline ? 'En ligne' : 'Hors ligne',
                      style: TextStyle(
                          fontSize: 11,
                          color: widget.chat.isOnline ? _kGreen : _sub(context)),
                    ),
                  ],
                ),
              ),
              Icon(
                widget.chat.type == ChatType.team
                    ? Icons.shield_rounded
                    : widget.chat.type == ChatType.manager
                        ? Icons.sports_soccer_rounded
                        : Icons.person_rounded,
                color: widget.chat.avatarColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _msgs.length,
              itemBuilder: (_, i) => _MessageBubble(msg: _msgs[i]),
            ),
          ),
          // Input
          Container(
            padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: _card(context),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: _kGreen, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _bg(context),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: TextStyle(fontSize: 14, color: _txt(context)),
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(color: _sub(context), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── BUBBLE ──

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4, bottom: 4,
          left: msg.isMe ? 64 : 0,
          right: msg.isMe ? 0 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isMe ? _kDark : _card(context),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.text,
                style: TextStyle(
                    fontSize: 14,
                    color: msg.isMe ? Colors.white : _txt(context),
                    height: 1.4)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(msg.time,
                    style: TextStyle(
                        fontSize: 10,
                        color: msg.isMe
                            ? Colors.white.withValues(alpha: 0.5)
                            : _sub(context))),
                if (msg.isMe) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all_rounded, size: 13,
                      color: _kGreen.withValues(alpha: 0.8)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── INVITATION TILE ──

class _InvitationTile extends StatefulWidget {
  final _InvitationData data;
  const _InvitationTile({required this.data});
  @override
  State<_InvitationTile> createState() => _InvitationTileState();
}

class _InvitationTileState extends State<_InvitationTile> {
  bool _handled = false;
  @override
  Widget build(BuildContext context) {
    if (_handled) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: widget.data.color, shape: BoxShape.circle),
            child: Center(
              child: Text(widget.data.name.substring(0, 1),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.data.name,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 3),
                Text(widget.data.message,
                    style: TextStyle(fontSize: 12, color: _sub(context))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _handled = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invitation acceptée !'), backgroundColor: _kGreen),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Accepter',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => _handled = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _sub(context).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Refuser',
                      style: TextStyle(color: _sub(context), fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvitationData {
  final String name;
  final String message;
  final String time;
  final Color color;
  const _InvitationData({required this.name, required this.message, required this.time, required this.color});
}

// ── NEW CHAT OPTION ──

class _NewChatOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _NewChatOption({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45))),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTACT PICKER SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ContactPickerSheet extends StatefulWidget {
  final String title;
  final List<_Contact> contacts;
  final ChatType type;
  final Color color;
  final void Function(_Contact) onSelect;

  const _ContactPickerSheet({
    required this.title,
    required this.contacts,
    required this.type,
    required this.color,
    required this.onSelect,
  });

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  List<_Contact> get _filtered => widget.contacts
      .where((c) =>
          c.name.toLowerCase().contains(_query.toLowerCase()) ||
          c.sub.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _sub(context).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.type == ChatType.team
                          ? Icons.shield_rounded
                          : widget.type == ChatType.manager
                              ? Icons.sports_soccer_rounded
                              : Icons.person_rounded,
                      color: widget.color, size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(widget.title,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.search_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), size: 18),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Rechercher...',
                          hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? Center(child: Text('Aucun résultat',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))))
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        return GestureDetector(
                          onTap: () => widget.onSelect(c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                            color: Colors.transparent,
                            child: Row(
                              children: [
                                Container(
                                  width: 46, height: 46,
                                  decoration: BoxDecoration(color: c.color, shape: BoxShape.circle),
                                  child: Center(
                                    child: Text(c.initials,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14)),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.name,
                                          style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                      const SizedBox(height: 3),
                                      Text(c.sub,
                                          style: TextStyle(
                                              color: _sub(context),
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: widget.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: widget.color.withValues(alpha: 0.25)),
                                  ),
                                  child: Text('Contacter',
                                      style: TextStyle(
                                          color: widget.color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}
