import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hero/presentation/pages/auth/cubit/auth_cubit.dart';
import 'cubit/auth_states.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  // ── Animation Controllers ─────────────────────────────────────────────────
  late AnimationController _logoController;
  late AnimationController _formController;
  late AnimationController _bgController;

  late Animation<double> _logoScale;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _bgFade;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _runAnimations();
  }

  void _initAnimations() {
    _bgController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _formController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _bgFade = CurvedAnimation(parent: _bgController, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));

    _logoScale =
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut)
            .drive(Tween(begin: 0.0, end: 1.0));

    _formFade = CurvedAnimation(parent: _formController, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));

    _formSlide =
        CurvedAnimation(parent: _formController, curve: Curves.easeOut)
            .drive(Tween(begin: const Offset(0, 0.3), end: Offset.zero));
  }

  void _runAnimations() {
    _bgController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logoController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _formController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _formController.dispose();
    _bgController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _bgFade,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFECFDF5), Colors.white],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is AuthRegistered) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('✅ Account created successfully!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                    context.go('/home');
                  }
                  if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ ${state.message}'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return Column(
                    children: [
                      // ── Back Button ──────────────────────────────────────
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => context.pop(),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                )
                              ],
                            ),
                            child: const Icon(Icons.arrow_back_ios,
                                size: 16, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Logo ─────────────────────────────────────────────
                      ScaleTransition(
                        scale: _logoScale,
                        child: Column(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF059669)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981)
                                        .withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.fitness_center,
                                  size: 44, color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Join Hero Fitness ',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your account and start your journey',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Form ─────────────────────────────────────────────
                      FadeTransition(
                        opacity: _formFade,
                        child: SlideTransition(
                          position: _formSlide,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Full Name
                                  _AnimatedField(
                                    delay: 0,
                                    formController: _formController,
                                    child: TextFormField(
                                      controller: _fullNameController,
                                      textCapitalization:
                                      TextCapitalization.words,
                                      decoration: _inputDecoration(
                                        label: 'Full Name',
                                        icon: Icons.person_outline,
                                        color: const Color(0xFF10B981),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your full name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Email
                                  _AnimatedField(
                                    delay: 100,
                                    formController: _formController,
                                    child: TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: _inputDecoration(
                                        label: 'Email Address',
                                        icon: Icons.email_outlined,
                                        color: const Color(0xFF3B82F6),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@') ||
                                            !value.contains('.')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Password
                                  _AnimatedField(
                                    delay: 200,
                                    formController: _formController,
                                    child: TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      decoration: _inputDecoration(
                                        label: 'Password',
                                        icon: Icons.lock_outline,
                                        color: Colors.purple,
                                        suffix: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() =>
                                          _obscurePassword =
                                          !_obscurePassword),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter password';
                                        }
                                        if (value.length < 6) {
                                          return 'Min 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Confirm Password
                                  _AnimatedField(
                                    delay: 300,
                                    formController: _formController,
                                    child: TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      decoration: _inputDecoration(
                                        label: 'Confirm Password',
                                        icon: Icons.lock_outline,
                                        color: Colors.orange,
                                        suffix: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() =>
                                          _obscureConfirmPassword =
                                          !_obscureConfirmPassword),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please confirm password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Terms checkbox
                                  GestureDetector(
                                    onTap: () => setState(
                                            () => _agreeToTerms = !_agreeToTerms),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _agreeToTerms
                                            ? const Color(0xFF10B981)
                                            .withOpacity(0.05)
                                            : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _agreeToTerms
                                              ? const Color(0xFF10B981)
                                              .withOpacity(0.3)
                                              : Colors.grey[200]!,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: _agreeToTerms
                                                  ? const Color(0xFF10B981)
                                                  : Colors.white,
                                              borderRadius:
                                              BorderRadius.circular(6),
                                              border: Border.all(
                                                color: _agreeToTerms
                                                    ? const Color(0xFF10B981)
                                                    : Colors.grey[300]!,
                                              ),
                                            ),
                                            child: _agreeToTerms
                                                ? const Icon(Icons.check,
                                                color: Colors.white,
                                                size: 14)
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Text(
                                              'I agree to the Terms & Conditions',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Create Account Button
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: _agreeToTerms
                                          ? [
                                        BoxShadow(
                                          color: const Color(0xFF10B981)
                                              .withOpacity(0.4),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        )
                                      ]
                                          : [],
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: _agreeToTerms &&
                                            state is! AuthLoading
                                            ? () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            context
                                                .read<AuthCubit>()
                                                .register(
                                              _emailController.text
                                                  .trim(),
                                              _passwordController
                                                  .text,
                                              _fullNameController.text
                                                  .trim(),
                                            );
                                          }
                                        }
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                          const Color(0xFF10B981),
                                          disabledBackgroundColor:
                                          Colors.grey[200],
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(14)),
                                          elevation: 0,
                                        ),
                                        child: state is AuthLoading
                                            ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child:
                                          CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                            : const Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Create Account',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(Icons.rocket_launch,
                                                size: 18),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Sign In link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Already have an account? ',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14)),
                                      GestureDetector(
                                        onTap: () => context.go('/login'),
                                        child: const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required Color color,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

// ── Animated Field Widget ─────────────────────────────────────────────────────
class _AnimatedField extends StatefulWidget {
  final int delay;
  final AnimationController formController;
  final Widget child;

  const _AnimatedField({
    required this.delay,
    required this.formController,
    required this.child,
  });

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField> {
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final start = (widget.delay / 1000).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: widget.formController,
      curve: Interval(start, 1.0, curve: Curves.easeOut),
    );
    _fade = curved.drive(Tween(begin: 0.0, end: 1.0));
    _slide = curved.drive(
        Tween(begin: const Offset(0, 0.2), end: Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}