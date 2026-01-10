import 'dart:async';
import 'package:coffee_vending/Screens/MainScreen/bloc/main_screen_bloc.dart';
import 'package:coffee_vending/Screens/ScreenSaverT/tab/ScreenSaverT.dart';
import 'package:coffee_vending/allImports.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screen_brightness/screen_brightness.dart';


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


  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MainScreenBloc>(
      create: (_) => MainScreenBloc(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          brightness: Brightness.light,
        ),
        home: ScreenSaverWrapper(),
      ),
    );
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
      setState(() {
        _showScreenSaver = true;
      });
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