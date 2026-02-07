import 'dart:async';

import 'package:coffee_vending/allImports.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../helper/colors.dart';
import '../../../helper/customtext.dart';
import '../../../helper/size_config.dart';
import '../../../main.dart';

class Cleaningscreen extends StatefulWidget {
  const Cleaningscreen({super.key});

  @override
  State<Cleaningscreen> createState() => _CleaningscreenState();
}

class _CleaningscreenState extends State<Cleaningscreen> {
  int _remainingSeconds = 15;
  Timer? _timer;
  Timer? _checkTimer;
  Timer? _clockTimer;
  String _currentTime = '';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
    _updateDateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
  }

  void _updateDateTime() {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm:ss').format(now);
        _currentDate = DateFormat('EEEE, MMM d, yyyy').format(now);
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ScreenSaverWrapper()),
        );
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Cleaning.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.all(50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 45),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CustomText(
                      text: _currentDate,
                      size: SizeConfig.subText,
                      color: const Color(0xFFE74C3C).withOpacity(0.85),
                      weight: FontWeight.w400,
                    ),
                  ],
                ),
                const Gap(20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomText(
                      text: 'GEMINI',
                      size: SizeConfig.bigText! * 2.2,
                      color: destructiveColor,
                      weight: FontWeight.bold,
                      letterSpacing: 2.0,
                      fontFamily: 'Amaranth',
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      text: 'COFFEE',
                      size: SizeConfig.bigText! * 2.2,
                      color: destructiveColor,
                      weight: FontWeight.bold,
                      letterSpacing: 2.0,
                      fontFamily: 'Amaranth',
                    ),
                  ],
                ),
                const Gap(50),
                const Row(
                  children: [
                    SizedBox(width: 20),
                    Text(
                      'Cleaning in process',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}