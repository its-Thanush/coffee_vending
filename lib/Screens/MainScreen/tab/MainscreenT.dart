import 'dart:convert';

import 'package:coffee_vending/Screens/MainScreen/bloc/main_screen_bloc.dart';
import 'package:coffee_vending/Screens/MainScreen/tab/MainscreenT.dart';
import 'package:coffee_vending/Screens/adminLogin/tab/AdminScreenLoginT.dart';
import 'package:coffee_vending/Widgets/WavePainter.dart';
import 'package:coffee_vending/helper/customtext.dart';
import 'package:coffee_vending/model/ItemDataModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    bloc=BlocProvider.of<MainScreenBloc>(context);
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

    bloc.connectionCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkNodeMCUConnection();
    });

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

  @override
  void dispose() {
    bloc.connectionCheckTimer?.cancel();
    bloc.timer.cancel();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];

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
    }else if (bloc.selectedItem == 'c2') {
      await _executeLiteCoffeeSequence();
    }else if (bloc.selectedItem == 'c3') {
      await _executeBlackCoffeeSequence();
    }else if (bloc.selectedItem == 't1') {
      await _executeStrongTeaSequence();
    } else if (bloc.selectedItem == 't2') {
      await _executeLiteTeaSequence();
    } else if (bloc.selectedItem == 't3') {
      await _executeBlackTeaSequence();
    }else if (bloc.selectedItem == 't4') {
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

    print("Sending Coffee Pump ON: {CP_FWD: 1023, CP_REV: 0}");
    await bloc.serialService.sendJsonData({"CP_FWD": "1023", "CP_REV": "0"});

    print("Waiting cpOnTime: $cpOnTime seconds");
    await Future.delayed(Duration(seconds: cpOnTime));
    print("cpOnTime complete");

    print("Sending Coffee Pump OFF: {CP_FWD: 0, CP_REV: 0}");
    await bloc.serialService.sendJsonData({"CP_FWD": "0", "CP_REV": "0"});

    print("Waiting milkDelay: $milkDelay seconds");
    await Future.delayed(Duration(seconds: milkDelay));
    print("milkDelay complete");

    print("Sending Milk Pump ON: {MAV: 1, MP_FWD: 1023, MP_REV: 0}");
    await bloc.serialService.sendJsonData({"MAV": "1", "MP_FWD": "1023", "MP_REV": "0"});

    print("Waiting milkOnTime: $milkOnTime seconds");
    await Future.delayed(Duration(seconds: milkOnTime));
    print("milkOnTime complete");

    print("Sending Milk Pump OFF: {MAV: 0, MP_FWD: 0, MP_REV: 0}");
    await bloc.serialService.sendJsonData({"MAV": "0", "MP_FWD": "0", "MP_REV": "0"});

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

    print("Sending Coffee Pump ON: {CP_FWD: 1023, CP_REV: 0}");
    await bloc.serialService.sendJsonData({"CP_FWD": "1023", "CP_REV": "0"});

    print("Waiting cpOnTime: $cpOnTime seconds");
    await Future.delayed(Duration(seconds: cpOnTime));
    print("cpOnTime complete");

    print("Sending Coffee Pump OFF: {CP_FWD: 0, CP_REV: 0}");
    await bloc.serialService.sendJsonData({"CP_FWD": "0", "CP_REV": "0"});

    print("Waiting milkDelay: $milkDelay seconds");
    await Future.delayed(Duration(seconds: milkDelay));
    print("milkDelay complete");

    print("Sending Milk Pump ON: {MAV: 1, MP_FWD: 1023, MP_REV: 0}");
    await bloc.serialService.sendJsonData({"MAV": "1", "MP_FWD": "1023", "MP_REV": "0"});

    print("Waiting milkOnTime: $milkOnTime seconds");
    await Future.delayed(Duration(seconds: milkOnTime));
    print("milkOnTime complete");

    print("Sending Milk Pump OFF: {MAV: 0, MP_FWD: 0, MP_REV: 0}");
    await bloc.serialService.sendJsonData({"MAV": "0", "MP_FWD": "0", "MP_REV": "0"});

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

    print("Sending Coffee Tea Pump ON: {CP_FWD: 1023, CP_REV: 0}");
    await bloc.serialService.sendJsonData({"CP_FWD": "1023", "CP_REV": "0"});

    print("Waiting ctpOnTime: $ctpOnTime seconds");
    await Future.delayed(Duration(seconds: ctpOnTime));
    print("ctpOnTime complete");

    print("Sending Coffee Tea Pump OFF: {CP_FWD: 0, CP_REV: 0}");
    await bloc.serialService.sendJsonData({"CP_FWD": "0", "CP_REV": "0"});

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

    print("Sending Tea Pump ON: {TP_FWD: 1023, TP_REV: 0}");
    await bloc.serialService.sendJsonData({"TP_FWD": "1023", "TP_REV": "0"});

    print("Waiting ttpOnTime: $ttpOnTime seconds");
    await Future.delayed(Duration(seconds: ttpOnTime));
    print("ttpOnTime complete");

    print("Sending Tea Pump OFF: {TP_FWD: 0, TP_REV: 0}");
    await bloc.serialService.sendJsonData({"TP_FWD": "0", "TP_REV": "0"});

    print("Waiting milkDelay: $milkDelay seconds");
    await Future.delayed(Duration(seconds: milkDelay));
    print("milkDelay complete");

    print("Sending Milk Pump ON: {MAV: 1, MP_FWD: 1023, MP_REV: 0}");
    await bloc.serialService.sendJsonData({"MAV": "1", "MP_FWD": "1023", "MP_REV": "0"});

    print("Waiting milkOnTime: $milkOnTime seconds");
    await Future.delayed(Duration(seconds: milkOnTime));
    print("milkOnTime complete");

    print("Sending Milk Pump OFF: {MAV: 0, MP_FWD: 0, MP_REV: 0}");
    await bloc.serialService.sendJsonData({"MAV": "0", "MP_FWD": "0", "MP_REV": "0"});

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

    print("Sending Tea Pump ON: {TP_FWD: 1023, TP_REV: 0}");
    await bloc.serialService.sendJsonData({"TP_FWD": "1023", "TP_REV": "0"});

    print("Waiting ttpOnTime: $ttpOnTime seconds");
    await Future.delayed(Duration(seconds: ttpOnTime));
    print("ttpOnTime complete");

    print("Sending Tea Pump OFF: {TP_FWD: 0, TP_REV: 0}");
    await bloc.serialService.sendJsonData({"TP_FWD": "0", "TP_REV": "0"});

    print("Waiting milkDelay: $milkDelay seconds");
    await Future.delayed(Duration(seconds: milkDelay));
    print("milkDelay complete");

    print("Sending Milk Pump ON: {MAV: 1, MP_FWD: 1023, MP_REV: 0}");
    await bloc.serialService.sendJsonData({"MAV": "1", "MP_FWD": "1023", "MP_REV": "0"});

    print("Waiting milkOnTime: $milkOnTime seconds");
    await Future.delayed(Duration(seconds: milkOnTime));
    print("milkOnTime complete");

    print("Sending Milk Pump OFF: {MAV: 0, MP_FWD: 0, MP_REV: 0}");
    await bloc.serialService.sendJsonData({"MAV": "0", "MP_FWD": "0", "MP_REV": "0"});

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

    print("Sending Tea Pump ON: {TP_FWD: 1023, TP_REV: 0}");
    await bloc.serialService.sendJsonData({"TP_FWD": "1023", "TP_REV": "0"});

    print("Waiting ttpOnTime: $ttpOnTime seconds");
    await Future.delayed(Duration(seconds: ttpOnTime));
    print("ttpOnTime complete");

    print("Sending Tea Pump OFF: {TP_FWD: 0, TP_REV: 0}");
    await bloc.serialService.sendJsonData({"TP_FWD": "0", "TP_REV": "0"});

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

    print("Sending Milk Pump ON: {MAV: 1, MP_FWD: 1023, MP_REV: 0}");
    await bloc.serialService.sendJsonData({"MAV": "1", "MP_FWD": "1023", "MP_REV": "0"});

    print("Waiting milkOnTime: $milkOnTime seconds");
    await Future.delayed(Duration(seconds: milkOnTime));
    print("milkOnTime complete");

    print("Sending Milk Pump OFF: {MAV: 0, MP_FWD: 0, MP_REV: 0}");
    await bloc.serialService.sendJsonData({"MAV": "0", "MP_FWD": "0", "MP_REV": "0"});

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

    print("Sending Milk Pump ON: {MAV: 1, MP_FWD: 1023, MP_REV: 0}");
    await bloc.serialService.sendJsonData({"MAV": "1", "MP_FWD": "1023", "MP_REV": "0"});

    print("Waiting milkOnTime: $milkOnTime seconds");
    await Future.delayed(Duration(seconds: milkOnTime));
    print("milkOnTime complete");

    print("Sending Milk Pump OFF: {MAV: 0, MP_FWD: 0, MP_REV: 0}");
    await bloc.serialService.sendJsonData({"MAV": "0", "MP_FWD": "0", "MP_REV": "0"});

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

    print("Sending Hot Water Valve ON: {MHWV: 1}");
    await bloc.serialService.sendJsonData({"MHWV": "1"});

    print("Waiting waterValveOnTime: $waterValveOnTime seconds");
    await Future.delayed(Duration(seconds: waterValveOnTime));
    print("waterValveOnTime complete");

    print("Sending Hot Water Valve OFF: {MHWV: 0}");
    await bloc.serialService.sendJsonData({"MHWV": "0"});

    print("Hot Water Sequence Complete");
  }

  void _startBrewing() {
    _sendBrewCommand();

    setState(() {
      bloc.isBrewAnimating = true;
      bloc.brewProgress = 0.0;
    });

    Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (bloc.brewProgress >= 1.0) {
        timer.cancel();
        setState(() {
          bloc.isBrewAnimating = false;
          bloc.brewProgress = 0.0;
        });
        _showBrewComplete();
      } else {
        setState(() {
          bloc.brewProgress += 0.01;
        });
      }
    });
  }

  void _showBrewComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.brown.shade400,
                Colors.brown.shade800,
              ],
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
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please collect it',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds:2), () {
      Navigator.pop(context);
      setState(() {
        bloc.selectedItem = null;
      });
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    bloc.companyName = prefs.getString('companyName') ?? '';

    bloc.delaySettings['strongCoffee'] = {
      'cpDelay': prefs.getInt('strongCoffee_cpDelay') ?? 0,
      'cpOnTime': prefs.getInt('strongCoffee_cpOnTime') ?? 0,
      'milkDelay': prefs.getInt('strongCoffee_milkDelay') ?? 0,
      'milkOnTime': prefs.getInt('strongCoffee_milkOnTime') ?? 0,
      'waterDelay': prefs.getInt('strongCoffee_waterDelay') ?? 0,
      'waterOnTime': prefs.getInt('strongCoffee_waterOnTime') ?? 0,
    };

    bloc.delaySettings['liteCoffee'] = {
      'cpDelay': prefs.getInt('liteCoffee_cpDelay') ?? 0,
      'cpOnTime': prefs.getInt('liteCoffee_cpOnTime') ?? 0,
      'milkDelay': prefs.getInt('liteCoffee_milkDelay') ?? 0,
      'milkOnTime': prefs.getInt('liteCoffee_milkOnTime') ?? 0,
      'waterDelay': prefs.getInt('liteCoffee_waterDelay') ?? 0,
      'waterOnTime': prefs.getInt('liteCoffee_waterOnTime') ?? 0,
    };

    bloc.delaySettings['blackCoffee'] = {
      'ctpDelay': prefs.getInt('blackCoffee_ctpDelay') ?? 0,
      'ctpOnTime': prefs.getInt('blackCoffee_ctpOnTime') ?? 0,
      'waterDelay': prefs.getInt('blackCoffee_waterDelay') ?? 0,
      'waterOnTime': prefs.getInt('blackCoffee_waterOnTime') ?? 0,
    };

    bloc.delaySettings['strongTea'] = {
      'ttpDelay': prefs.getInt('strongTea_ttpDelay') ?? 0,
      'ttpOnTime': prefs.getInt('strongTea_ttpOnTime') ?? 0,
      'milkDelay': prefs.getInt('strongTea_milkDelay') ?? 0,
      'milkOnTime': prefs.getInt('strongTea_milkOnTime') ?? 0,
      'waterDelay': prefs.getInt('strongTea_waterDelay') ?? 0,
      'waterOnTime': prefs.getInt('strongTea_waterOnTime') ?? 0,
    };

    bloc.delaySettings['liteTea'] = {
      'ttpDelay': prefs.getInt('liteTea_ttpDelay') ?? 0,
      'ttpOnTime': prefs.getInt('liteTea_ttpOnTime') ?? 0,
      'milkDelay': prefs.getInt('liteTea_milkDelay') ?? 0,
      'milkOnTime': prefs.getInt('liteTea_milkOnTime') ?? 0,
      'waterDelay': prefs.getInt('liteTea_waterDelay') ?? 0,
      'waterOnTime': prefs.getInt('liteTea_waterOnTime') ?? 0,
    };

    bloc.delaySettings['blackTea'] = {
      'ttpDelay': prefs.getInt('blackTea_ttpDelay') ?? 0,
      'ttpOnTime': prefs.getInt('blackTea_ttpOnTime') ?? 0,
      'waterDelay': prefs.getInt('blackTea_waterDelay') ?? 0,
      'waterOnTime': prefs.getInt('blackTea_waterOnTime') ?? 0,
    };

    bloc.delaySettings['dipTea'] = {
      'waterDelay': prefs.getInt('dipTea_waterDelay') ?? 0,
      'waterOnTime': prefs.getInt('dipTea_waterOnTime') ?? 0,
      'milkDelay': prefs.getInt('dipTea_milkDelay') ?? 0,
      'milkOnTime': prefs.getInt('dipTea_milkOnTime') ?? 0,
    };

    bloc.delaySettings['hotMilk'] = {
      'milkDelay': prefs.getInt('hotMilk_milkDelay') ?? 0,
      'milkOnTime': prefs.getInt('hotMilk_milkOnTime') ?? 0,
      'waterDelay': prefs.getInt('hotMilk_waterDelay') ?? 0,
      'waterOnTime': prefs.getInt('hotMilk_waterOnTime') ?? 0,
    };

    bloc.delaySettings['hotWater'] = {
      'waterValveDelay': prefs.getInt('hotWater_waterValveDelay') ?? 0,
      'waterValveOnTime': prefs.getInt('hotWater_waterValveOnTime') ?? 0,
    };



    print("strongCoffee cpDelay = ${bloc.delaySettings['strongCoffee']?['cpDelay']}");


    print("--------_companyName---------->"+bloc.companyName);

  }


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
      floatingActionButton: bloc.selectedItem != null ? _buildBrewButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  },
),
);
  }


  Widget _buildBrewButton() {
    const double size = 120; // 👈 reduced radius source

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
              blurRadius: 18,   // reduced
              spreadRadius: 5,  // reduced
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.brown.shade800,
                  width: 4, // slightly thinner
                ),
              ),
            ),

            // Coffee filling animation
            ClipOval(
              child: Stack(
                children: [
                  Container(
                    width: size,
                    height: size,
                    color: Colors.transparent,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 30),
                      height: size * bloc.brewProgress,
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
                        painter: WavePainter(bloc.brewProgress),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Button content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.coffee_maker,
                  size: 40, // reduced
                  color:
                  bloc.isBrewAnimating ? Colors.white : Colors.brown.shade900,
                ),
                const SizedBox(height: 8),
                Text(
                  bloc.isBrewAnimating ? 'BREWING' : 'BREW',
                  style: TextStyle(
                    fontSize: 18, // reduced
                    fontWeight: FontWeight.bold,
                    color: bloc.isBrewAnimating
                        ? Colors.white
                        : Colors.brown.shade900,
                    letterSpacing: 2,
                  ),
                ),
                if (bloc.isBrewAnimating)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${(bloc.brewProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
              Text(bloc.companyName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade900,
                ),
              ),
               SizedBox(height: 4),
              Text(
                _formatDate(bloc.currentTime),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.brown.shade600,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(height: 10),
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
                  SizedBox(width: 10,),
                  Text(
                   "70° C",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  SizedBox(width: 10,),
                  Text(
                    "|",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  SizedBox(width: 10,),
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: bloc.isNodeMCUOnline ? Colors.green : Colors.red,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: bloc.isNodeMCUOnline ? Colors.green.shade200 : Colors.red.shade200,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          bloc.isNodeMCUOnline ? Icons.usb : Icons.usb_off,
                          size: 16,
                          color:bloc.isNodeMCUOnline ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 4),
                        CustomText(
                          text: bloc.isNodeMCUOnline ? "Online" : "Offline",
                          weight: FontWeight.w500,
                          color: bloc.isNodeMCUOnline ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    splashRadius: 1,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => adminScreenLogin(),
                        ),
                      );
                    },
                    icon: Icon(Icons.admin_panel_settings, color: Colors.brown.shade900),
                  ),
                ],
              ),
            ],
          )
          
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
        ItemData('Strong Coffee', 'c1', Colors.brown.shade900,
            imagePath: 'assets/images/strong-espresso-coffee.jpg'),
        ItemData('Lite Coffee', 'c2', Colors.brown.shade600,
            imagePath: 'assets/images/light-latte-coffee.jpg'),
        ItemData('Black Coffee', 'c3', Colors.grey.shade900,
            imagePath: 'assets/images/black-americano-coffee.jpg'),
        ItemData('Espresso', 'c4', Colors.brown.shade800,
            imagePath: 'assets/images/strong-espresso-coffee.jpg'),
      ],
    );
  }

  Widget _buildTeaSection() {
    return _buildSection(
      title: 'Tea',
      icon: Icons.local_cafe,
      iconColor: Colors.orange.shade700,
      items: [
        ItemData('Strong Tea', 't1', Colors.orange.shade900,
            imagePath: 'assets/images/strong-hot-tea.jpg'),
        ItemData('Lite Tea', 't2', Colors.orange.shade600,
            imagePath: 'assets/images/light-milk-tea.jpg'),
        ItemData('Black Tea', 't3', Colors.grey.shade800,
            imagePath: 'assets/images/black-tea-cup.jpg'),
      ],
    );
  }

  Widget _buildEssentialsSection() {
    return _buildSection(
      title: 'Essentials',
      icon: Icons.whatshot,
      iconColor: Colors.blue.shade400,
      items: [
        ItemData('Hot Milk', 'e1', Colors.grey.shade100,
            textColor: Colors.grey.shade800,
            imagePath: 'assets/images/glass-of-hot-milk.jpg'),
        ItemData('Hot Water', 'e2', Colors.blue.shade100,
            textColor: Colors.grey.shade800,
            imagePath: 'assets/images/steaming-hot-water-cup.jpg'),
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
      padding:  EdgeInsets.symmetric(horizontal: 10,vertical: 8),
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
        height:110,
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



