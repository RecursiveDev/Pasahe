import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../models/fare_formula.dart';
import '../models/saved_route.dart';

@singleton
class FareRepository {
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

  /// Seeds the box with data from assets if it's empty or forced
  Future<void> seedDefaults({bool force = false}) async {
    final box = await openFormulaBox();
    if (box.isEmpty || force) {
      if (force) await box.clear();
      
      try {
        final String jsonString = await rootBundle.loadString('assets/data/fare_formulas.json');
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        final List<FareFormula> formulas = [];

        // Parse "road" formulas
        if (jsonMap.containsKey('road')) {
          final List<dynamic> roadList = jsonMap['road'];
          formulas.addAll(roadList.map((e) => FareFormula.fromJson(e)).toList());
        }

        // Add other modes here if/when they are added to the JSON

        await box.addAll(formulas);
      } catch (e) {
        // Fallback or rethrow depending on error handling strategy
        // For now, logging locally or doing nothing is acceptable if assets are guaranteed
        print('Error seeding default formulas: $e');
      }
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