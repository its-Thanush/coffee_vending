import 'dart:convert';

import 'package:coffee_vending/Screens/MainScreen/bloc/main_screen_bloc.dart';
import 'package:coffee_vending/Screens/MainScreen/tab/MainscreenT.dart';
import 'package:coffee_vending/Screens/adminLogin/tab/AdminScreenLoginT.dart';
import 'package:coffee_vending/Widgets/WavePainter.dart';
import 'package:coffee_vending/helper/customtext.dart';
import 'package:coffee_vending/model/ItemDataModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

class VendingMachineScreen extends StatefulWidget {
  const VendingMachineScreen({Key? key}) : super(key: key);

  @override
  State<VendingMachineScreen> createState() => _VendingMachineScreenState();
}

class _VendingMachineScreenState extends State<VendingMachineScreen> {
  late MainScreenBloc bloc;
  Timer? _brewProgressTimer;
  Timer? _brewTimer;

  double _coffeePumpSpeed = 120.0;
  double _teaPumpSpeed = 120.0;
  double _milkPumpSpeed = 120.0;

  String _currentTemp = "--";
  bool _tempError = false;
  Timer? _tempTimeoutTimer;

  double _milkPumpDelay = 0.0;
  double _milkPumpOnTime = 0.0;
  double _milkPumpForwardTime = 0.0;
  int? _lastMilkUsedTime;
  Timer? _milkReverseCheckTimer;

  double _teaPumpForwardTime = 0.0;
  double _teaPumpOnTime = 0.0;
  double _teaPumpDelay = 0.0;
  int? _lastTeaUsedTime;

  double _coffeePumpForwardTime = 0.0;
  double _coffeePumpOnTime = 0.0;
  double _coffeePumpDelay = 0.0;
  int? _lastCoffeeUsedTime;

  Timer? _teaReverseCheckTimer;
  Timer? _coffeeReverseCheckTimer;

  @override
  void initState() {
    super.initState();
    bloc = BlocProvider.of<MainScreenBloc>(context);
    _loadSettings();
    bloc.timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        bloc.currentTime = DateTime.now();
      });
    });

    _initNodeMCUConnection();

    bloc.serialService.onConnectionChanged = (bool status) {
      setState(() {
        bloc.isNodeMCUOnline = status;
      });
    };

    bloc.serialService.onTempReceived = (String temp) {
      setState(() {
        _currentTemp = temp;
        _tempError = false;
      });
      _resetTempTimeout();
    };

    bloc.connectionCheckTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) {
      _checkNodeMCUConnection();
    });

    _startTempTimeout();
    _startMilkReverseTimer();
    _startTeaReverseTimer();
    _startCoffeeReverseTimer();
  }

  void _showCancelBrewingDialog(String beverageType) {
    String title = beverageType == 'coffee' ? 'Coffee' : 'Tea';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFFFBF9F5), const Color(0xFFEDE7DD)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B6B47).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: Color(0xFF8B6B47),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cancel $title Brewing',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D3530),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to cancel\n$title brewing?',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF75675A),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF75675A),
                          side: const BorderSide(
                            color: Color(0xFFE0D7C9),
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'CLOSE',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          String valveKey = beverageType == 'tea'
                              ? 'TBV'
                              : 'CBV';
                          await bloc.serialService.sendJsonData({
                            valveKey: "0",
                          });
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          await prefs.remove('currentBrewing');
                          await prefs.remove('remainingSeconds');
                          if (mounted) setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B6B47),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFF8B6B47).withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _initNodeMCUConnection() async {
    bool connected = await bloc.serialService.connect();
    setState(() {
      bloc.isNodeMCUOnline = connected;
    });
  }

  Future<void> _checkNodeMCUConnection() async {
    bool connected = await bloc.serialService.checkConnection();
    if (connected != bloc.isNodeMCUOnline) {
      setState(() {
        bloc.isNodeMCUOnline = connected;
      });
    }
  }

  void _startTempTimeout() {
    _tempTimeoutTimer?.cancel();
    _tempTimeoutTimer = Timer(const Duration(seconds: 30), () {
      setState(() {
        _tempError = true;
        _currentTemp = "Error";
      });
    });
  }

  void _resetTempTimeout() {
    _tempTimeoutTimer?.cancel();
    _startTempTimeout();
  }

  void _startMilkReverseTimer() {
    _milkReverseCheckTimer?.cancel();
    _milkReverseCheckTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      if (_lastMilkUsedTime != null) {
        int elapsedSeconds =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 - _lastMilkUsedTime!;
        if (elapsedSeconds >= _milkPumpDelay) {
          await _executeMilkReverse();
          _lastMilkUsedTime = null;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('lastMilkUsedTime');
        }
      }
    });
  }

  Future<void> _executeMilkReverse() async {
    await bloc.serialService.sendJsonData({
      "MAV": "1",
      "MP_FWD": "0",
      "MP_REV": "${_milkPumpSpeed.toInt()}",
    });
    await Future.delayed(Duration(seconds: _milkPumpOnTime.toInt()));
    await bloc.serialService.sendJsonData({
      "MAV": "0",
      "MP_FWD": "0",
      "MP_REV": "0",
    });
    _milkPumpForwardTime = 0.0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('milkPumpForwardTime', 0.0);
  }

  Future<void> _updateMilkUsageTime() async {
    _lastMilkUsedTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastMilkUsedTime', _lastMilkUsedTime!);
  }

  void _startTeaReverseTimer() {
    _teaReverseCheckTimer?.cancel();
    _teaReverseCheckTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      if (_lastTeaUsedTime != null) {
        int elapsedSeconds =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 - _lastTeaUsedTime!;
        if (elapsedSeconds >= _teaPumpDelay) {
          await _executeTeaReverse();
          _lastTeaUsedTime = null;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('lastTeaUsedTime');
        }
      }
    });
  }

  void _startCoffeeReverseTimer() {
    _coffeeReverseCheckTimer?.cancel();
    _coffeeReverseCheckTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      if (_lastCoffeeUsedTime != null) {
        int elapsedSeconds =
            DateTime.now().millisecondsSinceEpoch ~/ 1000 -
            _lastCoffeeUsedTime!;
        if (elapsedSeconds >= _coffeePumpDelay) {
          await _executeCoffeeReverse();
          _lastCoffeeUsedTime = null;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('lastCoffeeUsedTime');
        }
      }
    });
  }

  Future<void> _executeTeaReverse() async {
    await bloc.serialService.sendJsonData({
      "TP_FWD": "0",
      "TP_REV": "${_teaPumpSpeed.toInt()}",
    });
    await Future.delayed(Duration(seconds: _teaPumpOnTime.toInt()));
    await bloc.serialService.sendJsonData({"TP_FWD": "0", "TP_REV": "0"});
    _teaPumpForwardTime = 0.0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('teaPumpForwardTime', 0.0);
  }

  Future<void> _executeCoffeeReverse() async {
    await bloc.serialService.sendJsonData({
      "CP_FWD": "0",
      "CP_REV": "${_coffeePumpSpeed.toInt()}",
    });
    await Future.delayed(Duration(seconds: _coffeePumpOnTime.toInt()));
    await bloc.serialService.sendJsonData({"CP_FWD": "0", "CP_REV": "0"});
    _coffeePumpForwardTime = 0.0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('coffeePumpForwardTime', 0.0);
  }

  Future<void> _updateTeaUsageTime() async {
    _lastTeaUsedTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastTeaUsedTime', _lastTeaUsedTime!);
  }

  Future<void> _updateCoffeeUsageTime() async {
    _lastCoffeeUsedTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastCoffeeUsedTime', _lastCoffeeUsedTime!);
  }

  @override
  void dispose() {
    bloc.connectionCheckTimer?.cancel();
    bloc.timer.cancel();
    _brewProgressTimer?.cancel();
    _brewTimer?.cancel();
    _tempTimeoutTimer?.cancel();
    _milkReverseCheckTimer?.cancel();
    _teaReverseCheckTimer?.cancel();
    _coffeeReverseCheckTimer?.cancel();
    super.dispose();
  }

  int _calculateBrewTime(String drinkKey) {
    final settings = bloc.delaySettings[drinkKey];
    if (settings == null) {
      print("Settings for $drinkKey is NULL");
      return 0;
    }

    int total = 0;
    settings.forEach((key, value) {
      print("$drinkKey - $key: $value");
      total += value;
    });
    print("Total brew time for $drinkKey: $total seconds");
    return total;
  }

  Future<void> _incrementDrinkCount(String drinkName) async {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt('${drinkName}_count') ?? 0;
    int limit = prefs.getInt('limit_$drinkName') ?? 0;
    int jump = prefs.getInt('jump_$drinkName') ?? 0;

    currentCount += 1;

    if (limit > 0 && jump > 0) {
      if (currentCount % limit == 0) {
        currentCount += jump;
      }
    }

    await prefs.setInt('${drinkName}_count', currentCount);
  }

  String _formatDate(DateTime date) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    int hour = date.hour;
    String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    String minute = date.minute.toString().padLeft(2, '0');
    String second = date.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second $period';
  }

  Future<void> _sendBrewCommand() async {
    if (bloc.selectedItem == null) return;

    // if (!bloc.isNodeMCUOnline) return;

    if (bloc.selectedItem == 'c1') {
      await _executeStrongCoffeeSequence();
    } else if (bloc.selectedItem == 'c2') {
      await _executeLiteCoffeeSequence();
    } else if (bloc.selectedItem == 'c3') {
      await _executeBlackCoffeeSequence();
    } else if (bloc.selectedItem == 't1') {
      await _executeStrongTeaSequence();
    } else if (bloc.selectedItem == 't2') {
      await _executeLiteTeaSequence();
    } else if (bloc.selectedItem == 't3') {
      await _executeBlackTeaSequence();
    } else if (bloc.selectedItem == 't4') {
      await _executeDipTeaSequence();
    } else if (bloc.selectedItem == 'e1') {
      await _executeHotMilkSequence();
    } else if (bloc.selectedItem == 'e2') {
      await _executeHotWaterSequence();
    }
  }

  Future<void> _executeStrongCoffeeSequence() async {
    final settings = bloc.delaySettings['strongCoffee'];
    if (settings == null) return;

    final cpDelay = settings['cpDelay'] ?? 0;
    final cpOnTime = settings['cpOnTime'] ?? 0;
    final milkDelay = settings['milkDelay'] ?? 0;
    final milkOnTime = settings['milkOnTime'] ?? 0;
    final waterDelay = settings['waterDelay'] ?? 0;
    final waterOnTime = settings['waterOnTime'] ?? 0;

    print("Starting Strong Coffee Sequence");

    print("Waiting cpDelay: $cpDelay seconds");
    await Future.delayed(Duration(seconds: cpDelay));
    print("cpDelay complete");

    final coffeeOnTimeWithForward = (cpOnTime + _coffeePumpForwardTime).toInt();
    print(
      "Sending Coffee Pump ON with forward time: $coffeeOnTimeWithForward seconds",
    );
    await bloc.serialService.sendJsonData({
      "CP_FWD": "${_coffeePumpSpeed.toInt()}",
      "CP_REV": "0",
    });

    print("Waiting cpOnTime with forward: $coffeeOnTimeWithForward seconds");
    await Future.delayed(Duration(seconds: coffeeOnTimeWithForward));
    print("cpOnTime complete");

    print("Sending Coffee Pump OFF: {CP_FWD: 0, CP_REV: 0}");
    await bloc.serialService.sendJsonData({"CP_FWD": "0", "CP_REV": "0"});

    _coffeePumpForwardTime = cpOnTime.toDouble();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('coffeePumpForwardTime', _coffeePumpForwardTime);
    await _updateCoffeeUsageTime();

    print("Waiting milkDelay: $milkDelay seconds");
    await Future.delayed(Duration(seconds: milkDelay));
    print("milkDelay complete");

    final milkOnTimeWithForward = (milkOnTime + _milkPumpForwardTime).toInt();
    print(
      "Sending Milk Pump ON with forward time: $milkOnTimeWithForward seconds",
    );
    await bloc.serialService.sendJsonData({
      "MAV": "1",
      "MP_FWD": "${_milkPumpSpeed.toInt()}",
      "MP_REV": "0",
    });

    print("Waiting milkOnTime with forward: $milkOnTimeWithForward seconds");
    await Future.delayed(Duration(seconds: milkOnTimeWithForward));
    print("milkOnTime complete");

    print("Sending Milk Pump OFF: {MAV: 0, MP_FWD: 0, MP_REV: 0}");
    await bloc.serialService.sendJsonData({
      "MAV": "0",
      "MP_FWD": "0",
      "MP_REV": "0",
    });

    _milkPumpForwardTime = milkOnTime.toDouble();
    await prefs.setDouble('milkPumpForwardTime', _milkPumpForwardTime);
    await _updateMilkUsageTime();

    print("Waiting waterDelay: $waterDelay seconds");
    await Future.delayed(Duration(seconds: waterDelay));
    print("waterDelay complete");

    print("Sending Hot Water Valve ON: {MHWV: 1}");
    await bloc.serialService.sendJsonData({"MHWV": "1"});

    print("Waiting waterOnTime: $waterOnTime seconds");
    await Future.delayed(Duration(seconds: waterOnTime));
    print("waterOnTime complete");

    print("Sending Hot Water Valve OFF: {MHWV: 0}");
    await bloc.serialService.sendJsonData({"MHWV": "0"});

    print("Strong Coffee Sequence Complete");
  }

  Future<void> _executeLiteCoffeeSequence() async {
    final settings = bloc.delaySettings['liteCoffee'];
    if (settings == null) return;

    final cpDelay = settings['cpDelay'] ?? 0;
    final cpOnTime = settings['cpOnTime'] ?? 0;
    final milkDelay = settings['milkDelay'] ?? 0;
    final milkOnTime = settings['milkOnTime'] ?? 0;
    final waterDelay = settings['waterDelay'] ?? 0;
    final waterOnTime = settings['waterOnTime'] ?? 0;

    print("Starting Lite Coffee Sequence");

    print("Waiting cpDelay: $cpDelay seconds");
    await Future.delayed(Duration(seconds: cpDelay));
    print("cpDelay complete");

    final coffeeOnTimeWithForward = (cpOnTime + _coffeePumpForwardTime).toInt();
    print(
      "Sending Coffee Pump ON with forward time: $coffeeOnTimeWithForward seconds",
    );
    await bloc.serialService.sendJsonData({
      "CP_FWD": "${_coffeePumpSpeed.toInt()}",
      "CP_REV": "0",
    });

    print("Waiting cpOnTime with forward: $coffeeOnTimeWithForward seconds");
    await Future.delayed(Duration(seconds: coffeeOnTimeWithForward));
    print("cpOnTime complete");

    print("Sending Coffee Pump OFF: {CP_FWD: 0, CP_REV: 0}");
    await bloc.serialService.sendJsonData({"CP_FWD": "0", "CP_REV": "0"});

    _coffeePumpForwardTime = cpOnTime.toDouble();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
      'coffeePumpForwardTime',
      _coffeePumpForwardTime + cpOnTime.toDouble(),
    );
    await _updateCoffeeUsageTime();

    print("Waiting milkDelay: $milkDelay seconds");
    await Future.delayed(Duration(seconds: milkDelay));
    print("milkDelay complete");

    final milkOnTimeWithForward = (milkOnTime + _milkPumpForwardTime).toInt();
    print(
      "Sending Milk Pump ON with forward time: $milkOnTimeWithForward seconds",
    );
    await bloc.serialService.sendJsonData({
      "MAV": "1",
      "MP_FWD": "${_milkPumpSpeed.toInt()}",
      "MP_REV": "0",
    });

    print("Waiting milkOnTime with forward: $milkOnTimeWithForward seconds");
    await Future.delayed(Duration(seconds: milkOnTimeWithForward));
    print("milkOnTime complete");

    print("Sending Milk Pump OFF: {MAV: 0, MP_FWD: 0, MP_REV: 0}");
    await bloc.serialService.sendJsonData({
      "MAV": "0",
      "MP_FWD": "0",
      "MP_REV": "0",
    });

    _milkPumpForwardTime = milkOnTime.toDouble();
    await prefs.setDouble('milkPumpForwardTime', _milkPumpForwardTime);
    await _updateMilkUsageTime();

    print("Waiting waterDelay: $waterDelay seconds");
    await Future.delayed(Duration(seconds: waterDelay));
    print("waterDelay complete");

    print("Sending Hot Water Valve ON: {MHWV: 1}");
    await bloc.serialService.sendJsonData({"MHWV": "1"});

    print("Waiting waterOnTime: $waterOnTime seconds");
    await Future.delayed(Duration(seconds: waterOnTime));
    print("waterOnTime complete");

    print("Sending Hot Water Valve OFF: {MHWV: 0}");
    await bloc.serialService.sendJsonData({"MHWV": "0"});

    print("Lite Coffee Sequence Complete");
  }

  Future<void> _executeBlackCoffeeSequence() async {
    final settings = bloc.delaySettings['blackCoffee'];
    if (settings == null) return;

    final ctpDelay = settings['ctpDelay'] ?? 0;
    final ctpOnTime = settings['ctpOnTime'] ?? 0;
    final waterDelay = settings['waterDelay'] ?? 0;
    final waterOnTime = settings['waterOnTime'] ?? 0;

    print("Starting Black Coffee Sequence");

    print("Waiting ctpDelay: $ctpDelay seconds");
    await Future.delayed(Duration(seconds: ctpDelay));
    print("ctpDelay complete");

    final coffeeOnTimeWithForward = (ctpOnTime + _coffeePumpForwardTime)
        .toInt();
    print(
      "Sending Coffee Tea Pump ON with forward time: $coffeeOnTimeWithForward seconds",
    );
    await bloc.serialService.sendJsonData({
      "CP_FWD": "${_coffeePumpSpeed.toInt()}",
      "CP_REV": "0",
    });

    print("Waiting ctpOnTime with forward: $coffeeOnTimeWithForward seconds");
    await Future.delayed(Duration(seconds: coffeeOnTimeWithForward));
    print("ctpOnTime complete");

    print("Sending Coffee Tea Pump OFF: {CP_FWD: 0, CP_REV: 0}");
    await bloc.serialService.sendJsonData({"CP_FWD": "0", "CP_REV": "0"});

    _coffeePumpForwardTime = ctpOnTime.toDouble();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('coffeePumpForwardTime', _coffeePumpForwardTime);
    await _updateCoffeeUsageTime();

    print("Waiting waterDelay: $waterDelay seconds");
    await Future.delayed(Duration(seconds: waterDelay));
    print("waterDelay complete");

    print("Sending Hot Water Valve ON: {MHWV: 1}");
    await bloc.serialService.sendJsonData({"MHWV": "1"});

    print("Waiting waterOnTime: $waterOnTime seconds");
    await Future.delayed(Duration(seconds: waterOnTime));
    print("waterOnTime complete");

    print("Sending Hot Water Valve OFF: {MHWV: 0}");
    await bloc.serialService.sendJsonData({"MHWV": "0"});

    print("Black Coffee Sequence Complete");
  }

  Future<void> _executeStrongTeaSequence() async {
    final settings = bloc.delaySettings['strongTea'];
    if (settings == null) return;

    final ttpDelay = settings['ttpDelay'] ?? 0;
    final ttpOnTime = settings['ttpOnTime'] ?? 0;
    final milkDelay = settings['milkDelay'] ?? 0;
    final milkOnTime = settings['milkOnTime'] ?? 0;
    final waterDelay = settings['waterDelay'] ?? 0;
    final waterOnTime = settings['waterOnTime'] ?? 0;

    print("Starting Strong Tea Sequence");

    print("Waiting ttpDelay: $ttpDelay seconds");
    await Future.delayed(Duration(seconds: ttpDelay));
    print("ttpDelay complete");

    final teaOnTimeWithForward = (ttpOnTime + _teaPumpForwardTime).toInt();
    print(
      "Sending Tea Pump ON with forward time: $teaOnTimeWithForward seconds",
    );
    await bloc.serialService.sendJsonData({
      "TP_FWD": "${_teaPumpSpeed.toInt()}",
      "TP_REV": "0",
    });

    print("Waiting ttpOnTime with forward: $teaOnTimeWithForward seconds");
    await Future.delayed(Duration(seconds: teaOnTimeWithForward));
    print("ttpOnTime complete");

    print("Sending Tea Pump OFF: {TP_FWD: 0, TP_REV: 0}");
    await bloc.serialService.sendJsonData({"TP_FWD": "0", "TP_REV": "0"});

    _teaPumpForwardTime = ttpOnTime.toDouble();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('teaPumpForwardTime', _teaPumpForwardTime);
    await _updateTeaUsageTime();

    print("Waiting milkDelay: $milkDelay seconds");
    await Future.delayed(Duration(seconds: milkDelay));
    print("milkDelay complete");

    final milkOnTimeWithForward = (milkOnTime + _milkPumpForwardTime).toInt();
    print(
      "Sending Milk Pump ON with forward time: $milkOnTimeWithForward seconds",
    );
    await bloc.serialService.sendJsonData({
      "MAV": "1",
      "MP_FWD": "${_milkPumpSpeed.toInt()}",
      "MP_REV": "0",
    });

    print("Waiting milkOnTime with forward: $milkOnTimeWithForward seconds");
    await Future.delayed(Duration(seconds: milkOnTimeWithForward));
    print("milkOnTime complete");

    print("Sending Milk Pump OFF: {MAV: 0, MP_FWD: 0, MP_REV: 0}");
    await bloc.serialService.sendJsonData({
      "MAV": "0",
      "MP_FWD": "0",
      "MP_REV": "0",
    });

    _milkPumpForwardTime = milkOnTime.toDouble();
    await prefs.setDouble('milkPumpForwardTime', _milkPumpForwardTime);
    await _updateMilkUsageTime();

    print("Waiting waterDelay: $waterDelay seconds");
    await Future.delayed(Duration(seconds: waterDelay));
    print("waterDelay complete");

    print("Sending Hot Water Valve ON: {MHWV: 1}");
    await bloc.serialService.sendJsonData({"MHWV": "1"});

    print("Waiting waterOnTime: $waterOnTime seconds");
    await Future.delayed(Duration(seconds: waterOnTime));
    print("waterOnTime complete");

    print("Sending Hot Water Valve OFF: {MHWV: 0}");
    await bloc.serialService.sendJsonData({"MHWV": "0"});

    print("Strong Tea Sequence Complete");
  }

  Future<void> _executeLiteTeaSequence() async {
    final settings = bloc.delaySettings['liteTea'];
    if (settings == null) return;

    final ttpDelay = settings['ttpDelay'] ?? 0;
    final ttpOnTime = settings['ttpOnTime'] ?? 0;
    final milkDelay = settings['milkDelay'] ?? 0;
    final milkOnTime = settings['milkOnTime'] ?? 0;
    final waterDelay = settings['waterDelay'] ?? 0;
    final waterOnTime = settings['waterOnTime'] ?? 0;

    print("Starting Lite Tea Sequence");

    print("Waiting ttpDelay: $ttpDelay seconds");
    await Future.delayed(Duration(seconds: ttpDelay));
    print("ttpDelay complete");

    final teaOnTimeWithForward = (ttpOnTime + _teaPumpForwardTime).toInt();
    print(
      "Sending Tea Pump ON with forward time: $teaOnTimeWithForward seconds",
    );
    await bloc.serialService.sendJsonData({
      "TP_FWD": "${_teaPumpSpeed.toInt()}",
      "TP_REV": "0",
    });

    print("Waiting ttpOnTime with forward: $teaOnTimeWithForward seconds");
    await Future.delayed(Duration(seconds: teaOnTimeWithForward));
    print("ttpOnTime complete");

    print("Sending Tea Pump OFF: {TP_FWD: 0, TP_REV: 0}");
    await bloc.serialService.sendJsonData({"TP_FWD": "0", "TP_REV": "0"});

    _teaPumpForwardTime = ttpOnTime.toDouble();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('teaPumpForwardTime', _teaPumpForwardTime);
    await _updateTeaUsageTime();

    print("Waiting milkDelay: $milkDelay seconds");
    await Future.delayed(Duration(seconds: milkDelay));
    print("milkDelay complete");

    final milkOnTimeWithForward = (milkOnTime + _milkPumpForwardTime).toInt();
    print(
      "Sending Milk Pump ON with forward time: $milkOnTimeWithForward seconds",
    );
    await bloc.serialService.sendJsonData({
      "MAV": "1",
      "MP_FWD": "${_milkPumpSpeed.toInt()}",
      "MP_REV": "0",
    });

    print("Waiting milkOnTime with forward: $milkOnTimeWithForward seconds");
    await Future.delayed(Duration(seconds: milkOnTimeWithForward));
    print("milkOnTime complete");

    print("Sending Milk Pump OFF: {MAV: 0, MP_FWD: 0, MP_REV: 0}");
    await bloc.serialService.sendJsonData({
      "MAV": "0",
      "MP_FWD": "0",
      "MP_REV": "0",
    });

    _milkPumpForwardTime = milkOnTime.toDouble();
    await prefs.setDouble('milkPumpForwardTime', _milkPumpForwardTime);
    await _updateMilkUsageTime();

    print("Waiting waterDelay: $waterDelay seconds");
    await Future.delayed(Duration(seconds: waterDelay));
    print("waterDelay complete");

    print("Sending Hot Water Valve ON: {MHWV: 1}");
    await bloc.serialService.sendJsonData({"MHWV": "1"});

    print("Waiting waterOnTime: $waterOnTime seconds");
    await Future.delayed(Duration(seconds: waterOnTime));
    print("waterOnTime complete");

    print("Sending Hot Water Valve OFF: {MHWV: 0}");
    await bloc.serialService.sendJsonData({"MHWV": "0"});

    print("Lite Tea Sequence Complete");
  }

  Future<void> _executeBlackTeaSequence() async {
    final settings = bloc.delaySettings['blackTea'];
    if (settings == null) return;

    final ttpDelay = settings['ttpDelay'] ?? 0;
    final ttpOnTime = settings['ttpOnTime'] ?? 0;
    final waterDelay = settings['waterDelay'] ?? 0;
    final waterOnTime = settings['waterOnTime'] ?? 0;

    print("Starting Black Tea Sequence");

    print("Waiting ttpDelay: $ttpDelay seconds");
    await Future.delayed(Duration(seconds: ttpDelay));
    print("ttpDelay complete");

    final teaOnTimeWithForward = (ttpOnTime + _teaPumpForwardTime).toInt();
    print(
      "Sending Tea Pump ON with forward time: $teaOnTimeWithForward seconds",
    );
    await bloc.serialService.sendJsonData({
      "TP_FWD": "${_teaPumpSpeed.toInt()}",
      "TP_REV": "0",
    });

    print("Waiting ttpOnTime with forward: $teaOnTimeWithForward seconds");
    await Future.delayed(Duration(seconds: teaOnTimeWithForward));
    print("ttpOnTime complete");

    print("Sending Tea Pump OFF: {TP_FWD: 0, TP_REV: 0}");
    await bloc.serialService.sendJsonData({"TP_FWD": "0", "TP_REV": "0"});

    _teaPumpForwardTime = ttpOnTime.toDouble();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('teaPumpForwardTime', _teaPumpForwardTime);
    await _updateTeaUsageTime();

    print("Waiting waterDelay: $waterDelay seconds");
    await Future.delayed(Duration(seconds: waterDelay));
    print("waterDelay complete");

    print("Sending Hot Water Valve ON: {MHWV: 1}");
    await bloc.serialService.sendJsonData({"MHWV": "1"});

    print("Waiting waterOnTime: $waterOnTime seconds");
    await Future.delayed(Duration(seconds: waterOnTime));
    print("waterOnTime complete");

    print("Sending Hot Water Valve OFF: {MHWV: 0}");
    await bloc.serialService.sendJsonData({"MHWV": "0"});

    print("Black Tea Sequence Complete");
  }

  Future<void> _executeDipTeaSequence() async {
    final settings = bloc.delaySettings['dipTea'];
    if (settings == null) return;

    final waterDelay = settings['waterDelay'] ?? 0;
    final waterOnTime = settings['waterOnTime'] ?? 0;
    final milkDelay = settings['milkDelay'] ?? 0;
    final milkOnTime = settings['milkOnTime'] ?? 0;

    print("Starting Dip Tea Sequence");

    print("Waiting waterDelay: $waterDelay seconds");
    await Future.delayed(Duration(seconds: waterDelay));
    print("waterDelay complete");

    print("Sending Hot Water Valve ON: {MHWV: 1}");
    await bloc.serialService.sendJsonData({"MHWV": "1"});

    print("Waiting waterOnTime: $waterOnTime seconds");
    await Future.delayed(Duration(seconds: waterOnTime));
    print("waterOnTime complete");

    print("Sending Hot Water Valve OFF: {MHWV: 0}");
    await bloc.serialService.sendJsonData({"MHWV": "0"});

    print("Waiting milkDelay: $milkDelay seconds");
    await Future.delayed(Duration(seconds: milkDelay));
    print("milkDelay complete");

    final milkOnTimeWithForward = (milkOnTime + _milkPumpForwardTime).toInt();
    print(
      "Sending Milk Pump ON with forward time: $milkOnTimeWithForward seconds",
    );
    await bloc.serialService.sendJsonData({
      "MAV": "1",
      "MP_FWD": "${_milkPumpSpeed.toInt()}",
      "MP_REV": "0",
    });

    print("Waiting milkOnTime with forward: $milkOnTimeWithForward seconds");
    await Future.delayed(Duration(seconds: milkOnTimeWithForward));
    print("milkOnTime complete");

    print("Sending Milk Pump OFF: {MAV: 0, MP_FWD: 0, MP_REV: 0}");
    await bloc.serialService.sendJsonData({
      "MAV": "0",
      "MP_FWD": "0",
      "MP_REV": "0",
    });

    _milkPumpForwardTime = milkOnTime.toDouble();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('milkPumpForwardTime', _milkPumpForwardTime);
    await _updateMilkUsageTime();

    print("Dip Tea Sequence Complete");
  }

  Future<void> _executeHotMilkSequence() async {
    final settings = bloc.delaySettings['hotMilk'];
    if (settings == null) return;

    final milkDelay = settings['milkDelay'] ?? 0;
    final milkOnTime = settings['milkOnTime'] ?? 0;
    final waterDelay = settings['waterDelay'] ?? 0;
    final waterOnTime = settings['waterOnTime'] ?? 0;

    print("Starting Hot Milk Sequence");

    print("Waiting milkDelay: $milkDelay seconds");
    await Future.delayed(Duration(seconds: milkDelay));
    print("milkDelay complete");

    final milkOnTimeWithForward = (milkOnTime + _milkPumpForwardTime).toInt();
    print(
      "Sending Milk Pump ON with forward time: $milkOnTimeWithForward seconds",
    );
    await bloc.serialService.sendJsonData({
      "MAV": "1",
      "MP_FWD": "${_milkPumpSpeed.toInt()}",
      "MP_REV": "0",
    });

    print("Waiting milkOnTime with forward: $milkOnTimeWithForward seconds");
    await Future.delayed(Duration(seconds: milkOnTimeWithForward));
    print("milkOnTime complete");

    print("Sending Milk Pump OFF: {MAV: 0, MP_FWD: 0, MP_REV: 0}");
    await bloc.serialService.sendJsonData({
      "MAV": "0",
      "MP_FWD": "0",
      "MP_REV": "0",
    });

    _milkPumpForwardTime = milkOnTime.toDouble();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('milkPumpForwardTime', _milkPumpForwardTime);
    await _updateMilkUsageTime();

    print("Waiting waterDelay: $waterDelay seconds");
    await Future.delayed(Duration(seconds: waterDelay));
    print("waterDelay complete");

    print("Sending Hot Water Valve ON: {MHWV: 1}");
    await bloc.serialService.sendJsonData({"MHWV": "1"});

    print("Waiting waterOnTime: $waterOnTime seconds");
    await Future.delayed(Duration(seconds: waterOnTime));
    print("waterOnTime complete");

    print("Sending Hot Water Valve OFF: {MHWV: 0}");
    await bloc.serialService.sendJsonData({"MHWV": "0"});

    print("Hot Milk Sequence Complete");
  }

  Future<void> _executeHotWaterSequence() async {
    final settings = bloc.delaySettings['hotWater'];
    if (settings == null) return;

    final waterValveDelay = settings['waterValveDelay'] ?? 0;
    final waterValveOnTime = settings['waterValveOnTime'] ?? 0;

    print("Starting Hot Water Sequence");

    print("Waiting waterValveDelay: $waterValveDelay seconds");
    await Future.delayed(Duration(seconds: waterValveDelay));
    print("waterValveDelay complete");

    print("Sending Hot Water Valve ON: {HWV: 1}");
    await bloc.serialService.sendJsonData({"HWV": "1"});

    print("Waiting waterValveOnTime: $waterValveOnTime seconds");
    await Future.delayed(Duration(seconds: waterValveOnTime));
    print("waterValveOnTime complete");

    print("Sending Hot Water Valve OFF: {HWV: 0}");
    await bloc.serialService.sendJsonData({"HWV": "0"});

    print("Hot Water Sequence Complete");
  }

  void _startBrewing() async {
    if (bloc.selectedItem == null || bloc.isBrewAnimating) return;

    String drinkKey = '';
    String drinkName = '';

    switch (bloc.selectedItem) {
      case 'c1':
        drinkKey = 'strongCoffee';
        drinkName = 'Strong Coffee';
        break;
      case 'c2':
        drinkKey = 'liteCoffee';
        drinkName = 'Lite Coffee';
        break;
      case 'c3':
        drinkKey = 'blackCoffee';
        drinkName = 'Black Coffee';
        break;
      case 't1':
        drinkKey = 'strongTea';
        drinkName = 'Strong Tea';
        break;
      case 't2':
        drinkKey = 'liteTea';
        drinkName = 'Lite Tea';
        break;
      case 't3':
        drinkKey = 'blackTea';
        drinkName = 'Black Tea';
        break;
      case 't4':
        drinkKey = 'dipTea';
        drinkName = 'Dip Tea';
        break;
      case 'e1':
        drinkKey = 'hotMilk';
        drinkName = 'Hot Milk';
        break;
      case 'e2':
        drinkKey = 'hotWater';
        drinkName = 'Hot Water';
        break;
    }

    int brewSeconds = _calculateBrewTime(drinkKey);

    print("Calculated brew time: $brewSeconds seconds");

    _brewProgressTimer?.cancel();
    _showBrewPopup();
    _sendBrewCommand();

    setState(() {
      bloc.isBrewAnimating = true;
      bloc.brewProgress = 0.0;
    });

    double incrementPerTick = 1.0 / (brewSeconds * 33.33);

    _brewProgressTimer = Timer.periodic(const Duration(milliseconds: 30), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        _brewProgressTimer = null;
        return;
      }

      if (bloc.brewProgress >= 1.0) {
        timer.cancel();
        _brewProgressTimer = null;

        if (mounted) {
          _incrementDrinkCount(drinkName);
          setState(() {
            bloc.isBrewAnimating = false;
            bloc.brewProgress = 0.0;
          });

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
              setState(() {
                bloc.selectedItem = null;
              });
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            bloc.brewProgress += incrementPerTick;
            if (bloc.brewProgress > 1.0) {
              bloc.brewProgress = 1.0;
            }
          });
        }
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    bloc.companyName = prefs.getString('companyName') ?? '';

    _coffeePumpSpeed = prefs.getDouble('coffeePumpSpeed') ?? 120.0;
    _teaPumpSpeed = prefs.getDouble('teaPumpSpeed') ?? 120.0;
    _milkPumpSpeed = prefs.getDouble('milkPumpSpeed') ?? 120.0;

    if (_coffeePumpSpeed > 250) _coffeePumpSpeed = 250.0;
    if (_teaPumpSpeed > 250) _teaPumpSpeed = 250.0;
    if (_milkPumpSpeed > 250) _milkPumpSpeed = 250.0;

    bloc.delaySettings['strongCoffee'] = {
      'cpDelay': (prefs.getInt('strongCoffee_cpDelay') ?? 0) ~/ 10,
      'cpOnTime': (prefs.getInt('strongCoffee_cpOnTime') ?? 0) ~/ 10,
      'milkDelay': (prefs.getInt('strongCoffee_milkDelay') ?? 0) ~/ 10,
      'milkOnTime': (prefs.getInt('strongCoffee_milkOnTime') ?? 0) ~/ 10,
      'waterDelay': (prefs.getInt('strongCoffee_waterDelay') ?? 0) ~/ 10,
      'waterOnTime': (prefs.getInt('strongCoffee_waterOnTime') ?? 0) ~/ 10,
    };

    bloc.delaySettings['liteCoffee'] = {
      'cpDelay': (prefs.getInt('liteCoffee_cpDelay') ?? 0) ~/ 10,
      'cpOnTime': (prefs.getInt('liteCoffee_cpOnTime') ?? 0) ~/ 10,
      'milkDelay': (prefs.getInt('liteCoffee_milkDelay') ?? 0) ~/ 10,
      'milkOnTime': (prefs.getInt('liteCoffee_milkOnTime') ?? 0) ~/ 10,
      'waterDelay': (prefs.getInt('liteCoffee_waterDelay') ?? 0) ~/ 10,
      'waterOnTime': (prefs.getInt('liteCoffee_waterOnTime') ?? 0) ~/ 10,
    };

    bloc.delaySettings['blackCoffee'] = {
      'ctpDelay': (prefs.getInt('blackCoffee_ctpDelay') ?? 0) ~/ 10,
      'ctpOnTime': (prefs.getInt('blackCoffee_ctpOnTime') ?? 0) ~/ 10,
      'waterDelay': (prefs.getInt('blackCoffee_waterDelay') ?? 0) ~/ 10,
      'waterOnTime': (prefs.getInt('blackCoffee_waterOnTime') ?? 0) ~/ 10,
    };

    bloc.delaySettings['strongTea'] = {
      'ttpDelay': (prefs.getInt('strongTea_ttpDelay') ?? 0) ~/ 10,
      'ttpOnTime': (prefs.getInt('strongTea_ttpOnTime') ?? 0) ~/ 10,
      'milkDelay': (prefs.getInt('strongTea_milkDelay') ?? 0) ~/ 10,
      'milkOnTime': (prefs.getInt('strongTea_milkOnTime') ?? 0) ~/ 10,
      'waterDelay': (prefs.getInt('strongTea_waterDelay') ?? 0) ~/ 10,
      'waterOnTime': (prefs.getInt('strongTea_waterOnTime') ?? 0) ~/ 10,
    };

    bloc.delaySettings['liteTea'] = {
      'ttpDelay': (prefs.getInt('liteTea_ttpDelay') ?? 0) ~/ 10,
      'ttpOnTime': (prefs.getInt('liteTea_ttpOnTime') ?? 0) ~/ 10,
      'milkDelay': (prefs.getInt('liteTea_milkDelay') ?? 0) ~/ 10,
      'milkOnTime': (prefs.getInt('liteTea_milkOnTime') ?? 0) ~/ 10,
      'waterDelay': (prefs.getInt('liteTea_waterDelay') ?? 0) ~/ 10,
      'waterOnTime': (prefs.getInt('liteTea_waterOnTime') ?? 0) ~/ 10,
    };

    bloc.delaySettings['blackTea'] = {
      'ttpDelay': (prefs.getInt('blackTea_ttpDelay') ?? 0) ~/ 10,
      'ttpOnTime': (prefs.getInt('blackTea_ttpOnTime') ?? 0) ~/ 10,
      'waterDelay': (prefs.getInt('blackTea_waterDelay') ?? 0) ~/ 10,
      'waterOnTime': (prefs.getInt('blackTea_waterOnTime') ?? 0) ~/ 10,
    };

    bloc.delaySettings['dipTea'] = {
      'waterDelay': (prefs.getInt('dipTea_waterDelay') ?? 0) ~/ 10,
      'waterOnTime': (prefs.getInt('dipTea_waterOnTime') ?? 0) ~/ 10,
      'milkDelay': (prefs.getInt('dipTea_milkDelay') ?? 0) ~/ 10,
      'milkOnTime': (prefs.getInt('dipTea_milkOnTime') ?? 0) ~/ 10,
    };

    bloc.delaySettings['hotMilk'] = {
      'milkDelay': (prefs.getInt('hotMilk_milkDelay') ?? 0) ~/ 10,
      'milkOnTime': (prefs.getInt('hotMilk_milkOnTime') ?? 0) ~/ 10,
      'waterDelay': (prefs.getInt('hotMilk_waterDelay') ?? 0) ~/ 10,
      'waterOnTime': (prefs.getInt('hotMilk_waterOnTime') ?? 0) ~/ 10,
    };

    bloc.delaySettings['hotWater'] = {
      'waterValveDelay': (prefs.getInt('hotWater_waterValveDelay') ?? 0) ~/ 10,
      'waterValveOnTime':
          (prefs.getInt('hotWater_waterValveOnTime') ?? 0) ~/ 10,
    };

    _milkPumpDelay = prefs.getDouble('milkPumpDelay') ?? 0.0;
    _milkPumpOnTime = prefs.getDouble('milkPumpOnTime') ?? 0.0;
    _milkPumpForwardTime = prefs.getDouble('milkPumpForwardTime') ?? 0.0;
    _lastMilkUsedTime = prefs.getInt('lastMilkUsedTime');

    _teaPumpDelay = prefs.getDouble('teaPumpDelay') ?? 0.0;
    _teaPumpOnTime = prefs.getDouble('teaPumpOnTime') ?? 0.0;
    _teaPumpForwardTime = prefs.getDouble('teaPumpForwardTime') ?? 0.0;

    _coffeePumpDelay = prefs.getDouble('coffeePumpDelay') ?? 0.0;
    _coffeePumpOnTime = prefs.getDouble('coffeePumpOnTime') ?? 0.0;
    _coffeePumpForwardTime = prefs.getDouble('coffeePumpForwardTime') ?? 0.0;

    print(
      "strongCoffee cpDelay = ${bloc.delaySettings['strongCoffee']?['cpDelay']}",
    );
    print("--------_companyName---------->" + bloc.companyName);
  }

  Future<void> stopBrewing() async {
    _brewTimer?.cancel();
    _brewProgressTimer?.cancel();
    setState(() {
      bloc.isBrewAnimating = false;
      bloc.selectedItem = null;
      bloc.brewProgress = 0.0;
    });
    await bloc.serialService.sendJsonData({
      "CP_FWD": "0",
      "CP_REV": "0",
      "MAV": "0",
      "MP_FWD": "0",
      "MP_REV": "0",
      "MHWV": "0",
      "TP_FWD": "0",
      "TP_REV": "0",
      "HWV": "0",
    });
    print("---Stop Brewing---");
  }

  void _showBrewPopup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.brown.shade400, Colors.brown.shade800],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Visibility(
                  visible: !bloc.isBrewAnimating,
                  replacement: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      StreamBuilder<void>(
                        stream: Stream.periodic(
                          const Duration(milliseconds: 30),
                        ),
                        builder: (dialogContext, snapshot) {
                          return Container(
                            width: 220,
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.brown.shade800,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.brown.withOpacity(0.6),
                                  blurRadius: 18,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  width: 220,
                                  height: 150,
                                  color: Colors.transparent,
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 150 * bloc.brewProgress,
                                          width: 220,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.brown.shade400,
                                                Colors.brown.shade700,
                                                Colors.brown.shade900,
                                              ],
                                            ),
                                          ),
                                          child: CustomPaint(
                                            painter: WavePainter(
                                              bloc.brewProgress,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.coffee_maker,
                                        size: 48,
                                        color: bloc.brewProgress > 0.5
                                            ? Colors.white
                                            : Colors.brown.shade900,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${(bloc.brewProgress * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: bloc.brewProgress > 0.5
                                              ? Colors.white
                                              : Colors.brown.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Preparing...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          stopBrewing();
                          if (Navigator.canPop(dialogContext)) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Stop',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Brewing Complete!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your beverage is ready',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please collect it',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          if (Navigator.canPop(dialogContext)) {
                            Navigator.pop(dialogContext);
                          }
                          setState(() {
                            bloc.selectedItem = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // void _showBrewPopup() {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (dialogContext) => StatefulBuilder(
  //       builder: (dialogContext, setDialogState) => Dialog(
  //         backgroundColor: Colors.transparent,
  //         child: Container(
  //           padding: const EdgeInsets.all(24),
  //           decoration: BoxDecoration(
  //             gradient: LinearGradient(
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight,
  //               colors: [
  //                 Colors.brown.shade400,
  //                 Colors.brown.shade800,
  //               ],
  //             ),
  //             borderRadius: BorderRadius.circular(24),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.brown.withOpacity(0.5),
  //                 blurRadius: 20,
  //                 spreadRadius: 5,
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Visibility(
  //                 visible: !bloc.isBrewAnimating,
  //                 replacement: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     const SizedBox(height: 20),
  //                     StreamBuilder<void>(
  //                       stream: Stream.periodic(const Duration(milliseconds: 30)),
  //                       builder: (dialogContext, snapshot) {
  //                         return Container(
  //                           width: 220,
  //                           height: 150,
  //                           decoration: BoxDecoration(
  //                             border: Border.all(
  //                               color: Colors.brown.shade800,
  //                               width: 3,
  //                             ),
  //                             borderRadius: BorderRadius.circular(16),
  //                             color: Colors.white,
  //                             boxShadow: [
  //                               BoxShadow(
  //                                 color: Colors.brown.withOpacity(0.6),
  //                                 blurRadius: 18,
  //                                 spreadRadius: 5,
  //                               ),
  //                             ],
  //                           ),
  //                           child: Stack(
  //                             children: [
  //                               Container(
  //                                 width: 220,
  //                                 height: 150,
  //                                 color: Colors.transparent,
  //                               ),
  //                               ClipRRect(
  //                                 borderRadius: BorderRadius.circular(13),
  //                                 child: Stack(
  //                                   children: [
  //                                     Positioned(
  //                                       bottom: 0,
  //                                       left: 0,
  //                                       right: 0,
  //                                       child: Container(
  //                                         height: 150 * bloc.brewProgress,
  //                                         width: 220,
  //                                         decoration: BoxDecoration(
  //                                           gradient: LinearGradient(
  //                                             begin: Alignment.topCenter,
  //                                             end: Alignment.bottomCenter,
  //                                             colors: [
  //                                               Colors.brown.shade400,
  //                                               Colors.brown.shade700,
  //                                               Colors.brown.shade900,
  //                                             ],
  //                                           ),
  //                                         ),
  //                                         child: CustomPaint(
  //                                           painter: WavePainter(bloc.brewProgress),
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                               Center(
  //                                 child: Column(
  //                                   mainAxisAlignment: MainAxisAlignment.center,
  //                                   children: [
  //                                     Icon(
  //                                       Icons.coffee_maker,
  //                                       size: 48,
  //                                       color: bloc.brewProgress > 0.5 ? Colors.white : Colors.brown.shade900,
  //                                     ),
  //                                     const SizedBox(height: 12),
  //                                     Text(
  //                                       'BREWING',
  //                                       style: TextStyle(
  //                                         fontSize: 20,
  //                                         fontWeight: FontWeight.bold,
  //                                         color: bloc.brewProgress > 0.5 ? Colors.white : Colors.brown.shade900,
  //                                         letterSpacing: 2,
  //                                       ),
  //                                     ),
  //                                     const SizedBox(height: 6),
  //                                     Text(
  //                                       '${(bloc.brewProgress * 100).toInt()}%',
  //                                       style: TextStyle(
  //                                         fontSize: 16,
  //                                         fontWeight: FontWeight.bold,
  //                                         color: bloc.brewProgress > 0.5 ? Colors.white : Colors.brown.shade900,
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         );
  //                       },
  //                     ),
  //                     const SizedBox(height: 28),
  //                     const Text(
  //                       'Brewing in Progress',
  //                       style: TextStyle(
  //                         fontSize: 24,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.white,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 12),
  //                     const Text(
  //                       'Your beverage is being prepared',
  //                       style: TextStyle(
  //                         fontSize: 16,
  //                         color: Colors.white70,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 32),
  //                     ElevatedButton(
  //                       onPressed: () {
  //                         stopBrewing();
  //                         if (Navigator.canPop(dialogContext)) {
  //                           Navigator.pop(dialogContext);
  //                         }
  //                       },
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: Colors.red[700],
  //                         foregroundColor: Colors.white,
  //                         padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
  //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //                       ),
  //                       child: const Text(
  //                         'Stop Brewing',
  //                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 20),
  //                   ],
  //                 ),
  //                 child: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Container(
  //                       padding: const EdgeInsets.all(16),
  //                       decoration: BoxDecoration(
  //                         color: Colors.white,
  //                         shape: BoxShape.circle,
  //                       ),
  //                       child: Icon(
  //                         Icons.check_circle,
  //                         color: Colors.green.shade600,
  //                         size: 64,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 20),
  //                     const Text(
  //                       'Brewing Complete!',
  //                       style: TextStyle(
  //                         fontSize: 28,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.white,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 12),
  //                     const Text(
  //                       'Your beverage is ready',
  //                       style: TextStyle(
  //                         fontSize: 18,
  //                         color: Colors.white,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 8),
  //                     const Text(
  //                       'Please collect it',
  //                       style: TextStyle(
  //                         fontSize: 16,
  //                         color: Colors.white70,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 24),
  //                     ElevatedButton(
  //                       onPressed: () {
  //                         if (Navigator.canPop(dialogContext)) {
  //                           Navigator.pop(dialogContext);
  //                         }
  //                         setState(() {
  //                           bloc.selectedItem = null;
  //                         });
  //                       },
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: Colors.green[600],
  //                         foregroundColor: Colors.white,
  //                         padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
  //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //                       ),
  //                       child: const Text(
  //                         'OK',
  //                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MainScreenBloc, MainScreenState>(
      listener: (context, state) {
        // TODO: implement listener
      },
      child: BlocBuilder<MainScreenBloc, MainScreenState>(
        builder: (context, state) {
          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.brown.shade900,
                    Colors.brown.shade700,
                    Colors.brown.shade800,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(flex: 1, child: _buildCoffeeSection()),
                            const SizedBox(height: 20),
                            Expanded(flex: 1, child: _buildTeaSection()),
                            const SizedBox(height: 20),
                            Expanded(flex: 1, child: _buildEssentialsSection()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: bloc.selectedItem != null
                ? _buildBrewButton()
                : null,
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        },
      ),
    );
  }

  Widget _buildBrewButton() {
    const double size = 120;

    return GestureDetector(
      onTap: bloc.isBrewAnimating ? null : _startBrewing,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.6),
              blurRadius: 18,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.brown.shade800, width: 4),
              ),
            ),
            ClipOval(
              child: Stack(
                children: [
                  Container(
                    width: size,
                    height: size,
                    color: Colors.transparent,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.coffee_maker,
                  size: 40,
                  color: Colors.brown.shade900,
                ),
                const SizedBox(height: 8),
                Text(
                  'START',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bloc.companyName.isEmpty ? "Gemini Coffee" : bloc.companyName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _formatDate(bloc.currentTime),
                style: TextStyle(fontSize: 10, color: Colors.brown.shade600),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Row(
                    children: [
                      Text(
                        "Temp :",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade900,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        _tempError ? "Error" : "$_currentTemp° C",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _tempError
                              ? Colors.red
                              : Colors.brown.shade900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 10),
                  Text(
                    "|",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    _formatTime(bloc.currentTime),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade900,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  FutureBuilder<String>(
                    future: SharedPreferences.getInstance().then(
                      (prefs) => prefs.getString('currentBrewing') ?? '',
                    ),
                    builder: (context, snapshot) {
                      String brewing = snapshot.data ?? '';
                      return Visibility(
                        visible: brewing == 'coffee',
                        child: GestureDetector(
                          onTap: () => _showCancelBrewingDialog('coffee'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.brown.withOpacity(0.1),
                              border: Border.all(color: Colors.brown),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 5,
                            ),
                            child: CustomText(
                              text: "Coffee Brewing",
                              weight: FontWeight.w400,
                              color: Colors.brown,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Gap(10),
                  FutureBuilder<String>(
                    future: SharedPreferences.getInstance().then(
                      (prefs) => prefs.getString('currentBrewing') ?? '',
                    ),
                    builder: (context, snapshot) {
                      String brewing = snapshot.data ?? '';
                      return Visibility(
                        visible: brewing == 'tea',
                        child: GestureDetector(
                          onTap: () => _showCancelBrewingDialog('tea'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 5,
                            ),
                            child: CustomText(
                              text: "Tea Brewing",
                              weight: FontWeight.w400,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 10),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bloc.isNodeMCUOnline ? Colors.green : Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (bloc.isNodeMCUOnline ? Colors.green : Colors.red)
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
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const adminScreenLogin(),
                        ),
                      );

                      // Re-register callbacks because SerialService is a singleton
                      // and AdminPanelT might have overwritten them.
                      bloc.serialService.onConnectionChanged = (bool status) {
                        if (mounted) {
                          setState(() {
                            bloc.isNodeMCUOnline = status;
                          });
                        }
                      };

                      bloc.serialService.onTempReceived = (String temp) {
                        if (mounted) {
                          setState(() {
                            _currentTemp = temp;
                            _tempError = false;
                          });
                          _resetTempTimeout();
                        }
                      };
                    },
                    icon: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.brown.shade900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoffeeSection() {
    return _buildSection(
      title: 'Coffee',
      icon: Icons.coffee,
      iconColor: Colors.amber.shade700,
      items: [
        ItemData(
          'Strong Coffee',
          'c1',
          Colors.brown.shade900,
          imagePath: 'assets/images/strong-espresso-coffee.jpg',
        ),
        ItemData(
          'Lite Coffee',
          'c2',
          Colors.brown.shade600,
          imagePath: 'assets/images/light-latte-coffee.jpg',
        ),
        ItemData(
          'Black Coffee',
          'c3',
          Colors.grey.shade900,
          imagePath: 'assets/images/black-americano-coffee.jpg',
        ),
      ],
    );
  }

  Widget _buildTeaSection() {
    return _buildSection(
      title: 'Tea',
      icon: Icons.local_cafe,
      iconColor: Colors.orange.shade700,
      items: [
        ItemData(
          'Strong Tea',
          't1',
          Colors.orange.shade900,
          imagePath: 'assets/images/strong-hot-tea.jpg',
        ),
        ItemData(
          'Lite Tea',
          't2',
          Colors.orange.shade600,
          imagePath: 'assets/images/light-milk-tea.jpg',
        ),
        ItemData(
          'Black Tea',
          't3',
          Colors.grey.shade800,
          imagePath: 'assets/images/black-tea-cup.jpg',
        ),
        ItemData(
          'Dip Tea',
          't4',
          Colors.grey.shade800,
          imagePath: 'assets/images/dip_tea.png',
        ),
      ],
    );
  }

  Widget _buildEssentialsSection() {
    return _buildSection(
      title: 'Essentials',
      icon: Icons.whatshot,
      iconColor: Colors.blue.shade400,
      items: [
        ItemData(
          'Hot Milk',
          'e1',
          Colors.grey.shade100,
          textColor: Colors.grey.shade800,
          imagePath: 'assets/images/glass-of-hot-milk.jpg',
        ),
        ItemData(
          'Hot Water',
          'e2',
          Colors.blue.shade100,
          textColor: Colors.grey.shade800,
          imagePath: 'assets/images/steaming-hot-water-cup.jpg',
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<ItemData> items,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: items.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildItemCard(item),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemData item) {
    final isSelected = bloc.selectedItem == item.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (bloc.selectedItem == item.id) {
            bloc.selectedItem = null;
          } else {
            bloc.selectedItem = item.id;
          }
        });
      },
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Colors.amber, width: 3)
              : Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.5 : 0.3),
              blurRadius: isSelected ? 16 : 8,
              offset: Offset(0, isSelected ? 6 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                item.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: item.color);
                },
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Selection Indicator
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
