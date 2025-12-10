// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../repositories/fare_repository.dart' as _i68;
import '../../services/connectivity/connectivity_service.dart' as _i831;
import '../../services/fare_comparison_service.dart' as _i758;
import '../../services/geocoding/geocoding_service.dart' as _i639;
import '../../services/offline/offline_map_service.dart' as _i805;
import '../../services/routing/haversine_routing_service.dart' as _i838;
import '../../services/routing/osrm_routing_service.dart' as _i570;
import '../../services/routing/route_cache_service.dart' as _i1015;
import '../../services/routing/routing_service.dart' as _i67;
import '../../services/routing/routing_service_manager.dart' as _i589;
import '../../services/settings_service.dart' as _i583;
import '../../services/transport_mode_filter_service.dart' as _i263;
import '../hybrid_engine.dart' as _i210;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i68.FareRepository>(() => _i68.FareRepository());
    gh.singleton<_i583.SettingsService>(() => _i583.SettingsService());
    gh.lazySingleton<_i831.ConnectivityService>(
      () => _i831.ConnectivityService(),
    );
    gh.lazySingleton<_i838.HaversineRoutingService>(
      () => _i838.HaversineRoutingService(),
    );
    gh.lazySingleton<_i570.OsrmRoutingService>(
      () => _i570.OsrmRoutingService(),
    );
    gh.lazySingleton<_i1015.RouteCacheService>(
      () => _i1015.RouteCacheService(),
    );
    gh.lazySingleton<_i263.TransportModeFilterService>(
      () => _i263.TransportModeFilterService(),
    );
    gh.lazySingleton<_i639.GeocodingService>(
      () => _i639.OpenStreetMapGeocodingService(),
    );
    gh.lazySingleton<_i67.RoutingService>(
      () => _i589.RoutingServiceManager(
        gh<_i570.OsrmRoutingService>(),
        gh<_i838.HaversineRoutingService>(),
        gh<_i1015.RouteCacheService>(),
        gh<_i831.ConnectivityService>(),
      ),
    );
    gh.lazySingleton<_i758.FareComparisonService>(
      () => _i758.FareComparisonService(gh<_i263.TransportModeFilterService>()),
    );
    gh.lazySingleton<_i805.OfflineMapService>(
      () => _i805.OfflineMapService(gh<_i831.ConnectivityService>()),
    );
    gh.lazySingleton<_i210.HybridEngine>(
      () => _i210.HybridEngine(
        gh<_i67.RoutingService>(),
        gh<_i583.SettingsService>(),
      ),
    );
    return this;
  }
}
