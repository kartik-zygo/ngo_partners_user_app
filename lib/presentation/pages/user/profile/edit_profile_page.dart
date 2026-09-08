import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/common_widgets.dart';
import '../../../../../domain/entities/user_entity.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import '../../../blocs/auth/auth_state.dart';

class EditProfilePage extends StatefulWidget {
  final UserEntity user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _orgNameCtrl;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(
        text: widget.user.firstName ?? widget.user.name.split(' ').first);
    _lastNameCtrl = TextEditingController(
        text: widget.user.lastName ??
            (widget.user.name.split(' ').length > 1
                ? widget.user.name.split(' ').last
                : ''));
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    _orgNameCtrl =
        TextEditingController(text: widget.user.organizationName ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _orgNameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    context.read<AuthBloc>().add(
          AuthProfileUpdated(
            firstName: _firstNameCtrl.text.trim().isEmpty
                ? null
                : _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim().isEmpty
                ? null
                : _lastNameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
            organizationName: _orgNameCtrl.text.trim().isEmpty
                ? null
                : _orgNameCtrl.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(ctx);
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
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(title: const Text('Edit Profile')),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (ctx, state) {
            final isSaving = state is AuthLoading;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Personal Information',
                          style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'First Name',
                              controller: _firstNameCtrl,
                              hint: 'John',
                              prefix: const Icon(Icons.person_outline_rounded,
                                  color: AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              label: 'Last Name',
                              controller: _lastNameCtrl,
                              hint: 'Doe',
                              prefix: const Icon(Icons.person_outline_rounded,
                                  color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Phone Number',
                        controller: _phoneCtrl,
                        hint: '+91 9876543210',
                        keyboardType: TextInputType.phone,
                        prefix: const Icon(Icons.phone_outlined,
                            color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (widget.user.isOrganizationAccount) ...[
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Organisation Details',
                            style: AppTextStyles.headlineSmall),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: 'Organisation Name',
                          controller: _orgNameCtrl,
                          hint: 'Green Earth NGO',
                          prefix: const Icon(Icons.business_outlined,
                              color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 8),
                GoldButton(
                  label: 'Save Changes',
                  icon: Icons.check_rounded,
                  isLoading: isSaving,
                  onTap: isSaving ? null : _save,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
