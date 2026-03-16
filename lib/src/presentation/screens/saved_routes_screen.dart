import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pasahe/src/core/di/injection.dart';

import '../../models/saved_route.dart';
import '../../repositories/fare_repository.dart';
import '../widgets/fare_result_card.dart';

/// Screen displaying saved routes with modern UI/UX design.
/// Features swipe-to-delete, staggered animations, and card-based layout.
class SavedRoutesScreen extends StatefulWidget {
  final FareRepository? fareRepository;

  const SavedRoutesScreen({super.key, this.fareRepository});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen>
    with TickerProviderStateMixin {
  late final FareRepository _fareRepository;
  List<SavedRoute> _savedRoutes = [];
  bool _isLoading = true;

  // Animation controller for staggered list animation
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _fareRepository = widget.fareRepository ?? getIt<FareRepository>();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadSavedRoutes();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedRoutes() async {
    final routes = await _fareRepository.getSavedRoutes();
    if (mounted) {
      setState(() {
        _savedRoutes = routes;
        _isLoading = false;
      });
      // Start staggered animation
      _listAnimationController.forward(from: 0);
    }
  }

  Future<void> _deleteRoute(SavedRoute route) async {
    await _fareRepository.deleteRoute(route);
    _loadSavedRoutes();
  }

  Future<bool> _confirmDelete(SavedRoute route) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_outline, color: colorScheme.tertiary),
              const SizedBox(width: 12),
              const Text('Delete Route'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this saved route?',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.route, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${route.origin} → ${route.destination}',
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.tertiary,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  void _loadRouteToCalculator(SavedRoute route) {
    // Return the route to the main screen via Navigator
    Navigator.of(context).pop(route);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // Modern App Bar
            _buildModernAppBar(colorScheme, textTheme),
            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(colorScheme)
                  : _savedRoutes.isEmpty
                  ? _buildEmptyState(colorScheme, textTheme)
                  : _buildRoutesList(colorScheme, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Semantics(
            label: 'Go back',
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: colorScheme.onSurface,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Routes',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (_savedRoutes.isNotEmpty && !_isLoading)
                  Text(
                    '${_savedRoutes.length} route${_savedRoutes.length != 1 ? 's' : ''} saved',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading saved routes...',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 56,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Saved Routes Yet',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Calculate a fare and tap "Save Route" to quickly access your frequent trips.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Semantics(
              label: 'Calculate your first fare',
              button: true,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Calculate Fare'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesList(ColorScheme colorScheme, TextTheme textTheme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _savedRoutes.length,
      itemBuilder: (context, index) {
        final route = _savedRoutes[index];
        return _buildAnimatedRouteCard(route, index, colorScheme, textTheme);
      },
    );
  }

  Widget _buildAnimatedRouteCard(
    SavedRoute route,
    int index,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Calculate stagger delay based on index
    final delay = index * 0.1;
    final startTime = delay;
    final endTime = (delay + 0.5).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        final animationValue = Curves.easeOutCubic.transform(
          (((_listAnimationController.value - startTime) /
                  (endTime - startTime))
              .clamp(0.0, 1.0)),
        );

        return Opacity(
          opacity: animationValue,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animationValue)),
            child: child,
          ),
        );
      },
      child: _buildRouteCard(route, colorScheme, textTheme),
    );
  }

  Widget _buildRouteCard(
    SavedRoute route,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Semantics(
      label:
          'Saved route from ${route.origin} to ${route.destination}, saved on ${DateFormat.yMMMd().format(route.timestamp)}. ${route.fareResults.length} fare options. Swipe left to delete.',
      child: Dismissible(
        key: Key(route.timestamp.toIso8601String()),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDelete(route),
        onDismissed: (_) => _deleteRoute(route),
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.tertiary,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_outline, color: colorScheme.onError, size: 28),
              const SizedBox(height: 4),
              Text(
                'Delete',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onError,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: InkWell(
            onTap: () => _showRouteDetails(route, colorScheme, textTheme),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route indicator with origin and destination
                  _buildRouteIndicator(route, colorScheme, textTheme),
                  const SizedBox(height: 16),
                  // Fare count and date row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 14,
                              color: colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${route.fareResults.length} fare option${route.fareResults.length != 1 ? 's' : ''}',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          DateFormat.yMMMd().add_jm().format(route.timestamp),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Load route button
                  SizedBox(
                    width: double.infinity,
                    child: Semantics(
                      label: 'Load this route to calculator',
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: () => _loadRouteToCalculator(route),
                        icon: const Icon(Icons.upload_outlined, size: 18),
                        label: const Text('Load Route'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(color: colorScheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteIndicator(
    SavedRoute route,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Route indicator dots and line
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 2, height: 32, color: colorScheme.outlineVariant),
            Icon(Icons.location_on, size: 16, color: colorScheme.tertiary),
          ],
        ),
        const SizedBox(width: 12),
        // Origin and Destination text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Origin
              Text(
                'From',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                route.origin,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Destination
              Text(
                'To',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                route.destination,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRouteDetails(
    SavedRoute route,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Route Details',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildRouteIndicator(route, colorScheme, textTheme),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Fare results list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: route.fareResults.length,
                      itemBuilder: (context, index) {
                        final result = route.fareResults[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FareResultCard(
                            transportMode: result.transportMode,
                            fare: result.fare,
                            indicatorLevel: result.indicatorLevel,
                            passengerCount: result.passengerCount,
                            totalFare: result.totalFare,
                          ),
                        );
                      },
                    ),
                  ),
                  // Action buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        top: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            label: 'Delete this route',
                            button: true,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                final confirmed = await _confirmDelete(route);
                                if (confirmed) {
                                  _deleteRoute(route);
                                }
                              },
                              icon: Icon(
                                Icons.delete_outline,
                                color: colorScheme.tertiary,
                              ),
                              label: Text(
                                'Delete',
                                style: TextStyle(color: colorScheme.tertiary),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: colorScheme.tertiary),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Semantics(
                            label: 'Load this route to calculator',
                            button: true,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _loadRouteToCalculator(route);
                              },
                              icon: const Icon(Icons.upload_outlined),
                              label: const Text('Load Route'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
