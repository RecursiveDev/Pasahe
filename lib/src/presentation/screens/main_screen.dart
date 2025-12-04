import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/di/injection.dart';
import '../../core/errors/failures.dart';
import '../../core/hybrid_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../models/discount_type.dart';
import '../../models/fare_formula.dart';
import '../../models/fare_result.dart';
import '../../models/location.dart';
import '../../models/saved_route.dart';
import '../../models/transport_mode.dart';
import '../../repositories/fare_repository.dart';
import '../../services/fare_comparison_service.dart';
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
  final SettingsService _settingsService = getIt<SettingsService>();
  final FareComparisonService _fareComparisonService =
      getIt<FareComparisonService>();
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
  int _passengerCount = 1;
  int _regularPassengers = 1;
  int _discountedPassengers = 0;
  SortCriteria _sortCriteria = SortCriteria.priceAsc;

  // Text controller for origin field
  final TextEditingController _originTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _originDebounceTimer?.cancel();
    _destinationDebounceTimer?.cancel();
    _originTextController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    // Data is already seeded in Splash Screen
    final formulas = await _fareRepository.getAllFormulas();

    // Load last known location if available
    final lastLocation = await _settingsService.getLastLocation();

    // Check if user has set their discount type
    final hasSetDiscountType = await _settingsService.hasSetDiscountType();

    // Read user's discount type to initialize passenger state
    final userDiscountType = await _settingsService.getUserDiscountType();

    if (mounted) {
      setState(() {
        _availableFormulas = formulas;
        _isLoading = false;

        // Auto-fill origin if last location exists
        if (lastLocation != null) {
          _originLocation = lastLocation;
          _originLatLng = LatLng(lastLocation.latitude, lastLocation.longitude);
          _originTextController.text = lastLocation.name;
        }

        // Sync passenger type from settings when user is the sole passenger
        // Only auto-apply discount when total passengers is 1
        if (userDiscountType == DiscountType.discounted &&
            _passengerCount == 1) {
          _regularPassengers = 0;
          _discountedPassengers = 1;
        } else {
          _regularPassengers = 1;
          _discountedPassengers = 0;
        }
      });

      // Show first-time passenger type prompt if not set
      if (!hasSetDiscountType) {
        _showFirstTimePassengerTypePrompt();
      }
    }
  }

  /// Show a dialog prompting first-time users to select their passenger type
  Future<void> _showFirstTimePassengerTypePrompt() async {
    // Use a short delay to ensure the widget is fully built
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome to PH Fare Calculator'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please select your passenger type to get accurate fare estimates:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'This can be changed later in Settings.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _settingsService.setUserDiscountType(
                  DiscountType.standard,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Regular'),
            ),
            TextButton(
              onPressed: () async {
                await _settingsService.setUserDiscountType(
                  DiscountType.discounted,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Discounted (Student/Senior/PWD)'),
            ),
          ],
        );
      },
    );
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
              textController: _originTextController,
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
                  _destinationLatLng = LatLng(
                    location.latitude,
                    location.longitude,
                  );
                  _resetResult();
                });
                // Trigger route calculation if both locations are selected
                if (_originLocation != null) {
                  _calculateRoute();
                }
              },
            ),
            const SizedBox(height: 16.0),
            // Passenger Count Selector
            _buildPassengerCountSelector(),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveRoute,
                    icon: const Icon(Icons.save),
                    label: Text(AppLocalizations.of(context)!.saveRouteButton),
                  ),
                  _buildSortCriteriaSelector(),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildGroupedFareResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerCountSelector() {
    final totalPassengers = _regularPassengers + _discountedPassengers;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _showPassengerDialog,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Passengers:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      Text(
                        '$totalPassengers',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit, size: 18, color: Colors.grey),
                    ],
                  ),
                ],
              ),
              if (_discountedPassengers > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Regular: $_regularPassengers • Discounted: $_discountedPassengers',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPassengerDialog() async {
    int tempRegular = _regularPassengers;
    int tempDiscounted = _discountedPassengers;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Passenger Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Regular Passengers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Regular Passengers:',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: tempRegular > 0
                                ? () {
                                    setDialogState(() {
                                      tempRegular--;
                                    });
                                  }
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$tempRegular',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: tempRegular < 99
                                ? () {
                                    setDialogState(() {
                                      tempRegular++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Discounted Passengers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discounted Passengers:',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              '(Student/Senior/PWD - 20% off)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: tempDiscounted > 0
                                ? () {
                                    setDialogState(() {
                                      tempDiscounted--;
                                    });
                                  }
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$tempDiscounted',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: tempDiscounted < 99
                                ? () {
                                    setDialogState(() {
                                      tempDiscounted++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Total: ${tempRegular + tempDiscounted} passenger(s)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (tempRegular + tempDiscounted) > 0
                      ? () {
                          setState(() {
                            _regularPassengers = tempRegular;
                            _discountedPassengers = tempDiscounted;
                            _passengerCount = tempRegular + tempDiscounted;
                            if (_originLocation != null &&
                                _destinationLocation != null) {
                              _calculateFare();
                            }
                          });
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSortCriteriaSelector() {
    return DropdownButton<SortCriteria>(
      value: _sortCriteria,
      items: const [
        DropdownMenuItem(
          value: SortCriteria.priceAsc,
          child: Text('Price: Low to High'),
        ),
        DropdownMenuItem(
          value: SortCriteria.priceDesc,
          child: Text('Price: High to Low'),
        ),
      ],
      onChanged: (SortCriteria? newValue) {
        if (newValue != null) {
          setState(() {
            _sortCriteria = newValue;
            // Re-sort existing results
            if (_fareResults.isNotEmpty) {
              _fareResults = _fareComparisonService.sortFares(
                _fareResults,
                _sortCriteria,
              );
              // Update the recommended flag for the first item
              _updateRecommendedFlag();
            }
          });
        }
      },
    );
  }

  /// Builds the grouped fare results display with section headers
  Widget _buildGroupedFareResults() {
    // Group the fare results by transport mode
    final groupedResults = _fareComparisonService.groupFaresByMode(
      _fareResults,
    );

    // Sort the groups by the best fare in each group
    final sortedGroups = groupedResults.entries.toList();
    if (_sortCriteria == SortCriteria.priceAsc) {
      sortedGroups.sort((a, b) {
        final aMin = a.value
            .map((r) => r.totalFare)
            .reduce((a, b) => a < b ? a : b);
        final bMin = b.value
            .map((r) => r.totalFare)
            .reduce((a, b) => a < b ? a : b);
        return aMin.compareTo(bMin);
      });
    } else if (_sortCriteria == SortCriteria.priceDesc) {
      sortedGroups.sort((a, b) {
        final aMax = a.value
            .map((r) => r.totalFare)
            .reduce((a, b) => a > b ? a : b);
        final bMax = b.value
            .map((r) => r.totalFare)
            .reduce((a, b) => a > b ? a : b);
        return bMax.compareTo(aMax);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sortedGroups.map((entry) {
        final mode = entry.key;
        final fares = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Header
            _buildTransportModeHeader(mode),
            const SizedBox(height: 8.0),
            // Fare cards for this mode
            ...fares.map(
              (result) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: FareResultCard(
                  transportMode: result.transportMode,
                  fare: result.totalFare,
                  indicatorLevel: result.indicatorLevel,
                  isRecommended: result.isRecommended,
                  passengerCount: result.passengerCount,
                  totalFare: result.totalFare,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
          ],
        );
      }).toList(),
    );
  }

  /// Builds a header widget for a transport mode section
  Widget _buildTransportModeHeader(TransportMode mode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(
            _getTransportModeIcon(mode),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12.0),
          Text(
            mode.displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns an appropriate icon for each transport mode
  IconData _getTransportModeIcon(TransportMode mode) {
    switch (mode) {
      case TransportMode.jeepney:
        return Icons.directions_bus;
      case TransportMode.bus:
        return Icons.directions_bus_filled;
      case TransportMode.taxi:
        return Icons.local_taxi;
      case TransportMode.train:
        return Icons.train;
      case TransportMode.ferry:
        return Icons.directions_boat;
      case TransportMode.tricycle:
        return Icons.electric_rickshaw;
      case TransportMode.uvExpress:
        return Icons.airport_shuttle;
      case TransportMode.van:
        return Icons.airport_shuttle;
      case TransportMode.motorcycle:
        return Icons.two_wheeler;
      case TransportMode.edsaCarousel:
        return Icons.directions_bus;
      case TransportMode.pedicab:
        return Icons.pedal_bike;
      case TransportMode.kuliglig:
        return Icons.agriculture;
    }
  }

  void _updateRecommendedFlag() {
    if (_fareResults.isEmpty) return;

    // Remove recommendation from all results first
    _fareResults = _fareResults.map((result) {
      return FareResult(
        transportMode: result.transportMode,
        fare: result.fare,
        indicatorLevel: result.indicatorLevel,
        isRecommended: false,
        passengerCount: result.passengerCount,
        totalFare: result.totalFare,
      );
    }).toList();

    // Mark the first one (based on current sort) as recommended
    _fareResults[0] = FareResult(
      transportMode: _fareResults[0].transportMode,
      fare: _fareResults[0].fare,
      indicatorLevel: _fareResults[0].indicatorLevel,
      isRecommended: true,
      passengerCount: _fareResults[0].passengerCount,
      totalFare: _fareResults[0].totalFare,
    );
  }

  Widget _buildLocationAutocomplete({
    required String label,
    required bool isOriginField,
    required ValueChanged<Location> onSelected,
    TextEditingController? textController,
  }) {
    final isOrigin = isOriginField;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<Location>(
          displayStringForOption: (Location option) => option.name,
          initialValue: textController != null
              ? TextEditingValue(text: textController.text)
              : null,
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.trim().isEmpty) {
              return const Iterable<Location>.empty();
            }

            // Debounce logic: cancel previous timer and create new one
            final debounceTimer = isOrigin
                ? _originDebounceTimer
                : _destinationDebounceTimer;
            debounceTimer?.cancel();

            // Create a completer to return results after debounce
            final completer = Completer<List<Location>>();

            final newTimer = Timer(const Duration(milliseconds: 800), () async {
              try {
                final locations = await _geocodingService.getLocations(
                  textEditingValue.text,
                );
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
                              onPressed: () => _useCurrentLocation(
                                textEditingController,
                                onSelected,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.map),
                            tooltip: 'Select from map',
                            onPressed: () => _openMapPicker(
                              isOriginField,
                              textEditingController,
                              onSelected,
                            ),
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
    // Fall back to origin location when destination is null for better UX
    final initialLocation = isOrigin
        ? _originLatLng
        : (_destinationLatLng ?? _originLatLng);
    final title = isOrigin ? 'Select Origin' : 'Select Destination';

    final LatLng? selectedLatLng = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MapPickerScreen(initialLocation: initialLocation, title: title),
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
    if (_fareResults.isNotEmpty ||
        _errorMessage != null ||
        _routePoints.isNotEmpty) {
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
      // Save the origin location for persistence
      if (_originLocation != null) {
        await _settingsService.saveLastLocation(_originLocation!);
      }

      final List<FareResult> results = [];
      final trafficFactor = await _settingsService.getTrafficFactor();
      final hiddenModes = await _settingsService.getHiddenTransportModes();

      // Filter formulas: exclude hidden modes
      final visibleFormulas = _availableFormulas.where((formula) {
        final modeSubTypeKey = '${formula.mode}::${formula.subType}';
        return !hiddenModes.contains(modeSubTypeKey);
      }).toList();

      // If no visible formulas, show error
      if (visibleFormulas.isEmpty) {
        setState(() {
          _errorMessage =
              'No transport modes enabled. Please enable at least one mode in Settings.';
        });
        return;
      }

      // Calculate fare for each visible formula
      for (final formula in visibleFormulas) {
        // Skip if formula is invalid (zero base fare and per km rate)
        if (formula.baseFare == 0.0 && formula.perKmRate == 0.0) {
          debugPrint(
            'Skipping invalid formula for ${formula.mode} (${formula.subType})',
          );
          continue;
        }

        final fare = await _hybridEngine.calculateDynamicFare(
          originLat: _originLocation!.latitude,
          originLng: _originLocation!.longitude,
          destLat: _destinationLocation!.latitude,
          destLng: _destinationLocation!.longitude,
          formula: formula,
          passengerCount: _passengerCount,
          regularCount: _regularPassengers,
          discountedCount: _discountedPassengers,
        );

        // Traffic indicator should ONLY apply to Taxi mode
        // All other modes should always show standard (green) indicator
        final indicator = formula.mode == 'Taxi'
            ? _hybridEngine.getIndicatorLevel(trafficFactor.name)
            : IndicatorLevel.standard;

        // Calculate total fare for display
        final totalFare = fare;

        results.add(
          FareResult(
            transportMode: '${formula.mode} (${formula.subType})',
            fare: fare,
            indicatorLevel: indicator,
            isRecommended: false, // Will be set after sorting
            passengerCount: _passengerCount,
            totalFare: totalFare,
          ),
        );
      }

      // Sort results using FareComparisonService
      final sortedResults = _fareComparisonService.sortFares(
        results,
        _sortCriteria,
      );

      // Mark the first option (based on sort criteria) as recommended
      if (sortedResults.isNotEmpty) {
        sortedResults[0] = FareResult(
          transportMode: sortedResults[0].transportMode,
          fare: sortedResults[0].fare,
          indicatorLevel: sortedResults[0].indicatorLevel,
          isRecommended: true,
          passengerCount: sortedResults[0].passengerCount,
          totalFare: sortedResults[0].totalFare,
        );
      }

      setState(() {
        _fareResults = sortedResults;
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
