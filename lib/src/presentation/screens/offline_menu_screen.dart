import 'package:flutter/material.dart';
import 'reference_screen.dart';
import 'saved_routes_screen.dart';

class OfflineMenuScreen extends StatelessWidget {
  const OfflineMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Reference'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildMenuCard(
            context,
            title: 'Saved Routes',
            icon: Icons.bookmark,
            description: 'View your saved fare estimates offline.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedRoutesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16.0),
          _buildMenuCard(
            context,
            title: 'Static Cheat Sheets',
            icon: Icons.table_chart,
            description: 'View fare matrices for Trains, Taxis, and more.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReferenceScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40.0, color: Theme.of(context).primaryColor),
              const SizedBox(width: 20.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}