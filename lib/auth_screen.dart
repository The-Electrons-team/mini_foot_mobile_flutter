import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'home_screen.dart';


const Color kGreen = Color(0xFF006F39);
const Color kBeige = Color(0xFFF5F0E8);

// ---------------------------------------------------------------------------
// AUTH SCREEN
// ---------------------------------------------------------------------------

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _formKey.currentState?.reset();
    _phoneController.clear();
    _prenomController.clear();
    _nomController.clear();
    _animController.reset();
    setState(() {
      _isLogin = !_isLogin;
      _birthDate = null;
    });
    _animController.forward();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 5),
      helpText: 'Date de naissance',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kGreen,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String get _birthDateLabel {
    if (_birthDate == null) return 'Date de naissance';
    return '${_birthDate!.day.toString().padLeft(2, '0')}/'
        '${_birthDate!.month.toString().padLeft(2, '0')}/'
        '${_birthDate!.year}';
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = '+221${_phoneController.text.trim()}';
    final authProvider = context.read<AuthProvider>();

    try {
      if (_isLogin) {
        // --- MODE CONNEXION ---
        await authProvider.login(phone);
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        // --- MODE INSCRIPTION ---
        if (_birthDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez sélectionner votre date de naissance')),
          );
          return;
        }

        await authProvider.signup(phone);
        if (!mounted) return;

        // Go OTP avec toutes les infos pour finaliser après
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => OtpScreen(
              phone: phone,
              firstName: _prenomController.text.trim(),
              lastName: _nomController.text.trim(),
              birthDate: _birthDate,
              isNewUser: true,
            ),
            transitionsBuilder: (_, animation, _, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 450),
          ),
        );
      }
    } catch (e) {
      String message = 'Une erreur est survenue';
      if (e.toString().contains('COMPTE_NON_TROUVE')) {
        message = 'Compte non trouvé. Veuillez vous inscrire.';
      } else if (e.toString().contains('déjà utilisé')) {
        message = 'Ce numéro est déjà utilisé par un autre compte.';
      } else {
        message = e.toString().replaceAll('Exception: ', '');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Titre MINIFOOT
                    Text(
                      'MINIFOOT',
                      style: GoogleFonts.orbitron(
                        color: kGreen,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Titre page
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _isLogin ? 'Connexion' : 'Créer un compte',
                        style: GoogleFonts.orbitron(
                          color: const Color(0xFF111111),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _isLogin
                            ? 'Entre ton numéro pour recevoir un code OTP'
                            : 'Remplis les informations pour créer ton compte',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.50),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Champs inscription uniquement
                    if (!_isLogin) ...[
                      _InputField(
                        controller: _prenomController,
                        label: 'Prénom',
                        icon: Icons.person_outline_rounded,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Le prénom est requis';
                          }
                          if (v.trim().length < 2) {
                            return 'Prénom trop court';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _InputField(
                        controller: _nomController,
                        label: 'Nom',
                        icon: Icons.badge_outlined,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Le nom est requis';
                          }
                          if (v.trim().length < 2) {
                            return 'Nom trop court';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      // Champ date de naissance
                      GestureDetector(
                        onTap: _pickBirthDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _birthDate != null ? kGreen : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cake_rounded,
                                  color: _birthDate != null ? kGreen : kGreen.withValues(alpha: 0.6),
                                  size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _birthDateLabel,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _birthDate != null
                                        ? Colors.black87
                                        : Colors.black.withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down_rounded,
                                  color: kGreen.withValues(alpha: 0.7), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Champ téléphone Sénégal
                    _PhoneField(
                      controller: _phoneController,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Le numéro est requis';
                        }
                        if (v.trim().length != 9) {
                          return 'Numéro invalide (9 chiffres après +221)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // Bouton principal
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: auth.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isLogin ? 'Recevoir le code' : 'S\'inscrire',
                                        style: GoogleFonts.orbitron(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.arrow_forward_rounded,
                                          color: Colors.white, size: 20),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),


                    const SizedBox(height: 22),

                    // Toggle connexion / inscription
                    GestureDetector(
                      onTap: _toggleMode,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14),
                          children: [
                            TextSpan(
                              text: _isLogin
                                  ? 'Pas encore de compte ? '
                                  : 'Déjà un compte ? ',
                              style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.5)),
                            ),
                            TextSpan(
                              text: _isLogin ? 'S\'inscrire' : 'Se connecter',
                              style: const TextStyle(
                                color: kGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CHAMP TEXTE GÉNÉRIQUE
// ---------------------------------------------------------------------------

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
        prefixIcon: Icon(icon, color: kGreen),
        filled: true,
        fillColor: const Color(0xFFF4F4F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CHAMP TÉLÉPHONE SÉNÉGAL
// ---------------------------------------------------------------------------

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const _PhoneField({required this.controller, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9),
      ],
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: 'Numéro de téléphone',
        labelStyle: TextStyle(color: Colors.black.withValues(alpha: 0.45)),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('🇸🇳', style: TextStyle(fontSize: 20)),
              SizedBox(width: 6),
              Text(
                '+221',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                height: 22,
                child: VerticalDivider(color: Colors.black26, width: 1),
              ),
            ],
          ),
        ),
        filled: true,
        fillColor: const Color(0xFFF4F4F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// OTP SCREEN
// ---------------------------------------------------------------------------

class OtpScreen extends StatefulWidget {
  final String phone;
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final bool isNewUser;

  const OtpScreen({
    super.key,
    required this.phone,
    this.firstName = '',
    this.lastName = '',
    this.birthDate,
    this.isNewUser = false,
  });



  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendSeconds = 30;
  bool _canResend = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startCountdown() {
    setState(() {
      _resendSeconds = 30;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) {
        setState(() => _canResend = true);
        return false;
      }
      return true;
    });
  }

  void _onDigit(String val, int index) {
    if (val.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (val.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() => _errorMessage = null);
  }

  void _validate() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _errorMessage = 'Saisis les 6 chiffres du code');
      return;
    }

    final authProvider = context.read<AuthProvider>();

    try {
      final verified = await authProvider.verifyOtp(widget.phone, code);

      if (!mounted) return;

      if (verified) {
        if (widget.isNewUser) {
          // Si nouveau, on doit appeler register
          if (widget.firstName.isEmpty || widget.lastName.isEmpty) {
            // Cas où l'utilisateur a essayé de se connecter sans passer par inscription
            // On pourrait rediriger vers un écran de complément de profil
            // Pour l'instant, on affiche une erreur ou on force le retour
            setState(() => _errorMessage = 'Informations de profil manquantes');
            return;
          }

          await authProvider.register(
            phone: widget.phone,
            firstName: widget.firstName,
            lastName: widget.lastName,
            birthDate: widget.birthDate?.toIso8601String(),
          );

        }

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const HomeScreen(),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (_) => false,
        );
      } else {
        setState(() => _errorMessage = 'Code invalide');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }


  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBeige,
      appBar: AppBar(
        backgroundColor: kBeige,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kGreen),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'MINIFOOT',
                style: GoogleFonts.orbitron(
                  color: kGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 36),

              Text(
                'Vérification OTP',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF111111),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Code envoyé au\n🇸🇳 +221 ${widget.phone}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.50),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 40),

              // 6 cases OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Container(
                    width: 44,
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextFormField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kGreen,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFFF4F4F4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: kGreen, width: 2),
                        ),
                      ),
                      onChanged: (val) => _onDigit(val, i),
                    ),
                  );
                }),
              ),

              // Message d'erreur
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],

              const SizedBox(height: 36),

              // Bouton valider
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _validate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: auth.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Valider le code',
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  );
                },
              ),


              const SizedBox(height: 24),

              // Renvoyer
              GestureDetector(
                onTap: _canResend ? _startCountdown : null,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: _canResend ? kGreen : Colors.black.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    decoration: _canResend ? TextDecoration.underline : TextDecoration.none,
                    decorationColor: kGreen,
                  ),
                  child: Text(
                    _canResend
                        ? 'Renvoyer le code'
                        : 'Renvoyer dans $_resendSeconds s',
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
