part of 'temp_sens_chart_mode_bloc.dart';

abstract class TempSensChartModeEvent extends Equatable {}

class TempSensChangeChartModeEvent extends TempSensChartModeEvent {
  final int iMode;

  TempSensChangeChartModeEvent(this.iMode);

  @override
  List<Object?> get props => [iMode];
}

