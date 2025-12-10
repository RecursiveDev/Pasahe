import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/di/injection.dart';
import '../../l10n/app_localizations.dart';
import '../../models/connectivity_status.dart';
import '../../services/connectivity/connectivity_service.dart';
import '../../services/fare_comparison_service.dart';
import '../controllers/main_screen_controller.dart';
import '../widgets/main_screen/calculate_fare_button.dart';
import '../widgets/main_screen/error_message_banner.dart';
import '../widgets/main_screen/fare_results_header.dart';
import '../widgets/main_screen/fare_results_list.dart';
import '../widgets/main_screen/first_time_passenger_prompt.dart';
import '../widgets/main_screen/location_input_section.dart';
import '../widgets/main_screen/main_screen_app_bar.dart';
import '../widgets/main_screen/map_preview.dart';
import '../widgets/main_screen/offline_status_banner.dart';
import '../widgets/main_screen/passenger_bottom_sheet.dart';
import '../widgets/main_screen/travel_options_bar.dart';
import 'map_picker_screen.dart';

/// Main screen for the PH Fare Calculator app.
/// Refactored to use modular widgets and a controller for state management.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final MainScreenController _controller;
  late final ConnectivityService _connectivityService;
  final TextEditingController _originTextController = TextEditingController();
  final TextEditingController _destinationTextController =
      TextEditingController();
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  ConnectivityStatus _connectivityStatus = ConnectivityStatus.online;

  @override
  void initState() {
    super.initState();
    _controller = MainScreenController();
    _connectivityService = getIt<ConnectivityService>();
    _controller.addListener(_onControllerChanged);
    _initializeData();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    _connectivityStatus = _connectivityService.lastKnownStatus;
    _connectivitySubscription = _connectivityService.connectivityStream.listen((
      status,
    ) {
      if (mounted) {
        setState(() => _connectivityStatus = status);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _originTextController.dispose();
    _destinationTextController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
      _syncTextControllers();
    }
  }

  void _syncTextControllers() {
    if (_controller.originLocation != null &&
        _originTextController.text != _controller.originLocation!.name) {
      _originTextController.text = _controller.originLocation!.name;
    }
    if (_controller.destinationLocation != null &&
        _destinationTextController.text !=
            _controller.destinationLocation!.name) {
      _destinationTextController.text = _controller.destinationLocation!.name;
    }
  }

  Future<void> _initializeData() async {
    await _controller.initialize();

    if (_controller.originLocation != null) {
      _originTextController.text = _controller.originLocation!.name;
    }

    final hasSetDiscountType = await _controller.hasSetDiscountType();
    if (!hasSetDiscountType && mounted) {
      _showFirstTimePassengerTypePrompt();
    }
  }

  Future<void> _showFirstTimePassengerTypePrompt() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    await FirstTimePassengerPrompt.show(
      context: context,
      onDiscountTypeSelected: (discountType) async {
        await _controller.setUserDiscountType(discountType);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            const MainScreenAppBar(),
            if (_connectivityStatus.isOffline || _connectivityStatus.isLimited)
              OfflineStatusBanner(status: _connectivityStatus),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    LocationInputSection(
                      originController: _originTextController,
                      destinationController: _destinationTextController,
                      isLoadingLocation: _controller.isLoadingLocation,
                      onSearchLocations: _controller.searchLocations,
                      onOriginSelected: _controller.setOriginLocation,
                      onDestinationSelected: _controller.setDestinationLocation,
                      onSwapLocations: _handleSwapLocations,
                      onUseCurrentLocation: _handleUseCurrentLocation,
                      onOpenMapPicker: _handleOpenMapPicker,
                    ),
                    const SizedBox(height: 16),
                    TravelOptionsBar(
                      regularPassengers: _controller.regularPassengers,
                      discountedPassengers: _controller.discountedPassengers,
                      sortCriteria: _controller.sortCriteria,
                      onPassengerTap: _showPassengerBottomSheet,
                      onSortChanged: _controller.setSortCriteria,
                    ),
                    const SizedBox(height: 16),
                    MapPreview(
                      origin: _controller.originLatLng,
                      destination: _controller.destinationLatLng,
                      routePoints: _controller.routePoints,
                    ),
                    const SizedBox(height: 24),
                    CalculateFareButton(
                      canCalculate: _controller.canCalculate,
                      isCalculating: _controller.isCalculating,
                      onPressed: _controller.calculateFare,
                    ),
                    if (_controller.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      ErrorMessageBanner(message: _controller.errorMessage!),
                    ],
                    if (_controller.fareResults.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      FareResultsHeader(onSaveRoute: _handleSaveRoute),
                      const SizedBox(height: 16),
                      FareResultsList(
                        fareResults: _controller.fareResults,
                        sortCriteria: _controller.sortCriteria,
                        fareComparisonService: getIt<FareComparisonService>(),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSwapLocations() {
    final tempText = _originTextController.text;
    _originTextController.text = _destinationTextController.text;
    _destinationTextController.text = tempText;
    _controller.swapLocations();
  }

  Future<void> _handleUseCurrentLocation() async {
    try {
      final location = await _controller.getCurrentLocationAddress();
      _originTextController.text = location.name;
      _controller.setOriginLocation(location);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage ?? 'Failed to get location'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleOpenMapPicker(bool isOrigin) async {
    final initialLocation = isOrigin
        ? _controller.originLatLng
        : (_controller.destinationLatLng ?? _controller.originLatLng);
    final title = isOrigin ? 'Select Origin' : 'Select Destination';

    final LatLng? selectedLatLng = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MapPickerScreen(initialLocation: initialLocation, title: title),
      ),
    );

    if (selectedLatLng != null) {
      await _processMapPickerResult(selectedLatLng, isOrigin);
    }
  }

  Future<void> _processMapPickerResult(LatLng latLng, bool isOrigin) async {
    try {
      final location = await _controller.getAddressFromLatLng(
        latLng.latitude,
        latLng.longitude,
      );

      if (mounted) {
        if (isOrigin) {
          _originTextController.text = location.name;
          _controller.setOriginLocation(location);
        } else {
          _destinationTextController.text = location.name;
          _controller.setDestinationLocation(location);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_controller.errorMessage ?? 'Failed to get address'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _showPassengerBottomSheet() async {
    await PassengerBottomSheet.show(
      context: context,
      initialRegular: _controller.regularPassengers,
      initialDiscounted: _controller.discountedPassengers,
      onApply: _controller.updatePassengers,
    );
  }

  Future<void> _handleSaveRoute() async {
    await _controller.saveRoute();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.routeSavedMessage),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
