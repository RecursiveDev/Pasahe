import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ph_fare_calculator/src/core/di/injection.dart';
import 'package:ph_fare_calculator/src/models/fare_formula.dart';
import 'package:ph_fare_calculator/src/models/fare_result.dart';
import 'package:ph_fare_calculator/src/models/saved_route.dart';
import 'package:ph_fare_calculator/src/presentation/screens/main_screen.dart';
import 'package:ph_fare_calculator/src/presentation/screens/onboarding_screen.dart';
import 'package:ph_fare_calculator/src/presentation/widgets/app_logo_widget.dart';
import 'package:ph_fare_calculator/src/repositories/fare_repository.dart';
import 'package:ph_fare_calculator/src/services/connectivity/connectivity_service.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modern splash screen with Jeepney-inspired design and smooth animations.
/// Implements the UI/UX design specification with:
/// - Animated logo with scale and fade effects
/// - Gradient background using Philippine flag colors
/// - Modern loading indicator
/// - Accessibility support via Semantics widgets
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _loadingController;

  // Animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Logo animation: scale up and fade in, then fade out
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Text animation: fade in and slide up
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Loading indicator animation
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Start animations sequence
    _logoController.forward().then((_) {
      _textController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Dependency Injection
      try {
        await configureDependencies();
      } catch (e) {
        // In tests, dependencies might be mocked/pre-registered.
        debugPrint('DI config warning: $e');
      }

      // 2. Local Database (Hive)
      final appDocumentDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDir.path);

      // Wrap adapter registration in try-catch
      try {
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(FareFormulaAdapter());
        }
        if (!Hive.isAdapterRegistered(1)) {
          Hive.registerAdapter(SavedRouteAdapter());
        }
        if (!Hive.isAdapterRegistered(2)) {
          Hive.registerAdapter(FareResultAdapter());
        }
        if (!Hive.isAdapterRegistered(3)) {
          Hive.registerAdapter(IndicatorLevelAdapter());
        }
      } catch (e) {
        debugPrint('Hive adapter registration warning: $e');
      }

      // 3. Repository Initialization & Seeding
      final fareRepository = getIt<FareRepository>();
      await fareRepository.seedDefaults();

      // 3b. Initialize ConnectivityService
      // This is crucial to start listening to network changes early
      final connectivityService = getIt<ConnectivityService>();
      await connectivityService.initialize();

      // 4. Settings
      final settingsService = getIt<SettingsService>();
      await settingsService.getThemeMode();

      // 5. Check Onboarding
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedOnboarding =
          prefs.getBool('hasCompletedOnboarding') ?? false;

      // Minimum splash duration for animation completion
      await Future<void>.delayed(const Duration(milliseconds: 2500));

      if (mounted) {
        _navigateToNextScreen(hasCompletedOnboarding);
      }
    } catch (e, stackTrace) {
      debugPrint('Initialization error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        _showErrorScreen(e);
      }
    }
  }

  void _navigateToNextScreen(bool hasCompletedOnboarding) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            hasCompletedOnboarding
            ? const MainScreen()
            : const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showErrorScreen(Object error) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.1),
                    colorScheme.surface,
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Initialization Failed',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $error',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'PH Fare Calculator loading screen',
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.85),
                colorScheme.primary.withValues(alpha: 0.7),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Animated Logo
                _buildAnimatedLogo(),
                const SizedBox(height: 32),
                // Animated App Title
                _buildAnimatedTitle(),
                const SizedBox(height: 8),
                // Animated Tagline
                _buildAnimatedTagline(),
                const Spacer(flex: 2),
                // Loading Indicator
                _buildLoadingIndicator(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Opacity(opacity: _logoOpacity.value, child: child),
        );
      },
      child: const AppLogoWidget(size: AppLogoSize.large, showShadow: true),
    );
  }

  Widget _buildAnimatedTitle() {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'PH Fare Calculator',
      child: SlideTransition(
        position: _textSlide,
        child: FadeTransition(
          opacity: _textOpacity,
          child: Text(
            'PH Fare Calculator',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTagline() {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Know your fare before you ride',
      child: SlideTransition(
        position: _textSlide,
        child: FadeTransition(
          opacity: _textOpacity,
          child: Text(
            'Know your fare before you ride',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: colorScheme.onPrimary.withValues(alpha: 0.9),
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Loading application',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            child: AnimatedBuilder(
              animation: _loadingController,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: null,
                  backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.secondary,
                  ),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onPrimary.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
