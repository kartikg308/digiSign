import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// import 'screens/dashboard_screen.dart'; // No longer the initial screen
import 'screens/signatures_screen.dart';
import 'screens/file_upload_screen.dart'; // New screen for file uploading

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Disable error banner in debug mode
  if (kDebugMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Container(alignment: Alignment.center, child: Text('Error: ${details.exception}', style: const TextStyle(color: Colors.red)));
    };
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigiSign',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), filled: true),
        cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 3),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), textStyle: const TextStyle(fontSize: 16))),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), filled: true),
        cardTheme: CardTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 3),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), textStyle: const TextStyle(fontSize: 16))),
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/', // Changed to FileUploadScreen
      routes: {
        '/': (context) => const FileUploadScreen(), // New initial route
        // '/': (context) => const DashboardScreen(), // Old initial route, commented out
        '/signatures': (context) => const SignaturesScreen(),
      },
    );
  }
}

// MyHomePage and _MyHomePageState are no longer used and can be removed.
// ... existing code ...
