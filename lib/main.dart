import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunu_task/core/theme/app_theme.dart';
import 'package:sunu_task/providers/app_provider.dart';
import 'package:sunu_task/providers/auth_provider.dart';
import 'package:sunu_task/providers/project_provider.dart';
import 'package:sunu_task/providers/task_provider.dart';
import 'package:sunu_task/screens/splash/splash_screen.dart';
import 'package:sunu_task/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.instance.init();

  runApp(const SunuTask());
}

class SunuTask extends StatelessWidget {
  const SunuTask({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: MaterialApp(
        title: 'Sunu Task',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
