import 'package:flutter/material.dart';

/// A bottom sheet widget for selecting passenger counts.
class PassengerBottomSheet extends StatefulWidget {
  final int initialRegular;
  final int initialDiscounted;
  final void Function(int regular, int discounted) onApply;

  const PassengerBottomSheet({
    super.key,
    required this.initialRegular,
    required this.initialDiscounted,
    required this.onApply,
  });

  /// Shows the passenger bottom sheet and returns the selected values.
  static Future<void> show({
    required BuildContext context,
    required int initialRegular,
    required int initialDiscounted,
    required void Function(int regular, int discounted) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => PassengerBottomSheet(
        initialRegular: initialRegular,
        initialDiscounted: initialDiscounted,
        onApply: onApply,
      ),
    );
  }

  @override
  State<PassengerBottomSheet> createState() => _PassengerBottomSheetState();
}

class _PassengerBottomSheetState extends State<PassengerBottomSheet> {
  late int _regular;
  late int _discounted;

  @override
  void initState() {
    super.initState();
    _regular = widget.initialRegular;
    _discounted = widget.initialDiscounted;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            'Passenger Details',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Regular Passengers
          _PassengerCounter(
            label: 'Regular Passengers',
            subtitle: 'Standard fare rate',
            count: _regular,
            onDecrement: _regular > 0 ? () => setState(() => _regular--) : null,
            onIncrement: _regular < 99
                ? () => setState(() => _regular++)
                : null,
          ),
          const SizedBox(height: 16),
          // Discounted Passengers
          _PassengerCounter(
            label: 'Discounted Passengers',
            subtitle: 'Student/Senior/PWD - 20% off',
            count: _discounted,
            onDecrement: _discounted > 0
                ? () => setState(() => _discounted--)
                : null,
            onIncrement: _discounted < 99
                ? () => setState(() => _discounted++)
                : null,
          ),
          const SizedBox(height: 24),
          // Total Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Total: ${_regular + _discounted} passenger(s)',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: (_regular + _discounted) > 0
                      ? () {
                          widget.onApply(_regular, _discounted);
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A reusable counter widget for passenger count selection.
class _PassengerCounter extends StatelessWidget {
  final String label;
  final String subtitle;
  final int count;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _PassengerCounter({
    required this.label,
    required this.subtitle,
    required this.count,
    this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Counter Controls
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.remove,
                    color: onDecrement != null
                        ? colorScheme.primary
                        : colorScheme.outline,
                    size: 20,
                  ),
                  onPressed: onDecrement,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: onIncrement != null
                        ? colorScheme.primary
                        : colorScheme.outline,
                    size: 20,
                  ),
                  onPressed: onIncrement,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
