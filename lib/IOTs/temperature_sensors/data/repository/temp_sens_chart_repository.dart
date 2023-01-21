
import 'dart:collection';
import 'dart:math';

import 'package:iots_manager/IOTs/temperature_sensors/data/repository/temp_sens_one_record.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/temp_sens_constants.dart';
import 'package:iots_manager/IOTs/temperature_sensors/domain/temp_sens_chart_mode.dart';
import 'package:iots_manager/common/def_types.dart';

class TempSensChartRepository {
  late SplayTreeMap<TimeStamp, TempSensOneRecord> _sensFullData;
  late TimeStamp _lastTimeStamp; // Last timestamp of received data
  late List<String> _sensorAddresses;
  late QuantityElements _numSensors;

  late ListElemIndex _curChartMode;

  SensorValue chartMinY = 0;
  SensorValue chartMaxY = 0;
  SensorValue get chartRangeY => chartMaxY - chartMinY;

  final List<TimeStamp> chartTimeStamps = <TimeStamp>[];
  final List<SplayTreeMap<TimeStamp, SensorValue>> _chartSensorsData = <SplayTreeMap<TimeStamp, SensorValue>>[];

  TempSensChartRepository() {
    _curChartMode = DEFAULT_CHART_MODE_INDEX;
  }

  ListElemIndex get chartMode => _curChartMode;

  QuantityElements get chartDataSize => _chartSensorsData.length;

  SplayTreeMap<TimeStamp, SensorValue> getChartDataAt(ListElemIndex index) {
    return _chartSensorsData[index];
  }

  void changeMode(ListElemIndex mode) {
    if(_curChartMode != mode) {
      _curChartMode = mode;
      _chartDataPreparing();
    }
  }

  SensorValue getSensorLastData(iSens) {
    if(_chartSensorsData.isEmpty || _chartSensorsData[iSens].isEmpty) {
      return double.nan;
    }
    return _chartSensorsData[iSens][_lastTimeStamp] ?? double.nan;
  }

  void chartDataPreparing({required TimeStamp lastTimeStamp, required List<String> sensorAddresses, required SplayTreeMap<TimeStamp, TempSensOneRecord> sensFullData}) {
    _lastTimeStamp = lastTimeStamp;
    _sensorAddresses = sensorAddresses;
    _numSensors = _sensorAddresses.length;
    _sensFullData = sensFullData;

    _chartDataPreparing();
  }

  void _chartDataPreparing() {
    /// Prepare the chart for defined time range (5 min, 30 min, 3 hours, 12 hours, 24 hours)
    /// For build the chart need N points (it's about 10-20)
    ///  ... but number of real record much more.
    ///  So need to compress data
    final sensDataTrimmed = _trimSensorsDataToTimeRange();

    /// 2. Since for the chart need to use less than N points (about 10-20),
    ///    and the last record is much actual for the user, then the last record need to use as single chart point,
    ///    and all a previous records need split to N-1 groups
    ///    After that, from each group it is necessary to create only one point of the chart, averaging values of all records.
    final lastRecord = sensDataTrimmed[_lastTimeStamp] as TempSensOneRecord;
    sensDataTrimmed.remove(_lastTimeStamp);

    final TimeStamp firstTS = sensDataTrimmed.firstKey() ?? 0;
    final stepTS = (_lastTimeStamp-firstTS) / (CHART_NUM_POINTS-1.0);
    final sensDataResult = SplayTreeMap<TimeStamp, TempSensOneRecord>();

    for(ListElemIndex iTime = 0; iTime < (CHART_NUM_POINTS-1.0); iTime ++) {
      final TimeStamp startTS = (firstTS + stepTS * iTime).toInt();
      final mapTSRange = SplayTreeMap<TimeStamp, TempSensOneRecord>.fromIterable(
          sensDataTrimmed.keys.where((ts) => ts >= startTS && ts < startTS+stepTS),
          key: (ts) => ts,
          value: (ts) => sensDataTrimmed[ts]!
      );

      final TempSensOneRecord averageRecord = _rangeRecordsToAverageSingleRecord(mapTSRange);
      sensDataResult.putIfAbsent( (startTS+stepTS/2).toInt(), () => averageRecord);
    }
    /// In the end to add the last record data as independent point, since its are a most actual data
    sensDataResult.putIfAbsent(_lastTimeStamp, () => lastRecord);

    _initChartData(sensDataResult);
    _initChartParameters(sensDataResult);
  }

  void _initChartData(SplayTreeMap<TimeStamp, TempSensOneRecord> sensDataResult) {
    _chartSensorsData.clear();
    for(ListElemIndex iSens = 0; iSens < _numSensors; iSens++) {
      _chartSensorsData.add( SplayTreeMap<TimeStamp, SensorValue>() );
    }

    chartTimeStamps.clear();
    sensDataResult.forEach((ts, sensorsRecord) {
      for(ListElemIndex iSens = 0; iSens < _numSensors; iSens++) {
        if(!sensorsRecord.temperatures[iSens].isNaN) {
          _chartSensorsData[iSens].putIfAbsent(ts, () => sensorsRecord.temperatures[iSens]);
        }
      }
      chartTimeStamps.add(ts);
    });
  }

  /// Determine the Max and min values
  void _initChartParameters(SplayTreeMap<TimeStamp, TempSensOneRecord> sensDataResult) {
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

  /// Calculate the average values for all elements of mapTSRange (for each sensor separately)
  TempSensOneRecord _rangeRecordsToAverageSingleRecord(SplayTreeMap<TimeStamp, TempSensOneRecord> mapTSRange) {
    final sensorsRecordAverage = TempSensOneRecord.empty(_sensorAddresses);
    final List<int> sensorsAverDivisors = List.filled(_numSensors, 0);

    ///  In first, to sum all values
    mapTSRange.forEach((recTS, oneRecord) {
      for(ListElemIndex iSens = 0; iSens < _numSensors; iSens++) {
        final fTemper = oneRecord.temperatures[iSens];
        if(!fTemper.isNaN) {
          sensorsAverDivisors[iSens] += 1;
          if (sensorsRecordAverage.temperatures[iSens].isNaN) {
            sensorsRecordAverage.temperatures[iSens] = fTemper;
          } else {
            sensorsRecordAverage.temperatures[iSens] += fTemper;
          }
        }
      }
    });
    /// ... and after that, to divide by number of their
    for(ListElemIndex iSens = 0; iSens < _numSensors; iSens++) {
      sensorsRecordAverage.temperatures[iSens] /= sensorsAverDivisors[iSens];
    }
    return sensorsRecordAverage;
  }

  /// Copy data which that has trimmed to specific time range
  SplayTreeMap<TimeStamp, TempSensOneRecord> _trimSensorsDataToTimeRange() {
    final thresholdTS = _lastTimeStamp - CHART_MODES[chartMode].duration;
    return _getCopyAllDataAfter(thresholdTS);
  }

  SplayTreeMap<TimeStamp, TempSensOneRecord> _getCopyAllDataAfter(TimeStamp thresholdTS) {
    final sensFullDataCopy = SplayTreeMap<TimeStamp, TempSensOneRecord>();

    _sensFullData.forEach((TimeStamp timestamp, TempSensOneRecord record) {
      if(timestamp > thresholdTS) {
        sensFullDataCopy[timestamp] = record;
      }
    });
    return sensFullDataCopy;
  }


}