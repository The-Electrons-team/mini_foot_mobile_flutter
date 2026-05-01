import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'terrain_data.dart';
import 'booking_confirmation_screen.dart';

const Color kGreen = Color(0xFF006F39);
const Color kBeige = Color(0xFFF5F0E8);
const Color kDark = Color(0xFF1A1A1A);

const List<Map<String, dynamic>> _methods = [
  {'label': 'Wave', 'asset': 'assets/images/wave.png'},
  {'label': 'Orange\nMoney', 'asset': 'assets/images/om.png'},
  {'label': 'Free\nMoney', 'asset': 'assets/images/free.png'},
];

class PaymentScreen extends StatefulWidget {
  final Terrain terrain;
  final SubTerrain? subTerrain;
  final DateTime date;
  final String startSlot;
  final String endSlot;
  final int totalPrice;
  final int intervals;

  const PaymentScreen({
    super.key,
    required this.terrain,
    this.subTerrain,
    required this.date,
    required this.startSlot,
    required this.endSlot,
    required this.totalPrice,
    required this.intervals,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _promoController = TextEditingController();
  bool _promoApplied = false;
  int _selectedMethod = 0;

  // 0 = totalité, 1 = acompte 30%, 2 = partagé
  int _paymentType = 0;
  int _nbPersonnes = 2;
  String? _shareLink;

  int get _discount => _promoApplied ? (widget.totalPrice * 0.10).round() : 0;
  int get _finalPrice => widget.totalPrice - _discount;

  int get _amountToPay {
    if (_paymentType == 0) return _finalPrice;
    if (_paymentType == 1) return (_finalPrice * 0.30).round();
    return (_finalPrice / _nbPersonnes).round();
  }

  String get _amountLabel {
    if (_paymentType == 0) return '$_finalPrice F';
    if (_paymentType == 1) return '$_amountToPay F  (30%)';
    return '$_amountToPay F  (ma part)';
  }

  String get _durationLabel {
    final m = widget.intervals * 15;
    final h = m ~/ 60;
    final min = m % 60;
    if (h == 0) return '${m}min';
    if (min == 0) return '${h}h';
    return '${h}h${min.toString().padLeft(2, '0')}';
  }

  String get _dateLabel {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    final d = widget.date;
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }

  void _generateLink() {
    final ref = 'MF-${widget.terrain.id}${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    setState(() {
      _shareLink = 'minifoot.app/pay/$ref?n=$_nbPersonnes&t=${(_finalPrice / _nbPersonnes).round()}';
    });
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      appBar: AppBar(
        backgroundColor: kBeige,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: kDark),
          ),
        ),
        title: Text('Paiement',
            style: GoogleFonts.orbitron(fontSize: 15, fontWeight: FontWeight.w800, color: kDark)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── RÉCAPITULATIF RÉSERVATION ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.terrain.imageUrl,
                      width: 72, height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                          width: 72, height: 72,
                          color: kGreen.withOpacity(0.10)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Chip(label: _dateLabel, color: const Color(0xFFF0F0F0), textColor: kDark),
                            const SizedBox(width: 6),
                            _Chip(
                              label: '${widget.startSlot}-${widget.endSlot}',
                              color: kDark,
                              textColor: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(widget.subTerrain != null 
                            ? '${widget.terrain.name} - ${widget.subTerrain!.name}' 
                            : widget.terrain.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kDark)),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.location_on_rounded, size: 12, color: Colors.black38),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(widget.terrain.address,
                                style: const TextStyle(fontSize: 11, color: Colors.black38),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── CODE PROMO ──
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      decoration: InputDecoration(
                        hintText: 'Code promo',
                        hintStyle: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kDark),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_promoController.text.trim().isNotEmpty) {
                        setState(() => _promoApplied = true);
                        FocusScope.of(context).unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code promo appliqué ! -10%'), backgroundColor: kGreen),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: kDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Appliquer',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── RÉSUMÉ PAIEMENT ──
            const Text('Résumé du paiement',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kDark)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Prix / 15 min', value: '${widget.totalPrice ~/ widget.intervals} F'),
                  _SummaryRow(label: 'Durée totale', value: _durationLabel),
                  _SummaryRow(label: 'Sous-total', value: '${widget.totalPrice} F'),
                  if (_promoApplied) ...[
                    const Divider(height: 20),
                    _SummaryRow(
                      label: 'Réduction (10%)',
                      value: '-$_discount F',
                      valueColor: kGreen,
                    ),
                  ],
                  const Divider(height: 20),
                  _SummaryRow(
                    label: 'Montant total',
                    value: '$_finalPrice F',
                    bold: true,
                    valueColor: kDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── TYPE DE PAIEMENT ──
            const Text('Type de paiement',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kDark)),
            const SizedBox(height: 12),

            Row(
              children: [
                _PayTypeCard(
                  icon: Icons.paid_rounded,
                  title: 'Totalité',
                  subtitle: '$_finalPrice F',
                  selected: _paymentType == 0,
                  onTap: () => setState(() { _paymentType = 0; _shareLink = null; }),
                ),
                const SizedBox(width: 10),
                _PayTypeCard(
                  icon: Icons.percent_rounded,
                  title: 'Acompte',
                  subtitle: '30% · ${(_finalPrice * 0.30).round()} F',
                  selected: _paymentType == 1,
                  onTap: () => setState(() { _paymentType = 1; _shareLink = null; }),
                ),
                const SizedBox(width: 10),
                _PayTypeCard(
                  icon: Icons.group_rounded,
                  title: 'Partagé',
                  subtitle: 'Par personne',
                  selected: _paymentType == 2,
                  onTap: () => setState(() { _paymentType = 2; _shareLink = null; }),
                ),
              ],
            ),

            // ── PAIEMENT PARTAGÉ (options) ──
            if (_paymentType == 2) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nombre de participants',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kDark)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Stepper
                        _StepperButton(
                          icon: Icons.remove_rounded,
                          onTap: _nbPersonnes > 2
                              ? () => setState(() { _nbPersonnes--; _shareLink = null; })
                              : null,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text('$_nbPersonnes',
                                  style: const TextStyle(
                                      fontSize: 28, fontWeight: FontWeight.w900, color: kDark)),
                              Text('personnes',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.black.withOpacity(0.4))),
                            ],
                          ),
                        ),
                        _StepperButton(
                          icon: Icons.add_rounded,
                          onTap: _nbPersonnes < 20
                              ? () => setState(() { _nbPersonnes++; _shareLink = null; })
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kGreen.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Part par personne',
                              style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.55))),
                          Text('${(_finalPrice / _nbPersonnes).round()} F',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w900, color: kGreen)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bouton générer lien
                    GestureDetector(
                      onTap: _generateLink,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: kDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.link_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Générer le lien de paiement',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),

                    // Lien généré
                    if (_shareLink != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: kGreen, size: 16),
                                const SizedBox(width: 6),
                                const Text('Lien généré !',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: kGreen)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: _shareLink!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Lien copié !'),
                                          backgroundColor: kGreen,
                                          duration: Duration(seconds: 2)),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: kGreen,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.copy_rounded, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text('Copier',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _shareLink!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.black.withOpacity(0.55),
                                  fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 12, color: Colors.black.withOpacity(0.35)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Chaque participant paiera ${(_finalPrice / _nbPersonnes).round()} F via ce lien.',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.black.withOpacity(0.4)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Bouton partager
                            GestureDetector(
                              onTap: () async {
                                await Share.share(
                                  'Tu es invité à rejoindre une réservation MiniFoot 🏟️\n\n'
                                  '📍 ${widget.terrain.name}\n'
                                  '📅 ${widget.startSlot} → ${widget.endSlot}\n'
                                  '💰 Ta part : ${(_finalPrice / _nbPersonnes).round()} F\n\n'
                                  '👉 $_shareLink',
                                  subject: 'Paiement partagé – MiniFoot',
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: kGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: kGreen.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.share_rounded, color: kGreen, size: 16),
                                    SizedBox(width: 6),
                                    Text('Partager le lien',
                                        style: TextStyle(
                                            color: kGreen,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 22),

            // ── MODE DE PAIEMENT ──
            const Text('Mode de paiement',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kDark)),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_methods.length, (i) {
                final m = _methods[i];
                final selected = _selectedMethod == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMethod = i),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? kGreen : Colors.black.withOpacity(0.08),
                            width: selected ? 2.5 : 1,
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
                        ),
                        child: ClipOval(
                          child: Image.asset(m['asset'] as String, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: selected ? kGreen : Colors.black.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),

      // ── BOUTON PAYER ──
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: kBeige,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Résumé montant à payer
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _paymentType == 0
                        ? 'Paiement total'
                        : _paymentType == 1
                            ? 'Acompte 30%'
                            : 'Ma part (1/$_nbPersonnes)',
                    style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5), fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _amountLabel,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kDark),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                final ref = 'MF-${widget.terrain.id}${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => BookingConfirmationScreen(
                    terrain: widget.terrain,
                    subTerrain: widget.subTerrain,
                    date: widget.date,
                    startSlot: widget.startSlot,
                    endSlot: widget.endSlot,
                    finalPrice: _finalPrice,
                    paymentMethod: _methods[_selectedMethod]['label'] as String,
                    reference: ref,
                  ),
                ));
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: kDark,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text('Payer · $_amountToPay F',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                    Container(
                      width: 44, height: 44,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(color: kGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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
}

// ── CARTE TYPE DE PAIEMENT ──
class _PayTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PayTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? kGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? kGreen : Colors.black.withOpacity(0.08),
            width: selected ? 0 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : kDark, size: 22),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : kDark)),
            const SizedBox(height: 3),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black.withOpacity(0.4))),
          ],
        ),
      ),
    ),
  );
}

// ── BOUTON STEPPER ──
class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: onTap != null ? kDark : const Color(0xFFEEEEEE),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: onTap != null ? Colors.white : Colors.black26, size: 20),
    ),
  );
}

// ── WIDGETS HELPERS ──
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Chip({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor)),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  const _SummaryRow({required this.label, required this.value, this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.5))),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                color: valueColor ?? kDark)),
      ],
    ),
  );
}
