import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/team_provider.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  
  String? _selectedZone;
  Color _selectedColor = const Color(0xFF006F39);
  XFile? _logoFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _zones = ['DAKAR', 'GUEEDIAWAYE', 'PIKINE', 'RUFISQUE'];
  final List<Color> _colors = [
    const Color(0xFF006F39), // Vert MiniFoot
    const Color(0xFF1A1A1A), // Noir
    const Color(0xFFD4AF37), // Or
    const Color(0xFFC41E3A), // Rouge
    const Color(0xFF0047AB), // Bleu
    const Color(0xFF702963), // Byzantium
  ];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _logoFile = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final teamProv = Provider.of<TeamProvider>(context, listen: false);

    if (authProv.token == null) return;

    try {
      List<int>? logoBytes;
      if (_logoFile != null) {
        logoBytes = await _logoFile!.readAsBytes();
      }

      await teamProv.createTeam(
        token: authProv.token!,
        name: _nameController.text.trim(),
        zone: _selectedZone,
        address: _addressController.text.trim(),
        color: '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
        logoBytes: logoBytes,
        logoFilename: _logoFile?.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Équipe créée avec succès !')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const kDark = Color(0xFF1A1A1A);
    const kGreen = Color(0xFF006F39);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Créer mon équipe',
          style: GoogleFonts.orbitron(
            color: kDark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SÉLECTION LOGO ──
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          image: _logoFile != null
                              ? DecorationImage(
                                  image: FileImage(File(_logoFile!.path)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _logoFile == null
                            ? const Icon(Icons.add_a_photo_rounded,
                                color: Colors.grey, size: 40)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: kGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── NOM DE L'ÉQUIPE ──
              _buildLabel('Nom de l\'équipe'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Ex: Dakar Warriors'),
                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 20),

              // ── ZONE ──
              _buildLabel('Zone / Ville'),
              DropdownButtonFormField<String>(
                value: _selectedZone,
                items: _zones.map((z) => DropdownMenuItem(
                  value: z,
                  child: Text(z),
                )).toList(),
                onChanged: (v) => setState(() => _selectedZone = v),
                decoration: _inputDecoration('Sélectionner une zone'),
              ),
              const SizedBox(height: 20),

              // ── ADRESSE ──
              _buildLabel('Adresse (Optionnel)'),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration('Ex: Parcelles Assainies, Villa 123'),
              ),
              const SizedBox(height: 20),

              // ── COULEUR ──
              _buildLabel('Couleur de l\'équipe'),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final color = _colors[i];
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? kGreen : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),

              // ── BOUTON SUBMIT ──
              Consumer<TeamProvider>(
                builder: (context, teamProv, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: teamProv.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: teamProv.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'CRÉER L\'ÉQUIPE',
                              style: GoogleFonts.orbitron(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.orbitron(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[600],
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF006F39), width: 1.5),
      ),
    );
  }
}
