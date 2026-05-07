import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/auth_provider.dart';

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

  factory ChatPreview.fromJson(Map<String, dynamic> json, String currentUserId) {
    final String typeStr = json['type'] ?? 'DIRECT';
    final List participants = json['participants'] ?? [];
    
    // Pour les équipes, on utilise le nom de la conversation directement
    String name = json['name'] ?? "Conversation";
    
    // Pour les messages directs, on cherche le nom de l'autre personne
    if (typeStr == 'DIRECT') {
      try {
        final other = participants.firstWhere(
          (p) => p['userId'] != currentUserId, 
          orElse: () => participants.first
        );
        final user = other['user'] ?? {};
        if (user['firstName'] != null) {
          name = "${user['firstName']} ${user['lastName']}";
        }
      } catch (e) {
        name = "Chat Privé";
      }
    }

    final List messages = json['messages'] ?? [];
    final lastMsg = messages.isNotEmpty ? messages[0]['text'] : "Pas de messages";
    
    return ChatPreview(
      id: json['id'],
      name: name,
      lastMessage: lastMsg,
      time: '12:00', // À formater plus tard
      unread: 0, // À récupérer du participant actuel
      type: typeStr == 'DIRECT' ? ChatType.direct : typeStr == 'TEAM' ? ChatType.team : ChatType.manager,
      initials: name.isNotEmpty ? name[0] : '?',
      avatarColor: typeStr == 'TEAM' ? const Color(0xFF006F39) : Colors.blueGrey,
    );
  }

}

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final String senderName; // Ajout du nom du sender

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    required this.senderName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    final sender = json['sender'] ?? {};
    return ChatMessage(
      text: json['text'] ?? '',
      isMe: json['senderId'] == currentUserId,
      time: '12:00', // À formater
      senderName: sender['firstName'] != null ? "${sender['firstName']} ${sender['lastName']}" : "Utilisateur",
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT LIST SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  List<ChatPreview> _getFiltered(List<dynamic> conversations, String currentUserId) {
    return conversations
        .map((c) => ChatPreview.fromJson(c, currentUserId))
        .where((c) =>
            c.name.toLowerCase().contains(_query.toLowerCase()) ||
            c.lastMessage.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  int _getTotalUnread(List<ChatPreview> chats) => chats.fold(0, (s, c) => s + c.unread);

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final auth = context.read<AuthProvider>();
    final currentUserId = auth.user?.id ?? '';
    final chats = _getFiltered(chatProvider.conversations, currentUserId);
    final totalUnread = _getTotalUnread(chats);

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chats${totalUnread > 0 ? "($totalUnread)" : ""}',
                        style: GoogleFonts.orbitron(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: _txt(context),
                        ),
                      ),
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
              child: chats.isEmpty
                  ? Center(
                      child: Text(chatProvider.isLoading ? 'Chargement...' : 'Aucun résultat',
                          style: TextStyle(color: _sub(context))),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      itemCount: chats.length,
                      itemBuilder: (_, i) => _ChatTile(
                        chat: chats[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatConversationScreen(chat: chats[i]),
                          ),
                        ),
                      ),
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
                // TODO: Implémenter la recherche d'équipes
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
                // TODO: Implémenter la recherche de gérants
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
                // TODO: Implémenter la recherche de joueurs
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
    required List<dynamic> contacts,
    required ChatType type,
    required Color color,
  }) {
    // Temporairement désactivé car les constantes ont été supprimées
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchMessages(widget.chat.id);
    });
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _send() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendMessage(widget.chat.id, text);
    _msgController.clear();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final currentUserId = context.read<AuthProvider>().user?.id ?? '';
                final messages = chatProvider.getMessages(widget.chat.id)
                    .map((m) => ChatMessage.fromJson(m, currentUserId))
                    .toList();
                
                if (messages.isEmpty && chatProvider.isLoading) {
                   return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: messages.length,
                        itemBuilder: (_, i) => _MessageBubble(msg: messages[i]),
                      ),
                    ),
                    if (messages.isEmpty && !chatProvider.isLoading)
                      _QuickSuggestions(
                        onSelect: (text) => context.read<ChatProvider>().sendMessage(widget.chat.id, text),
                      ),
                  ],
                );
              },
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
    final bool isMe = msg.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 2, top: 4),
              child: Text(
                msg.senderName,
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: _kGreen,
                ),
              ),
            ),
          Container(
            margin: EdgeInsets.only(
              top: 2, bottom: 4,
              left: isMe ? 64 : 0,
              right: isMe ? 0 : 64,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? _kDark : _card(context),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
              ],
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(msg.text,
                    style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : _txt(context),
                        height: 1.4)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(msg.time,
                        style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.5)
                                : _sub(context))),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.done_all_rounded, size: 13,
                          color: _kGreen.withValues(alpha: 0.8)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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


class _QuickSuggestions extends StatelessWidget {
  final Function(String) onSelect;
  const _QuickSuggestions({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'Bonjour !',
      'Quel est le prix ?',
      'C\'est disponible ?',
      'Où vous situez-vous ?',
      'Merci !',
    ];
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onSelect(suggestions[i]),
          child: Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGreen.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                suggestions[i],
                style: TextStyle(
                  color: _kGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── FIN ──
