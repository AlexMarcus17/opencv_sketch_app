import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:sketch/presentation/screens/menu_screen.dart';
import 'package:sketch/data/helpers/db_helper.dart';
import 'package:sketch/presentation/providers/projects_provider.dart';
import 'package:sketch/application/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await configureDependencies();
  await DBHelper.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => getIt<ProjectsProvider>(),
      child: const OverlaySupport.global(
        child: CupertinoApp(
          home: MenuScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
