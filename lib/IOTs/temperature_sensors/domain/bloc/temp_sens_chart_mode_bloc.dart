import 'package:equatable/equatable.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/repository/temp_sens_repository.dart';
import 'package:iots_manager/IOTs/temperature_sensors/domain/temp_sens_chart_mode.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'temp_sens_chart_mode_event.dart';
part 'temp_sens_chart_mode_state.dart';

class TempSensChartModeBloc extends Bloc<TempSensChartModeEvent, TempSensChartModeState> {
  final TempSensRepository sensRepo;

  TempSensChartModeBloc({required this.sensRepo})
           : super(TempSensCurrentChartModeState(DEFAULT_CHART_MODE_INDEX)) {
    on<TempSensChangeChartModeEvent>((event, emit) async {
        await Future<void> (() async {
          await sensRepo.chartRepo.changeMode(sensRepo.lastTimeStamp, event.iMode);
        });
        emit(TempSensCurrentChartModeState(event.iMode));
    });
  }

  @override
  Future<void> close() async {
    await sensRepo.close();
    super.close();
  }
}