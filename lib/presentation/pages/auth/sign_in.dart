import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'cubit/auth_cubit.dart';
import 'cubit/auth_states.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  // ── Animation Controllers ─────────────────────────────────────────────────
  late AnimationController _logoController;
  late AnimationController _formController;
  late AnimationController _bgController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;
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
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bgFade = CurvedAnimation(parent: _bgController, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));

    _logoScale =
        CurvedAnimation(parent: _logoController, curve: Curves.elasticOut)
            .drive(Tween(begin: 0.0, end: 1.0));

    _logoRotate =
        CurvedAnimation(parent: _logoController, curve: Curves.easeOut)
            .drive(Tween(begin: -0.05, end: 0.0));

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
    _emailController.dispose();
    _passwordController.dispose();
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
              colors: [Color(0xFFEFF6FF), Colors.white],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is AuthAuthenticated) {
                    context.go('/home');
                  }
                  if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                  }
                },
                builder: (context, state) {
                  return Column(
                    children: [
                      // ── Back Button ─────────────────────────────────────
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

                      const SizedBox(height: 20),

                      // ── Logo ────────────────────────────────────────────
                      ScaleTransition(
                        scale: _logoScale,
                        child: RotationTransition(
                          turns: _logoRotate,
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
                                      Color(0xFF3B82F6),
                                      Color(0xFF1D4ED8)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6)
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
                                'Welcome Back! ',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign in to continue your fitness journey',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Form ────────────────────────────────────────────
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
                                  CustomTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter password';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      Transform.scale(
                                        scale: 0.9,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: const Color(0xFF3B82F6),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(4)),
                                          onChanged: (value) => setState(
                                                  () => _rememberMe = value!),
                                        ),
                                      ),
                                      const Text('Remember me',
                                          style: TextStyle(fontSize: 13)),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                            foregroundColor:
                                            const Color(0xFF3B82F6)),
                                        child: const Text('Forgot Password?',
                                            style: TextStyle(fontSize: 13)),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // Sign In Button
                                  CustomButton(
                                    text: 'Sign In',
                                    isLoading: state is AuthLoading,
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<AuthCubit>().login(
                                          _emailController.text.trim(),
                                          _passwordController.text,
                                        );
                                      }
                                    },
                                  ),

                                  const SizedBox(height: 20),

                                  // Divider
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Divider(color: Colors.grey[200])),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text('or',
                                            style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 13)),
                                      ),
                                      Expanded(
                                          child: Divider(color: Colors.grey[200])),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Sign Up Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Don't have an account? ",
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14)),
                                      GestureDetector(
                                        onTap: () => context.go('/register'),
                                        child: const Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            color: Color(0xFF3B82F6),
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
}