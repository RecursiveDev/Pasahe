import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/errors/failures.dart';
import '../../core/hybrid_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../models/fare_formula.dart';
import '../../models/fare_result.dart';
import '../../models/location.dart';
import '../../models/saved_route.dart';
import '../../repositories/fare_repository.dart';
import '../../services/fare_comparison_service.dart';
import '../../services/geocoding/geocoding_service.dart';
import '../../services/settings_service.dart';
import '../widgets/fare_result_card.dart';
import 'offline_menu_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Geocoding state
  final GeocodingService _geocodingService = getIt<GeocodingService>();
  Location? _originLocation;
  Location? _destinationLocation;

  // Engine and Data state
  final HybridEngine _hybridEngine = getIt<HybridEngine>();
  final FareRepository _fareRepository = getIt<FareRepository>();
  final FareComparisonService _fareComparisonService =
      getIt<FareComparisonService>();
  // final RoutingService _routingService = getIt<RoutingService>();
  List<FareFormula> _availableFormulas = [];
  bool _isLoading = true;

  // UI state
  List<FareResult> _fareResults = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Data is already seeded in Splash Screen
    final formulas = await _fareRepository.getAllFormulas();
    if (mounted) {
      setState(() {
        _availableFormulas = formulas;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.fareEstimatorTitle),
        actions: [
          Semantics(
            label: 'Open offline reference menu',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.book),
              tooltip: 'Offline Reference',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfflineMenuScreen(),
                  ),
                );
              },
            ),
          ),
          Semantics(
            label: 'Open settings',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildLocationAutocomplete(
              label: AppLocalizations.of(context)!.originLabel,
              onSelected: (Location location) {
                setState(() {
                  _originLocation = location;
                  _resetResult();
                });
              },
            ),
            const SizedBox(height: 16.0),
            _buildLocationAutocomplete(
              label: AppLocalizations.of(context)!.destinationLabel,
              onSelected: (Location location) {
                setState(() {
                  _destinationLocation = location;
                  _resetResult();
                });
              },
            ),
            const SizedBox(height: 24.0),
            Semantics(
              label: 'Calculate Fare based on selected origin and destination',
              button: true,
              enabled:
                  !_isLoading &&
                  _originLocation != null &&
                  _destinationLocation != null,
              child: ElevatedButton(
                onPressed:
                    _isLoading ||
                        _originLocation == null ||
                        _destinationLocation == null
                    ? null
                    : _calculateFare,
                child: Text(AppLocalizations.of(context)!.calculateFareButton),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 24.0),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (_fareResults.isNotEmpty) ...[
              const SizedBox(height: 24.0),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _saveRoute,
                  icon: const Icon(Icons.save),
                  label: Text(AppLocalizations.of(context)!.saveRouteButton),
                ),
              ),
              const SizedBox(height: 16.0),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _fareResults.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16.0),
                itemBuilder: (context, index) {
                  final result = _fareResults[index];
                  return FareResultCard(
                    transportMode: result.transportMode,
                    fare: result.fare,
                    indicatorLevel: result.indicatorLevel,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationAutocomplete({
    required String label,
    required ValueChanged<Location> onSelected,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Location>(
          displayStringForOption: (Location option) => option.name,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.trim().isEmpty) {
              return const Iterable<Location>.empty();
            }
            // Simple debounce could be added here if needed,
            // but Autocomplete handles async futures well.
            return await _geocodingService.getLocations(textEditingValue.text);
          },
          onSelected: onSelected,
          fieldViewBuilder:
              (
                BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted,
              ) {
                return Semantics(
                  label: 'Input for $label location',
                  textField: true,
                  child: TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.search),
                    ),
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Location option = options.elementAt(index);
                      return ListTile(
                        title: Text(option.name),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _resetResult() {
    if (_fareResults.isNotEmpty || _errorMessage != null) {
      setState(() {
        _fareResults = [];
        _errorMessage = null;
      });
    }
  }

  Future<void> _saveRoute() async {
    if (_originLocation == null ||
        _destinationLocation == null ||
        _fareResults.isEmpty) {
      return;
    }

    final route = SavedRoute(
      origin: _originLocation!.name,
      destination: _destinationLocation!.name,
      fareResults: _fareResults,
      timestamp: DateTime.now(),
    );

    await _fareRepository.saveRoute(route);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.routeSavedMessage),
        ),
      );
    }
  }

  Future<void> _calculateFare() async {
    setState(() {
      _errorMessage = null;
      _fareResults = [];
    });

    final modesToCompare = [
      {'mode': 'Jeepney', 'subType': 'Traditional'},
      {'mode': 'Taxi', 'subType': 'White (Regular)'},
    ];

    try {
      final List<FareResult> results = [];
      final settingsService = SettingsService();
      final trafficFactor = await settingsService.getTrafficFactor();

      for (final modeData in modesToCompare) {
        final formula = _availableFormulas.firstWhere(
          (f) => f.mode == modeData['mode'] && f.subType == modeData['subType'],
          orElse: () => FareFormula(
            mode: modeData['mode']!,
            subType: modeData['subType']!,
            baseFare: 0.0,
            perKmRate: 0.0,
          ),
        );

        // Skip if formula not found or invalid (zero base fare as simplistic check)
        if (formula.baseFare == 0.0 && formula.perKmRate == 0.0) {
          debugPrint('Formula not found for ${modeData['mode']}');
          continue;
        }

        final fare = await _hybridEngine.calculateDynamicFare(
          originLat: _originLocation!.latitude,
          originLng: _originLocation!.longitude,
          destLat: _destinationLocation!.latitude,
          destLng: _destinationLocation!.longitude,
          formula: formula,
        );

        final indicator = _hybridEngine.getIndicatorLevel(trafficFactor.name);

        results.add(
          FareResult(
            transportMode: '${modeData['mode']} (${modeData['subType']})',
            fare: fare,
            indicatorLevel: indicator,
          ),
        );
      }

      setState(() {
        _fareResults = results;
      });
    } catch (e) {
      debugPrint('Error calculating fare: $e');
      String msg =
          'Could not calculate fare. Please check your route and try again.';
      if (e is Failure) {
        msg = e.message;
      }

      setState(() {
        _fareResults = [];
        _errorMessage = msg;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
