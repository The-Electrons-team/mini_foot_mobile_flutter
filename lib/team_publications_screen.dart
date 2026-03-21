import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'team_screen.dart' show TeamData, MemberStatus;

// ── helpers locaux ────────────────────────────────────────────────────────────
const Color _kGreen = Color(0xFF006F39);
Color _bg(BuildContext c) => Theme.of(c).scaffoldBackgroundColor;
Color _card(BuildContext c) => Theme.of(c).cardColor;
Color _txt(BuildContext c) => Theme.of(c).colorScheme.onSurface;
Color _sub(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFFF0EBE0).withValues(alpha: 0.5)
    : Colors.black.withValues(alpha: 0.45);

// ── Modèles ───────────────────────────────────────────────────────────────────

class Post {
  final String id;
  String text;
  List<String> images;
  String date;
  int likes;
  bool likedByMe;
  List<PostComment> comments;

  Post({
    required this.id,
    required this.text,
    List<String>? images,
    required this.date,
    this.likes = 0,
    this.likedByMe = false,
    List<PostComment>? comments,
  }) : images = images ?? [],
       comments = comments ?? [];
}

class PostComment {
  final String author;
  final String text;
  final String date;
  PostComment({required this.author, required this.text, required this.date});
}

// ── PublicationsPage ──────────────────────────────────────────────────────────

class PublicationsPage extends StatefulWidget {
  final TeamData team;
  const PublicationsPage({super.key, required this.team});
  @override
  State<PublicationsPage> createState() => _PublicationsPageState();
}

class _PublicationsPageState extends State<PublicationsPage> {
  TeamData get team => widget.team;
  int _tab = 0;

  final List<Post> _posts = [
    Post(
      id: '1',
      text: '🏆 Victoire 3-1 contre Black Panthers ! Grande performance de toute l\'équipe.',
      date: 'Il y a 3 jours',
      likes: 24,
      images: [
        'https://images.pexels.com/photos/46798/the-ball-stadion-football-the-pitch-46798.jpeg?auto=compress&cs=tinysrgb&w=800',
        'https://images.pexels.com/photos/1884574/pexels-photo-1884574.jpeg?auto=compress&cs=tinysrgb&w=800',
      ],
      comments: [
        PostComment(author: 'Moussa N.', text: 'Quelle belle victoire ! 🔥', date: 'Il y a 2 jours'),
        PostComment(author: 'Aliou B.', text: 'On continue comme ça 💪', date: 'Il y a 2 jours'),
      ],
    ),
    Post(
      id: '2',
      text: '📅 Prochain match ce samedi à 16h sur le Terrain Dakar Arena. Soyez à l\'heure !',
      date: 'Il y a 5 jours',
      likes: 18,
      likedByMe: true,
      comments: [
        PostComment(author: 'Pape G.', text: 'Je serai là 👍', date: 'Il y a 4 jours'),
      ],
    ),
    Post(
      id: '3',
      text: '📸 Séance d\'entraînement intense aujourd\'hui. L\'équipe est prête !',
      images: ['https://images.pexels.com/photos/3621104/pexels-photo-3621104.jpeg?auto=compress&cs=tinysrgb&w=800'],
      date: 'Il y a 1 semaine',
      likes: 31,
      comments: [],
    ),
    Post(
      id: '4',
      text: '⚽ Entraînement du mardi — présence obligatoire !',
      images: [
        'https://images.pexels.com/photos/274422/pexels-photo-274422.jpeg?auto=compress&cs=tinysrgb&w=800',
        'https://images.pexels.com/photos/1884574/pexels-photo-1884574.jpeg?auto=compress&cs=tinysrgb&w=800',
        'https://images.pexels.com/photos/46798/the-ball-stadion-football-the-pitch-46798.jpeg?auto=compress&cs=tinysrgb&w=800',
      ],
      date: 'Il y a 2 semaines',
      likes: 12,
      comments: [],
    ),
  ];

  Widget _teamLogo({double size = 38}) {
    final initials = team.name.split(' ').map((w) => w[0]).take(2).join();
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: team.color.withValues(alpha: 0.15)),
      child: team.logoPath != null
          ? ClipOval(child: Image.file(File(team.logoPath!), fit: BoxFit.cover))
          : Center(child: Text(initials,
              style: GoogleFonts.orbitron(fontSize: size * 0.28, fontWeight: FontWeight.w900, color: team.color))),
    );
  }

  void _addPost() {
    final textCtrl = TextEditingController();
    String? pickedPath;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(color: _card(context), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: _sub(context).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(children: [_teamLogo(), const SizedBox(width: 10),
              Text(team.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _txt(context)))]),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: _bg(context), borderRadius: BorderRadius.circular(14)),
              child: TextField(controller: textCtrl, maxLines: 4,
                style: TextStyle(fontSize: 14, color: _txt(context)),
                decoration: InputDecoration(
                  hintText: 'Quoi de neuf pour ${team.name} ?',
                  hintStyle: TextStyle(color: _sub(context), fontSize: 13),
                  border: InputBorder.none, contentPadding: const EdgeInsets.all(14))),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (picked != null) setS(() => pickedPath = picked.path);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: _bg(context), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _sub(context).withValues(alpha: 0.2))),
                child: Row(children: [
                  Icon(Icons.image_rounded, color: pickedPath != null ? _kGreen : _sub(context), size: 18),
                  const SizedBox(width: 8),
                  Text(pickedPath != null ? 'Image sélectionnée' : 'Ajouter une photo',
                      style: TextStyle(fontSize: 13, color: pickedPath != null ? _kGreen : _sub(context), fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                final txt = textCtrl.text.trim();
                if (txt.isEmpty && pickedPath == null) return;
                setState(() => _posts.insert(0, Post(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  text: txt,
                  images: pickedPath != null ? [pickedPath!] : [],
                  date: 'À l\'instant', likes: 0)));
                Navigator.pop(ctx);
              },
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(14)),
                child: const Text('Publier', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ]),
        ),
      )),
    );
  }

  void _openPost(Post post) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PostDetailPage(post: post, team: team),
    )).then((_) => setState(() {}));
  }

  void _deletePost(Post post) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card(context),
        title: Text('Supprimer ?', style: TextStyle(color: _txt(context), fontWeight: FontWeight.w800)),
        content: Text('Cette publication sera supprimée.', style: TextStyle(color: _sub(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler', style: TextStyle(color: _sub(context)))),
          TextButton(
            onPressed: () { setState(() => _posts.remove(post)); Navigator.pop(context); },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsWithImages = _posts.where((p) => p.images.isNotEmpty).toList();
    final initials = team.name.split(' ').map((w) => w[0]).take(2).join();

    return Scaffold(
      backgroundColor: _bg(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPost, backgroundColor: _kGreen,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: _bg(context),
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _card(context), shape: BoxShape.circle),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: _txt(context)),
            ),
          ),
          title: Text('Notre Page', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _txt(context))),
          centerTitle: true,
        ),

        // ── Avatar + stats ──
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 86, height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [team.color, team.color.withValues(alpha: 0.4), const Color(0xFFE040FB)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Padding(padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _bg(context)),
                  child: Padding(padding: const EdgeInsets.all(2),
                    child: ClipOval(child: team.logoPath != null
                        ? Image.file(File(team.logoPath!), fit: BoxFit.cover)
                        : Container(color: team.color.withValues(alpha: 0.15),
                            child: Center(child: Text(initials,
                                style: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.w900, color: team.color))))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _IGStat('${_posts.length}', 'Posts'),
              _IGStat('${team.members.where((m) => m.status == MemberStatus.active).length}', 'Membres'),
              _IGStat('${_posts.fold(0, (s, p) => s + p.likes)}', 'Likes'),
            ])),
          ]),
        )),

        // ── Bio ──
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(team.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _txt(context))),
            const SizedBox(height: 2),
            Text('⚽ Minifoot · ${team.zone}', style: TextStyle(fontSize: 13, color: _sub(context))),
            const SizedBox(height: 2),
            Row(children: [
              Icon(Icons.location_on_rounded, size: 13, color: _kGreen),
              const SizedBox(width: 3),
              Text(team.address.isNotEmpty ? team.address : 'Dakar, Sénégal',
                  style: const TextStyle(fontSize: 12, color: _kGreen)),
            ]),
          ]),
        )),

        // ── Bouton publier ──
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: GestureDetector(
            onTap: _addPost,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('Nouvelle publication',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
            ),
          ),
        )),

        // ── Onglets ──
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyTabDelegate(
            child: Container(
              color: _bg(context),
              child: Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _tab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(
                        color: _tab == 0 ? _txt(context) : Colors.transparent, width: 1.5))),
                    child: Icon(Icons.grid_on_rounded, size: 22, color: _tab == 0 ? _txt(context) : _sub(context)),
                  ),
                )),
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _tab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(
                        color: _tab == 1 ? _txt(context) : Colors.transparent, width: 1.5))),
                    child: Icon(Icons.view_agenda_outlined, size: 22, color: _tab == 1 ? _txt(context) : _sub(context)),
                  ),
                )),
              ]),
            ),
          ),
        ),

        // ── Contenu ──
        if (_tab == 0) ...[
          if (postsWithImages.isEmpty)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(child: Column(children: [
                Icon(Icons.photo_library_outlined, size: 48, color: _sub(context)),
                const SizedBox(height: 12),
                Text('Aucune photo publiée', style: TextStyle(color: _sub(context), fontSize: 14)),
              ])),
            ))
          else
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final post = postsWithImages[i];
                  return GestureDetector(
                    onTap: () => _openPost(post),
                    child: Stack(fit: StackFit.expand, children: [
                      PostImage(path: post.images.first),
                      if (post.images.length > 1)
                        Positioned(top: 6, right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                            child: const Icon(Icons.collections_rounded, color: Colors.white, size: 12),
                          )),
                    ]),
                  );
                },
                childCount: postsWithImages.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2),
            ),
        ] else ...[
          SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) => PostCard(
              post: _posts[i], team: team,
              onTap: () => _openPost(_posts[i]),
              onDelete: () => _deletePost(_posts[i]),
              onLike: () => setState(() {
                final p = _posts[i];
                if (p.likedByMe) { p.likes--; p.likedByMe = false; }
                else { p.likes++; p.likedByMe = true; }
              }),
            ),
            childCount: _posts.length,
          )),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]),
    );
  }
}

// ── _StickyTabDelegate ────────────────────────────────────────────────────────
class _StickyTabDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _StickyTabDelegate({required this.child});
  @override double get minExtent => 46;
  @override double get maxExtent => 46;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override bool shouldRebuild(_StickyTabDelegate old) => old.child != child;
}

// ── _IGStat ───────────────────────────────────────────────────────────────────
class _IGStat extends StatelessWidget {
  final String value, label;
  const _IGStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _txt(context))),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(fontSize: 12, color: _sub(context))),
  ]);
}

// ── PostCard ──────────────────────────────────────────────────────────────────
class PostCard extends StatelessWidget {
  final Post post;
  final TeamData team;
  final VoidCallback onTap, onDelete, onLike;
  const PostCard({super.key, required this.post, required this.team,
      required this.onTap, required this.onDelete, required this.onLike});

  Widget _logo(BuildContext context) {
    final initials = team.name.split(' ').map((w) => w[0]).take(2).join();
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, color: team.color.withValues(alpha: 0.15)),
      child: team.logoPath != null
          ? ClipOval(child: Image.file(File(team.logoPath!), fit: BoxFit.cover))
          : Center(child: Text(initials,
              style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.w900, color: team.color))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg(context),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
          child: Row(children: [
            _logo(context),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(team.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
              Text(post.date, style: TextStyle(fontSize: 10, color: _sub(context))),
            ])),
            GestureDetector(
              onTap: onDelete,
              child: Padding(padding: const EdgeInsets.all(8),
                  child: Icon(Icons.delete_outline_rounded, size: 18, color: _sub(context))),
            ),
          ]),
        ),
        if (post.images.isNotEmpty) PostImagesCarousel(images: post.images),
        if (post.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: RichText(text: TextSpan(children: [
              TextSpan(text: '${team.name} ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
              TextSpan(text: post.text,
                  style: TextStyle(fontSize: 13, color: _txt(context), height: 1.45)),
            ])),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 6),
          child: Row(children: [
            GestureDetector(
              onTap: onLike,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  post.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  key: ValueKey(post.likedByMe),
                  color: post.likedByMe ? Colors.red : _sub(context), size: 26),
              ),
            ),
            const SizedBox(width: 4),
            Text('${post.likes}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _txt(context))),
            const SizedBox(width: 14),
            GestureDetector(onTap: onTap,
                child: Icon(Icons.chat_bubble_outline_rounded, color: _sub(context), size: 24)),
            const SizedBox(width: 4),
            Text('${post.comments.length}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _txt(context))),
          ]),
        ),
        if (post.comments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ...post.comments.take(2).map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: RichText(text: TextSpan(children: [
                  TextSpan(text: '${c.author} ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _txt(context))),
                  TextSpan(text: c.text, style: TextStyle(fontSize: 12, color: _txt(context))),
                ])),
              )),
              if (post.comments.length > 2)
                GestureDetector(onTap: onTap,
                  child: Text('Voir les ${post.comments.length} commentaires',
                      style: TextStyle(fontSize: 11, color: _sub(context)))),
            ]),
          ),
        Divider(height: 1, color: _sub(context).withValues(alpha: 0.1)),
      ]),
    );
  }
}

// ── PostImagesCarousel ────────────────────────────────────────────────────────
class PostImagesCarousel extends StatefulWidget {
  final List<String> images;
  const PostImagesCarousel({super.key, required this.images});
  @override
  State<PostImagesCarousel> createState() => _PostImagesCarouselState();
}

class _PostImagesCarouselState extends State<PostImagesCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.length == 1) return PostImage(path: widget.images.first);
    return Stack(children: [
      SizedBox(
        height: 300,
        child: PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => PostImage(path: widget.images[i], height: 300),
        ),
      ),
      Positioned(bottom: 10, left: 0, right: 0,
        child: Row(mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _current == i ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: _current == i ? Colors.white : Colors.white54,
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ),
      ),
    ]);
  }
}

// ── PostImage ─────────────────────────────────────────────────────────────────
class PostImage extends StatelessWidget {
  final String path;
  final double? height;
  const PostImage({super.key, required this.path, this.height});
  @override
  Widget build(BuildContext context) {
    final h = height ?? 300.0;
    if (path.startsWith('http')) {
      return Image.network(path, width: double.infinity, height: h, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(height: h, color: _sub(context).withValues(alpha: 0.1),
              child: Center(child: Icon(Icons.broken_image_outlined, color: _sub(context)))));
    }
    return Image.file(File(path), width: double.infinity, height: h, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(height: h, color: _sub(context).withValues(alpha: 0.1),
            child: Center(child: Icon(Icons.broken_image_outlined, color: _sub(context)))));
  }
}

// ── PostDetailPage ────────────────────────────────────────────────────────────
class PostDetailPage extends StatefulWidget {
  final Post post;
  final TeamData team;
  const PostDetailPage({super.key, required this.post, required this.team});
  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentCtrl = TextEditingController();
  Post get post => widget.post;
  TeamData get team => widget.team;

  @override
  void dispose() { _commentCtrl.dispose(); super.dispose(); }

  void _sendComment() {
    final txt = _commentCtrl.text.trim();
    if (txt.isEmpty) return;
    setState(() => post.comments.add(PostComment(author: 'Moi', text: txt, date: 'À l\'instant')));
    _commentCtrl.clear();
  }

  Widget _logo() {
    final initials = team.name.split(' ').map((w) => w[0]).take(2).join();
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(shape: BoxShape.circle, color: team.color.withValues(alpha: 0.15)),
      child: team.logoPath != null
          ? ClipOval(child: Image.file(File(team.logoPath!), fit: BoxFit.cover))
          : Center(child: Text(initials,
              style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.w900, color: team.color))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg(context),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: _card(context), shape: BoxShape.circle),
                  child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: _txt(context))),
              ),
              const SizedBox(width: 12),
              Text('Publication', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _txt(context))),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(child: ListView(padding: EdgeInsets.zero, children: [
            Container(color: _bg(context), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(children: [
                  _logo(), const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(team.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
                    Text(post.date, style: TextStyle(fontSize: 10, color: _sub(context))),
                  ])),
                ]),
              ),
              if (post.images.isNotEmpty) PostImagesCarousel(images: post.images),
              if (post.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: RichText(text: TextSpan(children: [
                    TextSpan(text: '${team.name} ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _txt(context))),
                    TextSpan(text: post.text,
                        style: TextStyle(fontSize: 13, color: _txt(context), height: 1.45)),
                  ])),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      if (post.likedByMe) { post.likes--; post.likedByMe = false; }
                      else { post.likes++; post.likedByMe = true; }
                    }),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        post.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        key: ValueKey(post.likedByMe),
                        color: post.likedByMe ? Colors.red : _sub(context), size: 26),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('${post.likes}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _txt(context))),
                  const SizedBox(width: 14),
                  Icon(Icons.chat_bubble_outline_rounded, color: _sub(context), size: 24),
                  const SizedBox(width: 4),
                  Text('${post.comments.length}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _txt(context))),
                ]),
              ),
              Divider(height: 1, color: _sub(context).withValues(alpha: 0.1)),
            ])),
            const SizedBox(height: 8),
            ...post.comments.map((c) => Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 34, height: 34,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _kGreen.withValues(alpha: 0.12)),
                  child: Center(child: Text(c.author[0].toUpperCase(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _kGreen)))),
                const SizedBox(width: 10),
                Expanded(child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  decoration: BoxDecoration(color: _card(context), borderRadius: BorderRadius.circular(14)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.author, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _txt(context))),
                    const SizedBox(height: 2),
                    Text(c.text, style: TextStyle(fontSize: 13, color: _txt(context), height: 1.4)),
                    const SizedBox(height: 4),
                    Text(c.date, style: TextStyle(fontSize: 10, color: _sub(context))),
                  ]),
                )),
              ]),
            )),
            const SizedBox(height: 80),
          ])),
          Container(
            padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
            decoration: BoxDecoration(color: _card(context),
                border: Border(top: BorderSide(color: _sub(context).withValues(alpha: 0.1)))),
            child: Row(children: [
              Container(width: 34, height: 34,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _kGreen.withValues(alpha: 0.12)),
                child: const Center(child: Icon(Icons.person_rounded, color: _kGreen, size: 16))),
              const SizedBox(width: 10),
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: _bg(context), borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _sub(context).withValues(alpha: 0.15))),
                child: TextField(
                  controller: _commentCtrl,
                  style: TextStyle(fontSize: 13, color: _txt(context)),
                  decoration: InputDecoration(
                    hintText: 'Ajouter un commentaire...',
                    hintStyle: TextStyle(color: _sub(context), fontSize: 13),
                    border: InputBorder.none, isDense: true),
                  onSubmitted: (_) => _sendComment(),
                ),
              )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendComment,
                child: Container(width: 36, height: 36,
                  decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 16)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
