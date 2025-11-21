import 'package:flutter/material.dart';

class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Static Cheat Sheets'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          _SectionHeader(title: 'Taxi Meter Guide'),
          _TaxiGuide(),
          SizedBox(height: 24.0),
          _SectionHeader(title: 'LRT Station Matrix'),
          _LrtMatrix(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
      ),
    );
  }
}

class _TaxiGuide extends StatelessWidget {
  const _TaxiGuide();

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FareRow(
              mode: 'White Taxi (Regular)',
              base: '₱45.00',
              rate: '₱13.50/km',
              note: 'Standard city taxi.',
            ),
            Divider(),
            _FareRow(
              mode: 'Yellow Taxi (Airport)',
              base: '₱75.00',
              rate: '₱20.00/km',
              note: 'Airport usage only. Higher rates.',
            ),
          ],
        ),
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  final String mode;
  final String base;
  final String rate;
  final String note;

  const _FareRow({
    required this.mode,
    required this.base,
    required this.rate,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mode, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Flagdown: $base'),
            const SizedBox(width: 16),
            Text('Rate: $rate'),
          ],
        ),
        const SizedBox(height: 4),
        Text(note, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
      ],
    );
  }
}

class _LrtMatrix extends StatelessWidget {
  const _LrtMatrix();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maximum Fares (End-to-End)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _MatrixRow(line: 'MRT-3', route: 'North Ave - Taft', price: '₱28.00'),
            _MatrixRow(line: 'LRT-1', route: 'Baclaran - FPJ (Roosevelt)', price: '₱35.00'),
            _MatrixRow(line: 'LRT-2', route: 'Antipolo - Recto', price: '₱25.00'),
          ],
        ),
      ),
    );
  }
}

class _MatrixRow extends StatelessWidget {
  final String line;
  final String route;
  final String price;

  const _MatrixRow({
    required this.line,
    required this.route,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(line, style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(route, overflow: TextOverflow.ellipsis),
            ),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}