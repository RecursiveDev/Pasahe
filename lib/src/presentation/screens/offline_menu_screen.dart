import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/transit_colors.dart';
import '../../models/map_region.dart';
import '../../services/offline/offline_map_service.dart';
import 'reference_screen.dart';
import 'region_download_screen.dart';
import 'saved_routes_screen.dart';

/// Menu item data model for the offline menu.
class _MenuItemData {
  final String title;
  final String description;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final Widget destination;
  final String? badge;

  const _MenuItemData({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.destination,
    this.badge,
  });
}

/// Offline menu screen with modern UI/UX design.
/// Provides access to saved routes, static reference data, and offline maps.
class OfflineMenuScreen extends StatefulWidget {
  const OfflineMenuScreen({super.key});

  @override
  State<OfflineMenuScreen> createState() => _OfflineMenuScreenState();
}

class _OfflineMenuScreenState extends State<OfflineMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late List<Animation<double>> _itemFadeAnimations;
  late List<Animation<Offset>> _itemSlideAnimations;

  StorageInfo? _storageInfo;

  /// Menu items configuration
  List<_MenuItemData> _getMenuItems(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return [
      _MenuItemData(
        title: 'Saved Routes',
        description:
            'View your saved fare estimates and quickly access previous calculations.',
        icon: Icons.bookmark_rounded,
        iconBackgroundColor: colorScheme.secondary.withValues(alpha: 0.15),
        iconColor: colorScheme.secondary,
        destination: const SavedRoutesScreen(),
      ),
      _MenuItemData(
        title: 'Download Maps',
        description:
            'Download map regions for offline use. View maps without internet.',
        icon: Icons.download_for_offline_rounded,
        iconBackgroundColor: colorScheme.primary.withValues(alpha: 0.15),
        iconColor: colorScheme.primary,
        destination: const RegionDownloadScreen(),
        badge: _storageInfo?.mapCacheFormatted,
      ),
      _MenuItemData(
        title: 'Fare Reference',
        description:
            'Browse fare matrices for trains, ferries, and discount information.',
        icon: Icons.table_chart_rounded,
        iconBackgroundColor: colorScheme.tertiary.withValues(alpha: 0.12),
        iconColor: colorScheme.tertiary,
        destination: const ReferenceScreen(),
      ),
      _MenuItemData(
        title: 'Discount Guide',
        description:
            'Learn about available discounts for students, seniors, and PWD.',
        icon: Icons.percent_rounded,
        iconBackgroundColor:
            Theme.of(context).extension<TransitColors>()?.successContainer ??
            colorScheme.primaryContainer,
        iconColor:
            Theme.of(context).extension<TransitColors>()?.successColor ??
            colorScheme.primary,
        destination: const ReferenceScreen(initialTabIndex: 3),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadStorageInfo();
  }

  void _initAnimations() {
    // Header animation controller
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
    );

    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerController,
            curve: Curves.easeOutCubic,
          ),
        );

    // List animation controller
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Create staggered animations for each menu item
    _itemFadeAnimations = [];
    _itemSlideAnimations = [];

    for (int i = 0; i < 4; i++) {
      final startInterval = 0.15 + (i * 0.15);
      final endInterval = (startInterval + 0.35).clamp(0.0, 1.0);

      _itemFadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _listController,
            curve: Interval(startInterval, endInterval, curve: Curves.easeOut),
          ),
        ),
      );

      _itemSlideAnimations.add(
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _listController,
            curve: Interval(
              startInterval,
              endInterval,
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
      );
    }

    // Start animations
    _headerController.forward();
    _listController.forward();
  }

  Future<void> _loadStorageInfo() async {
    try {
      final offlineMapService = getIt<OfflineMapService>();
      await offlineMapService.initialize();
      final info = await offlineMapService.getStorageUsage();
      if (mounted) {
        setState(() => _storageInfo = info);
      }
    } catch (_) {
      // Ignore errors - storage info is optional
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final menuItems = _getMenuItems(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            leading: Semantics(
              label: 'Go back',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: FadeTransition(
                opacity: _headerFadeAnimation,
                child: SlideTransition(
                  position: _headerSlideAnimation,
                  child: _buildHeroSection(context),
                ),
              ),
            ),
          ),

          // Menu Items
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index >= menuItems.length) return null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FadeTransition(
                    opacity: _itemFadeAnimations[index],
                    child: SlideTransition(
                      position: _itemSlideAnimations[index],
                      child: _buildMenuCard(context, menuItems[index]),
                    ),
                  ),
                );
              }, childCount: menuItems.length),
            ),
          ),

          // Bottom info section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: _buildInfoSection(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the hero section with gradient background.
  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.85),
            colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and title row
              Row(
                children: [
                  // Offline icon
                  Semantics(
                    label: 'Offline mode indicator',
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.offline_bolt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      'Offline Reference',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'Access fare information and maps without internet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a menu card with icon, title, description, and optional badge.
  Widget _buildMenuCard(BuildContext context, _MenuItemData item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: '${item.title}. ${item.description}',
      button: true,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToScreen(context, item.destination),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: item.iconBackgroundColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, size: 28, color: item.iconColor),
                ),
                const SizedBox(width: 16),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.badge!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Chevron icon
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the bottom info section.
  Widget _buildInfoSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Data is cached locally for offline access. Refresh when online for updates.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigates to the specified screen with a slide transition.
  void _navigateToScreen(BuildContext context, Widget destination) {
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
