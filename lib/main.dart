import 'package:coffee_vending/allImports.dart';
import 'package:flutter/services.dart';
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


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        brightness: Brightness.light,
      ),
      home:  Mainscreen(),
    );
  }
}