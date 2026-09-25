import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/network/dio_client.dart';
import 'core/services/socket_service.dart';
import 'core/services/terms_consent.dart';
import 'core/theme/app_theme.dart';
import 'injection_container.dart';
import 'presentation/blocs/app/app_blocs.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/services/services_bloc.dart';
import 'presentation/pages/legal/terms_of_use_page.dart';
import 'presentation/pages/login/login_screen.dart';
import 'presentation/pages/onboarding/onboarding_screen.dart';
import 'presentation/pages/splash/splash_screen.dart';
import 'presentation/pages/user/user_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  setupInjection();

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool(AppConstants.onboardingDoneKey) ?? false;
  await TermsConsent.load();

  runApp(NgoPartnersApp(onboardingDone: onboardingDone));
}

class NgoPartnersApp extends StatelessWidget {
  final bool onboardingDone;
  const NgoPartnersApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(AuthCheckStatus()),
        ),
        BlocProvider<ServicesBloc>(create: (_) => sl<ServicesBloc>()),
        BlocProvider<CollabBloc>(create: (_) => sl<CollabBloc>()),
        BlocProvider<NotifBloc>(create: (_) => sl<NotifBloc>()),
        BlocProvider<TicketsBloc>(create: (_) => sl<TicketsBloc>()),
      ],
      child: MaterialApp(
        title: 'NGO Partners',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: _AppNavigator(onboardingDone: onboardingDone),
      ),
    );
  }
}

class _AppNavigator extends StatefulWidget {
  final bool onboardingDone;
  const _AppNavigator({required this.onboardingDone});

  @override
  State<_AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<_AppNavigator> {
  bool _splashDone = false;
  late bool _onboardingDone;

  @override
  void initState() {
    super.initState();
    _onboardingDone = widget.onboardingDone;
    // When the token can't be refreshed, force the user back to login.
    sl<DioClient>().onSessionExpired = () {
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthLogoutRequested());
    };
  }

  @override
  void dispose() {
    sl<DioClient>().stopRefreshTimer();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingDoneKey, true);
    setState(() => _onboardingDone = true);
  }

  Future<void> _connectSocket() async {
    final token = await sl<DioClient>().getAccessToken();
    if (token != null) {
      sl<SocketService>().connect(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(
        onComplete: () => setState(() => _splashDone = true),
      );
    }
    if (!_onboardingDone) {
      return OnboardingScreen(
        onFinish: _completeOnboarding,
      );
    }
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (state is AuthAuthenticated) {
          _connectSocket();
          sl<DioClient>().startRefreshTimer();
        } else if (state is AuthUnauthenticated) {
          sl<SocketService>().disconnect();
          sl<DioClient>().stopRefreshTimer();
        }
      },
      builder: (ctx, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9FAFB),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            ),
          );
        }
        if (state is AuthAuthenticated) {
          // Sessions restored from a build without the terms screen have
          // never agreed; they must before reaching the app.
          if (!TermsConsent.accepted) {
            return TermsOfUsePage.gate(
              onAgree: () async {
                await TermsConsent.accept();
                if (mounted) setState(() {});
              },
              onDecline: () => ctx.read<AuthBloc>().add(AuthLogoutRequested()),
            );
          }
          return UserDashboard(user: state.user);
        }
        return const LoginScreen();
      },
    );
  }
}
