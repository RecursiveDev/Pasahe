import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../models/map_region.dart';
import '../../services/offline/offline_map_service.dart';

/// Screen for managing offline map region downloads.
///
/// Displays a list of available regions with download status,
/// progress indicators, and storage usage information.
class RegionDownloadScreen extends StatefulWidget {
  const RegionDownloadScreen({super.key});

  @override
  State<RegionDownloadScreen> createState() => _RegionDownloadScreenState();
}

class _RegionDownloadScreenState extends State<RegionDownloadScreen> {
  late final OfflineMapService _offlineMapService;
  StreamSubscription<RegionDownloadProgress>? _progressSubscription;
  StorageInfo? _storageInfo;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _offlineMapService = getIt<OfflineMapService>();
    _initializeService();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeService() async {
    try {
      await _offlineMapService.initialize();
      await _loadStorageInfo();
      _listenToProgress();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize offline maps: $e';
      });
    }
  }

  Future<void> _loadStorageInfo() async {
    try {
      final info = await _offlineMapService.getStorageUsage();
      setState(() => _storageInfo = info);
    } catch (e) {
      // Ignore storage info errors
    }
  }

  void _listenToProgress() {
    _progressSubscription = _offlineMapService.progressStream.listen((
      progress,
    ) {
      if (!mounted) return;
      setState(() {});
      if (progress.isComplete) {
        _loadStorageInfo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${progress.region.name} downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (progress.hasError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed: ${progress.errorMessage}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    });
  }

  Future<void> _downloadRegion(MapRegion region) async {
    await for (final _ in _offlineMapService.downloadRegion(region)) {
      // Progress updates handled by stream listener
    }
  }

  Future<void> _deleteRegion(MapRegion region) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${region.name}?'),
        content: const Text(
          'You will need internet to view this map area again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _offlineMapService.deleteRegion(region);
      await _loadStorageInfo();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${region.name} deleted')));
      }
    }
  }

  Future<void> _cancelDownload() async {
    await _offlineMapService.cancelDownload();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Maps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState(colorScheme)
          : _buildContent(theme, colorScheme),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.error),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializeService();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme colorScheme) {
    return CustomScrollView(
      slivers: [
        // Storage summary header
        SliverToBoxAdapter(child: _buildStorageHeader(theme, colorScheme)),
        // Region list
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final region = PredefinedRegions.all[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRegionCard(theme, colorScheme, region),
              );
            }, childCount: PredefinedRegions.all.length),
          ),
        ),
        // Bottom info
        SliverToBoxAdapter(child: _buildInfoSection(theme, colorScheme)),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildStorageHeader(ThemeData theme, ColorScheme colorScheme) {
    final mapCacheFormatted = _storageInfo?.mapCacheFormatted ?? '0 KB';
    final availableFormatted = _storageInfo?.availableFormatted ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Storage',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _storageInfo?.usedPercentage ?? 0,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerLow,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Map cache: $mapCacheFormatted • Free: $availableFormatted',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard(
    ThemeData theme,
    ColorScheme colorScheme,
    MapRegion region,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Map thumbnail placeholder
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.map, size: 32, color: colorScheme.primary),
                ),
                const SizedBox(width: 16),
                // Region info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        region.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        region.status == DownloadStatus.downloading
                            ? 'Downloading... ${(region.downloadProgress * 100).toInt()}%'
                            : 'Est. ${region.estimatedSizeMB} MB',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (region.lastUpdated != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Updated ${_formatDate(region.lastUpdated!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Action button
                _buildActionButton(colorScheme, region),
              ],
            ),
            // Download progress bar
            if (region.status == DownloadStatus.downloading) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: region.downloadProgress,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerLow,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
            ],
            // Error message
            if (region.status == DownloadStatus.error &&
                region.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        region.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(ColorScheme colorScheme, MapRegion region) {
    switch (region.status) {
      case DownloadStatus.notDownloaded:
      case DownloadStatus.error:
        return Semantics(
          label:
              'Download ${region.name} map, ${region.estimatedSizeMB} megabytes',
          button: true,
          child: IconButton(
            icon: Icon(Icons.download, color: colorScheme.primary),
            onPressed: () => _downloadRegion(region),
            tooltip: 'Download',
          ),
        );
      case DownloadStatus.downloading:
        return Semantics(
          label: 'Cancel download',
          button: true,
          child: IconButton(
            icon: Icon(Icons.close, color: colorScheme.error),
            onPressed: _cancelDownload,
            tooltip: 'Cancel',
          ),
        );
      case DownloadStatus.downloaded:
      case DownloadStatus.updateAvailable:
        return PopupMenuButton<String>(
          icon: Icon(Icons.check_circle, color: Colors.green),
          tooltip: 'Options',
          onSelected: (value) {
            if (value == 'delete') {
              _deleteRegion(region);
            } else if (value == 'update') {
              _downloadRegion(region);
            }
          },
          itemBuilder: (context) => [
            if (region.status == DownloadStatus.updateAvailable)
              const PopupMenuItem(
                value: 'update',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Update'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  const Text('Delete'),
                ],
              ),
            ),
          ],
        );
      case DownloadStatus.paused:
        return IconButton(
          icon: Icon(Icons.play_arrow, color: colorScheme.primary),
          onPressed: () => _downloadRegion(region),
          tooltip: 'Resume',
        );
    }
  }

  Widget _buildInfoSection(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Downloaded maps are available offline. Delete to free up space.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Maps'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Download map regions to use the app without internet.'),
              SizedBox(height: 16),
              Text(
                '• Tap the download icon to save a region',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '• Downloaded maps show a green checkmark',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '• Tap the checkmark for delete options',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Note: Route calculations still require internet. '
                'Only map tiles are cached.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
