import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../domain/entities/user_entity.dart';
import '../../blocs/app/app_blocs.dart';
import '../../blocs/services/services_bloc.dart';
import '../../blocs/services/services_bloc_events_states.dart';
import 'tabs/ngo_home_tab.dart';
import 'tabs/ngo_collab_tab.dart';
import 'tabs/ngo_cases_tab.dart';
import 'tabs/ngo_profile_tab.dart';

class NgoDashboard extends StatefulWidget {
  final UserEntity user;
  const NgoDashboard({super.key, required this.user});

  @override
  State<NgoDashboard> createState() => _NgoDashboardState();
}

class _NgoDashboardState extends State<NgoDashboard> {
  int _tab = 0;

  final _tabs = const [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.handshake_rounded, label: 'Collabs'),
    _NavItem(icon: Icons.folder_open_rounded, label: 'Cases'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<ServicesBloc>()
      ..add(LoadServices())
      ..add(LoadCases(widget.user.id));
    context.read<CollabBloc>().add(LoadCollaborations());
    context.read<NotifBloc>().add(LoadNotifications(widget.user.id));
    context.read<TicketsBloc>().add(LoadTickets(widget.user.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          children: [
            const AnimatedBackground(),
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _tab,
                children: [
                  NgoHomeTab(user: widget.user, onNavigate: (i) => setState(() => _tab = i)),
                  NgoCollabTab(user: widget.user),
                  NgoCasesTab(user: widget.user),
                  NgoProfileTab(user: widget.user),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: const Border(
            top: BorderSide(color: AppColors.borderGold, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final t = _tabs[i];
              final selected = _tab == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tab = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.roleNGO.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(t.icon, size: 22,
                            color: selected ? AppColors.roleNGO : AppColors.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(t.label,
                          style: AppTextStyles.caption.copyWith(
                            color: selected ? AppColors.roleNGO : AppColors.textMuted,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 10,
                          )),
                    ],
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

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
