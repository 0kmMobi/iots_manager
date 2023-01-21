import 'package:equatable/equatable.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/repository/temp_sens_repository.dart';
import 'package:iots_manager/IOTs/temperature_sensors/domain/temp_sens_chart_mode.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'temp_sens_chart_mode_event.dart';
part 'temp_sens_chart_mode_state.dart';

class TempSensChartModeBloc extends Bloc<TempSensChartModeEvent, TempSensChartModeState> {
  final TempSensRepository chartRepository;

  TempSensChartModeBloc({required this.chartRepository})
                   : super(TempSensCurrentChartModeState(DEFAULT_CHART_MODE_INDEX)) {

    on<TempSensChangeChartModeEvent>((event, emit) async {
      await Future<void> (() {
        chartRepository.chartRepo.changeMode(event.iMode);
      });
      emit(TempSensCurrentChartModeState(event.iMode));
    });

  }
}