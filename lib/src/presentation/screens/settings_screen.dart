import 'package:flutter/material.dart';
import '../../core/di/injection.dart';
import '../../l10n/app_localizations.dart';
import '../../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService? settingsService;

  const SettingsScreen({super.key, this.settingsService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsService _settingsService;
  bool _isProvincialModeEnabled = false;
  bool _isHighContrastEnabled = false;
  TrafficFactor _trafficFactor = TrafficFactor.medium;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _settingsService = widget.settingsService ?? getIt<SettingsService>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final provincialMode = await _settingsService.getProvincialMode();
    final trafficFactor = await _settingsService.getTrafficFactor();
    final highContrast = await _settingsService.getHighContrastEnabled();
    if (mounted) {
      setState(() {
        _isProvincialModeEnabled = provincialMode;
        _isHighContrastEnabled = highContrast;
        _trafficFactor = trafficFactor;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.provincialModeTitle),
                  subtitle: Text(AppLocalizations.of(context)!.provincialModeSubtitle),
                  value: _isProvincialModeEnabled,
                  onChanged: (bool value) async {
                    setState(() {
                      _isProvincialModeEnabled = value;
                    });
                    await _settingsService.setProvincialMode(value);
                  },
                ),
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.highContrastModeTitle),
                  subtitle: Text(AppLocalizations.of(context)!.highContrastModeSubtitle),
                  value: _isHighContrastEnabled,
                  onChanged: (bool value) async {
                    setState(() {
                      _isHighContrastEnabled = value;
                    });
                    await _settingsService.setHighContrastEnabled(value);
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.trafficFactorTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    AppLocalizations.of(context)!.trafficFactorSubtitle,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                RadioListTile<TrafficFactor>(
                  title: Text(AppLocalizations.of(context)!.trafficLow),
                  subtitle: Text(AppLocalizations.of(context)!.trafficLowSubtitle),
                  value: TrafficFactor.low,
                  groupValue: _trafficFactor,
                  onChanged: (TrafficFactor? value) async {
                    if (value != null) {
                      setState(() {
                        _trafficFactor = value;
                      });
                      await _settingsService.setTrafficFactor(value);
                    }
                  },
                ),
                RadioListTile<TrafficFactor>(
                  title: Text(AppLocalizations.of(context)!.trafficMedium),
                  subtitle: Text(AppLocalizations.of(context)!.trafficMediumSubtitle),
                  value: TrafficFactor.medium,
                  groupValue: _trafficFactor,
                  onChanged: (TrafficFactor? value) async {
                    if (value != null) {
                      setState(() {
                        _trafficFactor = value;
                      });
                      await _settingsService.setTrafficFactor(value);
                    }
                  },
                ),
                RadioListTile<TrafficFactor>(
                  title: Text(AppLocalizations.of(context)!.trafficHigh),
                  subtitle: Text(AppLocalizations.of(context)!.trafficHighSubtitle),
                  value: TrafficFactor.high,
                  groupValue: _trafficFactor,
                  onChanged: (TrafficFactor? value) async {
                    if (value != null) {
                      setState(() {
                        _trafficFactor = value;
                      });
                      await _settingsService.setTrafficFactor(value);
                    }
                  },
                ),
              ],
            ),
    );
  }
}