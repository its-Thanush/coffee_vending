import 'dart:async';
import 'package:coffee_vending/allImports.dart';
import 'package:coffee_vending/helper/colors.dart';
import 'package:coffee_vending/helper/customtext.dart';
import 'package:coffee_vending/helper/size_config.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Widgets/SerialCommunication.dart';
import '../../adminLogin/tab/AdminScreenLoginT.dart';

class Preparation extends StatefulWidget {
  final VoidCallback onReady;

  const Preparation({
    super.key,
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
  double _targetTemp = 0.0;
  double _currentTemp = 0.0;
  String _currentTempString = "--";
  bool _tempError = false;
  Timer? _tempTimeoutTimer;
  String _floatLevel = "";
  bool _showWaterWarning = false;

  final SerialService serialService = SerialService();
  bool isNodeMCUOnline = false;
  Timer? connectionCheckTimer;


  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _loadTargetTemp();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateDateTime();
    });
    serialService.onTempReceived = (String temp) {
      print("=========Receving temp ========>"+temp);
      if (mounted) {
        setState(() {
          _currentTempString = temp;
          _currentTemp = double.tryParse(temp) ?? 0.0;
        });
      }
    };
    serialService.onFloatReceived = (String floatValue) {
      print("=========Receving FLOAT ========>"+floatValue.toString());
      if (mounted) {
        setState(() {
          _floatLevel = floatValue;
          _showWaterWarning = floatValue == "1";
        });
      }
      if (floatValue == "0") {
        print("---------------------heater ON --------------------------");
        _startTemperatureCheck();
      }
    };

    _initNodeMCUConnection();

    serialService.onConnectionChanged = (bool status) {
      if (mounted) {
        setState(() {
          isNodeMCUOnline = status;
        });
      }
    };

    // serialService.onTempReceived = (String temp) {
    //   setState(() {
    //     _currentTemp = temp as double;
    //     _tempError = false;
    //   });
    //   _resetTempTimeout();
    // };

    connectionCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkNodeMCUConnection();
    });
  }

  Future<void> _initNodeMCUConnection() async {
    bool connected = await serialService.connect();
    if (mounted) {
      setState(() {
        isNodeMCUOnline = connected;
      });
    }
  }

  Future<void> _checkNodeMCUConnection() async {
    bool connected = await serialService.checkConnection();
    if (connected != isNodeMCUOnline) {
      if (mounted) {
        setState(() {
          isNodeMCUOnline = connected;
        });
      }
    }
  }


  void _startTempTimeout() {
    _tempTimeoutTimer?.cancel();
    _tempTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _tempError = true;
          _currentTemp = 0.0;
        });
      }
    });
  }




  Future<void> _loadTargetTemp() async {
    final prefs = await SharedPreferences.getInstance();
    double coffeeTemp = prefs.getDouble('coffeeTemp') ?? 0.0;
    double teaTemp = prefs.getDouble('teaTemp') ?? 0.0;
    if (mounted) {
      setState(() {
        _targetTemp = coffeeTemp > teaTemp ? coffeeTemp : teaTemp;
      });
    }
  }

  void _startTemperatureCheck() {
    serialService.onTempReceived = (String temp) {
      if (mounted) {
        setState(() {
          _currentTempString = temp;
          _currentTemp = double.tryParse(temp) ?? 0.0;

        if (_floatLevel == "0" && _targetTemp > 0) {
          _currentProgress = (_currentTemp / _targetTemp).clamp(0.0, 1.0);

          if (_currentProgress < 0.3) {
            _statusText = 'Heating brewing systems...';
          } else if (_currentProgress < 0.6) {
            _statusText = 'Optimizing temperature...';
          } else if (_currentProgress < 0.9) {
            _statusText = 'Almost ready...';
          } else {
            _statusText = 'System ready!';
          }

          if (_currentTemp >= _targetTemp) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) widget.onReady();
            });
          } else {
            serialService.sendJsonData({"SETTEMP": _targetTemp});
          }
        }
      });
      }
    };
  }

  void _updateDateTime() {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm a').format(now);
        _currentDate = DateFormat('EEEE, MMM d, yyyy').format(now);
      });
    }
  }


  @override
  void dispose() {
    SerialService().onTempReceived = null;
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isNodeMCUOnline ? Colors.green : Colors.red,
                          boxShadow: [
                            BoxShadow(
                              color: (isNodeMCUOnline ? Colors.green : Colors
                                  .red)
                                  .withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      Gap(10),
                      IconButton(
                        splashRadius: 3,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => adminScreenLogin(),
                            ),
                          );
                        },
                        icon: Icon(Icons.admin_panel_settings,
                            color: Colors.brown.shade900),
                      ),
                    ],
                  ),
                  IconButton(
                    splashRadius: 3,
                    onPressed: () {
                      Future.delayed(const Duration(milliseconds: 800), () {
                        if (mounted) {
                          widget.onReady();
                        }
                      });
                    },
                    icon: Icon(Icons.arrow_forward_sharp,
                        color: Colors.brown.shade900),
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
                    size: SizeConfig.bigText! * 2.8,
                    color: destructiveColor,
                    weight: FontWeight.bold,
                    letterSpacing: 2.0,
                    fontFamily: 'Amaranth',
                  ),
                  const SizedBox(height: 4),
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
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: screenHeight * 0.22,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.11),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [

                        CustomText(
                          text: 'Current: $_currentTempString°C',
                          size: SizeConfig.smallTitleText,
                          color: destructiveColor.withOpacity(0.95),
                          weight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                        SizedBox(width: 20),
                        CustomText(
                          text: 'Target: ${_targetTemp.toInt()}°C',
                          size: SizeConfig.smallTitleText,
                          color: destructiveColor.withOpacity(0.95),
                          weight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                        SizedBox(width: 45),

                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomText(
                      text:  _showWaterWarning?'Water level is low':_statusText,
                      size: SizeConfig.smallTitleText,
                      color: _showWaterWarning?Colors.orange:Colors.white.withOpacity(0.95),
                      weight: _showWaterWarning?FontWeight.bold:FontWeight.w500,
                      letterSpacing: 0.8,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 17,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B4423).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: const Color(0xFFFF6B35).withOpacity(0.6),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.5),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: _currentProgress,
                              child: Container(
                                color: const Color(0xFFFF6B35),
                              ),
                            ),
                            Center(
                              child: CustomText(
                                text: '${(_currentProgress * 100).toInt()}%',
                                size: 11,
                                color: Colors.white,
                                weight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Positioned(
            //   left: 0,
            //   right: 0,
            //   bottom: screenHeight * 0.22,
            //   child: Padding(
            //     padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
            //     child: Column(
            //       children: [
            //         CustomText(
            //           text: _statusText,
            //           size: SizeConfig.smallTitleText,
            //           color: Colors.white.withOpacity(0.95),
            //           weight: FontWeight.w500,
            //           letterSpacing: 0.8,
            //           textAlign: TextAlign.center,
            //         ),
            //         const SizedBox(height: 24),
            //         Container(
            //           height: 17,
            //           decoration: BoxDecoration(
            //             color: const Color(0xFF6B4423).withOpacity(0.3),
            //             borderRadius: BorderRadius.circular(8.0),
            //             border: Border.all(
            //               color: const Color(0xFFFF6B35).withOpacity(0.6),
            //               width: 1.5,
            //             ),
            //           ),
            //           child: ClipRRect(
            //             borderRadius: BorderRadius.circular(6.5),
            //             child: Stack(
            //               children: [
            //                 FractionallySizedBox(
            //                   widthFactor: _currentProgress,
            //                   child: Container(
            //                     color: const Color(0xFFFF6B35),
            //                   ),
            //                 ),
            //                 Center(
            //                   child: CustomText(
            //                     text: '${(_currentProgress * 100).toInt()}%',
            //                     size: 11,
            //                     color: Colors.white,
            //                     weight: FontWeight.bold,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}