import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    _loadSavedForm();
  }

  Future<void> _loadSavedForm() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _phoneController.text = prefs.getString('signup_phone') ?? '';
        _prenomController.text = prefs.getString('signup_prenom') ?? '';
        _nomController.text = prefs.getString('signup_nom') ?? '';
        _passwordController.text = prefs.getString('signup_password') ?? '';
        _confirmPasswordController.text = prefs.getString('signup_password') ?? '';
      });
    }
  }

  void _saveFormValues() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('signup_phone', _phoneController.text.trim());
    await prefs.setString('signup_prenom', _prenomController.text.trim());
    await prefs.setString('signup_nom', _nomController.text.trim());
    await prefs.setString('signup_password', _passwordController.text.trim());
  }

  @override
  void dispose() {
    _animController.dispose();
    _phoneController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _formKey.currentState?.reset();
    _phoneController.clear();
    _prenomController.clear();
    _nomController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _animController.reset();
    setState(() {
      _isLogin = !_isLogin;
    });
    _animController.forward();
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = '+221${_phoneController.text.trim()}';
    final authProvider = context.read<AuthProvider>();

    try {
      if (_isLogin) {
        // --- MODE CONNEXION ---
        final password = _passwordController.text.trim();
        if (password.isEmpty) {
          _showAuthErrorDialog(
            title: 'Mot de passe requis',
            message: 'Veuillez saisir votre mot de passe.',
          );
          return;
        }

        await authProvider.login(phone, password);
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        // --- MODE INSCRIPTION ---
        _saveFormValues();
        final result = await authProvider.signup(
          phone: phone,
          firstName: _prenomController.text.trim(),
          lastName: _nomController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (!mounted) return;

        if (result['skipOtp'] == true) {
          // Le compte est déjà vérifié (passe-droit actif), on inscrit directement
          await authProvider.register(
            phone: phone,
            password: _passwordController.text.trim(),
            firstName: _prenomController.text.trim(),
            lastName: _nomController.text.trim(),
          );
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
          return;
        }

        if (result['otpActive'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Un code a déjà été envoyé précédemment.')),
          );
        }

        // Go OTP avec toutes les infos pour finaliser après
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => OtpScreen(
              phone: phone,
              firstName: _prenomController.text.trim(),
              lastName: _nomController.text.trim(),
              password: _passwordController.text.trim(),
              isNewUser: true,
            ),
            transitionsBuilder: (_, animation, _, child) => SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 450),
          ),
        );
      }
    } catch (e) {
      final raw = e.toString();
      String title = 'Connexion impossible';
      String message =
          'Nos serveurs sont momentanément indisponibles. Veuillez réessayer dans quelques instants.';

      if (raw.contains('AUTH_INVALID') ||
          raw.contains('COMPTE_NON_TROUVE') ||
          raw.contains('Identifiants invalides')) {
        title = 'Identifiants incorrects';
        message = 'Mot de passe ou téléphone incorrect.';
      } else if (raw.contains('SERVER_UNAVAILABLE') ||
          raw.contains('SocketException') ||
          raw.contains('TimeoutException')) {
        message =
            'Nos serveurs sont momentanément indisponibles. Veuillez réessayer dans quelques instants.';
      } else if (raw.contains('Numéro sénégalais invalide')) {
        title = 'Numéro invalide';
        message = 'Saisis les 9 chiffres du numéro sans +221.';
      } else if (raw.contains('déjà utilisé')) {
        title = 'Inscription impossible';
        message = 'Ce numéro est déjà utilisé par un autre compte.';
      }

      if (!mounted) return;
      _showAuthErrorDialog(title: title, message: message);
    }
  }

  void _showAuthErrorDialog({required String title, required String message}) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, color: kGreen),
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.black.withOpacity(0.72), height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: kGreen, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
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
                            ? 'Entre tes identifiants pour te connecter'
                            : 'Remplis les informations pour créer ton compte',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.50),
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

                    const SizedBox(height: 14),

                    // Champ Mot de Passe
                    _InputField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Le mot de passe est requis';
                        }
                        if (v.trim().length < 6) {
                          return 'Minimum 6 caractères';
                        }
                        return null;
                      },
                    ),

                    if (_isLogin) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(
                              color: kGreen,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (!_isLogin) ...[
                      const SizedBox(height: 14),
                      _InputField(
                        controller: _confirmPasswordController,
                        label: 'Confirmer le mot de passe',
                        icon: Icons.lock_reset_rounded,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleVisibility: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        validator: (v) {
                          if (v != _passwordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                    ],

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
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isLogin
                                            ? 'Se connecter'
                                            : 'S\'inscrire',
                                        style: GoogleFonts.orbitron(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
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
                                color: Colors.black.withOpacity(0.5),
                              ),
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
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggleVisibility;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggleVisibility,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: isPassword ? obscureText : false,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
        prefixIcon: Icon(icon, color: kGreen),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: kGreen.withOpacity(0.6),
                ),
                onPressed: onToggleVisibility,
              )
            : null,
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
        labelStyle: TextStyle(color: Colors.black.withOpacity(0.45)),
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
  final String password;
  final bool isNewUser;

  const OtpScreen({
    super.key,
    required this.phone,
    this.firstName = '',
    this.lastName = '',
    this.password = '',
    this.isNewUser = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
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

  void _resend() async {
    if (!_canResend) return;
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.resendOtp(widget.phone);
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Un nouveau code a été envoyé')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
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
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
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
                'Code envoyé au\n🇸🇳 ${widget.phone}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.50),
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
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
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
                onTap: _canResend ? _resend : null,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: _canResend ? kGreen : Colors.black.withOpacity(0.35),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    decoration: _canResend
                        ? TextDecoration.underline
                        : TextDecoration.none,
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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _obscurePassword = true;
  String? _phone;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_phoneFormKey.currentState?.validate() ?? false)) return;

    final phone = '+221${_phoneController.text.trim()}';
    final authProvider = context.read<AuthProvider>();

    try {
      final result = await authProvider.forgotPassword(phone);
      if (!mounted) return;
      setState(() {
        _phone = phone;
        _codeSent = true;
        _errorMessage = null;
      });
      final devCode = result['devCode'];
      if (devCode != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Code dev : $devCode')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyError(e));
    }
  }

  Future<void> _resetPassword() async {
    if (!(_resetFormKey.currentState?.validate() ?? false)) return;

    try {
      await context.read<AuthProvider>().resetPassword(
        phone: _phone!,
        code: _codeController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Mot de passe modifié',
            style: TextStyle(fontWeight: FontWeight.w800, color: kGreen),
          ),
          content: const Text(
            'Tu peux maintenant te connecter avec ton nouveau mot de passe.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: kGreen, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _friendlyError(e));
    }
  }

  String _friendlyError(Object error) {
    final raw = error.toString();
    if (raw.contains('Compte non trouvé')) {
      return 'Aucun compte ne correspond à ce numéro.';
    }
    if (raw.contains('Code OTP invalide') ||
        raw.contains('invalide ou expiré')) {
      return 'Code invalide ou expiré.';
    }
    if (raw.contains('Trop de demandes OTP')) {
      return 'Trop de demandes. Réessaie plus tard.';
    }
    if (raw.contains('Numéro de téléphone')) {
      return 'Saisis les 9 chiffres du numéro sans +221.';
    }
    return 'Impossible de réinitialiser le mot de passe pour le moment.';
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'MINIFOOT',
                    style: GoogleFonts.orbitron(
                      color: kGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  _codeSent ? 'Nouveau mot de passe' : 'Mot de passe oublié',
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFF111111),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _codeSent
                      ? 'Entre le code reçu et choisis un nouveau mot de passe.'
                      : 'Entre ton numéro pour recevoir un code de réinitialisation.',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.55),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                if (_codeSent) _buildResetForm() else _buildPhoneForm(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        children: [
          _PhoneField(
            controller: _phoneController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Le numéro est requis';
              if (v.trim().length != 9) {
                return 'Numéro invalide (9 chiffres après +221)';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          _SubmitButton(label: 'Envoyer le code', onPressed: _sendCode),
        ],
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _resetFormKey,
      child: Column(
        children: [
          _InputField(
            controller: _codeController,
            label: 'Code OTP',
            icon: Icons.password_rounded,
            validator: (v) {
              if (v == null || v.trim().length != 6) {
                return 'Saisis les 6 chiffres du code';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: _passwordController,
            label: 'Nouveau mot de passe',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleVisibility: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Le mot de passe est requis';
              }
              if (v.trim().length < 6) return 'Minimum 6 caractères';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _InputField(
            controller: _confirmPasswordController,
            label: 'Confirmer le mot de passe',
            icon: Icons.lock_reset_rounded,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleVisibility: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) {
              if (v != _passwordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          _SubmitButton(
            label: 'Modifier le mot de passe',
            onPressed: _resetPassword,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              setState(() {
                _codeSent = false;
                _errorMessage = null;
              });
            },
            child: const Text(
              'Changer de numéro',
              style: TextStyle(color: kGreen, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SubmitButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: auth.isLoading ? null : onPressed,
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
                  label,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
