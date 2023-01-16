
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'package:iots_manager/IOTs/temperature_sensors/data/temp_sens_constants.dart';

class TempSensChartMode {
  final String label;
  final int duration;

  const TempSensChartMode(this.label, this.duration);
}


const CHART_MODES = [
  TempSensChartMode("5m",   5*TIME_1_MINUTE),
  TempSensChartMode("20m", 20*TIME_1_MINUTE),
  TempSensChartMode("1h",   1*TIME_1_HOUR),
  TempSensChartMode("3h",   3*TIME_1_HOUR),
  TempSensChartMode("12h", 12*TIME_1_HOUR),
  TempSensChartMode("24h", 24*TIME_1_HOUR),
];
final DEFAULT_CHART_MODE_INDEX = CHART_MODES.length~/2+1;