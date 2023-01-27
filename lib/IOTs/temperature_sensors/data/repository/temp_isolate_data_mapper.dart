
import 'dart:isolate';
import 'package:async/async.dart';
import 'package:iots_manager/common/def_types.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/temp_sens_constants.dart';
import 'package:iots_manager/IOTs/temperature_sensors/domain/temp_sens_chart_mode.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/repository/temp_sens_one_record.dart';


class IsolateDataMapperTask {
  final QuantityElements numSensors;
  final Map<TimeStamp, TempSensOneRecord> sensFullData;
  final TimeStamp lastTimeStamp;
  final ListElemIndex curChartMode;

  IsolateDataMapperTask(this.numSensors, this.sensFullData, this.lastTimeStamp, this.curChartMode);
}

class TempIsolateDataMapper {
  late final Future<void> futureInitializer;

  late final Isolate _isolate;
  late final StreamQueue<dynamic> _streamQueue;
  late final SendPort _workerSendPort;

  TempIsolateDataMapper() {
    futureInitializer = Future(() async {
      final receivePort = ReceivePort();
      _isolate = await Isolate.spawn<SendPort>(isolateWorker, receivePort.sendPort, debugName: "IDM");
      _streamQueue = StreamQueue<dynamic>(receivePort);
      _workerSendPort = await _streamQueue.next;
    } );
  }

  Future<Map<TimeStamp, TempSensOneRecord>> startTask(IsolateDataMapperTask dataMapperTask) async {
    await futureInitializer;

    _workerSendPort.send(dataMapperTask);
    final workerAnswer = await _streamQueue.next as Map<TimeStamp, TempSensOneRecord>;
    // if(workerAnswer is Map<TimeStamp, TempSensOneRecord>)
    return workerAnswer;
  }



  void isolateWorker(SendPort sendPort) async {
    final ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    while(true) {

      await for (var task in receivePort) {
        //if (task is IsolateDataMapperTask)
        Map<TimeStamp, TempSensOneRecord> resultMap = _prepareDataSet(task as IsolateDataMapperTask);
        sendPort.send(resultMap);
      }
    }
  }


  Map<TimeStamp, TempSensOneRecord> _prepareDataSet(IsolateDataMapperTask task) {
    final Map<TimeStamp, TempSensOneRecord> sensFullData = task.sensFullData;
    final TimeStamp lastTimeStamp = task.lastTimeStamp;
    final ListElemIndex curChartMode = task.curChartMode;

    /// Prepare the chart for defined time range (5 min, 30 min, 3 hours, 12 hours, 24 hours)
    /// For build the chart need N points (it's about 10-20)
    ///  ... but number of real record much more.
    ///  So need to compress data
    final thresholdTS = lastTimeStamp - CHART_MODES[curChartMode].duration;
    final sensDataTrimmed = _copyTrimmedSensorsData(sensFullData, thresholdTS);

    /// 2. Since for the chart need to use less than N points (about 10-20),
    ///    and the last record is much actual for the user, then the last record need to use as single chart point,
    ///    and all a previous records need split to N-1 groups
    ///    After that, from each group it is necessary to create only one point of the chart, averaging values of all records.
    final sensDataResult = _compressFullDataToNumChartPoints(sensDataTrimmed, lastTimeStamp, task.numSensors);
    return sensDataResult;
  }

  /// Copy data which that has trimmed to specific time range
  Map<TimeStamp, TempSensOneRecord> _copyTrimmedSensorsData(
      Map<TimeStamp, TempSensOneRecord> sensFullData, TimeStamp thresholdTS) {

    final sensFullDataCopy = <TimeStamp, TempSensOneRecord>{};

    sensFullData.forEach((TimeStamp timestamp, TempSensOneRecord record) {
      if(timestamp > thresholdTS) {
        sensFullDataCopy[timestamp] = record;
      }
    });
    return sensFullDataCopy;
  }


  Map<TimeStamp, TempSensOneRecord> _compressFullDataToNumChartPoints(
                                Map<TimeStamp, TempSensOneRecord> sensDataTrimmed,
                                TimeStamp lastTimeStamp,
                                QuantityElements numSensors) {

    final lastRecord = sensDataTrimmed[lastTimeStamp] as TempSensOneRecord;
    sensDataTrimmed.remove(lastTimeStamp);

    final keys = sensDataTrimmed.keys.toList(growable: false)..sort();
    final TimeStamp firstTS = keys[0];

    final stepTS = (lastTimeStamp-firstTS) / (CHART_NUM_POINTS-1.0);
    final sensDataResult = <TimeStamp, TempSensOneRecord>{};

    for(ListElemIndex iTime = 0; iTime < (CHART_NUM_POINTS-1.0); iTime ++) {
      final TimeStamp startTS = (firstTS + stepTS * iTime).toInt();
      final mapTSRange = {
        for (var ts in sensDataTrimmed.keys.where((ts) => ts >= startTS && ts < startTS+stepTS))
          ts : sensDataTrimmed[ts]!
      };

      final averageRecord = _compressRecordsRangeToAverageSingleRecord(mapTSRange, numSensors);
      sensDataResult.putIfAbsent( (startTS+stepTS/2).toInt(), () => averageRecord);
    }
    /// In the end to add the last record data as independent point, since its are a most actual data
    sensDataResult.putIfAbsent(lastTimeStamp, () => lastRecord);
    return sensDataResult;
  }


  /// Calculate the average values for all elements of mapTSRange (for each sensor separately)
  TempSensOneRecord _compressRecordsRangeToAverageSingleRecord(
                Map<TimeStamp, TempSensOneRecord> mapTSRange, QuantityElements numSensors) {

    final sensorsRecordAverage = TempSensOneRecord.empty(numSensors);
    final List<int> sensorsAverDivisors = List.filled(numSensors, 0);

    ///  In first, to sum all values
    mapTSRange.forEach((recTS, oneRecord) {
      for(ListElemIndex iSens = 0; iSens < numSensors; iSens++) {
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
    for(ListElemIndex iSens = 0; iSens < numSensors; iSens++) {
      sensorsRecordAverage.temperatures[iSens] /= sensorsAverDivisors[iSens];
    }
    return sensorsRecordAverage;
  }


  Future<void> stop() async {

    print(" KKKKKKKKKKIIIIIIIIIIIIIIIILLLLLLLLLLLLLLLLLLLLLLLLLL ISOLATE");

    await _streamQueue.cancel();
    _isolate.kill();
  }
}

