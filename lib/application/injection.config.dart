// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:shared_preferences/shared_preferences.dart' as _i3;

import '../data/helpers/db_helper.dart' as _i6;
import '../data/helpers/opencv_helper.dart' as _i7;
import '../presentation/providers/image_project_provider.dart' as _i5;
import '../presentation/providers/projects_provider.dart' as _i8;
import '../presentation/providers/video_project_provider.dart' as _i4;
import 'module.dart' as _i9;

extension GetItInjectableX on _i1.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i1.GetIt> init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final appModule = _$AppModule();
    await gh.factoryAsync<_i3.SharedPreferences>(
      () => appModule.provideSharedPreferences(),
      preResolve: true,
    );
    gh.factory<_i4.VideoProjectProvider>(() => _i4.VideoProjectProvider());
    gh.factory<_i5.ImageProjectProvider>(() => _i5.ImageProjectProvider());
    gh.singleton<_i6.DBHelper>(() => _i6.DBHelper());
    gh.singleton<_i7.OpenCVHelper>(() => _i7.OpenCVHelper());
    gh.singleton<_i8.ProjectsProvider>(() => _i8.ProjectsProvider());
    return this;
  }
}

class _$AppModule extends _i9.AppModule {}
