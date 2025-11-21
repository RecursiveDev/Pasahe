import 'package:hive/hive.dart';
import '../models/fare_formula.dart';
import '../models/saved_route.dart';

class FareCacheService {
  static const String _formulaBoxName = 'fareFormulas';
  static const String _savedRoutesBoxName = 'savedRoutes';

  /// Opens the Hive box for FareFormula
  Future<Box<FareFormula>> openFormulaBox() async {
    return await Hive.openBox<FareFormula>(_formulaBoxName);
  }

  /// Opens the Hive box for SavedRoute
  Future<Box<SavedRoute>> openSavedRoutesBox() async {
    return await Hive.openBox<SavedRoute>(_savedRoutesBoxName);
  }

  /// Seeds the box with default data if it's empty or forced
  Future<void> seedDefaults({bool force = false}) async {
    final box = await openFormulaBox();
    if (box.isEmpty || force) {
      if (force) await box.clear();
      final defaultFormulas = [
        FareFormula(
          mode: 'Jeepney',
          subType: 'Traditional',
          baseFare: 14.00,
          perKmRate: 1.75,
          provincialMultiplier: 1.20,
          notes: 'Standard formula',
        ),
        FareFormula(
          mode: 'Taxi',
          subType: 'White (Regular)',
          baseFare: 45.00,
          perKmRate: 13.50,
          notes: 'Regular Taxi',
        ),
        FareFormula(
          mode: 'Taxi',
          subType: 'Yellow (Airport)',
          baseFare: 75.00,
          perKmRate: 20.00,
          notes: 'Airport Taxi',
        ),
      ];
      await box.addAll(defaultFormulas);
    }
  }

  /// Retrieves all FareFormula objects from the box
  Future<List<FareFormula>> getAllFormulas() async {
    final box = await openFormulaBox();
    return box.values.toList();
  }

  /// Saves a list of FareFormula objects to the box, replacing existing ones
  Future<void> saveFormulas(List<FareFormula> formulas) async {
    final box = await openFormulaBox();
    await box.clear();
    await box.addAll(formulas);
  }

  /// Saves a route to history
  Future<void> saveRoute(SavedRoute route) async {
    final box = await openSavedRoutesBox();
    await box.add(route);
  }

  /// Retrieves all saved routes
  Future<List<SavedRoute>> getSavedRoutes() async {
    final box = await openSavedRoutesBox();
    return box.values.toList().reversed.toList(); // Show newest first
  }

  /// Deletes a saved route
  Future<void> deleteRoute(SavedRoute route) async {
    await route.delete();
  }
}
