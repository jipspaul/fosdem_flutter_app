import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/api_constants.dart';
import '../services/notification_service.dart';
import '../../data/datasources/local/database.dart';
import '../../data/datasources/remote/fosdem_api.dart';
import '../../domain/repositories/events_repository.dart';
import '../../domain/repositories/tracks_repository.dart';
import '../../domain/repositories/favorites_repository.dart';
// import '../../domain/repositories/buildings_repository.dart';
import '../../data/repositories/events_repository_impl.dart';
import '../../data/repositories/tracks_repository_impl.dart';
import '../../data/repositories/favorites_repository_impl.dart';
// import '../../data/repositories/buildings_repository_impl.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/track_repository.dart';
import '../../data/repositories/data_sync_manager.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/xcal_parser_service.dart';
import '../../data/services/data_loading_service.dart';
import '../../data/services/event_scraper_service.dart';
import 'package:http/http.dart' as http;
import '../../domain/usecases/get_events_usecase.dart';
import '../../domain/usecases/search_events_usecase.dart';
import '../../domain/usecases/manage_favorites_usecase.dart';
import '../../domain/usecases/sync_data_usecase.dart';
import '../../presentation/bloc/events/events_bloc.dart';
import '../../presentation/bloc/favorites/favorites_bloc.dart';
import '../../presentation/bloc/theme/theme_bloc.dart';
import '../../presentation/bloc/sync/sync_bloc.dart';
import '../../presentation/bloc/settings/settings_bloc.dart';
import '../../presentation/bloc/event_detail/event_detail_bloc.dart';
import '../../presentation/bloc/speaker/speaker_bloc.dart';
import '../../presentation/bloc/track/track_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! External
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Connectivity
  sl.registerLazySingleton(() => Connectivity());

  // Dio
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: ApiConstants.defaultHeaders,
      ),
    );
    
    // Add logger interceptor in debug mode
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
      ),
    );
    
    return dio;
  });

  //! Core Services
  // Database
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  
  // Notification Service
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  
  // HTTP Client
  sl.registerLazySingleton<http.Client>(() => http.Client());
  
  // Event Scraper Service
  sl.registerLazySingleton<EventScraperService>(() => EventScraperService(sl()));

  //! Data Sources
  // Remote
  sl.registerLazySingleton<FosdemApi>(() => FosdemApi(sl()));

  //! Repositories
  sl.registerLazySingleton<EventRepository>(
    () => EventRepository(
      database: sl(),
      api: sl(),
    ),
  );

  sl.registerLazySingleton<TrackRepository>(
    () => TrackRepository(
      database: sl(),
      api: sl(),
    ),
  );

  sl.registerLazySingleton<EventsRepository>(
    () => EventsRepositoryImpl(
      database: sl(),
      api: sl(),
    ),
  );

  sl.registerLazySingleton<TracksRepository>(
    () => TracksRepositoryImpl(
      database: sl(),
      api: sl(),
    ),
  );

  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(
      prefs: sl(),
    ),
  );

  // sl.registerLazySingleton<BuildingsRepository>(
  //   () => BuildingsRepositoryImpl(
  //     database: sl(),
  //     api: sl(),
  //   ),
  // );

  //! Services
  // XCal Parser Service
  sl.registerLazySingleton<XCalParserService>(() => XCalParserService());

  // Data Loading Service
  sl.registerLazySingleton<DataLoadingService>(
    () => DataLoadingService(
      eventRepository: sl(),
      trackRepository: sl(),
      parserService: sl(),
      dio: sl(),
    ),
  );

  // Data Sync Manager
  sl.registerLazySingleton<DataSyncManager>(
    () => DataSyncManager(
      eventRepository: sl(),
    ),
  );
  
  // Settings Repository
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(sl()),
  );

  //! Use Cases
  sl.registerLazySingleton(() => GetEventsUseCase(sl()));
  sl.registerLazySingleton(() => SearchEventsUseCase(sl()));
  sl.registerLazySingleton(() => ManageFavoritesUseCase(sl()));
  sl.registerLazySingleton(() => SyncDataUseCase(sl()));

  //! BLoCs
  sl.registerFactory(() => EventsBloc(sl()));
  sl.registerFactory(() => FavoritesBloc(sl()));
  sl.registerFactory(() => EventDetailBloc(sl(), sl()));
  sl.registerFactory(() => ThemeBloc());
  sl.registerFactory(() => SyncBloc(sl()));
  sl.registerFactory(() => SettingsBloc(sl(), sl()));
  sl.registerFactory(() => SpeakerBloc(database: sl()));
  sl.registerFactory(() => TrackBloc(tracksRepository: sl()));
}
