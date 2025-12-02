import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/di/injection.dart';
import '../../core/errors/failures.dart';
import '../../core/hybrid_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../models/fare_formula.dart';
import '../../models/fare_result.dart';
import '../../models/location.dart';
import '../../models/saved_route.dart';
import '../../repositories/fare_repository.dart';
import '../../services/geocoding/geocoding_service.dart';
import '../../services/routing/routing_service.dart';
import '../../services/settings_service.dart';
import '../widgets/fare_result_card.dart';
import '../widgets/map_selection_widget.dart';
import 'map_picker_screen.dart';
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
  final RoutingService _routingService = getIt<RoutingService>();
  List<FareFormula> _availableFormulas = [];
  bool _isLoading = true;

  // Map state
  LatLng? _originLatLng;
  LatLng? _destinationLatLng;
  List<LatLng> _routePoints = [];

  // Debounce timers
  Timer? _originDebounceTimer;
  Timer? _destinationDebounceTimer;

  // UI state
  List<FareResult> _fareResults = [];
  String? _errorMessage;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _originDebounceTimer?.cancel();
    _destinationDebounceTimer?.cancel();
    super.dispose();
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
              isOriginField: true,
              onSelected: (Location location) {
                setState(() {
                  _originLocation = location;
                  _originLatLng = LatLng(location.latitude, location.longitude);
                  _resetResult();
                });
                // Trigger route calculation if both locations are selected
                if (_destinationLocation != null) {
                  _calculateRoute();
                }
              },
            ),
            const SizedBox(height: 16.0),
            _buildLocationAutocomplete(
              label: AppLocalizations.of(context)!.destinationLabel,
              isOriginField: false,
              onSelected: (Location location) {
                setState(() {
                  _destinationLocation = location;
                  _destinationLatLng = LatLng(location.latitude, location.longitude);
                  _resetResult();
                });
                // Trigger route calculation if both locations are selected
                if (_originLocation != null) {
                  _calculateRoute();
                }
              },
            ),
            const SizedBox(height: 16.0),
            // Map Widget
            SizedBox(
              height: 300,
              child: MapSelectionWidget(
                origin: _originLatLng,
                destination: _destinationLatLng,
                routePoints: _routePoints,
              ),
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
    required bool isOriginField,
    required ValueChanged<Location> onSelected,
  }) {
    final isOrigin = isOriginField;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Location>(
          displayStringForOption: (Location option) => option.name,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.trim().isEmpty) {
              return const Iterable<Location>.empty();
            }
            
            // Debounce logic: cancel previous timer and create new one
            final debounceTimer = isOrigin ? _originDebounceTimer : _destinationDebounceTimer;
            debounceTimer?.cancel();
            
            // Create a completer to return results after debounce
            final completer = Completer<List<Location>>();
            
            final newTimer = Timer(const Duration(milliseconds: 800), () async {
              try {
                final locations = await _geocodingService.getLocations(textEditingValue.text);
                if (!completer.isCompleted) {
                  completer.complete(locations);
                }
              } catch (e) {
                if (!completer.isCompleted) {
                  completer.complete([]);
                }
              }
            });
            
            if (isOrigin) {
              _originDebounceTimer = newTimer;
            } else {
              _destinationDebounceTimer = newTimer;
            }
            
            return completer.future;
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
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isOriginField && _isLoadingLocation)
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else if (isOriginField)
                            IconButton(
                              icon: const Icon(Icons.my_location),
                              tooltip: 'Use my current location',
                              onPressed: () => _useCurrentLocation(textEditingController, onSelected),
                            ),
                          IconButton(
                            icon: const Icon(Icons.map),
                            tooltip: 'Select from map',
                            onPressed: () => _openMapPicker(isOriginField, textEditingController, onSelected),
                          ),
                        ],
                      ),
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

  Future<void> _openMapPicker(
    bool isOrigin,
    TextEditingController controller,
    ValueChanged<Location> onSelected,
  ) async {
    final initialLocation = isOrigin ? _originLatLng : _destinationLatLng;
    final title = isOrigin ? 'Select Origin' : 'Select Destination';

    final LatLng? selectedLatLng = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLocation: initialLocation,
          title: title,
        ),
      ),
    );

    if (selectedLatLng != null) {
      try {
        // Show loading indicator
        setState(() {
          _isLoadingLocation = true;
          _errorMessage = null;
        });

        // Reverse geocode the selected location
        final location = await _geocodingService.getAddressFromLatLng(
          selectedLatLng.latitude,
          selectedLatLng.longitude,
        );

        if (mounted) {
          // Update the text field
          controller.text = location.name;
          
          // Call the onSelected callback to update state
          onSelected(location);
          
          setState(() {
            _isLoadingLocation = false;
          });
        }
      } catch (e) {
        if (mounted) {
          String errorMsg = 'Failed to get address for selected location.';
          
          if (e is Failure) {
            errorMsg = e.message;
          }
          
          setState(() {
            _isLoadingLocation = false;
            _errorMessage = errorMsg;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _resetResult() {
    if (_fareResults.isNotEmpty || _errorMessage != null || _routePoints.isNotEmpty) {
      setState(() {
        _fareResults = [];
        _errorMessage = null;
        _routePoints = [];
      });
    }
  }

  Future<void> _calculateRoute() async {
    if (_originLocation == null || _destinationLocation == null) {
      return;
    }

    try {
      final routeResult = await _routingService.getRoute(
        _originLocation!.latitude,
        _originLocation!.longitude,
        _destinationLocation!.latitude,
        _destinationLocation!.longitude,
      );

      setState(() {
        _routePoints = routeResult.geometry;
      });
    } catch (e) {
      debugPrint('Error calculating route: $e');
      // Don't show error for route visualization failure
      // Just leave route empty - user can still calculate fare
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

    try {
      final List<FareResult> results = [];
      final settingsService = getIt<SettingsService>();
      final trafficFactor = await settingsService.getTrafficFactor();
      final hiddenModes = await settingsService.getHiddenTransportModes();

      // Filter formulas: exclude hidden modes
      final visibleFormulas = _availableFormulas.where((formula) {
        final modeSubTypeKey = '${formula.mode}::${formula.subType}';
        return !hiddenModes.contains(modeSubTypeKey);
      }).toList();

      // If no visible formulas, show error
      if (visibleFormulas.isEmpty) {
        setState(() {
          _errorMessage = 'No transport modes enabled. Please enable at least one mode in Settings.';
        });
        return;
      }

      // Calculate fare for each visible formula
      for (final formula in visibleFormulas) {
        // Skip if formula is invalid (zero base fare and per km rate)
        if (formula.baseFare == 0.0 && formula.perKmRate == 0.0) {
          debugPrint('Skipping invalid formula for ${formula.mode} (${formula.subType})');
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
            transportMode: '${formula.mode} (${formula.subType})',
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

  Future<void> _useCurrentLocation(
    TextEditingController controller,
    ValueChanged<Location> onSelected,
  ) async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final location = await _geocodingService.getCurrentLocationAddress();
      
      if (mounted) {
        controller.text = location.name;
        onSelected(location);
        
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Failed to get current location.';
        
        if (e is Failure) {
          errorMsg = e.message;
        }
        
        setState(() {
          _isLoadingLocation = false;
          _errorMessage = errorMsg;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
