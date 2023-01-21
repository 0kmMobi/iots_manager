import 'dart:math';
import 'dart:collection';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/api/temp_sens_firebase_api.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/repository/temp_sens_chart_repository.dart';
import 'package:iots_manager/locator_service.dart';
import 'package:intl/intl.dart';
import 'package:iots_manager/common/def_types.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/temp_sens_constants.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/repository/temp_sens_one_record.dart';
import 'package:iots_manager/IOTs/temperature_sensors/domain/temp_sens_chart_mode.dart';


class TempSensRepository {
  final String sIoTId;

  late final TempSensFirebaseAPI firebaseAPI = sl<TempSensFirebaseAPI>();
  late final TempSensChartRepository chartRepo;

  final _sensorAddresses = <String>[]; // List of id's of defined sensors
  final _sensorNames = <String, String>{}; // The sensors user's names
  final _sensFullData = SplayTreeMap<TimeStamp, TempSensOneRecord>();

  TimeStamp _lastTimeStamp = 0; // Last timestamp of received data

  QuantityElements lastNumNewRecords = 0;
  int updatesCounter = 0;

  TempSensRepository(this.sIoTId) {
    final dtNowMinus1Day = DateTime.now().subtract(const Duration(days: 1));
    _lastTimeStamp = dtNowMinus1Day.millisecondsSinceEpoch;
    chartRepo = TempSensChartRepository();
  }

  QuantityElements get numSensors => _sensorAddresses.length;

  List<String> get sensorAddresses => _sensorAddresses;

  Map<String, String> get sensorNames => _sensorNames;

  QuantityElements get fullDataSize => _sensFullData.length;

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
    return _sensorsDataUpdatesStream().map((numNewElements) {
      if(numNewElements > 0) {
        lastNumNewRecords = numNewElements;
        updatesCounter++;
        chartRepo.chartDataPreparing(lastTimeStamp: _lastTimeStamp, sensorAddresses: _sensorAddresses, sensFullData: _sensFullData);
        //debugPrint("REPO[$sIoTId]: chartMinY= ${chartRepo.chartMinY}; chartMaxY= ${chartRepo.chartMaxY}; chartRangeY= ${chartRepo.chartRangeY}");
        debugPrint("REPO[$sIoTId]: updatesCounter= $updatesCounter; numNewRecords= $lastNumNewRecords");
      }
      return updatesCounter;
    });
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
    Map<dynamic, dynamic> mapRawSensData = snapshot.value as Map<dynamic, dynamic>;

    mapRawSensData.forEach((sRecord, mapRecord) { // Loop by records
      if(_mappingOneRecord(mapRecord as Map<dynamic, dynamic>)) {
        countRecords ++;
      }
    });
    /// Delete records older that MAX_CACHE_DURATION_MSEC milliseconds
    TimeStamp oldTimeStamp = _lastTimeStamp - MAX_CACHE_DURATION_MSEC;
    _sensFullData.removeWhere((timestamp, mapSensors) => timestamp <= oldTimeStamp);
    return countRecords;
  }

  bool _mappingOneRecord(final Map<dynamic, dynamic> mapOneRecord) {
    if(mapOneRecord.containsKey('time')) {
      TimeStamp curTimeStamp = mapOneRecord['time'] as TimeStamp;
      _lastTimeStamp = max(_lastTimeStamp, curTimeStamp);

      final sensorsOneRecord = TempSensOneRecord.fromData(mapOneRecord, _sensorAddresses);
      _sensFullData.putIfAbsent(curTimeStamp, ()=> sensorsOneRecord);
      return true;
    }
    return false;
  }

  /// Title of chart
  String getLastDateTimeData() {
    final dt = DateFormat('dd/MM/yyyy, HH:mm:ss').format( DateTime.fromMillisecondsSinceEpoch(_lastTimeStamp) );
    return dt.toString();
  }

  /// It uses as a notices on the chart timeline
  String timeStampToTime(TimeStamp ts, bool viewAbsoluteTimeLine) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final lessHour = CHART_MODES[chartRepo.chartMode].duration < TIME_1_HOUR;

    if(viewAbsoluteTimeLine) {
      return _timeStampToTimeAbsolute(dt, lessHour);
    }
    return _timeStampToTimeRelative(dt, lessHour);
  }

  String _timeStampToTimeAbsolute(DateTime dt, bool lessHour) {
    String dtForm = lessHour ? "mm:ss" : "HH:mm";
    return DateFormat(dtForm).format(dt).toString();
  }

  String _timeStampToTimeRelative(DateTime dt, bool lessHour) {
    final duration = DateTime.now().difference(dt);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if(lessHour) {
      return "-$twoDigitMinutes:$twoDigitSeconds";
    }
    return "-${twoDigits(duration.inHours)}:$twoDigitMinutes";
  }

}
