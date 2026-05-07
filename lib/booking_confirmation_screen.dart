import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'terrain_data.dart';

const Color kGreen = Color(0xFF006F39);
const Color kDark = Color(0xFF1A1A1A);
const Color kBeige = Color(0xFFF5F0E8);

class BookingConfirmationScreen extends StatefulWidget {
  final Terrain terrain;
  final SubTerrain? subTerrain;
  final DateTime date;
  final String startSlot;
  final String endSlot;
  final int finalPrice;
  final String reference;
  final String? qrData;
  final bool fromReservations;

  const BookingConfirmationScreen({
    super.key,
    required this.terrain,
    this.subTerrain,
    required this.date,
    required this.startSlot,
    required this.endSlot,
    required this.finalPrice,
    required this.reference,
    this.qrData,
    this.fromReservations = false,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _sharing = false;

  String get _dateLabel {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${days[widget.date.weekday - 1]} ${widget.date.day} ${months[widget.date.month - 1]}';
  }

  String get _qrData => widget.qrData ??
      'MINIFOOT:ref=${widget.reference}&terrain=${widget.terrain.id}'
      '${widget.subTerrain != null ? '&sub=${widget.subTerrain!.id}' : ''}'
      '&date=${widget.date.toIso8601String().substring(0, 10)}'
      '&start=${widget.startSlot}&end=${widget.endSlot}&price=${widget.finalPrice}';

  Future<Uint8List> _captureQrPng() async {
    final boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 4.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _shareQrPdf() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final qrPng = await _captureQrPng();
      final qrImage = pw.MemoryImage(qrPng);

      final doc = pw.Document(title: 'MiniFoot – ${widget.reference}');

      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // En-tête
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF006F39),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  'MINIFOOT',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 3,
                  ),
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                'Réservation Confirmée',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                '#${widget.reference}',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey),
              ),
              pw.SizedBox(height: 20),

              // Infos terrain
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: const PdfColor(0.96, 0.94, 0.91),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(widget.subTerrain != null 
                        ? '${widget.terrain.name} - ${widget.subTerrain!.name}' 
                        : widget.terrain.name,
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(widget.terrain.address,
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey)),
                    pw.SizedBox(height: 8),
                    pw.Row(children: [
                      pw.Text('Date : ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text(_dateLabel, style: const pw.TextStyle(fontSize: 11)),
                    ]),
                    pw.SizedBox(height: 3),
                    pw.Row(children: [
                      pw.Text('Heure : ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('${widget.startSlot} → ${widget.endSlot}', style: const pw.TextStyle(fontSize: 11)),
                    ]),
                    pw.SizedBox(height: 3),
                    pw.Row(children: [
                      pw.Text('Montant : ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('${widget.finalPrice} F', style: const pw.TextStyle(fontSize: 11)),
                    ]),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // QR code
              pw.Text('Présentez ce QR code à l\'entrée',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey)),
              pw.SizedBox(height: 10),
              pw.Image(qrImage, width: 180, height: 180),
              pw.SizedBox(height: 16),

              // Pied de page
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Text(
                'minifoot.app  |  Terrain de football Dakar',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              ),
            ],
          );
        },
      ));

      final pdfBytes = await doc.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'minifoot_${widget.reference}.pdf',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      body: SafeArea(
        child: Column(
          children: [
            // ── EN-TÊTE ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => widget.fromReservations
                        ? Navigator.pop(context)
                        : Navigator.popUntil(context, (r) => r.isFirst),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: kDark, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // ── BADGE + TITRE ──
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(6, (i) {
                  final radii = [52.0, 48.0, 55.0, 50.0, 53.0, 47.0];
                  return Transform.translate(
                    offset: Offset(
                      radii[i] * 1.4 * (i.isEven ? 1 : -1),
                      radii[i] * (i % 3 == 0 ? -1.0 : 0.5),
                    ),
                    child: Icon(
                      Icons.star_rounded,
                      color: kGreen.withOpacity(0.15 + (i * 0.04)),
                      size: 12.0 + (i * 2),
                    ),
                  );
                }),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: kGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: kGreen.withOpacity(0.35), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Text('Réservation Confirmée !',
                style: GoogleFonts.orbitron(
                    color: kDark, fontSize: 17, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text('Vous êtes prêt à jouer.',
                style: TextStyle(color: Colors.black.withOpacity(0.45), fontSize: 13)),

            const SizedBox(height: 20),

            // ── TICKET ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _TicketCard(
                  qrRepaintKey: _qrKey,
                  terrain: widget.terrain,
                  subTerrain: widget.subTerrain,
                  dateLabel: _dateLabel,
                  startSlot: widget.startSlot,
                  endSlot: widget.endSlot,
                  finalPrice: widget.finalPrice,
                  reference: widget.reference,
                  qrData: _qrData,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── BOUTONS ──
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.fromReservations
                          ? Navigator.pop(context)
                          : Navigator.popUntil(context, (r) => r.isFirst),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: kDark,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Center(
                          child: Text(
                            widget.fromReservations ? 'Retour' : 'Accueil',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: kDark,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Center(
                          child: Text('Voir réservation',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _shareQrPdf,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: _sharing ? kGreen : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
                      ),
                      child: _sharing
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.share_rounded, color: kDark, size: 20),
                    ),
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

// ── TICKET CARD ──
class _TicketCard extends StatelessWidget {
  final GlobalKey qrRepaintKey;
  final Terrain terrain;
  final SubTerrain? subTerrain;
  final String dateLabel;
  final String startSlot;
  final String endSlot;
  final int finalPrice;
  final String reference;
  final String qrData;

  const _TicketCard({
    required this.qrRepaintKey,
    required this.terrain,
    this.subTerrain,
    required this.dateLabel,
    required this.startSlot,
    required this.endSlot,
    required this.finalPrice,
    required this.reference,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          // ── HAUT DU TICKET ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('#$reference',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kGreen)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: reference));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Référence copiée'),
                              backgroundColor: kGreen,
                              duration: Duration(seconds: 2)),
                        );
                      },
                      child: Icon(Icons.copy_rounded, size: 16, color: Colors.black.withOpacity(0.3)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        terrain.imageUrl,
                        width: 64, height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                            width: 64, height: 60,
                            color: kGreen.withOpacity(0.10)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6, runSpacing: 4,
                            children: [
                              _InfoChip(label: dateLabel, dark: false),
                              _InfoChip(label: '$startSlot-$endSlot', dark: true),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(subTerrain != null 
                              ? '${terrain.name} - ${subTerrain!.name}' 
                              : terrain.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kDark)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.location_on_rounded, size: 11, color: Colors.black38),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(terrain.address,
                                  style: const TextStyle(fontSize: 11, color: Colors.black38),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.payments_outlined, size: 11, color: Colors.black38),
                            const SizedBox(width: 4),
                            Text('$finalPrice F',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: kDark)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── SÉPARATEUR DENTELÉ ──
          _DashedDivider(),

          // ── QR CODE ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              children: [
                RepaintBoundary(
                  key: qrRepaintKey,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    color: const Color(0xFFF8F8F8),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 150,
                      backgroundColor: const Color(0xFFF8F8F8),
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: kDark),
                      dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square, color: kDark),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, size: 14, color: Colors.black38),
                    const SizedBox(width: 6),
                    Text('Présentez ce QR code à l\'entrée',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.45),
                            fontWeight: FontWeight.w500)),
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

// ── CHIP INFO ──
class _InfoChip extends StatelessWidget {
  final String label;
  final bool dark;
  const _InfoChip({required this.label, required this.dark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: dark ? kDark : const Color(0xFFF0F0F0),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label,
        style: TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700,
            color: dark ? Colors.white : kDark)),
  );
}

// ── SÉPARATEUR DENTELÉ ──
class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20, height: 20,
          decoration: const BoxDecoration(
            color: kBeige,
            borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (_, c) {
            final count = (c.maxWidth / 10).floor();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(count, (_) => Container(
                width: 5, height: 1.5,
                color: Colors.black.withOpacity(0.12),
              )),
            );
          }),
        ),
        Container(
          width: 20, height: 20,
          decoration: const BoxDecoration(
            color: kBeige,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
          ),
        ),
      ],
    );
  }
}
