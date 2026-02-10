import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../Widgets/SerialCommunication.dart';
import '../../../helper/colors.dart';
import '../../CleaningScreen/tab/CleaningScreen.dart';

class Adminpanel extends StatefulWidget {
  final String userType;
  const Adminpanel({required this.userType,super.key});

  @override
  State<Adminpanel> createState() => _AdminpanelState();
}

class _AdminpanelState extends State<Adminpanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isCurrentVerified = false;

  double _coffeOnTimeValue = 0.0;
  double _teaOnTimeValue = 0.0;


  final Map<String, Map<String, int>> _delaySettings = {
    'strongCoffee': {'cpDelay': 0, 'cpOnTime': 0, 'milkDelay': 0, 'milkOnTime': 0, 'waterDelay': 0, 'waterOnTime': 0},
    'liteCoffee': {'cpDelay': 0, 'cpOnTime': 0, 'milkDelay': 0, 'milkOnTime': 0, 'waterDelay': 0, 'waterOnTime': 0},
    'blackCoffee': {'ctpDelay': 0, 'ctpOnTime': 0, 'waterDelay': 0, 'waterOnTime': 0},
    'strongTea': {'ttpDelay': 0, 'ttpOnTime': 0, 'milkDelay': 0, 'milkOnTime': 0, 'waterDelay': 0, 'waterOnTime': 0},
    'liteTea': {'ttpDelay': 0, 'ttpOnTime': 0, 'milkDelay': 0, 'milkOnTime': 0, 'waterDelay': 0, 'waterOnTime': 0},
    'blackTea': {'ttpDelay': 0, 'ttpOnTime': 0, 'waterDelay': 0, 'waterOnTime': 0},
    'dipTea': {'waterDelay': 0, 'waterOnTime': 0, 'milkDelay': 0, 'milkOnTime': 0},
    'hotMilk': {'milkDelay': 0, 'milkOnTime': 0, 'waterDelay': 0, 'waterOnTime': 0},
    'hotWater': {'waterValveDelay': 0, 'waterValveOnTime': 0},
  };

  double _coffeeTemp = 85.0;
  double _teaTemp = 90.0;

  int _teaClean = 10;
  int _coffeeClean = 10;
  int _milkClean = 15;

  int _milkPump = 5;
  int _teaPump = 5;
  int _coffeePump = 5;

  double _milkPumpDelay = 0.0;
  double _milkPumpOnTime = 0.0;
  double _milkPumpForwardTime = 0.0;

  double _teaPumpDelay = 0.0;
  double _teaPumpOnTime = 0.0;
  double _teaPumpForwardTime = 0.0;

  double _coffeePumpDelay = 0.0;
  double _coffeePumpOnTime = 0.0;
  double _coffeePumpForwardTime = 0.0;

  final Map<String, int> _drinkCounts = {
    'Strong Coffee': 0,
    'Lite Coffee': 0,
    'Black Coffee': 0,
    'Strong Tea': 0,
    'Lite Tea': 0,
    'Black Tea': 0,
    'Dip Tea': 0,
    'Hot Milk': 0,
    'Hot Water': 0,
  };

  final Map<String, int> _limitCounts = {
    'Strong Coffee': 0,
    'Lite Coffee': 0,
    'Black Coffee': 0,
    'Strong Tea': 0,
    'Lite Tea': 0,
    'Black Tea': 0,
    'Dip Tea': 0,
    'Hot Milk': 0,
    'Hot Water': 0,
  };

  final Map<String, int> _jumpCounts = {
    'Strong Coffee': 0,
    'Lite Coffee': 0,
    'Black Coffee': 0,
    'Strong Tea': 0,
    'Lite Tea': 0,
    'Black Tea': 0,
    'Dip Tea': 0,
    'Hot Milk': 0,
    'Hot Water': 0,
  };

  final Map<String, bool> _showCountControls = {
    'Strong Coffee': false,
    'Lite Coffee': false,
    'Black Coffee': false,
    'Strong Tea': false,
    'Lite Tea': false,
    'Black Tea': false,
    'Dip Tea': false,
    'Hot Milk': false,
    'Hot Water': false,
  };

  final Map<String, bool> _jumpCountControls = {
    'Strong Coffee': false,
    'Lite Coffee': false,
    'Black Coffee': false,
    'Strong Tea': false,
    'Lite Tea': false,
    'Black Tea': false,
    'Dip Tea': false,
    'Hot Milk': false,
    'Hot Water': false,
  };


  final Map<String, bool> _limitCountControls = {
    'Strong Coffee': false,
    'Lite Coffee': false,
    'Black Coffee': false,
    'Strong Tea': false,
    'Lite Tea': false,
    'Black Tea': false,
    'Dip Tea': false,
    'Hot Milk': false,
    'Hot Water': false,
  };

  String _companyName = '';
  String CleanAll='';
  int _configDelay = 0;

  int _teaCleanDelay = 0;
  int _coffeeCleanDelay = 0;
  int _milkCleanDelay = 0;


  double _teaPumpSpeed = 120.0;
  double _coffeePumpSpeed = 120.0;
  double _milkPumpSpeed = 120.0;


  String _currentTemp = "--";
  bool _tempError = false;
  Timer? _tempTimeoutTimer;



  final SerialService serialService = SerialService();

  Timer? _brewingTimer;
  bool _isValveOpen = false;


  @override

  void initState() {
    super.initState();
    int tabCount = widget.userType == 'staff' ? 3 : 7;
    _tabController = TabController(length: tabCount, vsync: this);
    _loadSettings();

    _tabController.addListener(() {
      if (_tabController.index == (widget.userType == 'staff' ? 2 : 2)) {
        _loadSettings();
      }
    });

    serialService.onTempReceived = (String temp) {
      setState(() {
        _currentTemp = temp;
        _tempError = false;
      });
      _resetTempTimeout();
    };



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

  @override
  void dispose() {
    _tabController.dispose();
    _brewingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _drinkCounts['Strong Coffee'] = prefs.getInt('Strong Coffee_count') ?? 0;
      _drinkCounts['Lite Coffee'] = prefs.getInt('Lite Coffee_count') ?? 0;
      _drinkCounts['Black Coffee'] = prefs.getInt('Black Coffee_count') ?? 0;
      _drinkCounts['Strong Tea'] = prefs.getInt('Strong Tea_count') ?? 0;
      _drinkCounts['Lite Tea'] = prefs.getInt('Lite Tea_count') ?? 0;
      _drinkCounts['Black Tea'] = prefs.getInt('Black Tea_count') ?? 0;
      _drinkCounts['Dip Tea'] = prefs.getInt('Dip Tea_count') ?? 0;
      _drinkCounts['Hot Milk'] = prefs.getInt('Hot Milk_count') ?? 0;
      _drinkCounts['Hot Water'] = prefs.getInt('Hot Water_count') ?? 0;

      _delaySettings['strongCoffee'] = {
        'cpDelay': prefs.getInt('strongCoffee_cpDelay') ?? 0,
        'cpOnTime': prefs.getInt('strongCoffee_cpOnTime') ?? 0,
        'milkDelay': prefs.getInt('strongCoffee_milkDelay') ?? 0,
        'milkOnTime': prefs.getInt('strongCoffee_milkOnTime') ?? 0,
        'waterDelay': prefs.getInt('strongCoffee_waterDelay') ?? 0,
        'waterOnTime': prefs.getInt('strongCoffee_waterOnTime') ?? 0,
      };

      _delaySettings['liteCoffee'] = {
        'cpDelay': prefs.getInt('liteCoffee_cpDelay') ?? 0,
        'cpOnTime': prefs.getInt('liteCoffee_cpOnTime') ?? 0,
        'milkDelay': prefs.getInt('liteCoffee_milkDelay') ?? 0,
        'milkOnTime': prefs.getInt('liteCoffee_milkOnTime') ?? 0,
        'waterDelay': prefs.getInt('liteCoffee_waterDelay') ?? 0,
        'waterOnTime': prefs.getInt('liteCoffee_waterOnTime') ?? 0,
      };

      _delaySettings['blackCoffee'] = {
        'ctpDelay': prefs.getInt('blackCoffee_ctpDelay') ?? 0,
        'ctpOnTime': prefs.getInt('blackCoffee_ctpOnTime') ?? 0,
        'waterDelay': prefs.getInt('blackCoffee_waterDelay') ?? 0,
        'waterOnTime': prefs.getInt('blackCoffee_waterOnTime') ?? 0,
      };

      _delaySettings['strongTea'] = {
        'ttpDelay': prefs.getInt('strongTea_ttpDelay') ?? 0,
        'ttpOnTime': prefs.getInt('strongTea_ttpOnTime') ?? 0,
        'milkDelay': prefs.getInt('strongTea_milkDelay') ?? 0,
        'milkOnTime': prefs.getInt('strongTea_milkOnTime') ?? 0,
        'waterDelay': prefs.getInt('strongTea_waterDelay') ?? 0,
        'waterOnTime': prefs.getInt('strongTea_waterOnTime') ?? 0,
      };

      _delaySettings['liteTea'] = {
        'ttpDelay': prefs.getInt('liteTea_ttpDelay') ?? 0,
        'ttpOnTime': prefs.getInt('liteTea_ttpOnTime') ?? 0,
        'milkDelay': prefs.getInt('liteTea_milkDelay') ?? 0,
        'milkOnTime': prefs.getInt('liteTea_milkOnTime') ?? 0,
        'waterDelay': prefs.getInt('liteTea_waterDelay') ?? 0,
        'waterOnTime': prefs.getInt('liteTea_waterOnTime') ?? 0,
      };

      _delaySettings['blackTea'] = {
        'ttpDelay': prefs.getInt('blackTea_ttpDelay') ?? 0,
        'ttpOnTime': prefs.getInt('blackTea_ttpOnTime') ?? 0,
        'waterDelay': prefs.getInt('blackTea_waterDelay') ?? 0,
        'waterOnTime': prefs.getInt('blackTea_waterOnTime') ?? 0,
      };

      _delaySettings['dipTea'] = {
        'waterDelay': prefs.getInt('dipTea_waterDelay') ?? 0,
        'waterOnTime': prefs.getInt('dipTea_waterOnTime') ?? 0,
        'milkDelay': prefs.getInt('dipTea_milkDelay') ?? 0,
        'milkOnTime': prefs.getInt('dipTea_milkOnTime') ?? 0,
      };

      _delaySettings['hotMilk'] = {
        'milkDelay': prefs.getInt('hotMilk_milkDelay') ?? 0,
        'milkOnTime': prefs.getInt('hotMilk_milkOnTime') ?? 0,
        'waterDelay': prefs.getInt('hotMilk_waterDelay') ?? 0,
        'waterOnTime': prefs.getInt('hotMilk_waterOnTime') ?? 0,
      };

      _delaySettings['hotWater'] = {
        'waterValveDelay': prefs.getInt('hotWater_waterValveDelay') ?? 0,
        'waterValveOnTime': prefs.getInt('hotWater_waterValveOnTime') ?? 0,
      };

      _coffeeTemp = prefs.getDouble('coffeeTemp') ?? 85.0;
      _teaTemp = prefs.getDouble('teaTemp') ?? 90.0;

      _teaClean = prefs.getInt('teaClean') ?? 10;
      _coffeeClean = prefs.getInt('coffeeClean') ?? 10;
      _milkClean = prefs.getInt('milkClean') ?? 15;

      _teaCleanDelay = prefs.getInt('teaCleanDelay') ?? 0;
      _coffeeCleanDelay = prefs.getInt('coffeeCleanDelay') ?? 0;
      _milkCleanDelay = prefs.getInt('milkCleanDelay') ?? 0;

      _milkPump = prefs.getInt('milkPump') ?? 5;
      _teaPump = prefs.getInt('teaPump') ?? 5;
      _coffeePump = prefs.getInt('coffeePump') ?? 5;

      _companyName = prefs.getString('companyName') ?? '';
      _configDelay = prefs.getInt('configDelay') ?? 0;

      _teaPumpSpeed = prefs.getDouble('teaPumpSpeed') ?? 120.0;
      _coffeePumpSpeed = prefs.getDouble('coffeePumpSpeed') ?? 120.0;
      _milkPumpSpeed = prefs.getDouble('milkPumpSpeed') ?? 120.0;

      if (_teaPumpSpeed > 250) _teaPumpSpeed = 250.0;
      if (_coffeePumpSpeed > 250) _coffeePumpSpeed = 250.0;
      if (_milkPumpSpeed > 250) _milkPumpSpeed = 250.0;

      _isLoading = false;
    });
  }

  void _startAUTOBrewing(String beverageType, double durationSeconds, double setPoint) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentBrewing', beverageType);
    await prefs.setInt('remainingSeconds', durationSeconds.toInt());

    _isValveOpen = true;
    String valveKey = beverageType == 'tea' ? 'TBV' : 'CBV';
    print('Sending JSON: {$valveKey: "1"}');
    await serialService.sendJsonData({valveKey: "1"});

    _checkTemperatureAndBrew(beverageType, durationSeconds.toInt(), setPoint);
  }

  void _checkTemperatureAndBrew(String beverageType, int totalSeconds, double setPoint) {
    _brewingTimer?.cancel();
    _brewingTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int remaining = prefs.getInt('remainingSeconds') ?? 0;

      if (remaining <= 0) {
        timer.cancel();
        _finishBrewing(beverageType);
        return;
      }

      double currentTemp = double.tryParse(_currentTemp.toString()) ?? 0.0;
      String valveKey = beverageType == 'tea' ? 'TBV' : 'CBV';

      if (currentTemp < setPoint - 5 && _isValveOpen) {
        _isValveOpen = false;
        print('Sending JSON: {$valveKey: "0"} - Pausing (Temp: $currentTemp < ${setPoint - 5})');
        await serialService.sendJsonData({valveKey: "0"});
      } else if (currentTemp >= setPoint && !_isValveOpen) {
        _isValveOpen = true;
        print('Sending JSON: {$valveKey: "1"} - Resuming (Temp: $currentTemp >= $setPoint)');
        await serialService.sendJsonData({valveKey: "1"});
      }

      if (_isValveOpen) {
        await prefs.setInt('remainingSeconds', remaining - 1);
        print('Timer running: ${remaining - 1}s remaining');
      } else {
        print('Timer paused: ${remaining}s remaining');
      }
    });
  }

  void _finishBrewing(String beverageType) async {
    String valveKey = beverageType == 'tea' ? 'TBV' : 'CBV';
    print('Sending JSON: {$valveKey: "0"} - Brewing Complete');
    await serialService.sendJsonData({valveKey: "0"});

    _isValveOpen = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentBrewing');
    await prefs.remove('remainingSeconds');
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('strongCoffee_cpDelay', _delaySettings['strongCoffee']!['cpDelay']!);
    await prefs.setInt('strongCoffee_cpOnTime', _delaySettings['strongCoffee']!['cpOnTime']!);
    await prefs.setInt('strongCoffee_milkDelay', _delaySettings['strongCoffee']!['milkDelay']!);
    await prefs.setInt('strongCoffee_milkOnTime', _delaySettings['strongCoffee']!['milkOnTime']!);
    await prefs.setInt('strongCoffee_waterDelay', _delaySettings['strongCoffee']!['waterDelay']!);
    await prefs.setInt('strongCoffee_waterOnTime', _delaySettings['strongCoffee']!['waterOnTime']!);

    await prefs.setInt('liteCoffee_cpDelay', _delaySettings['liteCoffee']!['cpDelay']!);
    await prefs.setInt('liteCoffee_cpOnTime', _delaySettings['liteCoffee']!['cpOnTime']!);
    await prefs.setInt('liteCoffee_milkDelay', _delaySettings['liteCoffee']!['milkDelay']!);
    await prefs.setInt('liteCoffee_milkOnTime', _delaySettings['liteCoffee']!['milkOnTime']!);
    await prefs.setInt('liteCoffee_waterDelay', _delaySettings['liteCoffee']!['waterDelay']!);
    await prefs.setInt('liteCoffee_waterOnTime', _delaySettings['liteCoffee']!['waterOnTime']!);

    await prefs.setInt('blackCoffee_ctpDelay', _delaySettings['blackCoffee']!['ctpDelay']!);
    await prefs.setInt('blackCoffee_ctpOnTime', _delaySettings['blackCoffee']!['ctpOnTime']!);
    await prefs.setInt('blackCoffee_waterDelay', _delaySettings['blackCoffee']!['waterDelay']!);
    await prefs.setInt('blackCoffee_waterOnTime', _delaySettings['blackCoffee']!['waterOnTime']!);

    await prefs.setInt('strongTea_ttpDelay', _delaySettings['strongTea']!['ttpDelay']!);
    await prefs.setInt('strongTea_ttpOnTime', _delaySettings['strongTea']!['ttpOnTime']!);
    await prefs.setInt('strongTea_milkDelay', _delaySettings['strongTea']!['milkDelay']!);
    await prefs.setInt('strongTea_milkOnTime', _delaySettings['strongTea']!['milkOnTime']!);
    await prefs.setInt('strongTea_waterDelay', _delaySettings['strongTea']!['waterDelay']!);
    await prefs.setInt('strongTea_waterOnTime', _delaySettings['strongTea']!['waterOnTime']!);

    await prefs.setInt('liteTea_ttpDelay', _delaySettings['liteTea']!['ttpDelay']!);
    await prefs.setInt('liteTea_ttpOnTime', _delaySettings['liteTea']!['ttpOnTime']!);
    await prefs.setInt('liteTea_milkDelay', _delaySettings['liteTea']!['milkDelay']!);
    await prefs.setInt('liteTea_milkOnTime', _delaySettings['liteTea']!['milkOnTime']!);
    await prefs.setInt('liteTea_waterDelay', _delaySettings['liteTea']!['waterDelay']!);
    await prefs.setInt('liteTea_waterOnTime', _delaySettings['liteTea']!['waterOnTime']!);

    await prefs.setInt('blackTea_ttpDelay', _delaySettings['blackTea']!['ttpDelay']!);
    await prefs.setInt('blackTea_ttpOnTime', _delaySettings['blackTea']!['ttpOnTime']!);
    await prefs.setInt('blackTea_waterDelay', _delaySettings['blackTea']!['waterDelay']!);
    await prefs.setInt('blackTea_waterOnTime', _delaySettings['blackTea']!['waterOnTime']!);

    await prefs.setInt('dipTea_waterDelay', _delaySettings['dipTea']!['waterDelay']!);
    await prefs.setInt('dipTea_waterOnTime', _delaySettings['dipTea']!['waterOnTime']!);
    await prefs.setInt('dipTea_milkDelay', _delaySettings['dipTea']!['milkDelay']!);
    await prefs.setInt('dipTea_milkOnTime', _delaySettings['dipTea']!['milkOnTime']!);

    await prefs.setInt('hotMilk_milkDelay', _delaySettings['hotMilk']!['milkDelay']!);
    await prefs.setInt('hotMilk_milkOnTime', _delaySettings['hotMilk']!['milkOnTime']!);
    await prefs.setInt('hotMilk_waterDelay', _delaySettings['hotMilk']!['waterDelay']!);
    await prefs.setInt('hotMilk_waterOnTime', _delaySettings['hotMilk']!['waterOnTime']!);

    await prefs.setInt('hotWater_waterValveDelay', _delaySettings['hotWater']!['waterValveDelay']!);
    await prefs.setInt('hotWater_waterValveOnTime', _delaySettings['hotWater']!['waterValveOnTime']!);

    await prefs.setDouble('coffeeTemp', _coffeeTemp);
    await prefs.setDouble('teaTemp', _teaTemp);

    await prefs.setInt('teaClean', _teaClean);
    await prefs.setInt('coffeeClean', _coffeeClean);
    await prefs.setInt('milkClean', _milkClean);

    await prefs.setInt('teaCleanDelay', _teaCleanDelay);
    await prefs.setInt('coffeeCleanDelay', _coffeeCleanDelay);
    await prefs.setInt('milkCleanDelay', _milkCleanDelay);

    await prefs.setInt('milkPump', _milkPump);
    await prefs.setInt('teaPump', _teaPump);
    await prefs.setInt('coffeePump', _coffeePump);

    await prefs.setInt('count_strongCoffee', _drinkCounts['Strong Coffee']!);
    await prefs.setInt('count_liteCoffee', _drinkCounts['Lite Coffee']!);
    await prefs.setInt('count_blackCoffee', _drinkCounts['Black Coffee']!);
    await prefs.setInt('count_strongTea', _drinkCounts['Strong Tea']!);
    await prefs.setInt('count_liteTea', _drinkCounts['Lite Tea']!);
    await prefs.setInt('count_blackTea', _drinkCounts['Black Tea']!);
    await prefs.setInt('count_dipTea', _drinkCounts['Dip Tea']!);
    await prefs.setInt('count_hotMilk', _drinkCounts['Hot Milk']!);
    await prefs.setInt('count_hotWater', _drinkCounts['Hot Water']!);

    await prefs.setInt('count_strongCoffee', _limitCounts['Strong Coffee']!);
    await prefs.setInt('count_liteCoffee', _limitCounts['Lite Coffee']!);
    await prefs.setInt('count_blackCoffee', _limitCounts['Black Coffee']!);
    await prefs.setInt('count_strongTea', _limitCounts['Strong Tea']!);
    await prefs.setInt('count_liteTea', _limitCounts['Lite Tea']!);
    await prefs.setInt('count_blackTea', _limitCounts['Black Tea']!);
    await prefs.setInt('count_dipTea', _limitCounts['Dip Tea']!);
    await prefs.setInt('count_hotMilk', _limitCounts['Hot Milk']!);
    await prefs.setInt('count_hotWater', _limitCounts['Hot Water']!);


    await prefs.setInt('count_strongCoffee', _jumpCounts['Strong Coffee']!);
    await prefs.setInt('count_liteCoffee', _jumpCounts['Lite Coffee']!);
    await prefs.setInt('count_blackCoffee', _jumpCounts['Black Coffee']!);
    await prefs.setInt('count_strongTea', _jumpCounts['Strong Tea']!);
    await prefs.setInt('count_liteTea', _jumpCounts['Lite Tea']!);
    await prefs.setInt('count_blackTea', _jumpCounts['Black Tea']!);
    await prefs.setInt('count_dipTea', _jumpCounts['Dip Tea']!);
    await prefs.setInt('count_hotMilk', _jumpCounts['Hot Milk']!);
    await prefs.setInt('count_hotWater', _jumpCounts['Hot Water']!);

    await prefs.setString('companyName', _companyName);
    await prefs.setString('cleanAll', CleanAll);
    await prefs.setInt('configDelay', _configDelay);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Settings saved successfully!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF8B6B47),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _savePumpSpeeds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('teaPumpSpeed', _teaPumpSpeed);
    await prefs.setDouble('coffeePumpSpeed', _coffeePumpSpeed);
    await prefs.setDouble('milkPumpSpeed', _milkPumpSpeed);
  }

  void _showSaveConfirmationDialog(BuildContext context) {
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
                colors: [
                  const Color(0xFFFBF9F5),
                  const Color(0xFFEDE7DD),
                ],
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
                const Text(
                  'Confirm Save Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D3530),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to save all settings?\nThis will update all configurations.',
                  style: TextStyle(
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
                          'CANCEL',
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
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _saveSettings();
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
                          'SUBMIT',
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

  void _CleanallConfirmationDialog(BuildContext context) {
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
                colors: [
                  const Color(0xFFFBF9F5),
                  const Color(0xFFEDE7DD),
                ],
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
                const Text(
                  'Confirm Clean All',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D3530),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Are you sure you want to Clean all settings ?',
                  style: TextStyle(
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
                          'CANCEL',
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
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString('cleanAll', '30');
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) =>  Cleaningscreen(CleanTiming: 15,)),
                          );
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
                          'SUBMIT',
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


  void _showDelayInputDialog(String title, double currentValue, Color color, IconData icon, Function(double) onSet) {
    TextEditingController controller = TextEditingController(text: currentValue.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}\.?\d{0,1}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Value',
                  hintText: '(e.g., 12.5)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  prefixIcon: Icon(Icons.timer_outlined, color: color),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Max 99.9 seconds',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      double? newValue = double.tryParse(controller.text);
                      if (newValue != null && newValue >= 0 && newValue <= 99.9) {
                        onSet(newValue);
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid value (0 - 99.9)'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Set Value',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDecimalInputDialog(
      String title,
      double currentValue,
      Color color,
      IconData icon,
      Function(double) onSet,
      ) {
    TextEditingController controller = TextEditingController(text: currentValue.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}\.?\d{0,1}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Value',
                  hintText: '(e.g., 12.5)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                  prefixIcon: Icon(Icons.timer, color: color),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '(Max 99.9 seconds)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      double? newValue = double.tryParse(controller.text);
                      if (newValue != null && newValue >= 0 && newValue <= 99.9) {
                        onSet(newValue);
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid value (0 - 999.9)'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Set Value',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6B4423),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4423),
        foregroundColor: Colors.white,
        title:  Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Admin Panel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Gap(10),
                Text(
                  "|",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Gap(10),
                Text(
                  "Temp :",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:Colors.white,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  _tempError ? "Error" : "$_currentTemp° C",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _tempError ? Colors.red : Colors.white,
                  ),
                ),
              ],
            ),
            Text('Machine Configuration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70)),

          ],
        ),
        actions: [
          Visibility(
            visible: widget.userType != 'staff',
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                  onPressed: () async {
                    await _savePumpSpeeds();
                    _showSaveConfirmationDialog(context);
                  },
                  label: const Text('SAVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6B4423),
                  elevation: 4,
                  shadowColor: Colors.black45,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          isScrollable: false,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          tabs: widget.userType == 'staff'
              ? const [
            Tab(icon: Icon(Icons.thermostat, size: 20), text: 'Brewing'),
            Tab(icon: Icon(Icons.cleaning_services, size: 20), text: 'Cleaning'),
            Tab(icon: Icon(Icons.format_list_numbered, size: 20), text: 'Counts'),
          ]
              : const [
            Tab(icon: Icon(Icons.timer, size: 20), text: 'Delays'),
            Tab(icon: Icon(Icons.thermostat, size: 20), text: 'Brewing'),
            Tab(icon: Icon(Icons.cleaning_services, size: 20), text: 'Cleaning'),
            Tab(icon: Icon(Icons.replay, size: 20), text: 'Reverse'),
            Tab(icon: Icon(Icons.format_list_numbered, size: 20), text: 'Counts'),
            Tab(icon: Icon(Icons.speed, size: 20), text: 'Speed'),
            Tab(icon: Icon(Icons.settings, size: 20), text: 'Config'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: widget.userType == 'staff'
            ? [
          _buildSTAFFBrewingSettings(),
          _buildStaffCleaningSettings(context),
          _buildStaffCountsSettings(),
        ]
            : [
          _buildDelaySettings(),
          _buildBrewingSettings(),
          _buildCleaningSettings(context),
          _buildReverseSettings(),
          _buildCountsSettings(),
          _buildSpeedSettings(),
          _buildConfigSettings(),
        ],
      ),
    );
  }

  Widget _buildDelaySettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Configure timing delays and on-time duration for each beverage component.'),
          const SizedBox(height: 16),
          _buildDelayCard('Strong Coffee', 'strongCoffee', [
            {'key': 'cpDelay', 'label': 'Coffee Pump Delay', 'onTimeKey': 'cpOnTime'},
            {'key': 'milkDelay', 'label': 'Milk Pump Delay', 'onTimeKey': 'milkOnTime'},
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
          ]),
          _buildDelayCard('Lite Coffee', 'liteCoffee', [
            {'key': 'cpDelay', 'label': 'Coffee Pump Delay', 'onTimeKey': 'cpOnTime'},
            {'key': 'milkDelay', 'label': 'Milk Pump Delay', 'onTimeKey': 'milkOnTime'},
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
          ]),
          _buildDelayCard('Black Coffee', 'blackCoffee', [
            {'key': 'ctpDelay', 'label': 'Coffee Pump Delay', 'onTimeKey': 'ctpOnTime'},
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
          ]),
          _buildDelayCard('Strong Tea', 'strongTea', [
            {'key': 'ttpDelay', 'label': 'Tea Pump Delay', 'onTimeKey': 'ttpOnTime'},
            {'key': 'milkDelay', 'label': 'Milk Pump Delay', 'onTimeKey': 'milkOnTime'},
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
          ]),
          _buildDelayCard('Lite Tea', 'liteTea', [
            {'key': 'ttpDelay', 'label': 'Tea Pump Delay', 'onTimeKey': 'ttpOnTime'},
            {'key': 'milkDelay', 'label': 'Milk Pump Delay', 'onTimeKey': 'milkOnTime'},
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
          ]),
          _buildDelayCard('Black Tea', 'blackTea', [
            {'key': 'ttpDelay', 'label': 'Tea Pump Delay', 'onTimeKey': 'ttpOnTime'},
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
          ]),
          _buildDelayCard('Dip Tea', 'dipTea', [
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
            {'key': 'milkDelay', 'label': 'Milk Pump Delay', 'onTimeKey': 'milkOnTime'},
          ]),
          _buildDelayCard('Hot Milk', 'hotMilk', [
            {'key': 'milkDelay', 'label': 'Milk Pump Delay', 'onTimeKey': 'milkOnTime'},
            {'key': 'waterDelay', 'label': 'Hot Water Pump Delay', 'onTimeKey': 'waterOnTime'},
          ]),
          _buildDelayCard('Hot Water', 'hotWater', [
            {'key': 'waterValveDelay', 'label': 'Hot Water Valve Delay', 'onTimeKey': 'waterValveOnTime'},
          ]),
        ],
      ),
    );
  }

  Widget _buildDelayCard(String title, String beverageKey, List<Map<String, String>> fields) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_cafe, color: const Color(0xFF6B4423), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...fields.map((field) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildDelayRow(
                field['label']!,
                _delaySettings[beverageKey]![field['key']]!,
                _delaySettings[beverageKey]![field['onTimeKey']!]!,
                    (delayValue) {
                  setState(() {
                    _delaySettings[beverageKey]![field['key']!] = delayValue;
                  });
                },
                    (onTimeValue) {
                  setState(() {
                    _delaySettings[beverageKey]![field['onTimeKey']!] = onTimeValue;
                  });
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDelayRow(String label, int delayValue, int onTimeValue, Function(int) onDelayChanged, Function(int) onTimeChanged) {
    double delayDouble = delayValue / 10.0;
    double onTimeDouble = onTimeValue / 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delay', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => delayValue > 0 ? onDelayChanged(delayValue - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF6B4423),
                      ),
                      GestureDetector(
                        onTap: () => _showDelayInputDialog(
                          'Enter Delay',
                          delayDouble,
                          const Color(0xFF6B4423),
                          Icons.timer,
                              (newValue) {
                            int intValue = (newValue * 10).round();
                            onDelayChanged(intValue);
                          },
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4423).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${delayDouble.toStringAsFixed(1)} sec',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6B4423)),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onDelayChanged(delayValue + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF6B4423),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('On Time', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => onTimeValue > 0 ? onTimeChanged(onTimeValue - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF6B4423),
                      ),
                      GestureDetector(
                        onTap: () => _showDelayInputDialog(
                          'Enter On Time',
                          onTimeDouble,
                          const Color(0xFF6B4423),
                          Icons.timer,
                              (newValue) {
                            int intValue = (newValue * 10).round();
                            onTimeChanged(intValue);
                          },
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4423).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${onTimeDouble.toStringAsFixed(1)} sec',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6B4423)),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onTimeChanged(onTimeValue + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF6B4423),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget _buildDelayRow(String label, int delayValue, int onTimeValue, Function(int) onDelayChanged, Function(int) onTimeChanged) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  //       ),
  //       const SizedBox(height: 8),
  //       Row(
  //         children: [
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text('Delay', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
  //                 const SizedBox(height: 4),
  //                 Row(
  //                   children: [
  //                     IconButton(
  //                       onPressed: () => delayValue > 0 ? onDelayChanged(delayValue - 1) : null,
  //                       icon: const Icon(Icons.remove_circle_outline),
  //                       color: const Color(0xFF6B4423),
  //                     ),
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                       decoration: BoxDecoration(
  //                         color: const Color(0xFF6B4423).withOpacity(0.1),
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       child: Text(
  //                         '$delayValue sec',
  //                         style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6B4423)),
  //                       ),
  //                     ),
  //                     IconButton(
  //                       onPressed: () => onDelayChanged(delayValue + 1),
  //                       icon: const Icon(Icons.add_circle_outline),
  //                       color: const Color(0xFF6B4423),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //           const SizedBox(width: 8),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text('On Time', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
  //                 const SizedBox(height: 4),
  //                 Row(
  //                   children: [
  //                     IconButton(
  //                       onPressed: () => onTimeValue > 0 ? onTimeChanged(onTimeValue - 1) : null,
  //                       icon: const Icon(Icons.remove_circle_outline),
  //                       color: const Color(0xFF6B4423),
  //                     ),
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                       decoration: BoxDecoration(
  //                         color: const Color(0xFF6B4423).withOpacity(0.1),
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       child: Text(
  //                         '$onTimeValue sec',
  //                         style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6B4423)),
  //                       ),
  //                     ),
  //                     IconButton(
  //                       onPressed: () => onTimeChanged(onTimeValue + 1),
  //                       icon: const Icon(Icons.add_circle_outline),
  //                       color: const Color(0xFF6B4423),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _buildBrewingSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Set optimal brewing temperatures for coffee and tea (20-99°C).'),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildTemperatureSlider(
                    'Coffee Brewing Temperature',
                    _coffeeTemp,
                    Icons.coffee,
                    Colors.brown,
                        (value) => setState(() => _coffeeTemp = value),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('On Time', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _coffeOnTimeValue > 0 ? setState(() => _coffeOnTimeValue = (_coffeOnTimeValue - 0.1).clamp(0, 999.9)) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.brown,
                          ),
                          GestureDetector(
                            onTap: () => _showDecimalInputDialog(
                              'Enter Coffee On Time',
                              _coffeOnTimeValue,
                              Colors.brown,
                              Icons.coffee,
                                  (value) => setState(() => _coffeOnTimeValue = value),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.brown.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${_coffeOnTimeValue.toStringAsFixed(1)} s',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _coffeOnTimeValue = (_coffeOnTimeValue + 0.1).clamp(0, 999.9)),
                            icon: const Icon(Icons.add_circle_outline),
                            color: Colors.brown,
                          ),
                        ],
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () {
                            _startAUTOBrewing('coffee', _coffeOnTimeValue, _coffeeTemp);
                          print('Coffee Temp Set: $_coffeeTemp°C');
                        },
                        child: const Text('Brew Coffee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Divider(height: 40),
                  _buildTemperatureSlider(
                    'Tea Brewing Temperature',
                    _teaTemp,
                    Icons.emoji_food_beverage,
                    Colors.green,
                        (value) => setState(() => _teaTemp = value),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('On Time', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _teaOnTimeValue > 0 ? setState(() => _teaOnTimeValue = (_teaOnTimeValue - 0.1).clamp(0, 999.9)) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: Colors.green,
                          ),
                          GestureDetector(
                            onTap: () => _showDecimalInputDialog(
                              'Enter Tea On Time',
                              _teaOnTimeValue,
                              Colors.green,
                              Icons.emoji_food_beverage,
                                  (value) => setState(() => _teaOnTimeValue = value),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${_teaOnTimeValue.toStringAsFixed(1)} s',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _teaOnTimeValue = (_teaOnTimeValue + 0.1).clamp(0, 999.9)),
                            icon: const Icon(Icons.add_circle_outline),
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        _startAUTOBrewing('tea', _teaOnTimeValue, _teaTemp);
                        print('Tea Temp Set: $_teaTemp°C');
                      },
                      child: const Text('Brew Tea', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSTAFFBrewingSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.coffee, color: Colors.brown, size: 24),
                      SizedBox(width: 12),
                      Text('Coffee Brewing Temperature', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.brown.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.brown.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${_coffeeTemp.round()}°C',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          print('Coffee Temp Set: $_coffeeTemp°C');
                        },
                        child: const Text('Brew Coffee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 40),
                  Row(
                    children: [
                      Icon(Icons.emoji_food_beverage, color: Colors.green, size: 24),
                      SizedBox(width: 12),
                      Text('Tea Brewing Temperature', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${_teaTemp.round()}°C',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          print('Tea Temp Set:: $_teaTemp°C');
                        },
                        child: const Text('Brew Tea', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureSlider(String label, double value, IconData icon, Color color, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: 20,
                max: 99,
                divisions: 79,
                activeColor: color,
                label: '${value.round()}°C',
                onChanged: onChanged,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                '${value.round()}°C',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCleaningSettings(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Configure automatic cleaning delay and duration for each component.'),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildCleaningItem('Tea Cleaning', _teaClean, _teaCleanDelay, Icons.emoji_food_beverage, Colors.green,
                          (value) => setState(() => _teaClean = value),
                          (delay) => setState(() => _teaCleanDelay = delay)),
                  const Divider(height: 32),
                  _buildCleaningItem('Coffee Cleaning', _coffeeClean, _coffeeCleanDelay, Icons.coffee, Colors.brown,
                          (value) => setState(() => _coffeeClean = value),
                          (delay) => setState(() => _coffeeCleanDelay = delay)),
                  const Divider(height: 32),
                  _buildCleaningItem('Milk Cleaning', _milkClean, _milkCleanDelay, Icons.water_drop, Colors.blue,
                          (value) => setState(() => _milkClean = value),
                          (delay) => setState(() => _milkCleanDelay = delay)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCleaningSettings(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_food_beverage, color: Colors.green, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text("Tea Cleaning", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          int brewValveOnTime = _teaCleanDelay ~/ 10;
                          int pumpOnTime = _teaClean;
                          int totalSeconds = brewValveOnTime + pumpOnTime;
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString('cleanTea', totalSeconds.toString());
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Cleaningscreen(CleanTiming: totalSeconds)));

                          await SerialService().sendJsonData({"TBV": "1"});
                          await Future.delayed(Duration(seconds: brewValveOnTime));
                          await SerialService().sendJsonData({"TBV": "0"});
                          await SerialService().sendJsonData({"TP_FWD": "${_teaPumpSpeed.toInt()}", "TP_REV": "0"});
                          await Future.delayed(Duration(seconds: pumpOnTime));
                          await SerialService().sendJsonData({"TP_FWD": "0", "TP_REV": "0"});

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Text("Clean Tea", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Icon(Icons.coffee, color: Colors.brown, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text("Coffee Cleaning", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          int brewValveOnTime = _coffeeCleanDelay ~/ 10;
                          int pumpOnTime = _coffeeClean;
                          int totalSeconds = brewValveOnTime + pumpOnTime;
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString('cleanCoffee', totalSeconds.toString());
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Cleaningscreen(CleanTiming: totalSeconds)));


                          await SerialService().sendJsonData({"CBV": "1"});
                          await Future.delayed(Duration(seconds: brewValveOnTime));
                          await SerialService().sendJsonData({"CBV": "0"});
                          await SerialService().sendJsonData({"CP_FWD": "${_coffeePumpSpeed.toInt()}", "CP_REV": "0"});
                          await Future.delayed(Duration(seconds: pumpOnTime));
                          await SerialService().sendJsonData({"CP_FWD": "0", "CP_REV": "0"});

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Text("Clean Coffee", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Icon(Icons.water_drop, color: Colors.blue, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text("Milk Cleaning", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          int totalSendSeconds =_milkCleanDelay + _milkClean;
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          int pumpOnTime = _milkClean;
                          int totalSeconds = pumpOnTime;
                          await prefs.setString('cleanMilk', totalSeconds.toString());
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Cleaningscreen(CleanTiming: totalSendSeconds)));

                          await SerialService().sendJsonData({"MAV": "1", "MP_FWD": "${_milkPumpSpeed.toInt()}"});
                          await Future.delayed(Duration(seconds: pumpOnTime));
                          await SerialService().sendJsonData({"MAV": "0", "MP_FWD": "0"});

                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Text("Clean Milk", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCleaningItem(String label, int value, int delayValue, IconData icon, Color color, Function(int) onChanged, Function(int) onDelayChanged) {
    double delayDouble = delayValue / 10.0;
    double durationDouble = value / 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Brewing Valve On time', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => delayValue > 0 ? onDelayChanged(delayValue - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: color,
                      ),
                      GestureDetector(
                        onTap: () => _showDelayInputDialog(
                          'Enter Delay',
                          delayDouble,
                          color,
                          icon,
                              (newValue) {
                            int intValue = (newValue * 10).round();
                            onDelayChanged(intValue);
                          },
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${delayDouble.toStringAsFixed(1)} sec', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onDelayChanged(delayValue + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        color: color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pump on Time', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => value > 0 ? onChanged(value - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: color,
                      ),
                      GestureDetector(
                        onTap: () => _showDelayInputDialog(
                          'Enter Duration',
                          durationDouble,
                          color,
                          icon,
                              (newValue) {
                            int intValue = (newValue * 10).round();
                            onChanged(intValue);
                          },
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('$value sec', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onChanged(value + 1),
                        icon: const Icon(Icons.add_circle_outline),
                        color: color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                int brewValveOnTime = delayValue ~/ 10;
                int pumpOnTime = value;
                String type = label.split(' ')[0];
                int totalSeconds = brewValveOnTime + pumpOnTime;

                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('clean$type', totalSeconds.toString());

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Cleaningscreen(CleanTiming: totalSeconds)),
                );

                if (type == 'Tea') {
                  SerialService().sendJsonData({"TBV": "1"}).then((_) async {
                    await Future.delayed(Duration(seconds: brewValveOnTime));
                    await SerialService().sendJsonData({"TBV": "0"});
                    await SerialService().sendJsonData({"TP_FWD": "${_teaPumpSpeed.toInt()}", "TP_REV": "0"});
                    await Future.delayed(Duration(seconds: pumpOnTime));
                    await SerialService().sendJsonData({"TP_FWD": "0", "TP_REV": "0"});
                  });
                } else if (type == 'Coffee') {
                  SerialService().sendJsonData({"CBV": "1"}).then((_) async {
                    await Future.delayed(Duration(seconds: brewValveOnTime));
                    await SerialService().sendJsonData({"CBV": "0"});
                    await SerialService().sendJsonData({"CP_FWD": "${_coffeePumpSpeed.toInt()}", "CP_REV": "0"});
                    await Future.delayed(Duration(seconds: pumpOnTime));
                    await SerialService().sendJsonData({"CP_FWD": "0", "CP_REV": "0"});
                  });
                } else if (type == 'Milk') {
                  SerialService().sendJsonData({"MAV": "1", "MP_FWD": "${_milkPumpSpeed.toInt()}"}).then((_) async {
                    await Future.delayed(Duration(seconds: pumpOnTime));
                    await SerialService().sendJsonData({"MAV": "0", "MP_FWD": "0"});
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }


  // Widget _buildCleaningItem(String label, int value, int delayValue, IconData icon, Color color, Function(int) onChanged, Function(int) onDelayChanged) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           Icon(icon, color: color, size: 28),
  //           const SizedBox(width: 16),
  //           Expanded(
  //             child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 16),
  //       Row(
  //         children: [
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text('Delay', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
  //                 const SizedBox(height: 4),
  //                 Row(
  //                   children: [
  //                     IconButton(
  //                       onPressed: () => delayValue > 0 ? onDelayChanged(delayValue - 1) : null,
  //                       icon: const Icon(Icons.remove_circle_outline),
  //                       color: color,
  //                     ),
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                       decoration: BoxDecoration(
  //                         color: color.withOpacity(0.1),
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       child: Text('$delayValue sec', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
  //                     ),
  //                     IconButton(
  //                       onPressed: () => onDelayChanged(delayValue + 1),
  //                       icon: const Icon(Icons.add_circle_outline),
  //                       color: color,
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //           const SizedBox(width: 8),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text('Duration', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
  //                 const SizedBox(height: 4),
  //                 Row(
  //                   children: [
  //                     IconButton(
  //                       onPressed: () => value > 0 ? onChanged(value - 1) : null,
  //                       icon: const Icon(Icons.remove_circle_outline),
  //                       color: color,
  //                     ),
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                       decoration: BoxDecoration(
  //                         color: color.withOpacity(0.1),
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       child: Text('$value sec', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
  //                     ),
  //                     IconButton(
  //                       onPressed: () => onChanged(value + 1),
  //                       icon: const Icon(Icons.add_circle_outline),
  //                       color: color,
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //           // Spacer(),
  //           ElevatedButton(
  //             onPressed: () {
  //               print('$label triggered');
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: color,
  //               foregroundColor: Colors.white,
  //               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(5),
  //               ),
  //             ),
  //             child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildCleaningItem(String label, int value, int delayValue, IconData icon, Color color, Function(int) onChanged, Function(int) onDelayChanged) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           Icon(icon, color: color, size: 28),
  //           const SizedBox(width: 16),
  //           Expanded(
  //             child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 16),
  //       Row(
  //         children: [
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text('Delay', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
  //                 const SizedBox(height: 4),
  //                 Row(
  //                   children: [
  //                     IconButton(
  //                       onPressed: () => delayValue > 0 ? onDelayChanged(delayValue - 1) : null,
  //                       icon: const Icon(Icons.remove_circle_outline),
  //                       color: color,
  //                     ),
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                       decoration: BoxDecoration(
  //                         color: color.withOpacity(0.1),
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       child: Text('$delayValue sec', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
  //                     ),
  //                     IconButton(
  //                       onPressed: () => onDelayChanged(delayValue + 1),
  //                       icon: const Icon(Icons.add_circle_outline),
  //                       color: color,
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //           const SizedBox(width: 8),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text('Duration', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
  //                 const SizedBox(height: 4),
  //                 Row(
  //                   children: [
  //                     IconButton(
  //                       onPressed: () => value > 0 ? onChanged(value - 1) : null,
  //                       icon: const Icon(Icons.remove_circle_outline),
  //                       color: color,
  //                     ),
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                       decoration: BoxDecoration(
  //                         color: color.withOpacity(0.1),
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       child: Text('$value sec', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
  //                     ),
  //                     IconButton(
  //                       onPressed: () => onChanged(value + 1),
  //                       icon: const Icon(Icons.add_circle_outline),
  //                       color: color,
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _buildReverseSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Set delay timing to reverse pumps and return liquid to storage.'),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildReverseItem('Milk Pump Reverse', _milkPumpDelay, _milkPumpOnTime, _milkPumpForwardTime, Icons.water_drop, Colors.blue,
                      onDelayChanged: (value) => setState(() => _milkPumpDelay = value),
                      onOnTimeChanged: (value) => setState(() => _milkPumpOnTime = value),
                      onForwardTimeChanged: (value) => setState(() => _milkPumpForwardTime = value),
                      onReverse: () => print('Milk Pump Reverse triggered')),
                  const Divider(height: 32),
                  _buildReverseItem('Tea Pump Reverse', _teaPumpDelay, _teaPumpOnTime, _teaPumpForwardTime, Icons.emoji_food_beverage, Colors.green,
                      onDelayChanged: (value) => setState(() => _teaPumpDelay = value),
                      onOnTimeChanged: (value) => setState(() => _teaPumpOnTime = value),
                      onForwardTimeChanged: (value) => setState(() => _teaPumpForwardTime = value),
                      onReverse: () => print('Tea Pump Reverse triggered')),
                  const Divider(height: 32),
                  _buildReverseItem('Coffee Pump Reverse', _coffeePumpDelay, _coffeePumpOnTime, _coffeePumpForwardTime, Icons.coffee, Colors.brown,
                      onDelayChanged: (value) => setState(() => _coffeePumpDelay = value),
                      onOnTimeChanged: (value) => setState(() => _coffeePumpOnTime = value),
                      onForwardTimeChanged: (value) => setState(() => _coffeePumpForwardTime = value),
                      onReverse: () => print('Coffee Pump Reverse triggered')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildReverseItem(
      String label,
      double delayValue,
      double onTimeValue,
      double forwardTimeValue,
      IconData icon,
      Color color, {
        required Function(double) onDelayChanged,
        required Function(double) onOnTimeChanged,
        required Function(double) onForwardTimeChanged,
        required VoidCallback onReverse,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delay', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => delayValue > 0 ? onDelayChanged((delayValue - 0.1).clamp(0, 999.9)) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: color,
                      ),
                      GestureDetector(
                        onTap: () => _showDecimalInputDialog(
                          'Enter Delay',
                          delayValue,
                          color,
                          icon,
                          onDelayChanged,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${delayValue.toStringAsFixed(1)} s',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onDelayChanged((delayValue + 0.1).clamp(0, 999.9)),
                        icon: const Icon(Icons.add_circle_outline),
                        color: color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('On Time', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => onTimeValue > 0 ? onOnTimeChanged((onTimeValue - 0.1).clamp(0, 999.9)) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: color,
                      ),
                      GestureDetector(
                        onTap: () => _showDecimalInputDialog(
                          'Enter On Time',
                          onTimeValue,
                          color,
                          icon,
                          onOnTimeChanged,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${onTimeValue.toStringAsFixed(1)} s',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onOnTimeChanged((onTimeValue + 0.1).clamp(0, 999.9)),
                        icon: const Icon(Icons.add_circle_outline),
                        color: color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Forward Time', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => forwardTimeValue > 0 ? onForwardTimeChanged((forwardTimeValue - 0.1).clamp(0, 999.9)) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: color,
                      ),
                      GestureDetector(
                        onTap: () => _showDecimalInputDialog(
                          'Enter Forward Time',
                          forwardTimeValue,
                          color,
                          icon,
                          onForwardTimeChanged,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${forwardTimeValue.toStringAsFixed(1)} s',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onForwardTimeChanged((forwardTimeValue + 0.1).clamp(0, 999.9)),
                        icon: const Icon(Icons.add_circle_outline),
                        color: color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: onReverse,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Reverse', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }


  // Widget _buildReverseItem(
  //     String label,
  //     double delayValue,
  //     double onTimeValue,
  //     double forwardTimeValue,
  //     IconData icon,
  //     Color color, {
  //       required Function(double) onDelayChanged,
  //       required Function(double) onOnTimeChanged,
  //       required Function(double) onForwardTimeChanged,
  //       required VoidCallback onReverse,
  //     }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           Icon(icon, color: color, size: 28),
  //           const SizedBox(width: 16),
  //           Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //         ],
  //       ),
  //       const SizedBox(height: 16),
  //       Row(
  //         children: [
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text('Delay', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600)),
  //                 const SizedBox(height: 8),
  //                 Row(
  //                   children: [
  //                     IconButton(
  //                       onPressed: () => delayValue > 0 ? onDelayChanged((delayValue - 0.1).clamp(0, 999.9)) : null,
  //                       icon: const Icon(Icons.remove_circle_outline),
  //                       color: color,
  //                     ),
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                       decoration: BoxDecoration(
  //                         color: color.withOpacity(0.1),
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       child: Text('${delayValue.toStringAsFixed(1)} s',
  //                           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
  //                     ),
  //                     IconButton(
  //                       onPressed: () => onDelayChanged((delayValue + 0.1).clamp(0, 999.9)),
  //                       icon: const Icon(Icons.add_circle_outline),
  //                       color: color,
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //           const SizedBox(width: 8),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text('On Time', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600)),
  //                 const SizedBox(height: 8),
  //                 Row(
  //                   children: [
  //                     IconButton(
  //                       onPressed: () => onTimeValue > 0 ? onOnTimeChanged((onTimeValue - 0.1).clamp(0, 999.9)) : null,
  //                       icon: const Icon(Icons.remove_circle_outline),
  //                       color: color,
  //                     ),
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                       decoration: BoxDecoration(
  //                         color: color.withOpacity(0.1),
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       child: Text('${onTimeValue.toStringAsFixed(1)} s',
  //                           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
  //                     ),
  //                     IconButton(
  //                       onPressed: () => onOnTimeChanged((onTimeValue + 0.1).clamp(0, 999.9)),
  //                       icon: const Icon(Icons.add_circle_outline),
  //                       color: color,
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 12),
  //       Row(
  //         children: [
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text('Forward Time', style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600)),
  //                 const SizedBox(height: 8),
  //                 Row(
  //                   children: [
  //                     IconButton(
  //                       onPressed: () => forwardTimeValue > 0 ? onForwardTimeChanged((forwardTimeValue - 0.1).clamp(0, 999.9)) : null,
  //                       icon: const Icon(Icons.remove_circle_outline),
  //                       color: color,
  //                     ),
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                       decoration: BoxDecoration(
  //                         color: color.withOpacity(0.1),
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       child: Text('${forwardTimeValue.toStringAsFixed(1)} s',
  //                           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
  //                     ),
  //                     IconButton(
  //                       onPressed: () => onForwardTimeChanged((forwardTimeValue + 0.1).clamp(0, 999.9)),
  //                       icon: const Icon(Icons.add_circle_outline),
  //                       color: color,
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //           const SizedBox(width: 16),
  //           ElevatedButton(
  //             onPressed: onReverse,
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: color,
  //               foregroundColor: Colors.white,
  //               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //             ),
  //             child: const Text('Reverse', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _buildCountsSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Track beverage consumption counts. tap reset to clear.'),
          const SizedBox(height: 16),
          ..._drinkCounts.keys.map((drink) => _buildCountItem(drink)).toList(),
        ],
      ),
    );
  }

  Widget _buildCountItem(String drinkName) {
    IconData icon;
    Color color;

    if (drinkName.contains('Coffee')) {
      icon = Icons.coffee;
      color = Colors.brown;
    } else if (drinkName.contains('Tea')) {
      icon = Icons.emoji_food_beverage;
      color = Colors.green;
    } else if (drinkName.contains('Milk')) {
      icon = Icons.water_drop;
      color = Colors.blue;
    } else {
      icon = Icons.local_drink;
      color = Colors.cyan;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(drinkName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Total served', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildCountControl(
                    'LC',
                    _limitCounts[drinkName]!,
                    _limitCountControls[drinkName]!,
                    color,
                        (value) => setState(() => _limitCounts[drinkName] = value),
                        (show) => setState(() => _limitCountControls[drinkName] = show),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCountControl(
                    'JC',
                    _jumpCounts[drinkName]!,
                    _jumpCountControls[drinkName]!,
                    color,
                        (value) => setState(() => _jumpCounts[drinkName] = value),
                        (show) => setState(() => _jumpCountControls[drinkName] = show),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCountControl(
                    'AC',
                    _drinkCounts[drinkName]!,
                    _showCountControls[drinkName]!,
                    color,
                        (value) => setState(() => _drinkCounts[drinkName] = value),
                        (show) => setState(() => _showCountControls[drinkName] = show),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _drinkCounts[drinkName] = 0;
                    _limitCounts[drinkName] = 0;
                    _jumpCounts[drinkName] = 0;
                    _showCountControls[drinkName] = false;
                    _limitCountControls[drinkName] = false;
                    _jumpCountControls[drinkName] = false;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child:  Text('Reset all', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountControl(
      String label,
      int value,
      bool showControls,
      Color color,
      Function(int) onValueChanged,
      Function(bool) onShowControlsChanged,
      ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showControls)
              IconButton(
                onPressed: () {
                  if (value > 0) {
                    onValueChanged(value - 1);
                  }
                  Future.delayed(const Duration(seconds: 5), () {
                    onShowControlsChanged(false);
                  });
                },
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: color,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (showControls) const SizedBox(width: 4),
            GestureDetector(
              onLongPress: () {
                Future.delayed(const Duration(seconds: 2), () {
                  onShowControlsChanged(!showControls);
                  if (!showControls) {
                    Future.delayed(const Duration(seconds: 5), () {
                      onShowControlsChanged(false);
                    });
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  '$value',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ),
            if (showControls) const SizedBox(width: 4),
            if (showControls)
              IconButton(
                onPressed: () {
                  onValueChanged(value + 1);
                  Future.delayed(const Duration(seconds: 5), () {
                    onShowControlsChanged(false);
                  });
                },
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: color,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ],
    );
  }


  Widget _buildSpeedSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Configure motor speed for each pump.'),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSpeedSlider(
                    'Tea Pump Speed',
                    _teaPumpSpeed,
                    Icons.emoji_food_beverage,
                    Colors.green,
                        (value) {
                      setState(() => _teaPumpSpeed = value);
                      _savePumpSpeeds();
                    },
                  ),
                  const Divider(height: 40),
                  _buildSpeedSlider(
                    'Coffee Pump Speed',
                    _coffeePumpSpeed,
                    Icons.coffee,
                    Colors.brown,
                        (value) {
                      setState(() => _coffeePumpSpeed = value);
                      _savePumpSpeeds();
                    },
                  ),
                  const Divider(height: 40),
                  _buildSpeedSlider(
                    'Milk Pump Speed',
                    _milkPumpSpeed,
                    Icons.water_drop,
                    Colors.blue,
                        (value) {
                      setState(() => _milkPumpSpeed = value);
                      _savePumpSpeeds();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedSlider(String label, double value, IconData icon, Color color, Function(double) onChanged) {
    TextEditingController controller = TextEditingController(text: value.round().toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: 100,
                max: 250,
                divisions: 973,
                activeColor: color,
                label: '${value.round()}',
                onChanged: onChanged,
              ),
            ),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      width: 400,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, color: color, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Enter $label',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            autofocus: true,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              TextInputFormatter.withFunction((oldValue, newValue) {
                                if (newValue.text.isEmpty) return newValue;

                                final int value = int.parse(newValue.text);
                                if (value > 250) {
                                  return oldValue; // block values > 1000
                                }
                                return newValue;
                              }),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Speed Value',
                              hintText: 'Enter value (100 -250)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: color, width: 2),
                              ),
                              prefixIcon: Icon(Icons.speed, color: color),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Valid range: 100 - 250',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  int? newValue = int.tryParse(controller.text);
                                  if (newValue != null && newValue >= 100 && newValue <= 250) {
                                    onChanged(newValue.toDouble());
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter a valid value between 100 and 250'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Set Speed',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.4), width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${value.round()}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfigSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard('Configure company information and general machine settings.'),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business, color: const Color(0xFF6B4423), size: 24),
                      const SizedBox(width: 12),
                      const Text('Company Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: _companyName)..selection = TextSelection.fromPosition(TextPosition(offset: _companyName.length)),
                    decoration: InputDecoration(
                      hintText: 'Enter company name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF6B4423), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _companyName = value;
                      });
                    },
                  ),
                  const Divider(height: 40),
                  Row(
                    children: [
                      Icon(Icons.timer, color: const Color(0xFF6B4423), size: 24),
                      const SizedBox(width: 12),
                      const Text('ScreenSaver Timer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _configDelay > 0 ? setState(() => _configDelay--) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFF6B4423),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B4423).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_configDelay sec',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6B4423)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _configDelay++),
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF6B4423),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (widget.userType == 'admin' || widget.userType == 'developer')
                    Row(
                      children: [
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _showChangePasswordDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B4423),
                              padding: const EdgeInsets.symmetric(vertical: 12,horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: _showResetAllDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              padding: const EdgeInsets.symmetric(vertical: 12,horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Reset All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4423).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF6B4423).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: const Color(0xFF6B4423)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF6B4423), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCountsSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ..._drinkCounts.keys.map((drink) => _buildStaffCountItem(drink)).toList(),
        ],
      ),
    );
  }

  Widget _buildStaffCountItem(String drinkName) {
    IconData icon;
    Color color;

    if (drinkName.contains('Coffee')) {
      icon = Icons.coffee;
      color = Colors.brown;
    } else if (drinkName.contains('Tea')) {
      icon = Icons.emoji_food_beverage;
      color = Colors.green;
    } else if (drinkName.contains('Milk')) {
      icon = Icons.water_drop;
      color = Colors.blue;
    } else {
      icon = Icons.local_drink;
      color = Colors.cyan;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(drinkName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                '${_drinkCounts[drinkName]!}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final _currentPassController = TextEditingController();
    final _newPassController = TextEditingController();
    final _confirmPassController = TextEditingController();

    bool _showCurrentPass = false;
    bool _showNewPass = false;
    bool _showConfirmPass = false;

    bool _isVerified = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,

              title: Row(
                children: [
                  Icon(Icons.lock, color: Color(0xFF6B4423), size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4423),
                    ),
                  ),
                ],
              ),

              content: SizedBox(
                width: 420, // ✅ WIDER DIALOG
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      /// CURRENT PASSWORD
                      TextField(
                        controller: _currentPassController,
                        readOnly: _isVerified, // ✅ FIXED
                        obscureText: !_showCurrentPass,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF6B4423)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showCurrentPass
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Color(0xFF6B4423),
                            ),
                            onPressed: () =>
                                setDialogState(() => _showCurrentPass = !_showCurrentPass),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// VERIFY BUTTON (HIDDEN AFTER VERIFIED)
                      if (!_isVerified)
                        ElevatedButton.icon(
                          onPressed: () {
                            String currentPass = _currentPassController.text;

                            bool isValid =
                                (widget.userType == 'admin' &&
                                    currentPass == '987654') ||
                                    (widget.userType == 'developer' &&
                                        currentPass == '3');

                            if (isValid) {
                              setDialogState(() {
                                _currentPassController.text = 'verified';
                                _isVerified = true; // ✅ HIDE BUTTON
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password verified'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Invalid password'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Verify'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6B4423),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                      /// NEW PASSWORD FIELDS (SHOW AFTER VERIFIED)
                      if (_isVerified) ...[
                        const SizedBox(height: 20),

                        TextField(
                          controller: _newPassController,
                          obscureText: !_showNewPass,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon:
                            Icon(Icons.lock_outline, color: Color(0xFF6B4423)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showNewPass
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Color(0xFF6B4423),
                              ),
                              onPressed: () =>
                                  setDialogState(() => _showNewPass = !_showNewPass),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _confirmPassController,
                          obscureText: !_showConfirmPass,
                          decoration: InputDecoration(
                            labelText: 'Re-enter New Password',
                            prefixIcon:
                            Icon(Icons.lock_outline, color: Color(0xFF6B4423)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirmPass
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Color(0xFF6B4423),
                              ),
                              onPressed: () => setDialogState(
                                      () => _showConfirmPass = !_showConfirmPass),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Color(0xFF6B4423),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                if (_isVerified)
                  ElevatedButton(
                    onPressed: () {
                      if (_newPassController.text ==
                          _confirmPassController.text &&
                          _newPassController.text.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password changed successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6B4423),
                    ),
                    child: const Text('Submit',style: TextStyle(color: Colors.white,fontSize: 18),),
                  ),
              ],
            );
          },
        );
      },
    );
  }


  void _showResetAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
              const SizedBox(width: 12),
              const Text('Reset All Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Text(
                  'Are you sure you want to reset all data ? This action cannot be undone.',
                  style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been reset'), backgroundColor: Colors.red),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Reset All', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

}