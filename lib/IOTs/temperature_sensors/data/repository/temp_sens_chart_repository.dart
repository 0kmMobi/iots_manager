// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:math';
import 'dart:collection';
import 'package:firebase_database/firebase_database.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/api/temp_sens_firebase_api.dart';
import 'package:iots_manager/locator_service.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:iots_manager/common/def_types.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/temp_sens_constants.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/repository/temp_sens_one_record.dart';
import 'package:iots_manager/IOTs/temperature_sensors/domain/temp_sens_chart_mode.dart';


class TempSensChartRepository {
  final String sIoTId;

  late final TempSensFirebaseAPI firebaseAPI = sl<TempSensFirebaseAPI>();

  final _sensorAddresses = <String>[]; // List of id's of defined sensors
  final _sensorNames = <String, String>{}; // The sensors user's names
  final _sensFullData = SplayTreeMap<TimeStamp, TempSensOneRecord>();

  TimeStamp _lastTimeStamp = 0; // Last timestamp of received data

  late ListElemIndex _curChartMode;

  SensorValue chartRangeY = 0; // The chart range exceeds the real data range by a few percent
  SensorValue chartMinY = 0;
  SensorValue chartMaxY = 0;

  final List<TimeStamp> chartTimeStamps = <TimeStamp>[];
  final List<SplayTreeMap<TimeStamp, SensorValue>> _chartSensorsData = <SplayTreeMap<TimeStamp, SensorValue>>[];

  QuantityElements lastNumNewRecords = 0;
  int updatesCounter = 0;

  TempSensChartRepository(this.sIoTId) {
    final dtNowMinus1Day = DateTime.now().subtract(const Duration(days: 1));
    _lastTimeStamp = dtNowMinus1Day.millisecondsSinceEpoch;
    _curChartMode = DEFAULT_CHART_MODE_INDEX;
  }

  QuantityElements get numSensors => _sensorAddresses.length;

  List<String> get sensorAddresses => _sensorAddresses;

  Map<String, String> get sensorNames => _sensorNames;

  String getSensorNameByIndex(ListElemIndex index) => _sensorNames[_sensorAddresses[index]] ?? _sensorAddresses[index];

  bool updateSensorName(String sSensorAddress, String? sNewName) {
    if(sNewName == null || sNewName == _sensorNames[sSensorAddress]) {
      return false;
    }
    firebaseAPI.updateSensorName(sIoTId, sSensorAddress, sNewName);
    _sensorNames[sSensorAddress] = sNewName;
    return true;
  }



  Future<bool> initSensorsNames() async {
    DataSnapshot snapshot = await firebaseAPI.getSensorsNames(sIoTId);
    _sensorNames.addAll( (snapshot.value as Map<dynamic, dynamic>).cast<String,String>() );
    _sensorAddresses.clear();
    _sensorNames.forEach((address, name) => _sensorAddresses.add(address));
    return true;
  }



  Stream<int> initSensorsDataUpdatesStream() {
    return _sensorsDataUpdatesStream()
        .map((numNewElements) {
      if(numNewElements > 0) {
        lastNumNewRecords = numNewElements;
        updatesCounter++;
        prepareDataForChart();
      }
      return updatesCounter;
    },);
  }

  Stream<QuantityElements> _sensorsDataUpdatesStream() async* {
    while(true) {
      DataSnapshot snapshot = await firebaseAPI.getSensorsData(sIoTId, _lastTimeStamp);
      QuantityElements numNewElements = addNewSensorsData(snapshot);

      if(numNewElements > 0) {
        yield numNewElements;
      }
      await Future.delayed(const Duration(seconds: 30+1));
    }
  }

  QuantityElements addNewSensorsData(DataSnapshot snapshot) {
    QuantityElements countRecords = 0;
    TimeStamp maxTimeStampLocal = 0;
    Map<dynamic, dynamic> mapRawSensData = snapshot.value as Map<dynamic, dynamic>;

    mapRawSensData.forEach((sRecord, value) { // Loop by records
      final mapOneRecord = value as Map<dynamic, dynamic>;

      if(mapOneRecord.containsKey('time')) {
        TimeStamp curTimeStamp = mapOneRecord['time'] as TimeStamp;
        if(maxTimeStampLocal < curTimeStamp) {
          maxTimeStampLocal = curTimeStamp;
        }
        final sensorsOneRecord = TempSensOneRecord.fromData(mapOneRecord, _sensorAddresses);
        _sensFullData.putIfAbsent(curTimeStamp, ()=> sensorsOneRecord);
        countRecords ++;
      }
    });
    //mapRawSensData.clear(); // Optionally clean snapshot data after single query

    _lastTimeStamp = maxTimeStampLocal > _lastTimeStamp ? maxTimeStampLocal : _lastTimeStamp;

    /// Delete records older that MAX_CACHE_DURATION_MSEC milliseconds
    TimeStamp oldTimeStamp = _lastTimeStamp - MAX_CACHE_DURATION_MSEC;
    _sensFullData.removeWhere((timestamp, mapSensors) => timestamp <= oldTimeStamp);

    return countRecords;
  }


  ListElemIndex get chartMode => _curChartMode;

  QuantityElements get chartDataSize => _chartSensorsData.length;

  SplayTreeMap<TimeStamp, SensorValue> getChartDataAt(ListElemIndex index) {
    return _chartSensorsData[index];
  }

  void changeMode(ListElemIndex mode) {
    if(_curChartMode != mode) {
      _curChartMode = mode;
      prepareDataForChart();
    }
  }



  SensorValue getSensorLastData(iSens) {
    if(_chartSensorsData.isEmpty || _chartSensorsData[iSens].isEmpty) {
      return double.nan;
    }
    return _chartSensorsData[iSens][_lastTimeStamp] ?? double.nan;
  }


  QuantityElements get fullDataSize => _sensFullData.length;

  SplayTreeMap<TimeStamp, TempSensOneRecord> _getCopyAllDataAfter(TimeStamp thresholdTS) {
    final sensFullDataCopy = SplayTreeMap<TimeStamp, TempSensOneRecord>();

    _sensFullData.forEach((TimeStamp timestamp, TempSensOneRecord record) {
      if(timestamp > thresholdTS) {
        sensFullDataCopy[timestamp] = record;
      }
    });
    return sensFullDataCopy;
  }


  void prepareDataForChart() {
    /// Prepare the chart for defined time range (5 min, 30 min, 3 hours, 12 hours, 24 hours)
    /// For build the chart need N points (it's about 10-20)
    TimeStamp lastTS = _lastTimeStamp;

    ///  ... but number of real record much more.
    ///  So need to compress data
    /// 1. Copy data which that has trimmed to specific time range
    final thresholdTS = lastTS - CHART_MODES[chartMode].duration;
    final sensDataForMode = _getCopyAllDataAfter(thresholdTS);

    /// 2. Since for the chart need use about less than N (about 10-20) points,
    ///    and the last record is much actual, then the last record need use as one the chart point,
    ///    and all a previous records need split to N-1 groups
    ///    After that, from each group it is necessary to create only one point of the chart, averaging values of all records.
    final lastRecord = sensDataForMode[lastTS] as TempSensOneRecord;
    sensDataForMode.remove(lastTS);

    final TimeStamp firstTS = sensDataForMode.firstKey() ?? 0;
    final stepTS = (lastTS-firstTS) / (CHART_NUM_POINTS-1.0);

    final sensDataResult = SplayTreeMap<TimeStamp, TempSensOneRecord>();

    for(ListElemIndex iTime = 0; iTime < (CHART_NUM_POINTS-1.0); iTime ++) {
      TimeStamp startTS = (firstTS + stepTS * iTime).toInt();
       final mapTSRange = SplayTreeMap.fromIterable(
           sensDataForMode.keys.where((ts) => ts >= startTS && ts < startTS+stepTS),
           key: (sKey) => sKey,
           value: (sKey) => sensDataForMode[sKey]
       );

      /// To calculate the average values for all elements of mapTSRange (for each sensor separatelly)
      ///  In first, to sum all values
      final sensorsRecordAverage = TempSensOneRecord.empty(_sensorAddresses);

      final List<int> sensorsAverDivisors = List.filled(numSensors, 0);

      mapTSRange.forEach((recTS, oneRecord) {
        for(ListElemIndex iSens = 0; iSens < numSensors; iSens++) {
          final fTemper = oneRecord!.temperatures[iSens];
          if(fTemper.isNaN) {
            continue;
          }
          sensorsAverDivisors[iSens] += 1;

          if (sensorsRecordAverage.temperatures[iSens].isNaN) {
            sensorsRecordAverage.temperatures[iSens] = fTemper;
          } else {
            sensorsRecordAverage.temperatures[iSens] += fTemper;
          }
        }
      });

      /// ... and after that, to divide by number of their
      for(ListElemIndex iSens = 0; iSens < numSensors; iSens++) {
        sensorsRecordAverage.temperatures[iSens] /= sensorsAverDivisors[iSens];
      }
      TimeStamp averTS = (startTS+stepTS/2).toInt();
      sensDataResult.putIfAbsent( averTS, () => sensorsRecordAverage);
    }

    /// In the end to add last record datas as single point, since its are a most actual data
    sensDataResult.putIfAbsent(lastTS, () => lastRecord);

    chartTimeStamps.clear();
    _chartSensorsData.clear();

    SensorValue chartMinValue = double.maxFinite;
    SensorValue chartMaxValue = -double.maxFinite;

    for(ListElemIndex iSens = 0; iSens < numSensors; iSens++) {
      _chartSensorsData.add( SplayTreeMap<TimeStamp, SensorValue>() );
    }

    /// Determine the Max and min values
    sensDataResult.forEach((ts, sensorsRecord) {
      for(ListElemIndex iSens = 0; iSens < numSensors; iSens++) {
        final temperature = sensorsRecord.temperatures[iSens];
        if(!temperature.isNaN) {
          chartMinValue = min(chartMinValue, temperature);
          chartMaxValue = max(chartMaxValue, temperature);
          _chartSensorsData[iSens].putIfAbsent(ts, () => temperature);
        }
      }
      chartTimeStamps.add(ts);
    });
    num rangeY = chartMaxValue - chartMinValue;
    if(rangeY == 0) {
      rangeY = 1.0;
    }

    chartMinY = chartMinValue - rangeY*0.1;
    chartMaxY = chartMaxValue + rangeY*0.1;
    chartRangeY = chartMaxY - chartMinY;
    debugPrint("REPO[$sIoTId]: chartMinY= $chartMinY; chartMaxY= $chartMaxY; chartRangeY= $chartRangeY");
  }


  /// Title of chart
  String getLastDateTimeData() {
    final dt = DateFormat('dd/MM/yyyy, HH:mm:ss').format( DateTime.fromMillisecondsSinceEpoch(_lastTimeStamp) );
    return dt.toString();
  }

  /// Notices on the chart timeline
  String timeStampToTime(TimeStamp ts, bool viewAbsoluteTimeLine) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final lessHour = CHART_MODES[chartMode].duration < TIME_1_HOUR;

    if(viewAbsoluteTimeLine) {
      String dtForm = lessHour ? "mm:ss" : "HH:mm";
      return DateFormat(dtForm).format(dt).toString();
    } else {
      final duration = DateTime.now().difference(dt);
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
      if(lessHour) {
        return "-$twoDigitMinutes:$twoDigitSeconds";
      } else {
        return "-${twoDigits(duration.inHours)}:$twoDigitMinutes";
      }
    }
  }

}
