import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ph_fare_calculator/src/core/di/injection.dart';

import '../../models/saved_route.dart';
import '../../repositories/fare_repository.dart';
import '../widgets/fare_result_card.dart';

class SavedRoutesScreen extends StatefulWidget {
  final FareRepository? fareRepository;

  const SavedRoutesScreen({super.key, this.fareRepository});

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  late final FareRepository _fareRepository;
  List<SavedRoute> _savedRoutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fareRepository = widget.fareRepository ?? getIt<FareRepository>();
    _loadSavedRoutes();
  }

  Future<void> _loadSavedRoutes() async {
    final routes = await _fareRepository.getSavedRoutes();
    if (mounted) {
      setState(() {
        _savedRoutes = routes;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRoute(SavedRoute route) async {
    await _fareRepository.deleteRoute(route);
    _loadSavedRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Routes')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedRoutes.isEmpty
          ? const Center(child: Text('No saved routes yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _savedRoutes.length,
              itemBuilder: (context, index) {
                final route = _savedRoutes[index];
                return _buildRouteCard(route);
              },
            ),
    );
  }

  Widget _buildRouteCard(SavedRoute route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${route.origin} to ${route.destination}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMd().add_jm().format(route.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteRoute(route),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: route.fareResults.map((result) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: FareResultCard(
                    transportMode: result.transportMode,
                    fare: result.fare,
                    indicatorLevel: result.indicatorLevel,
                    passengerCount: result.passengerCount,
                    totalFare: result.totalFare,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
