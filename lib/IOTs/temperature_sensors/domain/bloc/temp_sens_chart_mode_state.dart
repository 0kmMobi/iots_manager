part of 'temp_sens_chart_mode_bloc.dart';

abstract class TempSensChartModeState extends Equatable {}

/// When the user presses the logIn or Register button the state is changed to loading first and then to Authenticated.
class TempSensCurrentChartModeState extends TempSensChartModeState {
  final int iMode;

  TempSensCurrentChartModeState(this.iMode);

  @override
  List<Object?> get props => [iMode];
}
