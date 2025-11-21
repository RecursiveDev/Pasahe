import 'package:flutter/material.dart';
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
    _settingsService = widget.settingsService ?? SettingsService();
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
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Provincial Mode'),
                  subtitle: const Text('Enable provincial fare rates'),
                  value: _isProvincialModeEnabled,
                  onChanged: (bool value) async {
                    setState(() {
                      _isProvincialModeEnabled = value;
                    });
                    await _settingsService.setProvincialMode(value);
                  },
                ),
                SwitchListTile(
                  title: const Text('High Contrast Mode'),
                  subtitle: const Text('Increase contrast for better visibility'),
                  value: _isHighContrastEnabled,
                  onChanged: (bool value) async {
                    setState(() {
                      _isHighContrastEnabled = value;
                    });
                    await _settingsService.setHighContrastEnabled(value);
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Traffic Factor',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Adjusts the fare calculation based on expected traffic conditions.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                RadioListTile<TrafficFactor>(
                  title: const Text('Low'),
                  subtitle: const Text('Light traffic'),
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
                  title: const Text('Medium'),
                  subtitle: const Text('Moderate traffic'),
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
                  title: const Text('High'),
                  subtitle: const Text('Heavy traffic'),
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