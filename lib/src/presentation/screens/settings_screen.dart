import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../l10n/app_localizations.dart';
import '../../models/discount_type.dart';
import '../../models/fare_formula.dart';
import '../../models/transport_mode.dart';
import '../../repositories/fare_repository.dart';
import '../../services/offline/offline_map_service.dart';
import '../../services/offline/offline_mode_service.dart';
import '../../services/settings_service.dart';
import '../widgets/app_logo_widget.dart';


/// Modern settings screen with grouped sections and Material 3 styling.
/// Follows 8dp grid system and uses theme colors from AppTheme.
class SettingsScreen extends StatefulWidget {
  final SettingsService? settingsService;
  final OfflineModeService? offlineModeService;
  final OfflineMapService? offlineMapService;

  const SettingsScreen({
    super.key,
    this.settingsService,
    this.offlineModeService,
    this.offlineMapService,
  });


  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final SettingsService _settingsService;
  late final OfflineModeService _offlineModeService;
  late final OfflineMapService _offlineMapService;
  late final FareRepository _fareRepository;
  late final AnimationController _animationController;

  bool _isProvincialModeEnabled = false;
  String _themeMode = 'system';
  TrafficFactor _trafficFactor = TrafficFactor.medium;
  DiscountType _discountType = DiscountType.standard;
  Locale _currentLocale = const Locale('en');
  bool _isLoading = true;

  bool _offlineModeEnabled = false;
  bool _autoCacheEnabled = true;
  bool _autoCacheWifiOnly = true;
  String _cacheSizeFormatted = '0.0 MB';


  Set<String> _hiddenTransportModes = {};
  bool _hasSetTransportModePreferences = false;
  Map<String, List<FareFormula>> _groupedFormulas = {};

  // App version info (loaded dynamically from pubspec.yaml)
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _settingsService = widget.settingsService ?? getIt<SettingsService>();
    _offlineModeService = widget.offlineModeService ?? getIt<OfflineModeService>();
    _offlineMapService = widget.offlineMapService ?? getIt<OfflineMapService>();
    _fareRepository = getIt<FareRepository>();


    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offlineModeService.addListener(_onOfflineModeChanged);
    _loadSettings();
  }

  void _onOfflineModeChanged() {
    if (mounted) {
      _updateOfflineState();
    }
  }

  Future<void> _updateOfflineState() async {
    final storageInfo = await _offlineMapService.getStorageUsage();
    if (mounted) {
      setState(() {
        _offlineModeEnabled = _offlineModeService.offlineModeEnabled;
        _autoCacheEnabled = _offlineModeService.autoCacheEnabled;
        _autoCacheWifiOnly = _offlineModeService.autoCacheWifiOnly;
        _cacheSizeFormatted = storageInfo.mapCacheFormatted;
      });
    }
  }

  @override
  void dispose() {
    _offlineModeService.removeListener(_onOfflineModeChanged);
    _animationController.dispose();
    super.dispose();
  }


  Future<void> _loadSettings() async {
    final provincialMode = await _settingsService.getProvincialMode();
    final trafficFactor = await _settingsService.getTrafficFactor();
    final themeMode = await _settingsService.getThemeMode();
    final discountType = await _settingsService.getUserDiscountType();
    final hiddenModes = await _settingsService.getHiddenTransportModes();
    final hasSetModePrefs = await _settingsService
        .hasSetTransportModePreferences();
    final locale = await _settingsService.getLocale();
    final formulas = await _fareRepository.getAllFormulas();

    final offlineModeEnabled = _offlineModeService.offlineModeEnabled;
    final autoCacheEnabled = _offlineModeService.autoCacheEnabled;
    final autoCacheWifiOnly = _offlineModeService.autoCacheWifiOnly;
    final storageInfo = await _offlineMapService.getStorageUsage();


    // Load package info with fallback for test environment
    String version = '2.0.0';
    String buildNumber = '2';
    try {
      final packageInfo = await PackageInfo.fromPlatform().timeout(
        const Duration(seconds: 1),
        onTimeout: () => throw TimeoutException('Platform info timeout'),
      );
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    } catch (_) {
      // Use fallback values if platform info is unavailable (e.g., in tests)
    }

    // Group formulas by mode
    final grouped = <String, List<FareFormula>>{};
    for (final formula in formulas) {
      if (!grouped.containsKey(formula.mode)) {
        grouped[formula.mode] = [];
      }
      grouped[formula.mode]!.add(formula);
    }

    if (mounted) {
      setState(() {
        _isProvincialModeEnabled = provincialMode;
        _themeMode = themeMode;
        _trafficFactor = trafficFactor;
        _discountType = discountType;
        _currentLocale = locale;
        _hiddenTransportModes = hiddenModes;
        _hasSetTransportModePreferences = hasSetModePrefs;
        _groupedFormulas = grouped;
        _appVersion = version;
        _buildNumber = buildNumber;
        _offlineModeEnabled = offlineModeEnabled;
        _autoCacheEnabled = autoCacheEnabled;
        _autoCacheWifiOnly = autoCacheWifiOnly;
        _cacheSizeFormatted = storageInfo.mapCacheFormatted;
        _isLoading = false;
      });

      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(
            AppLocalizations.of(context)!.settingsTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : FadeTransition(
              opacity: _animationController,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  // Preferences Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.tune_rounded,
                    title: 'Preferences',
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    context,
                    children: [
                      _buildSwitchTile(
                        context,
                        title: AppLocalizations.of(
                          context,
                        )!.provincialModeTitle,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.provincialModeSubtitle,
                        value: _isProvincialModeEnabled,
                        icon: Icons.location_city_rounded,
                        onChanged: (value) async {
                          setState(() => _isProvincialModeEnabled = value);
                          await _settingsService.setProvincialMode(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Appearance Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.palette_rounded,
                    title: 'Appearance',
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    context,
                    children: [
                      _buildThemeModeTile(context),
                      const Divider(height: 1, indent: 56),
                      _buildLanguageTile(context),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Traffic Factor Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.traffic_rounded,
                    title: AppLocalizations.of(context)!.trafficFactorTitle,
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    context,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          AppLocalizations.of(context)!.trafficFactorSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      _buildTrafficFactorTile(
                        context,
                        title: AppLocalizations.of(context)!.trafficLow,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.trafficLowSubtitle,
                        value: TrafficFactor.low,
                        icon: Icons.speed_rounded,
                        iconColor: _getTrafficIconColor(
                          context,
                          TrafficFactor.low,
                        ),
                      ),
                      _buildTrafficFactorTile(
                        context,
                        title: AppLocalizations.of(context)!.trafficMedium,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.trafficMediumSubtitle,
                        value: TrafficFactor.medium,
                        icon: Icons.speed_rounded,
                        iconColor: _getTrafficIconColor(
                          context,
                          TrafficFactor.medium,
                        ),
                      ),
                      _buildTrafficFactorTile(
                        context,
                        title: AppLocalizations.of(context)!.trafficHigh,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.trafficHighSubtitle,
                        value: TrafficFactor.high,
                        icon: Icons.speed_rounded,
                        iconColor: _getTrafficIconColor(
                          context,
                          TrafficFactor.high,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Passenger Type Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.person_rounded,
                    title: 'Passenger Type',
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    context,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          'Select your passenger type to apply eligible discounts (20% off for Student, Senior, PWD)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      _buildDiscountTypeTile(
                        context,
                        title: DiscountType.standard.displayName,
                        subtitle: 'No discount',
                        value: DiscountType.standard,
                        icon: Icons.person_outline_rounded,
                      ),
                      _buildDiscountTypeTile(
                        context,
                        title: DiscountType.discounted.displayName,
                        subtitle: '20% discount (RA 11314, RA 9994, RA 7277)',
                        value: DiscountType.discounted,
                        icon: Icons.discount_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Transport Modes Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.directions_bus_rounded,
                    title: 'Transport Modes',
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    context,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          'Select which transport modes to include in fare calculations',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (_groupedFormulas.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No transport modes available',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      else
                        ..._buildCategorizedTransportModes(context),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Offline Mode Section
                  _buildSectionHeader(
                    context,
                    icon: Icons.offline_bolt_rounded,
                    title: 'Offline Mode',
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    context,
                    children: [
                      _buildSwitchTile(
                        context,
                        title: 'Enable Offline Mode',
                        subtitle: 'Use cached data when no internet connection',
                        value: _offlineModeEnabled,
                        icon: Icons.offline_pin_rounded,
                         onChanged: (value) async {
                          await _offlineModeService.setAutoCacheEnabled(value);
                        },
                      ),
                      if (_autoCacheEnabled) ...[
                        const Divider(height: 1, indent: 56),
                        _buildSwitchTile(
                          context,
                          title: 'WiFi Only',
                          subtitle: 'Only auto-download maps when on WiFi',
                          value: _autoCacheWifiOnly,
                          icon: Icons.wifi_rounded,
                          onChanged: (value) async {
                            await _offlineModeService.setAutoCacheWifiOnly(
                              value,
                            );
                          },
                        ),
                      ],
                      const Divider(height: 1, indent: 56),
                      _buildCacheManagementTile(context),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Accuracy Indicators',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildAccuracyExplanation(
                              context,
                              icon: Icons.wifi_rounded,
                              color: Colors.green,
                              label: 'Precise (Online)',
                              description:
                                  'Based on real-time road data and current conditions.',
                            ),
                            const SizedBox(height: 8),
                            _buildAccuracyExplanation(
                              context,
                              icon: Icons.cached_rounded,
                              color: Colors.orange,
                              label: 'Estimated (Cached)',
                              description:
                                  'Based on previously cached route data.',
                            ),
                            const SizedBox(height: 8),
                            _buildAccuracyExplanation(
                              context,
                              icon: Icons.offline_bolt_rounded,
                              color: Colors.blue,
                              label: 'Approximate (Offline)',
                              description:
                                  'Based on straight-line distance calculations.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About Section
                  _buildSectionHeader(

                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                  ),
                  const SizedBox(height: 8),
                  _buildSettingsCard(
                    context,
                    children: [
                      // App logo and name
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const AppLogoWidget(
                              size: AppLogoSize.medium,
                              showShadow: false,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PH Fare Calculator',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Version $_appVersion (Build $_buildNumber)',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      const Divider(height: 1, indent: 56),
                      _buildAboutTile(
                        context,
                        title: 'Open Source Licenses',
                        subtitle: 'View third-party licenses',
                        icon: Icons.description_rounded,
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: 'PH Fare Calculator',
                          applicationVersion: '$_appVersion+$_buildNumber',
                        ),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildAboutTile(
                        context,
                        title: AppLocalizations.of(context)!.sourceCodeTitle,
                        subtitle: AppLocalizations.of(
                          context,
                        )!.sourceCodeSubtitle,
                        icon: Icons.code_rounded,
                        onTap: () => _launchRepositoryUrl(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  /// Builds a section header with icon and title.
  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a card container for settings items.
  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  /// Gets theme-aware traffic icon color based on traffic factor.
  Color _getTrafficIconColor(BuildContext context, TrafficFactor factor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (factor) {
      case TrafficFactor.low:
        // Green - darker in light mode, lighter pastel in dark mode
        return isDark ? const Color(0xFFA8D5AA) : const Color(0xFF2E7D32);
      case TrafficFactor.medium:
        // Orange - darker in light mode, lighter pastel in dark mode
        return isDark ? const Color(0xFFE8CFA8) : const Color(0xFFE65100);
      case TrafficFactor.high:
        // Red - darker in light mode, lighter pastel in dark mode
        return isDark ? const Color(0xFFE8AEAB) : const Color(0xFFC62828);
    }
  }

  /// Builds a switch tile with icon.
  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      toggled: value,
      child: SwitchListTile(
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        value: value,
        onChanged: onChanged,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 24),
        ),
        activeTrackColor: colorScheme.primary,
        activeThumbColor: colorScheme.onPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  /// Builds a theme mode selection tile with segmented button.
  Widget _buildThemeModeTile(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    String getThemeModeLabel(String mode) {
      switch (mode) {
        case 'light':
          return l10n.themeModeLight;
        case 'dark':
          return l10n.themeModeDark;
        case 'system':
        default:
          return l10n.themeModeSystem;
      }
    }

    return Semantics(
      label: l10n.themeModeTitle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.brightness_6_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.themeModeTitle,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.themeModeSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment<String>(
                    value: 'system',
                    label: Text(getThemeModeLabel('system')),
                    icon: const Icon(Icons.phone_android_rounded, size: 18),
                  ),
                  ButtonSegment<String>(
                    value: 'light',
                    label: Text(getThemeModeLabel('light')),
                    icon: const Icon(Icons.light_mode_rounded, size: 18),
                  ),
                  ButtonSegment<String>(
                    value: 'dark',
                    label: Text(getThemeModeLabel('dark')),
                    icon: const Icon(Icons.dark_mode_rounded, size: 18),
                  ),
                ],
                selected: {_themeMode},
                onSelectionChanged: (Set<String> newSelection) async {
                  final newMode = newSelection.first;
                  setState(() => _themeMode = newMode);
                  await _settingsService.setThemeMode(newMode);
                },
                style: ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a language selection tile.
  Widget _buildLanguageTile(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final languageName = _currentLocale.languageCode == 'tl'
        ? 'Filipino'
        : 'English';

    return Semantics(
      button: true,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.language_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        title: Text(
          'Language',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          languageName,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: () => _showLanguageBottomSheet(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  /// Shows language selection bottom sheet.
  void _showLanguageBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Language',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildLanguageOption(
              context,
              locale: const Locale('en'),
              name: 'English',
              flag: '🇺🇸',
            ),
            _buildLanguageOption(
              context,
              locale: const Locale('tl'),
              name: 'Filipino',
              flag: '🇵🇭',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Builds a language option in bottom sheet.
  Widget _buildLanguageOption(
    BuildContext context, {
    required Locale locale,
    required String name,
    required String flag,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _currentLocale.languageCode == locale.languageCode;

    return Semantics(
      selected: isSelected,
      child: ListTile(
        leading: Text(flag, style: const TextStyle(fontSize: 28)),
        title: Text(
          name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
            : null,
        onTap: () async {
          final navigator = Navigator.of(context);
          await _settingsService.setLocale(locale);
          if (mounted) {
            setState(() => _currentLocale = locale);
            navigator.pop();
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Builds a traffic factor radio tile.
  Widget _buildTrafficFactorTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required TrafficFactor value,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      selected: _trafficFactor == value,
      // Using deprecated groupValue/onChanged for test compatibility
      // ignore: deprecated_member_use
      child: RadioListTile<TrafficFactor>(
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        value: value,
        // ignore: deprecated_member_use
        groupValue: _trafficFactor,
        // ignore: deprecated_member_use
        onChanged: (TrafficFactor? newValue) async {
          if (newValue != null) {
            setState(() => _trafficFactor = newValue);
            await _settingsService.setTrafficFactor(newValue);
          }
        },
        secondary: Icon(icon, color: iconColor, size: 24),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
    );
  }

  /// Builds a discount type radio tile.
  Widget _buildDiscountTypeTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required DiscountType value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      selected: _discountType == value,
      // Using deprecated groupValue/onChanged for test compatibility
      // ignore: deprecated_member_use
      child: RadioListTile<DiscountType>(
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        value: value,
        // ignore: deprecated_member_use
        groupValue: _discountType,
        // ignore: deprecated_member_use
        onChanged: (DiscountType? newValue) async {
          if (newValue != null) {
            setState(() => _discountType = newValue);
            await _settingsService.setUserDiscountType(newValue);
          }
        },
        secondary: Icon(icon, color: colorScheme.primary, size: 24),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
    );
  }

  /// Builds categorized transport mode toggles.
  List<Widget> _buildCategorizedTransportModes(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final widgets = <Widget>[];

    // Group modes by category
    final categorizedModes = <String, List<String>>{
      'Road': [],
      'Rail': [],
      'Water': [],
    };

    for (final modeStr in _groupedFormulas.keys) {
      try {
        final mode = TransportMode.fromString(modeStr);
        final category = mode.category;

        // Capitalize category for display
        final categoryKey = category[0].toUpperCase() + category.substring(1);

        if (categorizedModes.containsKey(categoryKey)) {
          categorizedModes[categoryKey]!.add(modeStr);
        }
      } catch (e) {
        // Skip invalid modes
        continue;
      }
    }

    // Build UI for each category
    for (final category in ['Road', 'Rail', 'Water']) {
      final modesInCategory = categorizedModes[category] ?? [];
      if (modesInCategory.isEmpty) continue;

      // Category Header with colored icon
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(
                _getIconForCategory(category),
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      );

      // Transport Mode Cards for this category
      for (final modeStr in modesInCategory) {
        try {
          final mode = TransportMode.fromString(modeStr);
          final formulas = _groupedFormulas[modeStr] ?? [];

          widgets.add(_buildTransportModeSection(context, mode, formulas));
        } catch (e) {
          continue;
        }
      }
    }

    return widgets;
  }

  /// Builds a transport mode section with toggles.
  Widget _buildTransportModeSection(
    BuildContext context,
    TransportMode mode,
    List<FareFormula> formulas,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      container: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Header with Icon and Name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getIconForMode(mode),
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.displayName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mode.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (formulas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),

              // Subtype Toggles using SwitchListTile for test compatibility
              ...formulas.map((formula) {
                final modeSubTypeKey = '${formula.mode}::${formula.subType}';
                // For new users who haven't set any preferences, all modes are hidden (disabled) by default
                // For users who have set preferences, check if mode is in the hidden set
                final isHidden =
                    !_hasSetTransportModePreferences ||
                    _hiddenTransportModes.contains(modeSubTypeKey);

                return SwitchListTile(
                  title: Text(
                    '  ${formula.subType}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: formula.notes != null && formula.notes!.isNotEmpty
                      ? Text(
                          '  ${formula.notes}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  value: !isHidden,
                  onChanged: (bool value) async {
                    final shouldHide = !value;
                    await _settingsService.toggleTransportMode(
                      modeSubTypeKey,
                      shouldHide,
                    );

                    setState(() {
                      // Mark that user has now set transport mode preferences
                      _hasSetTransportModePreferences = true;
                      if (shouldHide) {
                        _hiddenTransportModes.add(modeSubTypeKey);
                      } else {
                        _hiddenTransportModes.remove(modeSubTypeKey);
                      }
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeTrackColor: colorScheme.primary,
                  activeThumbColor: colorScheme.onPrimary,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds an about tile.
  Widget _buildAboutTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      button: onTap != null,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 24),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: onTap != null
            ? Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              )
            : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  /// Launches the GitHub repository URL in an external browser.
  Future<void> _launchRepositoryUrl() async {
    final uri = Uri.parse(AppConstants.repositoryUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Builds a tile for map cache management.
  Widget _buildCacheManagementTile(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.storage_rounded,
          color: colorScheme.onPrimaryContainer,
          size: 24,
        ),
      ),
      title: const Text('Map Cache Size'),
      subtitle: Text(_cacheSizeFormatted),
      trailing: TextButton(
        onPressed: _showClearCacheDialog,
        child: const Text('Clear'),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Future<void> _showClearCacheDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Map Cache?'),
        content: const Text(
          'This will delete all automatically cached map tiles. Downloaded regions will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _offlineMapService.clearAllTiles();
      await _updateOfflineState();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Map cache cleared')),
        );
      }
    }
  }

  IconData _getIconForCategory(String category) {

    switch (category.toLowerCase()) {
      case 'road':
        return Icons.directions_car_rounded;
      case 'rail':
        return Icons.train_rounded;
      case 'water':
        return Icons.directions_boat_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  IconData _getIconForMode(TransportMode mode) {
    switch (mode) {
      case TransportMode.jeepney:
        return Icons.directions_bus_rounded;
      case TransportMode.bus:
        return Icons.airport_shuttle_rounded;
      case TransportMode.taxi:
        return Icons.local_taxi_rounded;
      case TransportMode.train:
        return Icons.train_rounded;
      case TransportMode.ferry:
        return Icons.directions_boat_rounded;
      case TransportMode.tricycle:
        return Icons.pedal_bike_rounded;
      case TransportMode.uvExpress:
        return Icons.local_shipping_rounded;
      case TransportMode.van:
        return Icons.airport_shuttle_rounded;
      case TransportMode.motorcycle:
        return Icons.two_wheeler_rounded;
      case TransportMode.edsaCarousel:
        return Icons.directions_bus_filled_rounded;
      case TransportMode.pedicab:
        return Icons.directions_bike_rounded;
      case TransportMode.kuliglig:
        return Icons.agriculture_rounded;
    }
  }

  /// Builds an accuracy explanation row.
  Widget _buildAccuracyExplanation(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

