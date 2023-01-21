// ignore_for_file: constant_identifier_names, non_constant_identifier_names
import 'dart:collection';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:iots_manager/IOTs/door_alert/data/api/door_alert_firebase_api.dart';
import 'package:iots_manager/IOTs/door_alert/data/repository/door_alert_event_model.dart';
import 'package:iots_manager/locator_service.dart';
import 'package:iots_manager/common/def_types.dart';
import 'package:iots_manager/IOTs/door_alert/data/door_alert_constants.dart';
import 'package:iots_manager/IOTs/door_alert/data/repository/door_alert_session_model.dart';


class DoorAlertEventsRepository{
  final String sIoTId;

  late final DoorAlertFirebaseAPI firebaseAPI = sl<DoorAlertFirebaseAPI>();
  final _eventsFullData = SplayTreeMap<TimeStamp, DoorAlertEvent>();
  final _alertSessions = <DoorAlertSession>[];

  TimeStamp _lastTimeStamp = 0; // Last timestamp of received data

  QuantityElements lastNumNewRecords = 0;
  int updatesCounter = 0;

  DoorAlertEventsRepository(this.sIoTId) {
    final dtNowMinus1Day = DateTime.now().subtract(const Duration(seconds: MAX_CACHE_DURATION_MSEC));
    _lastTimeStamp = dtNowMinus1Day.millisecondsSinceEpoch;
  }

  Stream<int> initSensorsDataUpdatesStream() {
    return _eventsUpdatesStream()
        .map((numNewElements) {
      if(numNewElements > 0) {
        lastNumNewRecords = numNewElements;
        updatesCounter++;
        _groupingEventsBySessions();
        _recognitionOfSessionTypes();
      }
      return updatesCounter;
    },);
  }

  Stream<QuantityElements> _eventsUpdatesStream() async* {
    while(true) {
      DataSnapshot snapshot = await firebaseAPI.getEvents(sIoTId, _lastTimeStamp);
      QuantityElements numNewElements = _addNewRawEvents(snapshot);

      if(numNewElements > 0) {
        yield numNewElements;
      }
    }
  }

  QuantityElements _addNewRawEvents(DataSnapshot snapshot) {
    QuantityElements countRecords = 0;
    TimeStamp maxTimeStampLocal = 0;
    Map<dynamic, dynamic> mapRawSensData = snapshot.value as Map<dynamic, dynamic>;

    mapRawSensData.forEach((sRecord, mapRecord) { // Loop by records
      if(_mappingOneRecord(mapRecord as Map<dynamic, dynamic>)) {
        countRecords ++;
      }
    });
    _lastTimeStamp = maxTimeStampLocal > _lastTimeStamp ? maxTimeStampLocal : _lastTimeStamp;

    /// Trim very old records which are older than 7 days
    TimeStamp oldTimeStamp = _lastTimeStamp - MAX_CACHE_DURATION_MSEC;
    _eventsFullData.removeWhere((timestamp, mapSensors) => timestamp <= oldTimeStamp);
    return countRecords;
  }

  bool _mappingOneRecord(final Map<dynamic, dynamic> mapOneRecord) {
    if(mapOneRecord.containsKey('time')) {
      TimeStamp curTimeStamp = mapOneRecord['time'] as TimeStamp;
      _lastTimeStamp = max(_lastTimeStamp, curTimeStamp);
      mapOneRecord.remove('time');
      if(mapOneRecord.length == 1) {
        final String eventName = mapOneRecord.keys.first;
        final num eventValue = mapOneRecord[eventName];
        DoorAlertEvent event = DoorAlertEvent(curTimeStamp, eventName, eventValue);
        _eventsFullData.putIfAbsent(curTimeStamp, ()=> event);
        return true;
      }
      /// data error: the record contains not 2 parameters
      return false;
    }
    return false;
  }

  /// The events session is a group of events that was created one-by-one, since its has timestamp no more than 2 minutes.
  void _groupingEventsBySessions() {
    final sessions = <DoorAlertSession>[];
    var oneSession = DoorAlertSession();
    sessions.add(oneSession);

    final List<int> eventsTS = _eventsFullData.keys.toList();
    for (TimeStamp ts in eventsTS) {
      DoorAlertEvent event = _eventsFullData[ts]!;
      if(!oneSession.tryToAddAnEvent(event)) {
        oneSession = DoorAlertSession()..tryToAddAnEvent(event);
        sessions.add(oneSession);
      }
    }
    if(sessions.isNotEmpty) {
      _alertSessions.clear();
      _alertSessions.addAll(sessions);
    }
  }

  void _recognitionOfSessionTypes() {
    for (var oneSession in _alertSessions) {
      oneSession.completeSettingParameters();
    }
  }

  QuantityElements get numEvents => _eventsFullData.length;

  QuantityElements get numSessions => _alertSessions.length;

  DoorAlertSession getSessionAt(ListElemIndex index) => _alertSessions[index];

  String getLastDateTimeData() {
    return _alertSessions.last.getStartTime(true);
  }
}
