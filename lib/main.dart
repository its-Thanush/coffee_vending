import 'dart:async';
import 'package:coffee_vending/Screens/MainScreen/bloc/main_screen_bloc.dart';
import 'package:coffee_vending/Screens/ScreenSaverT/tab/ScreenSaverT.dart';
import 'package:coffee_vending/Screens/preparation%20Screen/tab/Preparation.dart';
import 'package:coffee_vending/allImports.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'LocalDatabase/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Isar local database
  await DatabaseHelper.instance.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MainScreenBloc>(
      create: (_) => MainScreenBloc(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Gemini Coffee',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          brightness: Brightness.light,
        ),
        home: const PreparationWrapper(),
      ),
    );
  }
}

class PreparationWrapper extends StatefulWidget {
  const PreparationWrapper({super.key});

  @override
  State<PreparationWrapper> createState() => _PreparationWrapperState();
}

class _PreparationWrapperState extends State<PreparationWrapper> {
  bool _isReady = false;

  void _onSystemReady() {
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Preparation(onReady: _onSystemReady);
    }
    return const ScreenSaverWrapper();
  }
}

class ScreenSaverWrapper extends StatefulWidget {
  const ScreenSaverWrapper({super.key});

  @override
  State<ScreenSaverWrapper> createState() => _ScreenSaverWrapperState();
}

class _ScreenSaverWrapperState extends State<ScreenSaverWrapper> {
  Timer? _inactivityTimer;
  bool _showScreenSaver = false;
  int _configDelay = 60;

  @override
  void initState() {
    super.initState();
    _loadConfigDelay();
  }

  Future<void> _loadConfigDelay() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _configDelay = prefs.getInt('configDelay')!;
    });
    _resetTimer();
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(seconds: _configDelay), () {
      if (mounted) {
        setState(() {
          _showScreenSaver = true;
        });
      }
    });
  }

  void _onUserInteraction() {
    if (_showScreenSaver) {
      setState(() {
        _showScreenSaver = false;
      });
    }
    _resetTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onUserInteraction,
      onPanDown: (_) => _onUserInteraction(),
      behavior: HitTestBehavior.translucent,
      child: _showScreenSaver ? ScreenSaver() : VendingMachineScreen(),
    );
  }
}
