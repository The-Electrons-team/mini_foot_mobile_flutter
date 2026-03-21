import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

const Color _kGreen = Color(0xFF006F39);

bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bg(BuildContext c)   => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c)  => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c)  => _isDark(c)
    ? const Color(0xFFF0EBE0).withValues(alpha: 0.5)
    : Colors.black.withValues(alpha: 0.45);

// ── MODÈLES ──

class _Comment {
  final String author;
  final String initials;
  final Color color;
  final String text;
  final String time;
  int likes;
  _Comment({required this.author, required this.initials, required this.color,
      required this.text, required this.time, this.likes = 0});
}

class _Post {
  final String id;
  final String author;
  final String initials;
  final Color avatarColor;
  final String? badge;
  final String time;
  final String caption;
  final List<String> imageUrls;
  int likes;
  bool likedByMe;
  final List<_Comment> comments;

  _Post({required this.id, required this.author, required this.initials,
      required this.avatarColor, this.badge, required this.time,
      required this.caption, required this.imageUrls,
      this.likes = 0, this.likedByMe = false, required this.comments});
}

// ── DONNÉES FAKE ──

final List<_Post> _posts = [
  _Post(
    id: '1', author: 'Les Lions FC', initials: 'LF',
    avatarColor: _kGreen, badge: 'Équipe',
    time: 'Il y a 1h', likes: 124, likedByMe: true,
    caption: 'Victoire 5-2 contre les Tigres FC hier soir ! Merci à tous les supporters présents ⚽🏆 #LionsFC #Victoire',
    imageUrls: [
      'https://images.pexels.com/photos/13890306/pexels-photo-13890306.jpeg?auto=compress&cs=tinysrgb&w=800',
    ],
    comments: [
      _Comment(author: 'Pape Sarr',   initials: 'PS', color: const Color(0xFF6A1B9A), text: 'Quelle performance !',    time: '45min', likes: 7),
      _Comment(author: 'Aliou Badji', initials: 'AB', color: const Color(0xFF006F39), text: 'On continue comme ça 🙌', time: '50min', likes: 4),
      _Comment(author: 'Lamine Koné', initials: 'LK', color: const Color(0xFF1565C0), text: 'Bravo l\'équipe !',       time: '55min', likes: 2),
    ],
  ),
  _Post(
    id: '2', author: 'Tigres FC', initials: 'TF',
    avatarColor: const Color(0xFFE65100), badge: 'Équipe',
    time: 'Il y a 3h', likes: 89, likedByMe: false,
    caption: 'Tournoi inter-quartiers ce samedi à HLM Grand Yoff ! Inscriptions ouvertes, 8 équipes max. DM pour participer 🏆',
    imageUrls: [
      'https://images.pexels.com/photos/13783930/pexels-photo-13783930.jpeg?auto=compress&cs=tinysrgb&w=800',
    ],
    comments: [],
  ),
  _Post(
    id: '3', author: 'Black Panthers', initials: 'BP',
    avatarColor: const Color(0xFF212121), badge: 'Équipe',
    time: 'Il y a 5h', likes: 56, likedByMe: false,
    caption: 'Séance d\'entraînement au Terrain Dakar Arena 🔥 On prépare le prochain tournoi ! #BlackPanthers',
    imageUrls: [
      'https://images.pexels.com/photos/12486370/pexels-photo-12486370.jpeg?auto=compress&cs=tinysrgb&w=800',
      'https://images.pexels.com/photos/7160121/pexels-photo-7160121.jpeg?auto=compress&cs=tinysrgb&w=800',
    ],
    comments: [
      _Comment(author: 'Moussa Ndiaye', initials: 'MN', color: const Color(0xFF1A237E), text: 'Feu 🔥 on est prêts !', time: '4h', likes: 3),
    ],
  ),
  _Post(
    id: '4', author: 'FC Médina', initials: 'FM',
    avatarColor: const Color(0xFF006F39), badge: 'Équipe',
    time: 'Hier', likes: 31, likedByMe: false,
    caption: 'Nouveau terrain découvert à Point E 👀 Gazon impeccable, éclairage LED, vestiaires propres. On recommande !',
    imageUrls: [
      'https://images.pexels.com/photos/7160121/pexels-photo-7160121.jpeg?auto=compress&cs=tinysrgb&w=800',
    ],
    comments: [
      _Comment(author: 'Cheikh Fall', initials: 'CF', color: const Color(0xFFE65100), text: 'On y va ce weekend ?', time: '20h'),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// SOCIAL FEED SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});
  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final List<_Post> _feed = List.from(_posts);

  void _toggleLike(_Post post) => setState(() {
    post.likedByMe = !post.likedByMe;
    post.likes += post.likedByMe ? 1 : -1;
  });

  void _openComments(_Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        post: post,
        onComment: (text) => setState(() {
          post.comments.add(_Comment(
            author: 'Moi', initials: 'MO', color: _kGreen,
            text: text, time: 'À l\'instant',
          ));
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: ListView.builder(
        itemCount: _feed.length,
        itemBuilder: (_, i) => _PostCard(
          post: _feed[i],
          onLike: () => _toggleLike(_feed[i]),
          onComment: () => _openComments(_feed[i]),
        ),
      ),
    );
  }
}

// ── POST CARD ──

class _PostCard extends StatefulWidget {
  final _Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  const _PostCard({required this.post, required this.onLike, required this.onComment});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      color: _card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                // Avatar avec anneau vert
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _kGreen, width: 2),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: p.avatarColor),
                    child: Center(child: Text(p.initials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.author,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: _txt(context))),
                      if (p.badge != null)
                        Text(p.badge!, style: const TextStyle(fontSize: 11, color: _kGreen, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Text(p.time, style: TextStyle(fontSize: 11, color: _sub(context))),
              ],
            ),
          ),

          // ── IMAGES (PageView avec dots) ──
          if (p.imageUrls.isNotEmpty)
            _ImageCarousel(imageUrls: p.imageUrls, pageCtrl: _pageCtrl),

          // ── ACTIONS style Instagram ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                // Like
                GestureDetector(
                  onTap: widget.onLike,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      p.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey(p.likedByMe),
                      color: p.likedByMe ? Colors.red : _txt(context),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Commentaire
                GestureDetector(
                  onTap: widget.onComment,
                  child: Icon(Icons.chat_bubble_outline_rounded, color: _txt(context), size: 26),
                ),
                const Spacer(),
              ],
            ),
          ),

          // ── LIKES ──
          if (p.likes > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Text('${p.likes} J\'aime',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _txt(context))),
            ),

          // ── CAPTION ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
            child: RichText(
              text: TextSpan(children: [
                TextSpan(text: '${p.author} ',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _txt(context))),
                TextSpan(text: p.caption,
                    style: TextStyle(fontSize: 13, color: _txt(context), height: 1.4)),
              ]),
            ),
          ),

          // ── APERÇU COMMENTAIRES ──
          if (p.comments.isNotEmpty)
            GestureDetector(
              onTap: widget.onComment,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
                child: Text(
                  'Voir les ${p.comments.length} commentaire${p.comments.length > 1 ? "s" : ""}',
                  style: TextStyle(fontSize: 13, color: _sub(context)),
                ),
              ),
            ),

          // ── DERNIER COMMENTAIRE ──
          if (p.comments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(text: '${p.comments.last.author} ',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: _txt(context))),
                  TextSpan(text: p.comments.last.text,
                      style: TextStyle(fontSize: 12.5, color: _txt(context))),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
            child: Text(p.time, style: TextStyle(fontSize: 10, color: _sub(context))),
          ),

          Divider(height: 1, color: _sub(context).withValues(alpha: 0.12)),
        ],
      ),
    );
  }
}

// ── IMAGE CAROUSEL ──

class _ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final PageController pageCtrl;
  const _ImageCarousel({required this.imageUrls, required this.pageCtrl});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final multi = widget.imageUrls.length > 1;
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: widget.pageCtrl,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => Image.network(
              widget.imageUrls[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: _kGreen.withValues(alpha: 0.1)),
            ),
          ),
        ),
        // Dots indicateurs
        if (multi)
          Positioned(
            bottom: 10,
            left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
      ],
    );
  }
}

// ── COMMENTS SHEET ──

class _CommentsSheet extends StatefulWidget {
  final _Post post;
  final void Function(String) onComment;
  const _CommentsSheet({required this.post, required this.onComment});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  late final List<_Comment> _comments;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.post.comments);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.add(_Comment(
        author: 'Moi', initials: 'MO', color: _kGreen,
        text: text, time: 'À l\'instant',
      ));
    });
    widget.onComment(text);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _sub(context).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text('Commentaires',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: _txt(context))),
            ),
            Divider(height: 1, color: _sub(context).withValues(alpha: 0.15)),
            // Liste commentaires
            Expanded(
              child: _comments.isEmpty
                  ? Center(
                      child: Text('Aucun commentaire',
                          style: TextStyle(color: _sub(context), fontSize: 13)),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _comments.length,
                      itemBuilder: (_, i) => _CommentRow(comment: _comments[i]),
                    ),
            ),
            // Input
            Container(
              padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 12),
              decoration: BoxDecoration(
                color: _card(context),
                border: Border(top: BorderSide(color: _sub(context).withValues(alpha: 0.12))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                    child: const Center(
                      child: Text('MO',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _bg(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _sub(context).withValues(alpha: 0.2)),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        style: TextStyle(fontSize: 13, color: _txt(context)),
                        decoration: InputDecoration(
                          hintText: 'Ajouter un commentaire...',
                          hintStyle: TextStyle(color: _sub(context), fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: const Icon(Icons.send_rounded, color: _kGreen, size: 24),
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

// ── COMMENT ROW (style Instagram) ──

class _CommentRow extends StatefulWidget {
  final _Comment comment;
  const _CommentRow({required this.comment});

  @override
  State<_CommentRow> createState() => _CommentRowState();
}

class _CommentRowState extends State<_CommentRow> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: c.color, shape: BoxShape.circle),
            child: Center(
              child: Text(c.initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Auteur en gras + texte inline (style Instagram)
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: '${c.author} ',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13, color: _txt(context)),
                    ),
                    TextSpan(
                      text: c.text,
                      style: TextStyle(fontSize: 13, color: _txt(context), height: 1.4),
                    ),
                  ]),
                ),
                const SizedBox(height: 4),
                // Temps + likes
                Row(
                  children: [
                    Text(c.time,
                        style: TextStyle(fontSize: 11, color: _sub(context))),
                    if (c.likes > 0) ...[
                      const SizedBox(width: 12),
                      Text('${c.likes} J\'aime',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600, color: _sub(context))),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Like commentaire
          GestureDetector(
            onTap: () => setState(() {
              _liked = !_liked;
              c.likes += _liked ? 1 : -1;
            }),
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Icon(
                _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 14,
                color: _liked ? Colors.red : _sub(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── NEW POST SHEET ──

class _NewPostSheet extends StatefulWidget {
  final void Function(String caption, List<String> images) onPost;
  const _NewPostSheet({required this.onPost});

  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _captionCtrl = TextEditingController();
  final List<XFile> _picked = [];
  bool _loading = false;

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) setState(() => _picked.addAll(images));
  }

  void _submit() {
    final caption = _captionCtrl.text.trim();
    if (caption.isEmpty && _picked.isEmpty) return;
    // On utilise les chemins locaux comme URLs (affichage via Image.file)
    widget.onPost(caption, _picked.map((x) => x.path).toList());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: _card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: _sub(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Nouvelle publication',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _txt(context))),
            const SizedBox(height: 16),
            // Caption
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: _bg(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _sub(context).withValues(alpha: 0.2)),
              ),
              child: TextField(
                controller: _captionCtrl,
                maxLines: 4,
                style: TextStyle(fontSize: 14, color: _txt(context)),
                decoration: InputDecoration(
                  hintText: 'Partagez un moment de jeu...',
                  hintStyle: TextStyle(color: _sub(context), fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Photos sélectionnées
            if (_picked.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _picked.length,
                  itemBuilder: (_, i) => Stack(
                    children: [
                      Container(
                        width: 80, height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(File(_picked[i].path), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 2, right: 10,
                        child: GestureDetector(
                          onTap: () => setState(() => _picked.removeAt(i)),
                          child: Container(
                            width: 20, height: 20,
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // Boutons
            Row(
              children: [
                // Ajouter photos
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_rounded, color: _kGreen, size: 18),
                        const SizedBox(width: 6),
                        Text('Photos${_picked.isNotEmpty ? " (${_picked.length})" : ""}',
                            style: const TextStyle(color: _kGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Publier
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: _kGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Publier',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
