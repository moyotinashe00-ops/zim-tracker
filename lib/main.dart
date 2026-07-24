import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:zim_tracker/theme/volt_theme.dart';
import 'package:zim_tracker/theme/theme_controller.dart';
import 'package:zim_tracker/viewmodels/home_view_model.dart';
import 'package:zim_tracker/repositories/grid_repository.dart';
import 'package:zim_tracker/screens/main_layout.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => GridRepository()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: const ZimTrackerApp(),
    ),
  );
}

class ZimTrackerApp extends StatelessWidget {
  const ZimTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watching ThemeController here is what makes the toggle actually take
    // effect -- VoltTheme.theme is a plain getter, not itself reactive, so
    // something needs to trigger a rebuild when the flag flips. This is
    // the one place that happens.
    context.watch<ThemeController>();
    return MaterialApp(
      title: 'Volt Grid Intelligence',
      debugShowCheckedModeBanner: false,
      theme: VoltTheme.theme,
      home: const MainLayout(),
    );
  }
}
