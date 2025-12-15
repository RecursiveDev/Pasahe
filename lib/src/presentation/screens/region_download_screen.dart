import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../models/map_region.dart';
import '../../services/offline/offline_map_service.dart';

/// Screen for managing offline map region downloads.
///
/// Displays a hierarchical list of island groups and their child islands
/// with download status, progress indicators, and storage usage information.
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

  /// Island groups (parent regions)
  List<MapRegion> _islandGroups = [];

  /// Map of parent ID to child islands
  Map<String, List<MapRegion>> _islandsByGroup = {};

  /// Tracks which groups are expanded
  final Set<String> _expandedGroups = {};

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
      await _loadRegions();
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

  Future<void> _loadRegions() async {
    _islandGroups = await _offlineMapService.getIslandGroups();
    _islandsByGroup = {};
    for (final group in _islandGroups) {
      final islands = await _offlineMapService.getIslandsForGroup(group.id);
      _islandsByGroup[group.id] = islands;
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

  Future<void> _downloadIslandGroup(String groupId) async {
    try {
      await _offlineMapService.downloadIslandGroup(groupId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download group: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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

  Future<void> _deleteIslandGroup(String groupId) async {
    final group = _offlineMapService.getRegionById(groupId);
    if (group == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete all ${group.name} maps?'),
        content: const Text(
          'All downloaded islands in this group will be removed.',
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
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _offlineMapService.deleteIslandGroup(groupId);
      await _loadStorageInfo();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${group.name} maps deleted')));
      }
    }
  }

  Future<void> _cancelDownload() async {
    await _offlineMapService.cancelDownload();
    setState(() {});
  }

  void _toggleGroupExpansion(String groupId) {
    setState(() {
      if (_expandedGroups.contains(groupId)) {
        _expandedGroups.remove(groupId);
      } else {
        _expandedGroups.add(groupId);
      }
    });
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Offline Data?'),
        content: const Text(
          'Are you sure you want to delete all offline map data? '
          'You will need internet to view any map areas again.',
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
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _offlineMapService.clearAllTiles();
      await _loadRegions();
      await _loadStorageInfo();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All offline map data cleared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDownloading = _offlineMapService.isDownloading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Maps'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Options',
            onSelected: (value) {
              if (value == 'clear_all') {
                _clearAllData();
              } else if (value == 'help') {
                _showHelpDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_all',
                enabled: !isDownloading,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_sweep,
                      color: isDownloading
                          ? colorScheme.onSurface.withValues(alpha: 0.38)
                          : colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Clear All Data',
                      style: TextStyle(
                        color: isDownloading
                            ? colorScheme.onSurface.withValues(alpha: 0.38)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 8),
                    Text('Help'),
                  ],
                ),
              ),
            ],
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
        // Hierarchical region list
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final group = _islandGroups[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildIslandGroupCard(theme, colorScheme, group),
              );
            }, childCount: _islandGroups.length),
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

  Widget _buildIslandGroupCard(
    ThemeData theme,
    ColorScheme colorScheme,
    MapRegion group,
  ) {
    final isExpanded = _expandedGroups.contains(group.id);
    final islands = _islandsByGroup[group.id] ?? [];
    final downloadedCount = islands
        .where((i) => i.status.isAvailableOffline)
        .length;
    final totalSize = islands.fold<int>(0, (sum, i) => sum + i.estimatedSizeMB);

    // Determine group status based on children
    final allDownloaded =
        islands.isNotEmpty && islands.every((i) => i.status.isAvailableOffline);
    final anyDownloading = islands.any(
      (i) => i.status == DownloadStatus.downloading,
    );
    final partiallyDownloaded = downloadedCount > 0 && !allDownloaded;

    Color? cardBackground;
    if (allDownloaded) {
      cardBackground = Colors.green.withValues(alpha: 0.1);
    } else if (partiallyDownloaded) {
      cardBackground = colorScheme.primaryContainer.withValues(alpha: 0.3);
    }

    return Card(
      elevation: 0,
      color: cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Group header
          InkWell(
            onTap: () => _toggleGroupExpansion(group.id),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Expand/collapse icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Map thumbnail placeholder
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.map,
                      size: 24,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Group info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name.toUpperCase(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          anyDownloading
                              ? 'Downloading...'
                              : '${islands.length} islands • ~$totalSize MB total',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (downloadedCount > 0 && !allDownloaded) ...[
                          const SizedBox(height: 2),
                          Text(
                            '$downloadedCount/${islands.length} downloaded',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Group action button
                  _buildGroupActionButton(
                    colorScheme,
                    group,
                    allDownloaded,
                    anyDownloading,
                    partiallyDownloaded,
                  ),
                ],
              ),
            ),
          ),
          // Expanded island list
          if (isExpanded) ...[
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: islands.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final island = islands[index];
                return _buildIslandTile(theme, colorScheme, island);
              },
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupActionButton(
    ColorScheme colorScheme,
    MapRegion group,
    bool allDownloaded,
    bool anyDownloading,
    bool partiallyDownloaded,
  ) {
    if (anyDownloading) {
      return IconButton(
        icon: Icon(Icons.close, color: colorScheme.error),
        onPressed: _cancelDownload,
        tooltip: 'Cancel',
      );
    }

    if (allDownloaded) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.check_circle, color: Colors.green),
        tooltip: 'Options',
        onSelected: (value) {
          if (value == 'delete') {
            _deleteIslandGroup(group.id);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                const SizedBox(width: 8),
                const Text('Delete All'),
              ],
            ),
          ),
        ],
      );
    }

    return ElevatedButton(
      onPressed: () => _downloadIslandGroup(group.id),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(partiallyDownloaded ? 'Complete' : 'Download'),
    );
  }

  Widget _buildIslandTile(
    ThemeData theme,
    ColorScheme colorScheme,
    MapRegion island,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: island.status.isAvailableOffline
            ? Colors.green.withValues(alpha: 0.05)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Status icon
          _buildIslandStatusIcon(colorScheme, island),
          const SizedBox(width: 12),
          // Island info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  island.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (island.status == DownloadStatus.downloading) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: island.downloadProgress,
                            minHeight: 4,
                            backgroundColor: colorScheme.surfaceContainerLow,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(island.downloadProgress * 100).round()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    '~${island.estimatedSizeMB} MB',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Action button
          _buildIslandActionButton(colorScheme, island),
        ],
      ),
    );
  }

  Widget _buildIslandStatusIcon(ColorScheme colorScheme, MapRegion island) {
    switch (island.status) {
      case DownloadStatus.downloaded:
      case DownloadStatus.updateAvailable:
        return Icon(Icons.check_circle, color: Colors.green, size: 20);
      case DownloadStatus.downloading:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: island.downloadProgress,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        );
      case DownloadStatus.error:
        return Icon(Icons.error, color: colorScheme.error, size: 20);
      default:
        return Icon(
          Icons.radio_button_unchecked,
          color: colorScheme.onSurfaceVariant,
          size: 20,
        );
    }
  }

  Widget _buildIslandActionButton(ColorScheme colorScheme, MapRegion island) {
    switch (island.status) {
      case DownloadStatus.notDownloaded:
      case DownloadStatus.error:
        return IconButton(
          icon: Icon(Icons.download, color: colorScheme.primary, size: 20),
          onPressed: () => _downloadRegion(island),
          tooltip: 'Download',
          visualDensity: VisualDensity.compact,
        );
      case DownloadStatus.downloading:
        return IconButton(
          icon: Icon(Icons.close, color: colorScheme.error, size: 20),
          onPressed: _cancelDownload,
          tooltip: 'Cancel',
          visualDensity: VisualDensity.compact,
        );
      case DownloadStatus.downloaded:
      case DownloadStatus.updateAvailable:
        return IconButton(
          icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
          onPressed: () => _deleteRegion(island),
          tooltip: 'Delete',
          visualDensity: VisualDensity.compact,
        );
      case DownloadStatus.paused:
        return IconButton(
          icon: Icon(Icons.play_arrow, color: colorScheme.primary, size: 20),
          onPressed: () => _downloadRegion(island),
          tooltip: 'Resume',
          visualDensity: VisualDensity.compact,
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
                'Download individual islands or entire island groups. '
                'Tap a group to see available islands.',
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
                '• Tap an island group to expand and see individual islands',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '• Use "Download" to get all islands in a group at once',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '• Or download individual islands to save space',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '• Green checkmarks indicate downloaded areas',
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
}
