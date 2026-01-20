import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/injection_container.dart' as di;
import 'core/constants/app_constants.dart';
import 'core/services/notification_service.dart';
import 'presentation/bloc/bloc_observer.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/bloc/schedule/schedule_bloc.dart';
import 'presentation/bloc/favorites/favorites_bloc.dart';
import 'presentation/bloc/favorites/favorites_event.dart';
import 'presentation/screens/schedule_screen.dart';
import 'presentation/screens/favorites_screen.dart';
import 'presentation/screens/map_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'data/services/data_loading_service.dart';
import 'data/datasources/local/database.dart';
import 'features/filters/bloc/filter_bloc.dart';
import 'features/filters/services/filter_persistence_service.dart';
import 'features/journey/presentation/bloc/journey_bloc.dart';
import 'features/journey/presentation/bloc/journey_event.dart';
import 'features/journey/presentation/screens/my_journey_screen.dart';
import 'features/discovery/presentation/bloc/event_discovery_bloc.dart';
import 'features/discovery/presentation/bloc/event_discovery_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up BLoC observer for debugging
  Bloc.observer = AppBlocObserver();
  
  // Initialize dependency injection
  await di.init();
  
  // Initialize notification service
  final notificationService = di.sl<NotificationService>();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  
  // Load initial data from bundled xcal
  await _loadInitialData();
  
  runApp(const MyApp());
}

Future<void> _loadInitialData() async {
  try {
    print('🚀 Starting data initialization...');
    final dataLoadingService = di.sl<DataLoadingService>();
    final database = di.sl<AppDatabase>();
    final prefs = di.sl<SharedPreferences>();
    
    // Check if data has already been loaded
    final dbVersion = prefs.getInt('db_version');
    final hasData = await dataLoadingService.hasData();
    
    if (dbVersion == 5 && hasData) {
      print('✅ Data already loaded (version $dbVersion), skipping reload');
      final allEvents = await database.select(database.events).get();
      print('📊 Database has ${allEvents.length} events');
      return;
    }
    
    print('📥 Loading bundled xcal data...');
    
    // Clear old data only if upgrading or first load
    if (dbVersion != null && dbVersion < 5) {
      print('🔄 Upgrading database from version $dbVersion to 5...');
      await database.clearAllData();
    } else if (!hasData) {
      print('📦 First load - loading data...');
    }
    
    await dataLoadingService.loadBundledData();
    await prefs.setInt('db_version', 5);
    print('✅ Data loaded!');
    
    // Verify data was loaded
    print('🔍 Verifying data in database...');
    final allEvents = await database.select(database.events).get();
    print('📊 Total events in database: ${allEvents.length}');
    
    if (allEvents.isNotEmpty) {
      final firstEvent = allEvents.first;
      print('📋 First event: ${firstEvent.title}');
      print('🔗 First event URL: ${firstEvent.url ?? "NULL!"}');
      
      final eventsWithUrls = allEvents.where((e) => e.url != null && e.url!.isNotEmpty).length;
      final eventsWithoutUrls = allEvents.length - eventsWithUrls;
      print('✅ Events WITH URLs: $eventsWithUrls');
      print('❌ Events WITHOUT URLs: $eventsWithoutUrls');
      
      if (eventsWithoutUrls > 0) {
        print('⚠️  WARNING: Some events are missing URLs!');
      }
    }
  } catch (e, stackTrace) {
    print('❌ Error loading initial data: $e');
    print('Stack trace: $stackTrace');
    // Continue anyway - app will show empty state or user can load from URL
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ScheduleBloc(
            eventRepository: di.sl(),
          )..add(const LoadSchedule()),
        ),
        BlocProvider(
          create: (context) => FavoritesBloc(
            di.sl(),
          )..add(const LoadFavorites()),
        ),
        BlocProvider(
          create: (context) => FilterBloc(
            persistenceService: FilterPersistenceService(di.sl()),
            database: di.sl(),
          )..add(LoadSavedFilters()),
        ),
        BlocProvider(
          create: (context) => JourneyBloc(
            database: di.sl(),
            notificationService: NotificationService(),
          )..add(const LoadJourney()),
        ),
        BlocProvider(
          create: (context) {
            final favoritesBloc = context.read<FavoritesBloc>();
            return EventDiscoveryBloc(
              eventRepository: di.sl(),
              favoritesBloc: favoritesBloc,
            )..add(LoadNextEvent());
          },
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    ScheduleScreen(),
    FavoritesScreen(),
    MyJourneyScreen(),
    MapScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.route),
            label: 'Journey',
          ),
          NavigationDestination(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
