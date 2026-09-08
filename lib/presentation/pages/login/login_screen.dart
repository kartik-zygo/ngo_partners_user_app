import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../auth/sign_up_page.dart';

// ── Login Screen ──────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );

    // Animate entrance
    _shakeCtrl.value = 0;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _login(BuildContext ctx) {
    context.read<AuthBloc>().add(
          AuthLoginRequested(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          ),
        );
  }

  void _triggerShake() {
    _shakeCtrl.reset();
    _shakeCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthError) _triggerShake();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Top gradient hero
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.42,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9), Color(0xFF22D3EE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -60,
                      right: -60,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      left: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Center(
                                child: Text('🏛️', style: TextStyle(fontSize: 26)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Welcome Back',
                              style: AppTextStyles.displayLarge.copyWith(
                                color: Colors.white,
                                fontSize: 30,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'NGO Partners — your legal & compliance partner',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
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
            // Scrollable form
            SafeArea(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (ctx, state) {
                  final isLoading = state is AuthLoading;
                  final error = state is AuthError ? state.message : null;
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.34,
                      bottom: 32,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(6 * math.sin(_shakeAnim.value * math.pi * 4), 0),
                          child: child,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                              const BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sign In', style: AppTextStyles.headlineMedium),
                              const SizedBox(height: 4),
                              Text('Enter your credentials to continue',
                                  style: AppTextStyles.bodyMedium),
                              const SizedBox(height: 24),
                              // Email
                              _buildLabel('Email Address'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: AppTextStyles.bodyLarge,
                                onSubmitted: (_) => _login(ctx),
                                decoration: InputDecoration(
                                  hintText: 'email@example.com',
                                  prefixIcon: Icon(Icons.email_outlined,
                                      color: AppColors.primary.withValues(alpha: 0.6), size: 20),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Password
                              _buildLabel('Password'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _passCtrl,
                                obscureText: _obscurePass,
                                style: AppTextStyles.bodyLarge,
                                onSubmitted: (_) => _login(ctx),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: Icon(Icons.lock_outline,
                                      color: AppColors.primary.withValues(alpha: 0.6), size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePass
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscurePass = !_obscurePass),
                                  ),
                                ),
                              ),
                              // Error
                              if (error != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.error.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: AppColors.error, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(error,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(color: AppColors.error)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              GoldButton(
                                label: 'Sign In',
                                onTap: isLoading ? null : () => _login(ctx),
                                isLoading: isLoading,
                                icon: Icons.arrow_forward_rounded,
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const SignUpPage()),
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      text: "Don't have an account? ",
                                      style: AppTextStyles.bodyMedium,
                                      children: [
                                        TextSpan(
                                          text: 'Sign Up',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: AppTextStyles.labelLarge.copyWith(fontSize: 13));
  }

}


// ── Matrix Rain ───────────────────────────────────────────────────────────────
class _MatrixRain extends StatefulWidget {
  final Color color;
  const _MatrixRain({required this.color});

  @override
  State<_MatrixRain> createState() => _MatrixRainState();
}

class _MatrixRainState extends State<_MatrixRain> with TickerProviderStateMixin {
  static const _chars = '01アイウエオNGOLAWREGISTER';
  static const _cols = 14;
  final _rng = math.Random();
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_cols, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 3000 + _rng.nextInt(4000)),
      )..repeat();
      Future.delayed(Duration(milliseconds: _rng.nextInt(3000)), ctrl.forward);
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.12,
        child: SizedBox.expand(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_cols, (i) {
              final colChars = List.generate(
                18,
                (_) => _chars[_rng.nextInt(_chars.length)],
              ).join('\n');
              return AnimatedBuilder(
                animation: _controllers[i],
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, -80 + _controllers[i].value * 900),
                  child: Text(
                    colChars,
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.color,
                      fontFamily: 'monospace',
                      height: 1.4,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
