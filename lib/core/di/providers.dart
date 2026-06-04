import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/app_database.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/dhikr_repository_impl.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/dhikr_repository.dart';

/// Overridden in `main()` with the resolved instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences not initialised'),
);

final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => AppDatabase.instance,
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final dhikrRepositoryProvider = Provider<DhikrRepository>(
  (ref) => DhikrRepositoryImpl(ref.watch(appDatabaseProvider)),
);
