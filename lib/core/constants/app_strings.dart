class AppStrings {
  AppStrings._();

  static const String appName = 'NGO Partners';
  static const String tagline = 'FAST. SECURE. PROFESSIONAL.';
  static const String brandTagline = 'FAST. EASY NGO REGISTRATION';

  // Onboarding
  static const List<Map<String, String>> onboardingSlides = [
    {
      'icon': '🏛️',
      'title': 'Register & Grow Your NGO Seamlessly',
      'sub':
          'Streamlined digital registration, government approvals, and compliance management — all in one platform.',
    },
    {
      'icon': '🚀',
      'title': 'Business Setup Made Easy',
      'sub':
          'LLP, Startup India, Pvt Ltd, GST — fast filing with verified legal experts and secure documents.',
    },
    {
      'icon': '🤝',
      'title': 'Collaborate. Connect. Create Impact.',
      'sub':
          'Join a thriving ecosystem of NGOs, funding partners, and CSR companies driving real change.',
    },
  ];

  // Login
  static const String welcomeBack = 'Welcome Back';
  static const String selectRole = 'SELECT YOUR ROLE';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String loginButton = 'Login →';
  static const String continueWithGoogle = 'Continue with Google';
  static const String demoCredentials =
      'Demo · user@ngo.com / user123 · ngo@ngo.com / ngo123';

  // Navigation
  static const String home = 'Home';
  static const String services = 'Services';
  static const String myCases = 'My Cases';
  static const String collaborate = 'Collaborate';
  static const String profile = 'Profile';
  static const String notifications = 'Notifications';
  static const String support = 'Support';

  // Roles
  static const String roleUser = 'User';
  static const String roleNGO = 'NGO';

  // Status
  static const String statusFiling = 'Filing in Progress';
  static const String statusReview = 'Under Review';
  static const String statusSubmitted = 'Submitted';
  static const String statusApproved = 'Approved';
  static const String statusPending = 'Pending';
  static const String statusRejected = 'Rejected';
  static const String statusResubmit = 'Resubmit Required';
}
