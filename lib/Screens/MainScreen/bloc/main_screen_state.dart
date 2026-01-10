part of 'main_screen_bloc.dart';

@immutable
sealed class MainScreenState {}

final class MainScreenInitial extends MainScreenState {}

final class BroadcastRefreshState extends MainScreenState {}

