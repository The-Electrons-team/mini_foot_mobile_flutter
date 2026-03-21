import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _kGreenShop = Color(0xFF006F39);

bool _isDarkShop(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
Color _bgShop(BuildContext c)   => Theme.of(c).scaffoldBackgroundColor;
Color _cardShop(BuildContext c) => Theme.of(c).cardColor;
Color _txtShop(BuildContext c)  => Theme.of(c).colorScheme.onSurface;
Color _subShop(BuildContext c)  => _isDarkShop(c)
    ? const Color(0xFFF0EBE0).withValues(alpha: 0.5)
    : Colors.black.withValues(alpha: 0.45);

class _ShopProduct {
  final String vendor, name, price, category, imageUrl;
  final List<String> gallery;
  final String whatsapp, description;
  final Color accentColor;
  final IconData icon;

  const _ShopProduct({
    required this.vendor, required this.name, required this.price,
    required this.category, required this.imageUrl, required this.gallery,
    required this.accentColor, required this.icon,
    required this.whatsapp, required this.description,
  });
}

const _kShopProducts = [
  _ShopProduct(
    vendor: 'DakarSport', name: 'Maillot Pro Lions FC',
    price: '12 500 F', category: 'Maillots',
    imageUrl: 'https://images.pexels.com/photos/3621104/pexels-photo-3621104.jpeg?auto=compress&cs=tinysrgb&w=600',
    gallery: [
      'https://images.pexels.com/photos/3621104/pexels-photo-3621104.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/1884574/pexels-photo-1884574.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/13783930/pexels-photo-13783930.jpeg?auto=compress&cs=tinysrgb&w=600',
    ],
    accentColor: Color(0xFF006F39), icon: Icons.checkroom_rounded,
    whatsapp: '221771234567',
    description: 'Maillot professionnel aux couleurs des Lions FC. Tissu respirant, coupe slim. Disponible en S, M, L, XL.',
  ),
  _ShopProduct(
    vendor: 'FootShop SN', name: 'Ballon Match FIFA Quality',
    price: '8 000 F', category: 'Ballons',
    imageUrl: 'https://images.pexels.com/photos/47730/the-ball-stadion-football-the-pitch-47730.jpeg?auto=compress&cs=tinysrgb&w=600',
    gallery: [
      'https://images.pexels.com/photos/47730/the-ball-stadion-football-the-pitch-47730.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/12486370/pexels-photo-12486370.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/13890306/pexels-photo-13890306.jpeg?auto=compress&cs=tinysrgb&w=600',
    ],
    accentColor: Color(0xFF1565C0), icon: Icons.sports_soccer_rounded,
    whatsapp: '221769876543',
    description: 'Ballon certifié FIFA Quality Pro. Idéal pour les matchs officiels et tournois. Taille 5.',
  ),
  _ShopProduct(
    vendor: 'SportZone DK', name: 'Crampons Nike Mercurial',
    price: '35 000 F', category: 'Chaussures',
    imageUrl: 'https://images.pexels.com/photos/2385477/pexels-photo-2385477.jpeg?auto=compress&cs=tinysrgb&w=600',
    gallery: [
      'https://images.pexels.com/photos/2385477/pexels-photo-2385477.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/1884574/pexels-photo-1884574.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/3621104/pexels-photo-3621104.jpeg?auto=compress&cs=tinysrgb&w=600',
    ],
    accentColor: Color(0xFFE65100), icon: Icons.directions_run_rounded,
    whatsapp: '221781112233',
    description: 'Crampons Nike Mercurial Vapor. Gazon naturel et synthétique. Pointures 38 à 46. Coloris noir/orange.',
  ),
  _ShopProduct(
    vendor: 'KitFoot SN', name: 'Protège-tibias Adidas',
    price: '3 500 F', category: 'Équipement',
    imageUrl: 'https://images.pexels.com/photos/1884574/pexels-photo-1884574.jpeg?auto=compress&cs=tinysrgb&w=600',
    gallery: [
      'https://images.pexels.com/photos/1884574/pexels-photo-1884574.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/2385477/pexels-photo-2385477.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/47730/the-ball-stadion-football-the-pitch-47730.jpeg?auto=compress&cs=tinysrgb&w=600',
    ],
    accentColor: Color(0xFF6A1B9A), icon: Icons.shield_rounded,
    whatsapp: '221701234567',
    description: 'Protège-tibias Adidas avec chaussette intégrée. Légère et résistante. Tailles S, M, L.',
  ),
  _ShopProduct(
    vendor: 'DakarSport', name: 'Maillot Gardien Pro',
    price: '9 500 F', category: 'Maillots',
    imageUrl: 'https://images.pexels.com/photos/13783930/pexels-photo-13783930.jpeg?auto=compress&cs=tinysrgb&w=600',
    gallery: [
      'https://images.pexels.com/photos/13783930/pexels-photo-13783930.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/3621104/pexels-photo-3621104.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/13890306/pexels-photo-13890306.jpeg?auto=compress&cs=tinysrgb&w=600',
    ],
    accentColor: Color(0xFF006F39), icon: Icons.checkroom_rounded,
    whatsapp: '221771234567',
    description: 'Maillot gardien rembourré aux coudes. Tissu anti-transpiration. Disponible en M, L, XL.',
  ),
  _ShopProduct(
    vendor: 'FootShop SN', name: "Ballon d'entraînement",
    price: '4 500 F', category: 'Ballons',
    imageUrl: 'https://images.pexels.com/photos/12486370/pexels-photo-12486370.jpeg?auto=compress&cs=tinysrgb&w=600',
    gallery: [
      'https://images.pexels.com/photos/12486370/pexels-photo-12486370.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/47730/the-ball-stadion-football-the-pitch-47730.jpeg?auto=compress&cs=tinysrgb&w=600',
      'https://images.pexels.com/photos/13890306/pexels-photo-13890306.jpeg?auto=compress&cs=tinysrgb&w=600',
    ],
    accentColor: Color(0xFF1565C0), icon: Icons.sports_soccer_rounded,
    whatsapp: '221769876543',
    description: 'Ballon entraînement toutes surfaces. Couture renforcée, longue durabilité. Taille 4 ou 5.',
  ),
];

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _categoryIndex = 0;
  String _search = '';
  double _minPrice = 0;
  double _maxPrice = 40000;
  _SortOrder _sort = _SortOrder.none;
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  static const _categories = [
    ('Tout', Icons.grid_view_rounded),
    ('Maillots', Icons.checkroom_rounded),
    ('Ballons', Icons.sports_soccer_rounded),
    ('Chaussures', Icons.directions_run_rounded),
    ('Équipement', Icons.shield_rounded),
  ];

  // Prix numérique extrait du string "12 500 F"
  int _parsePrice(String s) =>
      int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  List<_ShopProduct> get _filtered {
    var list = _kShopProducts.where((p) {
      final matchCat = _categoryIndex == 0 || p.category == _categories[_categoryIndex].$1;
      final matchSearch = _search.isEmpty ||
          p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.vendor.toLowerCase().contains(_search.toLowerCase());
      final price = _parsePrice(p.price);
      final matchPrice = price >= _minPrice && price <= _maxPrice;
      return matchCat && matchSearch && matchPrice;
    }).toList();

    if (_sort == _SortOrder.asc) {
      list.sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));
    } else if (_sort == _SortOrder.desc) {
      list.sort((a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)));
    }
    return list;
  }

  void _showFilterSheet() {
    double tmpMin = _minPrice;
    double tmpMax = _maxPrice;
    _SortOrder tmpSort = _sort;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).padding.bottom + 24),
          decoration: BoxDecoration(
            color: _cardShop(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text('Filtres & Tri',
                  style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.w900, color: _txtShop(context))),
              const SizedBox(height: 20),

              // Filtre prix
              Text('Fourchette de prix',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _txtShop(context))),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${tmpMin.round()} F',
                      style: TextStyle(fontSize: 12, color: _kGreenShop, fontWeight: FontWeight.w700)),
                  Text('${tmpMax.round()} F',
                      style: TextStyle(fontSize: 12, color: _kGreenShop, fontWeight: FontWeight.w700)),
                ],
              ),
              RangeSlider(
                values: RangeValues(tmpMin, tmpMax),
                min: 0, max: 40000,
                divisions: 40,
                activeColor: _kGreenShop,
                inactiveColor: _kGreenShop.withValues(alpha: 0.15),
                onChanged: (v) => setS(() { tmpMin = v.start; tmpMax = v.end; }),
              ),
              const SizedBox(height: 16),

              // Tri
              Text('Trier par prix',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _txtShop(context))),
              const SizedBox(height: 10),
              Row(
                children: [
                  _SortChip(
                    label: 'Par défaut',
                    icon: Icons.sort_rounded,
                    selected: tmpSort == _SortOrder.none,
                    onTap: () => setS(() => tmpSort = _SortOrder.none),
                  ),
                  const SizedBox(width: 8),
                  _SortChip(
                    label: 'Croissant',
                    icon: Icons.arrow_upward_rounded,
                    selected: tmpSort == _SortOrder.asc,
                    onTap: () => setS(() => tmpSort = _SortOrder.asc),
                  ),
                  const SizedBox(width: 8),
                  _SortChip(
                    label: 'Décroissant',
                    icon: Icons.arrow_downward_rounded,
                    selected: tmpSort == _SortOrder.desc,
                    onTap: () => setS(() => tmpSort = _SortOrder.desc),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() { _minPrice = 0; _maxPrice = 40000; _sort = _SortOrder.none; });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _subShop(context).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('Réinitialiser', textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700, color: _subShop(context))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() { _minPrice = tmpMin; _maxPrice = tmpMax; _sort = tmpSort; });
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _kGreenShop,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text('Appliquer', textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;
    final hasActiveFilter = _minPrice > 0 || _maxPrice < 40000 || _sort != _SortOrder.none;

    return Scaffold(
      backgroundColor: _bgShop(context),
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
                    child: Text('Boutique',
                        style: GoogleFonts.orbitron(
                            fontSize: 22, fontWeight: FontWeight.w900, color: _txtShop(context))),
                  ),
                  // Bouton recherche
                  GestureDetector(
                    onTap: () => setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) { _search = ''; _searchCtrl.clear(); }
                    }),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: _showSearch ? _kGreenShop : _kGreenShop.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.search_rounded,
                          color: _showSearch ? Colors.white : _kGreenShop, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bouton filtre
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: hasActiveFilter ? _kGreenShop : _kGreenShop.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.tune_rounded,
                              color: hasActiveFilter ? Colors.white : _kGreenShop, size: 20),
                        ),
                        if (hasActiveFilter)
                          Positioned(
                            top: -3, right: -3,
                            child: Container(
                              width: 10, height: 10,
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── BARRE DE RECHERCHE ──
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: _showSearch
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _cardShop(context),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          autofocus: true,
                          onChanged: (v) => setState(() => _search = v),
                          style: TextStyle(fontSize: 14, color: _txtShop(context)),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un produit ou vendeur...',
                            hintStyle: TextStyle(color: _subShop(context), fontSize: 13),
                            prefixIcon: Icon(Icons.search_rounded, color: _kGreenShop, size: 20),
                            suffixIcon: _search.isNotEmpty
                                ? GestureDetector(
                                    onTap: () => setState(() { _search = ''; _searchCtrl.clear(); }),
                                    child: Icon(Icons.close_rounded, color: _subShop(context), size: 18),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 12),

            // ── CATÉGORIES ──
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final selected = _categoryIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _categoryIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? _kGreenShop : _cardShop(context),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_categories[i].$2, size: 14,
                              color: selected ? Colors.white : _subShop(context)),
                          const SizedBox(width: 6),
                          Text(_categories[i].$1,
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: selected ? Colors.white : _subShop(context))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── RÉSULTATS COUNT + TRI ACTIF ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  Text('${results.length} résultat${results.length > 1 ? "s" : ""}',
                      style: TextStyle(fontSize: 12, color: _subShop(context), fontWeight: FontWeight.w600)),
                  if (_sort != _SortOrder.none) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kGreenShop.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sort == _SortOrder.asc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 11, color: _kGreenShop,
                          ),
                          const SizedBox(width: 3),
                          Text(_sort == _SortOrder.asc ? 'Prix croissant' : 'Prix décroissant',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kGreenShop)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── GRILLE ──
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: _subShop(context).withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('Aucun résultat',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _subShop(context))),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: results.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => _ProductDetailScreen(product: results[i]))),
                        child: _ProductCard(product: results[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SortOrder { none, asc, desc }

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? _kGreenShop : _kGreenShop.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? _kGreenShop : _kGreenShop.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: selected ? Colors.white : _kGreenShop),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _kGreenShop)),
        ],
      ),
    ),
  );
}

class _ProductCard extends StatelessWidget {
  final _ShopProduct product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Container(
      decoration: BoxDecoration(
        color: _cardShop(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkShop(context) ? 0.25 : 0.07),
            blurRadius: 10, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network(
              p.imageUrl, width: double.infinity, height: 130, fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Container(
                height: 130,
                color: p.accentColor.withValues(alpha: 0.15),
                child: Center(child: Icon(p.icon, color: p.accentColor, size: 40)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.vendor,
                    style: TextStyle(fontSize: 9.5, color: p.accentColor, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(p.name,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: _txtShop(context), height: 1.2)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(p.price,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: p.accentColor)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: p.accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Text('Voir',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: p.accentColor)),
                    ),
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

// ---------------------------------------------------------------------------
// PAGE DÉTAIL PRODUIT
// ---------------------------------------------------------------------------

class _ProductDetailScreen extends StatefulWidget {
  final _ShopProduct product;
  const _ProductDetailScreen({required this.product});

  @override
  State<_ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<_ProductDetailScreen> {
  int _galleryIndex = 0;

  Future<void> _openWhatsApp() async {
    final p = widget.product;
    final msg = Uri.encodeComponent(
      'Bonjour ${p.vendor} 👋\n\nJe suis intéressé(e) par :\n'
      '📦 *${p.name}*\n💰 Prix : ${p.price}\n\n'
      'Pouvez-vous me donner plus d\'informations ? Merci !',
    );
    final url = Uri.parse('https://wa.me/${p.whatsapp}?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      backgroundColor: _bgShop(context),
      body: CustomScrollView(
        slivers: [
          // ── GALERIE HERO ──
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: _bgShop(context),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image principale
                  PageView.builder(
                    itemCount: p.gallery.length,
                    onPageChanged: (i) => setState(() => _galleryIndex = i),
                    itemBuilder: (_, i) => Image.network(
                      p.gallery[i], fit: BoxFit.cover,
                      errorBuilder: (ctx2, err, st) => Container(
                        color: p.accentColor.withValues(alpha: 0.2),
                        child: Center(child: Icon(p.icon, color: p.accentColor, size: 80)),
                      ),
                    ),
                  ),
                  // Dégradé bas
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, _bgShop(context).withValues(alpha: 0.9)],
                        ),
                      ),
                    ),
                  ),
                  // Indicateurs galerie
                  Positioned(
                    bottom: 12,
                    left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(p.gallery.length, (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _galleryIndex == i ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _galleryIndex == i ? p.accentColor : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendeur
                  Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: p.accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.storefront_rounded, color: p.accentColor, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(p.vendor,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.accentColor)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Nom
                  Text(p.name,
                      style: GoogleFonts.orbitron(
                          fontSize: 18, fontWeight: FontWeight.w900, color: _txtShop(context))),
                  const SizedBox(height: 10),

                  // Prix
                  Text(p.price,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: p.accentColor)),
                  const SizedBox(height: 20),

                  // Miniatures galerie
                  SizedBox(
                    height: 72,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: p.gallery.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => setState(() => _galleryIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 72, height: 72,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _galleryIndex == i ? p.accentColor : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              p.gallery[i], fit: BoxFit.cover,
                              errorBuilder: (ctx3, err, st) => Container(
                                color: p.accentColor.withValues(alpha: 0.15),
                                child: Icon(p.icon, color: p.accentColor, size: 24),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text('Description',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _txtShop(context))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _cardShop(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(p.description,
                        style: TextStyle(fontSize: 13, color: _subShop(context), height: 1.6)),
                  ),
                  const SizedBox(height: 20),

                  // Infos vendeur
                  Text('Vendeur',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _txtShop(context))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _cardShop(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: p.accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.storefront_rounded, color: p.accentColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.vendor,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _txtShop(context))),
                              const SizedBox(height: 2),
                              Text('Dakar, Sénégal',
                                  style: TextStyle(fontSize: 11, color: _subShop(context))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF075E54).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Vérifié',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF075E54))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Bouton WhatsApp
                  GestureDetector(
                    onTap: _openWhatsApp,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF075E54),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF075E54).withValues(alpha: 0.4),
                            blurRadius: 12, offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 10),
                          const Text('Contacter sur WhatsApp',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
