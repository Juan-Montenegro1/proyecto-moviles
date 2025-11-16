import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taller_flutter/features/tasks/presentation/pages/tasks_page.dart';
import 'package:taller_flutter/core/database/database_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar base de datos global
  try {
    await initializeDatabase();
  } catch (e) {
    debugPrint('Error initializing database: $e');
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Lista de Tareas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TasksPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
