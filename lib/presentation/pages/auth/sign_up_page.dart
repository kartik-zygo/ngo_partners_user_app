import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _orgNameCtrl = TextEditingController();
  final _orgTypeCtrl = TextEditingController();
  final _orgRegCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _isOrgAccount = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _orgNameCtrl.dispose();
    _orgTypeCtrl.dispose();
    _orgRegCtrl.dispose();
    super.dispose();
  }

  void _register() {
    if (_firstNameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
            isOrganizationAccount: _isOrgAccount,
            organizationName: _isOrgAccount
                ? _orgNameCtrl.text.trim().isEmpty
                    ? null
                    : _orgNameCtrl.text.trim()
                : null,
            organizationType: _isOrgAccount
                ? _orgTypeCtrl.text.trim().isEmpty
                    ? null
                    : _orgTypeCtrl.text.trim()
                : null,
            organizationRegNumber: _isOrgAccount
                ? _orgRegCtrl.text.trim().isEmpty
                    ? null
                    : _orgRegCtrl.text.trim()
                : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(ctx).pop(); // Let main navigator handle routing
        } else if (state is AuthError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
              height: MediaQuery.of(context).size.height * 0.28,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1D4ED8),
                      Color(0xFF0EA5E9),
                      Color(0xFF22D3EE),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(40),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Create Account',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: Colors.white,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Join NGO Partners today',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Scrollable form
            SafeArea(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (ctx, state) {
                  final isLoading = state is AuthLoading;
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.22,
                      bottom: 40,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Personal Details',
                                style: AppTextStyles.headlineMedium),
                            const SizedBox(height: 20),
                            // Name row
                            Row(
                              children: [
                                Expanded(
                                  child: _field(
                                    'First Name *',
                                    _firstNameCtrl,
                                    hint: 'John',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _field(
                                    'Last Name',
                                    _lastNameCtrl,
                                    hint: 'Doe',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _field(
                              'Email Address *',
                              _emailCtrl,
                              hint: 'email@example.com',
                              type: TextInputType.emailAddress,
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 14),
                            _field(
                              'Phone Number',
                              _phoneCtrl,
                              hint: '+91 9876543210',
                              type: TextInputType.phone,
                              icon: Icons.phone_outlined,
                            ),
                            const SizedBox(height: 14),
                            // Password
                            _buildLabel('Password *'),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePass,
                              style: AppTextStyles.bodyLarge,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: Icon(Icons.lock_outline,
                                    color:
                                        AppColors.primary.withValues(alpha: 0.6),
                                    size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePass
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePass = !_obscurePass),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Org account toggle
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isOrgAccount = !_isOrgAccount),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: _isOrgAccount
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                          color: AppColors.primary,
                                          width: 1.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: _isOrgAccount
                                        ? const Icon(Icons.check,
                                            color: Colors.white, size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Register as Organisation/NGO',
                                    style: AppTextStyles.bodyLarge,
                                  ),
                                ],
                              ),
                            ),
                            // Org fields (conditionally shown)
                            if (_isOrgAccount) ...[
                              const SizedBox(height: 20),
                              const Divider(color: AppColors.borderSubtle),
                              const SizedBox(height: 14),
                              Text('Organisation Details',
                                  style: AppTextStyles.headlineSmall),
                              const SizedBox(height: 16),
                              _field(
                                'Organisation Name',
                                _orgNameCtrl,
                                hint: 'Green Earth NGO',
                                icon: Icons.business_outlined,
                              ),
                              const SizedBox(height: 14),
                              _field(
                                'Organisation Type',
                                _orgTypeCtrl,
                                hint: 'Environmental',
                                icon: Icons.category_outlined,
                              ),
                              const SizedBox(height: 14),
                              _field(
                                'Registration Number',
                                _orgRegCtrl,
                                hint: 'REG12345',
                                icon: Icons.numbers_outlined,
                              ),
                            ],
                            const SizedBox(height: 24),
                            GoldButton(
                              label: 'Create Account',
                              icon: Icons.person_add_rounded,
                              isLoading: isLoading,
                              onTap: isLoading ? null : _register,
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Already have an account? ',
                                    style: AppTextStyles.bodyMedium,
                                    children: [
                                      TextSpan(
                                        text: 'Sign In',
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) =>
      Text(text, style: AppTextStyles.labelLarge.copyWith(fontSize: 13));

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String hint = '',
    TextInputType type = TextInputType.text,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: type,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon,
                    color: AppColors.primary.withValues(alpha: 0.6), size: 20)
                : null,
          ),
        ),
      ],
    );
  }
}
