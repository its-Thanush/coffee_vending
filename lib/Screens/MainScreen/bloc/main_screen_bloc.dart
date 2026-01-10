import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:coffee_vending/Widgets/SerialCommunication.dart';
import 'package:meta/meta.dart';

part 'main_screen_event.dart';
part 'main_screen_state.dart';

class MainScreenBloc extends Bloc<MainScreenEvent, MainScreenState> {

  String? selectedItem;
  String companyName = '';
  late Timer timer;
  DateTime currentTime = DateTime.now();
  bool isBrewAnimating = false;
  double brewProgress = 0.0;

  final SerialService serialService = SerialService();
  bool isNodeMCUOnline = false;
  Timer? connectionCheckTimer;

  MainScreenBloc() : super(MainScreenInitial()) {


    on<MainScreenEvent>((event, emit) {
      // TODO: implement event handler


    });

  }
}
