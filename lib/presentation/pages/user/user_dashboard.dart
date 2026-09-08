import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../domain/entities/user_entity.dart';
import '../../blocs/app/app_blocs.dart';
import '../../blocs/services/services_bloc.dart';
import '../../blocs/services/services_bloc_events_states.dart';
import 'tabs/home_tab.dart';
import 'tabs/services_tab.dart';
import 'tabs/cases_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/notifications_tab.dart';
import '../community/community_tab.dart';

class UserDashboard extends StatefulWidget {
  final UserEntity user;
  const UserDashboard({super.key, required this.user});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _tab = 0;

  final _tabs = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.grid_view_rounded, label: 'Services'),
    _NavItem(icon: Icons.forum_rounded, label: 'Community'),
    _NavItem(icon: Icons.folder_open_rounded, label: 'Cases'),
    _NavItem(icon: Icons.notifications_rounded, label: 'Alerts'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<ServicesBloc>()
      ..add(LoadServices())
      ..add(LoadCases(widget.user.id));
    context.read<NotifBloc>().add(LoadNotifications(widget.user.id));
    context.read<TicketsBloc>().add(LoadTickets(widget.user.id));
  }

  void _switchTab(int i) {
    setState(() => _tab = i);
    switch (i) {
      case 1:
        context.read<ServicesBloc>().add(LoadServices());
      case 3:
        context.read<ServicesBloc>().add(LoadCases(widget.user.id));
      case 4:
        context.read<NotifBloc>().add(LoadNotifications(widget.user.id));
    }
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
                  HomeTab(user: widget.user, onNavigate: _switchTab),
                  ServicesTab(user: widget.user),
                  CommunityTab(user: widget.user),
                  CasesTab(user: widget.user),
                  NotificationsTab(userId: widget.user.id),
                  ProfileTab(user: widget.user),
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
    return BlocBuilder<NotifBloc, NotifState>(
      builder: (ctx, notifState) {
        final unread = notifState is NotifLoaded ? notifState.unreadCount : 0;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: AppColors.borderSubtle, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, -6),
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
                  final showBadge = i == 4 && unread > 0;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _switchTab(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primarySurface
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    t.icon,
                                    size: 21,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                  ),
                                ),
                                if (showBadge)
                                  Positioned(
                                    right: 4,
                                    top: 0,
                                    child: NotificationDot(count: unread),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              t.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: selected ? AppColors.primary : AppColors.textMuted,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

