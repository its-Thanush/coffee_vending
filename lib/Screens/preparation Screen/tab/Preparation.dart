import 'dart:async';
import 'package:coffee_vending/allImports.dart';
import 'package:coffee_vending/helper/colors.dart';
import 'package:coffee_vending/helper/customtext.dart';
import 'package:coffee_vending/helper/size_config.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';

class Preparation extends StatefulWidget {
  final double coffeeTargetTemp;
  final double teaTargetTemp;
  final Function(double, double) getCurrentTemperatures;
  final VoidCallback onReady;

  const Preparation({
    super.key,
    required this.coffeeTargetTemp,
    required this.teaTargetTemp,
    required this.getCurrentTemperatures,
    required this.onReady,
  });

  @override
  State<Preparation> createState() => _PreparationState();
}

class _PreparationState extends State<Preparation> {
  Timer? _checkTimer;
  Timer? _clockTimer;
  String _currentTime = '';
  String _currentDate = '';
  double _currentProgress = 0.0;
  String _statusText = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });

    _startTemperatureCheck();
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

  void _startTemperatureCheck() {
    _checkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final temps = widget.getCurrentTemperatures(
        widget.coffeeTargetTemp,
        widget.teaTargetTemp,
      );
      final coffeeTemp = temps.$1;
      final teaTemp = temps.$2;

      final coffeeProgress =
      (coffeeTemp / widget.coffeeTargetTemp).clamp(0.0, 1.0);
      final teaProgress = (teaTemp / widget.teaTargetTemp).clamp(0.0, 1.0);
      final totalProgress = (coffeeProgress + teaProgress) / 2;

      if (mounted) {
        setState(() {
          _currentProgress = totalProgress;

          if (totalProgress < 0.3) {
            _statusText = 'Heating brewing systems...';
          } else if (totalProgress < 0.6) {
            _statusText = 'Optimizing temperature...';
          } else if (totalProgress < 0.9) {
            _statusText = 'Almost ready...';
          } else {
            _statusText = 'System ready!';
          }
        });
      }

      if (coffeeTemp >= widget.coffeeTargetTemp &&
          teaTemp >= widget.teaTargetTemp) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            widget.onReady();
          }
        });
      }
    });
  }

  @override
  void dispose() {
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
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Loading.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomText(
                    text: _currentTime,
                    size: SizeConfig.medbigText,
                    color: const Color(0xFFE74C3C),
                    weight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    text: _currentDate,
                    size: SizeConfig.subText,
                    color: const Color(0xFFE74C3C).withOpacity(0.85),
                    weight: FontWeight.w400,
                  ),
                ],
              ),
            ),
            Positioned(
              right: screenWidth * 0.15,
              top: screenHeight * 0.35,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CustomText(
                    text: 'GEMINI',
                    size: SizeConfig.bigText! * 2.2,
                    color: const Color(0xFFE74C3C),
                    weight: FontWeight.bold,
                    letterSpacing: 2.0,
                    fontFamily: 'Amaranth',
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    text: 'COFFEE',
                    size: SizeConfig.bigText! * 2.2,
                    color: const Color(0xFFE74C3C),
                    weight: FontWeight.bold,
                    letterSpacing: 2.0,
                    fontFamily: 'Amaranth',
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: screenHeight * 0.22,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Column(
                  children: [
                    CustomText(
                      text: _statusText,
                      size: SizeConfig.smallTitleText,
                      color: Colors.white.withOpacity(0.95),
                      weight: FontWeight.w500,
                      letterSpacing: 0.8,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 17,
                      child: LiquidLinearProgressIndicator(
                        value: _currentProgress,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFFF6B35),
                        ),
                        backgroundColor: const Color(0xFF6B4423).withOpacity(0.3),
                        borderColor: const Color(0xFFFF6B35).withOpacity(0.6),
                        borderWidth: 1.5,
                        borderRadius: 8.0,
                        direction: Axis.horizontal,
                        center: CustomText(
                          text: '${(_currentProgress * 100).toInt()}%',
                          size: 11,
                          color: Colors.white,
                          weight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}