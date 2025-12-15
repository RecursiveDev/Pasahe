import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'package:ph_fare_calculator/src/core/di/injection.dart';
import 'package:ph_fare_calculator/src/presentation/widgets/app_logo_widget.dart';
import 'package:ph_fare_calculator/src/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ph_fare_calculator/src/presentation/screens/main_screen.dart';

/// Modern onboarding screen with Jeepney-inspired design.
/// Implements the UI/UX design specification with:
/// - PageView with animated dots indicator
/// - Smooth page transitions with slide and fade animations
/// - Philippine-themed illustrations and colors
/// - Language selection on the final slide
/// - Skip and Get Started navigation
/// - Accessibility support via Semantics widgets
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // Page controller
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Animation controllers
  late final AnimationController _contentAnimationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  // Total pages count
  static const int _totalPages = 3;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _contentAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentAnimationController,
            curve: Curves.easeOut,
          ),
        );

    // Start initial animation
    _contentAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // Restart content animation on page change
    _contentAnimationController.reset();
    _contentAnimationController.forward();
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      label: 'Onboarding screen',
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Skip button row
                _buildSkipButton(l10n),
                // Main content - PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildKnowYourFarePage(l10n, theme),
                      _buildWorkOfflinePage(l10n, theme),
                      _buildLanguageSelectionPage(l10n, theme),
                    ],
                  ),
                ),
                // Page indicator dots
                _buildPageIndicator(),
                const SizedBox(height: 24),
                // Bottom navigation buttons
                _buildBottomButtons(l10n, theme),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Semantics(
            label: 'Skip onboarding',
            button: true,
            child: TextButton(
              onPressed: _skipOnboarding,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                l10n.skipButtonLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnowYourFarePage(AppLocalizations l10n, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Semantics(
      label: 'Know Your Fare - Calculate fares for different transport',
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Use AppLogoWidget for visual consistency with splash screen
                const AppLogoWidget(size: AppLogoSize.large, showShadow: true),
                const SizedBox(height: 48),
                // Title
                Text(
                  l10n.welcomeTitle,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  l10n.onboardingKnowFareDescription,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkOfflinePage(AppLocalizations l10n, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return _buildOnboardingPage(
      icon: Icons.cloud_download_rounded,
      iconColor: colorScheme.secondary,
      iconBackgroundColor: colorScheme.secondaryContainer,
      title: l10n.onboardingWorkOfflineTitle,
      description: l10n.onboardingWorkOfflineDescription,
      theme: theme,
      semanticLabel: 'Work Offline - Access fare data without internet',
    );
  }

  Widget _buildLanguageSelectionPage(AppLocalizations l10n, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Language icon
              Semantics(
                label: 'Language selection icon',
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.translate_rounded,
                    size: 48,
                    color: colorScheme.tertiary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                l10n.onboardingLanguageTitle,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                l10n.selectLanguage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Language selection cards
              _buildLanguageCards(theme),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCards(ThemeData theme) {
    return ValueListenableBuilder<Locale>(
      valueListenable: SettingsService.localeNotifier,
      builder: (context, currentLocale, child) {
        return Column(
          children: [
            // English Card
            _buildLanguageCard(
              language: 'English',
              languageCode: 'en',
              isSelected: currentLocale.languageCode == 'en',
              theme: theme,
              onTap: () {
                getIt<SettingsService>().setLocale(const Locale('en'));
              },
            ),
            const SizedBox(height: 16),
            // Tagalog Card
            _buildLanguageCard(
              language: 'Tagalog',
              languageCode: 'tl',
              isSelected: currentLocale.languageCode == 'tl',
              theme: theme,
              onTap: () {
                getIt<SettingsService>().setLocale(const Locale('tl'));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageCard({
    required String language,
    required String languageCode,
    required bool isSelected,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    final colorScheme = theme.colorScheme;
    return Semantics(
      label:
          'Select $language language${isSelected ? ", currently selected" : ""}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Language flag/icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    languageCode == 'en' ? '🇺🇸' : '🇵🇭',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Language name
              Expanded(
                child: Text(
                  language,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              // Checkmark
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: colorScheme.onPrimary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage({
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    required String title,
    required String description,
    required ThemeData theme,
    required String semanticLabel,
  }) {
    final colorScheme = theme.colorScheme;
    return Semantics(
      label: semanticLabel,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration container
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 64, color: iconColor),
                ),
                const SizedBox(height: 48),
                // Title
                Text(
                  title,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Semantics(
      label: 'Page ${_currentPage + 1} of $_totalPages',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages, (index) => _buildDot(index)),
      ),
    );
  }

  Widget _buildDot(int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primary
            : colorScheme.primary.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildBottomButtons(AppLocalizations l10n, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isLastPage = _currentPage == _totalPages - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Primary action button
          Semantics(
            label: isLastPage
                ? 'Complete onboarding and start using the app'
                : 'Go to next onboarding step',
            button: true,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToNextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(
                  isLastPage ? l10n.getStartedButton : l10n.nextButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Disclaimer (only on last page)
          if (isLastPage)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                l10n.disclaimer,
                style: TextStyle(
                  color: colorScheme.outline,
                  fontSize: 12,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
