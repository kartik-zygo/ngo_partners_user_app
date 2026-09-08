import 'package:flutter/material.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../user/tabs/cases_tab.dart';

class NgoCasesTab extends StatelessWidget {
  final UserEntity user;
  const NgoCasesTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return CasesTab(user: user);
  }
}
