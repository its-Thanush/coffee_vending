import 'dart:async';
import 'package:coffee_vending/Screens/MainScreen/bloc/main_screen_bloc.dart';
import 'package:coffee_vending/Screens/ScreenSaverT/tab/ScreenSaverT.dart';
import 'package:coffee_vending/Screens/preparation%20Screen/tab/Preparation.dart';
import 'package:coffee_vending/allImports.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  double _currentCoffeeTemp = 20.0;
  double _currentTeaTemp = 20.0;
  Timer? _tempSimulator;

  final double coffeeTargetTemp = 95.0;
  final double teaTargetTemp = 85.0;

  @override
  void initState() {
    super.initState();
    _initializeHeating();
  }

  void _initializeHeating() {
    _tempSimulator = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          if (_currentCoffeeTemp < coffeeTargetTemp) {
            _currentCoffeeTemp += 0.5;
          }
          if (_currentTeaTemp < teaTargetTemp) {
            _currentTeaTemp += 0.4;
          }
        });
      }
    });
  }

  (double, double) _getCurrentTemperatures(double coffeeTarget, double teaTarget) {
    return (_currentCoffeeTemp, _currentTeaTemp);
  }

  void _onSystemReady() {
    _tempSimulator?.cancel();
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  void dispose() {
    _tempSimulator?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Preparation(
        coffeeTargetTemp: coffeeTargetTemp,
        teaTargetTemp: teaTargetTemp,
        getCurrentTemperatures: _getCurrentTemperatures,
        onReady: _onSystemReady,
      );
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

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 1), () {
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