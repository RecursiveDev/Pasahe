import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../src/models/fare_formula.dart';
import '../../../src/models/static_fare.dart';

/// A modern reference screen with tab-based navigation for fare information.
/// Displays Road, Train, Ferry fares and Discount information with search functionality.
class ReferenceScreen extends StatefulWidget {
  const ReferenceScreen({super.key});

  @override
  State<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends State<ReferenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<FareFormula> _roadFormulas = [];
  Map<String, List<StaticFare>> _trainMatrix = {};
  List<StaticFare> _ferryRoutes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadReferenceData();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      // Clear search when changing tabs for better UX
      setState(() {
        _searchQuery = '';
        _searchController.clear();
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceData() async {
    try {
      // Load road formulas
      final formulasJson = await rootBundle.loadString(
        'assets/data/fare_formulas.json',
      );
      final formulasData = json.decode(formulasJson);
      _roadFormulas = (formulasData['road'] as List)
          .map((json) => FareFormula.fromJson(json))
          .toList();

      // Load train matrix
      final trainJson = await rootBundle.loadString(
        'assets/data/train_matrix.json',
      );
      final trainData = json.decode(trainJson) as Map<String, dynamic>;
      _trainMatrix = trainData.map((key, value) {
        final routes = (value as List)
            .map((json) => StaticFare.fromJson(json))
            .toList();
        return MapEntry(key, routes);
      });

      // Load ferry routes
      final ferryJson = await rootBundle.loadString(
        'assets/data/ferry_matrix.json',
      );
      final ferryData = json.decode(ferryJson);
      _ferryRoutes = (ferryData['routes'] as List)
          .map((json) => StaticFare.fromJson(json))
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load reference data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: const Text('Fare Reference Guide'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Semantics(
                label: 'Search fare information',
                textField: true,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search routes, stations, or fares...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                            tooltip: 'Clear search',
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: theme.textTheme.labelLarge,
                splashBorderRadius: BorderRadius.circular(12),
                tabs: [
                  _buildTab(Icons.directions_bus_rounded, 'Road'),
                  _buildTab(Icons.train_rounded, 'Train'),
                  _buildTab(Icons.directions_boat_rounded, 'Ferry'),
                  _buildTab(Icons.info_outline_rounded, 'Discount Guide'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(colorScheme)
                  : _error != null
                  ? _buildErrorState(colorScheme)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _RoadTransportTab(
                          formulas: _roadFormulas,
                          searchQuery: _searchQuery,
                        ),
                        _TrainTab(
                          trainMatrix: _trainMatrix,
                          searchQuery: _searchQuery,
                        ),
                        _FerryTab(
                          ferryRoutes: _ferryRoutes,
                          searchQuery: _searchQuery,
                        ),
                        _DiscountInfoTab(searchQuery: _searchQuery),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Semantics(
        label: '$label tab',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
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
            'Loading fare data...',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadReferenceData();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Road Transport Tab
// ============================================================================

class _RoadTransportTab extends StatelessWidget {
  final List<FareFormula> formulas;
  final String searchQuery;

  const _RoadTransportTab({required this.formulas, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    // Group formulas by mode
    final groupedFormulas = <String, List<FareFormula>>{};
    for (final formula in formulas) {
      groupedFormulas.putIfAbsent(formula.mode, () => []).add(formula);
    }

    // Filter by search query
    final filteredGroups = <String, List<FareFormula>>{};
    for (final entry in groupedFormulas.entries) {
      if (searchQuery.isEmpty ||
          entry.key.toLowerCase().contains(searchQuery) ||
          entry.value.any(
            (f) =>
                f.subType.toLowerCase().contains(searchQuery) ||
                (f.notes?.toLowerCase().contains(searchQuery) ?? false),
          )) {
        filteredGroups[entry.key] = entry.value;
      }
    }

    if (filteredGroups.isEmpty) {
      return _EmptySearchState(
        icon: Icons.directions_bus_rounded,
        message: searchQuery.isEmpty
            ? 'No road transport data available'
            : 'No results found for "$searchQuery"',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredGroups.length,
      itemBuilder: (context, index) {
        final entry = filteredGroups.entries.elementAt(index);
        return _TransportModeCard(
          modeName: entry.key,
          formulas: entry.value,
          icon: _getTransportIcon(entry.key),
          index: index,
        );
      },
    );
  }

  IconData _getTransportIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'jeepney':
        return Icons.airport_shuttle_rounded;
      case 'bus':
        return Icons.directions_bus_rounded;
      case 'p2p bus':
        return Icons.directions_bus_filled_rounded;
      case 'uv express':
        return Icons.commute_rounded;
      case 'tricycle':
        return Icons.electric_rickshaw_rounded;
      case 'taxi':
        return Icons.local_taxi_rounded;
      case 'grabcar':
        return Icons.drive_eta_rounded;
      default:
        return Icons.directions_bus_rounded;
    }
  }
}

class _TransportModeCard extends StatelessWidget {
  final String modeName;
  final List<FareFormula> formulas;
  final IconData icon;
  final int index;

  const _TransportModeCard({
    required this.modeName,
    required this.formulas,
    required this.icon,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Semantics(
        container: true,
        label: '$modeName transport fare information',
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 24),
              ),
              title: Text(
                modeName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${formulas.length} fare type(s)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: formulas.asMap().entries.map((entry) {
                final formula = entry.value;
                final isLast = entry.key == formulas.length - 1;
                return Column(
                  children: [
                    _FareFormulaItem(formula: formula),
                    if (!isLast)
                      Divider(height: 24, color: colorScheme.outlineVariant),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _FareFormulaItem extends StatelessWidget {
  final FareFormula formula;

  const _FareFormulaItem({required this.formula});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasBaseFare = formula.baseFare > 0;
    final hasPerKm = formula.perKmRate > 0;

    return Semantics(
      container: true,
      label:
          '${formula.subType} fare: '
          '${hasBaseFare ? "Base fare ${formula.baseFare} pesos" : ""} '
          '${hasPerKm ? "Per kilometer ${formula.perKmRate} pesos" : ""}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formula.subType,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasBaseFare)
                _FareChip(
                  label: 'Base',
                  value: '₱${formula.baseFare.toStringAsFixed(2)}',
                  color: colorScheme.primary,
                ),
              if (hasPerKm)
                _FareChip(
                  label: 'Per km',
                  value: '₱${formula.perKmRate.toStringAsFixed(2)}',
                  color: colorScheme.tertiary,
                ),
              if (formula.minimumFare != null)
                _FareChip(
                  label: 'Min',
                  value: '₱${formula.minimumFare!.toStringAsFixed(2)}',
                  color: colorScheme.secondary,
                ),
            ],
          ),
          if (formula.notes != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formula.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FareChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FareChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Train Tab
// ============================================================================

class _TrainTab extends StatelessWidget {
  final Map<String, List<StaticFare>> trainMatrix;
  final String searchQuery;

  const _TrainTab({required this.trainMatrix, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    // Filter by search query
    final filteredMatrix = <String, List<StaticFare>>{};
    for (final entry in trainMatrix.entries) {
      final filteredRoutes = entry.value.where((route) {
        if (searchQuery.isEmpty) return true;
        return entry.key.toLowerCase().contains(searchQuery) ||
            route.origin.toLowerCase().contains(searchQuery) ||
            route.destination.toLowerCase().contains(searchQuery);
      }).toList();

      if (filteredRoutes.isNotEmpty) {
        filteredMatrix[entry.key] = filteredRoutes;
      }
    }

    if (filteredMatrix.isEmpty) {
      return _EmptySearchState(
        icon: Icons.train_rounded,
        message: searchQuery.isEmpty
            ? 'No train data available'
            : 'No results found for "$searchQuery"',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredMatrix.length,
      itemBuilder: (context, index) {
        final entry = filteredMatrix.entries.elementAt(index);
        return _TrainLineCard(
          lineName: entry.key,
          routes: entry.value,
          index: index,
        );
      },
    );
  }
}

class _TrainLineCard extends StatelessWidget {
  final String lineName;
  final List<StaticFare> routes;
  final int index;

  const _TrainLineCard({
    required this.lineName,
    required this.routes,
    required this.index,
  });

  Color _getLineColor(String name) {
    if (name.contains('LRT-1') || name.contains('LRT1')) {
      return const Color(0xFF4CAF50); // Green
    } else if (name.contains('LRT-2') || name.contains('LRT2')) {
      return const Color(0xFF7B1FA2); // Purple
    } else if (name.contains('MRT-3') || name.contains('MRT3')) {
      return const Color(0xFF2196F3); // Blue
    } else if (name.contains('MRT-7') || name.contains('MRT7')) {
      return const Color(0xFFFF9800); // Orange
    } else if (name.contains('PNR')) {
      return const Color(0xFF795548); // Brown
    }
    return const Color(0xFF607D8B); // Default grey-blue
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lineColor = _getLineColor(lineName);

    // Calculate stats
    final maxFare = routes.map((r) => r.price).reduce((a, b) => a > b ? a : b);
    final minFare = routes.map((r) => r.price).reduce((a, b) => a < b ? a : b);
    final uniqueStations = <String>{};
    for (final route in routes) {
      uniqueStations.add(route.origin);
      uniqueStations.add(route.destination);
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Semantics(
        container: true,
        label: '$lineName with ${routes.length} routes',
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header with line color strip
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [lineColor, lineColor.withValues(alpha: 0.7)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.train_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lineName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${uniqueStations.length} stations • ${routes.length} routes',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '₱${minFare.toStringAsFixed(0)} - ₱${maxFare.toStringAsFixed(0)}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Routes list
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    'View All Routes',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  trailing: Icon(Icons.expand_more, color: colorScheme.primary),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: routes.map((route) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _RouteRow(
                        origin: route.origin,
                        destination: route.destination,
                        price: route.price,
                        accentColor: lineColor,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String origin;
  final String destination;
  final double price;
  final Color accentColor;

  const _RouteRow({
    required this.origin,
    required this.destination,
    required this.price,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Route from $origin to $destination costs $price pesos',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                origin,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                destination,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '₱${price.toStringAsFixed(2)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Ferry Tab
// ============================================================================

class _FerryTab extends StatelessWidget {
  final List<StaticFare> ferryRoutes;
  final String searchQuery;

  const _FerryTab({required this.ferryRoutes, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    // Group by origin
    final groupedFerries = <String, List<StaticFare>>{};
    for (final route in ferryRoutes) {
      groupedFerries.putIfAbsent(route.origin, () => []).add(route);
    }

    // Filter by search
    final filteredGroups = <String, List<StaticFare>>{};
    for (final entry in groupedFerries.entries) {
      final filteredRoutes = entry.value.where((route) {
        if (searchQuery.isEmpty) return true;
        return route.origin.toLowerCase().contains(searchQuery) ||
            route.destination.toLowerCase().contains(searchQuery) ||
            (route.operator?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();

      if (filteredRoutes.isNotEmpty) {
        filteredGroups[entry.key] = filteredRoutes;
      }
    }

    if (filteredGroups.isEmpty) {
      return _EmptySearchState(
        icon: Icons.directions_boat_rounded,
        message: searchQuery.isEmpty
            ? 'No ferry data available'
            : 'No results found for "$searchQuery"',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredGroups.length,
      itemBuilder: (context, index) {
        final entry = filteredGroups.entries.elementAt(index);
        return _FerryOriginCard(
          origin: entry.key,
          routes: entry.value,
          index: index,
        );
      },
    );
  }
}

class _FerryOriginCard extends StatelessWidget {
  final String origin;
  final List<StaticFare> routes;
  final int index;

  const _FerryOriginCard({
    required this.origin,
    required this.routes,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Semantics(
        container: true,
        label: 'Ferry routes from $origin',
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_boat_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              title: Text(
                'From $origin',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${routes.length} destination(s)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: routes.map((route) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _FerryRouteItem(route: route),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _FerryRouteItem extends StatelessWidget {
  final StaticFare route;

  const _FerryRouteItem({required this.route});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label:
          'Ferry to ${route.destination} ${route.operator != null ? "via ${route.operator}" : ""} costs ${route.price} pesos',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          route.destination,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (route.operator != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            route.operator!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '₱${route.price.toStringAsFixed(2)}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Discount Info Tab
// ============================================================================

class _DiscountInfoTab extends StatelessWidget {
  final String searchQuery;

  const _DiscountInfoTab({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final discounts = [
      _DiscountData(
        icon: Icons.school_rounded,
        category: 'Students',
        discount: '20% off',
        description:
            'Valid student ID from accredited institution required. Must be enrolled in current academic year.',
        color: const Color(0xFF2196F3),
      ),
      _DiscountData(
        icon: Icons.elderly_rounded,
        category: 'Senior Citizens (60+)',
        discount: '20% off',
        description:
            'Senior Citizen ID or valid government ID showing age 60 and above required.',
        color: const Color(0xFF9C27B0),
      ),
      _DiscountData(
        icon: Icons.accessible_rounded,
        category: 'Persons with Disabilities',
        discount: '20% off',
        description:
            'PWD ID issued by the local government required. Companion may also be entitled to discount.',
        color: const Color(0xFF4CAF50),
      ),
    ];

    // Filter by search
    final filteredDiscounts = discounts.where((d) {
      if (searchQuery.isEmpty) return true;
      return d.category.toLowerCase().contains(searchQuery) ||
          d.description.toLowerCase().contains(searchQuery);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.percent_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Discount Privileges',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Save on your daily commute',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Discount Cards
          if (filteredDiscounts.isEmpty)
            _EmptySearchState(
              icon: Icons.search_off_rounded,
              message: 'No discount info found for "$searchQuery"',
            )
          else
            ...filteredDiscounts.asMap().entries.map((entry) {
              return _DiscountCard(data: entry.value, index: entry.key);
            }),

          const SizedBox(height: 16),

          // Important Note Card
          if (searchQuery.isEmpty)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Semantics(
                container: true,
                label: 'Important note about discounts',
                child: Card(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.secondary.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lightbulb_rounded,
                            color: colorScheme.secondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Important',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Valid ID is required for discount eligibility. Discounts apply to most public transport modes including buses, jeepneys, trains, and ferries.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DiscountData {
  final IconData icon;
  final String category;
  final String discount;
  final String description;
  final Color color;

  const _DiscountData({
    required this.icon,
    required this.category,
    required this.discount,
    required this.description,
    required this.color,
  });
}

class _DiscountCard extends StatelessWidget {
  final _DiscountData data;
  final int index;

  const _DiscountCard({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Semantics(
        container: true,
        label:
            '${data.category} discount: ${data.discount}. ${data.description}',
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, color: data.color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data.category,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF4CAF50,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(
                                  0xFF4CAF50,
                                ).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              data.discount,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Empty State Widget
// ============================================================================

class _EmptySearchState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptySearchState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
