import 'dart:async';

import 'package:coffee_vending/allImports.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../helper/colors.dart';
import '../../../helper/customtext.dart';
import '../../../helper/size_config.dart';
import '../../../main.dart';
import '../../../Widgets/SerialCommunication.dart';

class Cleaningscreen extends StatefulWidget {
  final int cleanTiming;
  final String cleaningType; // 'Tea', 'Coffee', 'Milk', 'All'
  final int valveOnTime;
  final int pumpOnTime;
  final int pumpSpeed;

  const Cleaningscreen({
    required this.cleanTiming,
    required this.cleaningType,
    required this.valveOnTime,
    required this.pumpOnTime,
    required this.pumpSpeed,
    super.key,
  });

  @override
  State<Cleaningscreen> createState() => _CleaningscreenState();
}

class _CleaningscreenState extends State<Cleaningscreen> {
  late int _remainingSeconds = widget.cleanTiming;
  Timer? _timer;
  Timer? _checkTimer;
  Timer? _clockTimer;
  String _currentTime = '';
  String _currentDate = '';
  bool _isStopped = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _updateDateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
    _runCleaningSequence();
  }

  Future<void> _safeDelay(int seconds) async {
    for (int i = 0; i < seconds * 10; i++) {
      if (_isStopped) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _runCleaningSequence() async {
    if (widget.cleaningType == 'Tea') {
      await SerialService().sendJsonData({"TBV": "1"});
      if (_isStopped) return;
      await _safeDelay(widget.valveOnTime);
      if (_isStopped) return;
      await SerialService().sendJsonData({"TBV": "0"});
      if (_isStopped) return;
      await SerialService().sendJsonData({
        "TP_FWD": "${widget.pumpSpeed}",
        "TP_REV": "0",
      });
      if (_isStopped) return;
      await _safeDelay(widget.pumpOnTime);
      if (_isStopped) return;
      await SerialService().sendJsonData({
        "TP_FWD": "0",
        "TP_REV": "0",
      });
    } else if (widget.cleaningType == 'Coffee') {
      await SerialService().sendJsonData({"CBV": "1"});
      if (_isStopped) return;
      await _safeDelay(widget.valveOnTime);
      if (_isStopped) return;
      await SerialService().sendJsonData({"CBV": "0"});
      if (_isStopped) return;
      await SerialService().sendJsonData({
        "CP_FWD": "${widget.pumpSpeed}",
        "CP_REV": "0",
      });
      if (_isStopped) return;
      await _safeDelay(widget.pumpOnTime);
      if (_isStopped) return;
      await SerialService().sendJsonData({
        "CP_FWD": "0",
        "CP_REV": "0",
      });
    } else if (widget.cleaningType == 'Milk') {
      await SerialService().sendJsonData({
        "MAV": "1",
        "MP_FWD": "${widget.pumpSpeed}",
      });
      if (_isStopped) return;
      await _safeDelay(widget.pumpOnTime);
      if (_isStopped) return;
      await SerialService().sendJsonData({
        "MAV": "0",
        "MP_FWD": "0",
      });
    }
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
        if (!_isStopped) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        _timer?.cancel();
        if (!_isStopped) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ScreenSaverWrapper()),
          );
        }
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _stopCleaning() async {
    setState(() {
      _isStopped = true;
    });
    _timer?.cancel();
    _checkTimer?.cancel();
    _clockTimer?.cancel();

    await SerialService().sendJsonData({
      "CP_FWD": "0",
      "CP_REV": "0",
      "MAV": "0",
      "MP_FWD": "0",
      "MP_REV": "0",
      "MHWV": "0",
      "TP_FWD": "0",
      "TP_REV": "0",
      "HWV": "0",
      "TBV": "0",
      "CBV": "0"
    });

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ScreenSaverWrapper()),
      );
    }
  }

  @override
  void dispose() {
    _isStopped = true;
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
                const SizedBox(height: 25),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _stopCleaning,
                    label: const Text(
                      'Stop Cleaning',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
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
