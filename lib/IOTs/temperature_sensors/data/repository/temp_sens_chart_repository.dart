
import 'dart:math';
import 'package:iots_manager/common/def_types.dart';
import 'package:iots_manager/IOTs/temperature_sensors/domain/temp_sens_chart_mode.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/repository/temp_sens_one_record.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/repository/temp_isolate_data_mapper.dart';


class TempSensChartRepository {
  late final TempIsolateDataMapper isolateDataMapper;
  late Map<TimeStamp, TempSensOneRecord> _sensFullData;
  late List<String> _sensorAddresses;
  late QuantityElements _numSensors;
  late ListElemIndex _curChartMode;

  SensorValue chartMinY = 0;
  SensorValue chartMaxY = 0;
  SensorValue get chartRangeY => chartMaxY - chartMinY;

  final List<TimeStamp> chartTimeStamps = <TimeStamp>[];
  final List<Map<TimeStamp, SensorValue>> _chartSensorsData = <Map<TimeStamp, SensorValue>>[];

  TempSensChartRepository() {
    isolateDataMapper = TempIsolateDataMapper();
    _curChartMode = DEFAULT_CHART_MODE_INDEX;
  }

  void initSensorsAddresses(List<String> sensorAddresses) {
    _sensorAddresses = sensorAddresses;
    _numSensors = _sensorAddresses.length;
  }

  ListElemIndex get chartMode => _curChartMode;

  QuantityElements get chartDataSize => _chartSensorsData.length;

  Map<TimeStamp, SensorValue> getChartDataAt(ListElemIndex index) {
    return _chartSensorsData[index];
  }

  Future<void> changeMode(TimeStamp lastTimeStamp, ListElemIndex mode) async {
    if(_curChartMode != mode) {
      _curChartMode = mode;
      await _preparingChartData(_sensFullData, lastTimeStamp, mode);
    }
  }

  SensorValue getSensorLastData(TimeStamp lastTimeStamp, ListElemIndex iSens) {
    if(_chartSensorsData.isEmpty || _chartSensorsData[iSens].isEmpty) {
      return double.nan;
    }
    return _chartSensorsData[iSens][lastTimeStamp] ?? double.nan;
  }

  Future<void> updateChartData(TimeStamp lastTimeStamp,
                        Map<TimeStamp,TempSensOneRecord> sensFullData) async {
    _sensFullData = sensFullData;
    await _preparingChartData(_sensFullData, lastTimeStamp, _curChartMode);
  }

  Future<void> _preparingChartData(
      Map<TimeStamp, TempSensOneRecord> sensFullData,
      TimeStamp lastTimeStamp, ListElemIndex curChartMode) async {

int t1 = DateTime.now().millisecondsSinceEpoch;

    await isolateDataMapper.startTask(
        IsolateDataMapperTask(_numSensors, sensFullData, lastTimeStamp, curChartMode)
    ).then((sensDataSet) {
      _mapDataSetToChartData(sensDataSet);
      _initChartParameters(sensDataSet);
    });

int t2 = DateTime.now().millisecondsSinceEpoch;

print("******************* _preparingChartData: ${t2-t1}");

  }


  /// Initialize data for the chart
  void _mapDataSetToChartData(Map<TimeStamp, TempSensOneRecord> sensDataSections) {
    _chartSensorsData.clear();
    for(ListElemIndex iSens = 0; iSens < _numSensors; iSens++) {
      _chartSensorsData.add( <TimeStamp, SensorValue>{} );
    }

    chartTimeStamps.clear();
    sensDataSections.forEach((ts, sensorsRecord) {
      for(ListElemIndex iSens = 0; iSens < _numSensors; iSens++) {
        if(!sensorsRecord.temperatures[iSens].isNaN) {
          _chartSensorsData[iSens].putIfAbsent(ts, () => sensorsRecord.temperatures[iSens]);
        }
      }
      chartTimeStamps.add(ts);
    });
  }

  /// Determine the Max and min values
  void _initChartParameters(Map<TimeStamp, TempSensOneRecord> sensDataResult) {
    SensorValue chartMinValue = double.maxFinite;
    SensorValue chartMaxValue = -double.maxFinite;

    sensDataResult.forEach((ts, sensorsRecord) {
      for(ListElemIndex iSens = 0; iSens < _numSensors; iSens++) {
        final temperature = sensorsRecord.temperatures[iSens];
        if(!temperature.isNaN) {
          chartMinValue = min(chartMinValue, temperature);
          chartMaxValue = max(chartMaxValue, temperature);
        }
      }
    });
    final num rangeY = chartMaxValue - chartMinValue == 0? 1.0: chartMaxValue - chartMinValue;

    /// The chart range exceeds the real data range by a few percent
    chartMinY = chartMinValue - rangeY*0.1;
    chartMaxY = chartMaxValue + rangeY*0.1;
  }





  Future<void> close() async {
    await isolateDataMapper.stop();
  }


}