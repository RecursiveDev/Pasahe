// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../presentation/controllers/main_screen_controller.dart' as _i434;
import '../../repositories/fare_repository.dart' as _i68;
import '../../repositories/region_repository.dart' as _i1024;
import '../../repositories/routing_repository.dart' as _i925;
import '../../services/connectivity/connectivity_service.dart' as _i831;
import '../../services/fare_comparison_service.dart' as _i758;
import '../../services/geocoding/geocoding_cache_service.dart' as _i190;
import '../../services/geocoding/geocoding_service.dart' as _i639;
import '../../services/offline/offline_map_service.dart' as _i805;
import '../../services/offline/offline_mode_service.dart' as _i518;
import '../../services/routing/haversine_routing_service.dart' as _i838;
import '../../services/routing/osrm_routing_service.dart' as _i570;
import '../../services/routing/route_cache_service.dart' as _i1015;
import '../../services/routing/routing_service.dart' as _i67;
import '../../services/routing/routing_service_manager.dart' as _i589;
import '../../services/routing/train_ferry_graph_service.dart' as _i20;
import '../../services/settings_service.dart' as _i583;
import '../../services/transport_mode_filter_service.dart' as _i263;
import '../hybrid_engine.dart' as _i210;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.singleton<_i68.FareRepository>(() => _i68.FareRepository());
    gh.singleton<_i583.SettingsService>(() => _i583.SettingsService());
    gh.lazySingleton<_i1024.RegionRepository>(() => _i1024.RegionRepository());
    gh.lazySingleton<_i831.ConnectivityService>(
        () => _i831.ConnectivityService());
    gh.lazySingleton<_i1015.RouteCacheService>(
        () => _i1015.RouteCacheService());
    gh.lazySingleton<_i20.TrainFerryGraphService>(
        () => _i20.TrainFerryGraphService());
    gh.lazySingleton<_i263.TransportModeFilterService>(
        () => _i263.TransportModeFilterService());
    gh.lazySingleton<_i190.GeocodingCacheService>(
        () => _i190.GeocodingCacheService());
    gh.lazySingleton<_i67.RoutingService>(
      () => _i838.HaversineRoutingService(),
      instanceName: 'haversine',
    );
    gh.lazySingleton<_i67.RoutingService>(
      () => _i570.OsrmRoutingService(),
      instanceName: 'osrm',
    );
    gh.lazySingleton<_i805.OfflineMapService>(() => _i805.OfflineMapService(
          gh<_i831.ConnectivityService>(),
          gh<_i1024.RegionRepository>(),
        ));
    gh.lazySingleton<_i758.FareComparisonService>(() =>
        _i758.FareComparisonService(gh<_i263.TransportModeFilterService>()));
    gh.lazySingleton<_i518.OfflineModeService>(() => _i518.OfflineModeService(
          gh<_i831.ConnectivityService>(),
          gh<_i583.SettingsService>(),
          gh<_i805.OfflineMapService>(),
        ));
    gh.lazySingleton<_i639.GeocodingService>(
        () => _i639.OpenStreetMapGeocodingService(
              gh<_i190.GeocodingCacheService>(),
              gh<_i518.OfflineModeService>(),
            ));
    gh.lazySingleton<_i67.RoutingService>(() => _i589.RoutingServiceManager(
          gh<_i67.RoutingService>(instanceName: 'osrm'),
          gh<_i67.RoutingService>(instanceName: 'haversine'),
          gh<_i1015.RouteCacheService>(),
          gh<_i831.ConnectivityService>(),
        ));
    gh.lazySingleton<_i925.RoutingRepository>(() => _i925.RoutingRepository(
          gh<_i67.RoutingService>(instanceName: 'osrm'),
          gh<_i1015.RouteCacheService>(),
          gh<_i20.TrainFerryGraphService>(),
          gh<_i67.RoutingService>(instanceName: 'haversine'),
          gh<_i831.ConnectivityService>(),
          gh<_i518.OfflineModeService>(),
        ));
    gh.lazySingleton<_i210.HybridEngine>(() => _i210.HybridEngine(
          gh<_i925.RoutingRepository>(),
          gh<_i583.SettingsService>(),
        ));
    gh.lazySingleton<_i434.MainScreenController>(
        () => _i434.MainScreenController(
              gh<_i639.GeocodingService>(),
              gh<_i210.HybridEngine>(),
              gh<_i68.FareRepository>(),
              gh<_i925.RoutingRepository>(),
              gh<_i583.SettingsService>(),
              gh<_i758.FareComparisonService>(),
              gh<_i518.OfflineModeService>(),
            ));
    return this;
  }
}
