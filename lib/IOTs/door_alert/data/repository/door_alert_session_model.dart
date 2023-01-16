import 'package:flutter/material.dart';
import 'package:iots_manager/IOTs/door_alert/data/door_alert_constants.dart';
import 'package:iots_manager/IOTs/door_alert/data/repository/door_alert_event_model.dart';
import 'package:iots_manager/common/def_types.dart';
import 'package:intl/intl.dart';

class DoorAlertSession {
  late final int type;
  late final TimeStamp startTS;
  late final TimeStamp endTS;

  final _events = <DoorAlertEvent>[];

  DoorAlertSession();

  /// If the new event timestamp not older 2 minutes than the last event in the events list
  ///   then need to add this event and return True,
  ///   otherwise return False because this event should be added on the next session.
  bool tryToAddAnEvent(DoorAlertEvent event) {
    if(_events.isEmpty) {
      _events.add(event);
      return true;
    }
    final lastEvent = _events.last;
    if(event.timeStamp - lastEvent.timeStamp <= DEFAULT_MAX_TIME_BETWEEN_EVENTS_IN_SESSION) {
      _events.add(event);
      return true;
    }
    return false;
  }

  void completeSettingParameters() {
    if(_events.isEmpty) {
      startTS = endTS = 0;
      type = FRAGMENT_TYPE_UNKNOWN;
    } else {
      startTS = _events.first.timeStamp;
      endTS = _events.last.timeStamp;

      bool hasLaunching = false;
      bool hasBell = false;
      bool hasDoor = false;
      bool hasNearMotion = false;

      for (DoorAlertEvent event in _events) {
        hasBell |= event.type == DOOR_EVENT_TYPE_BELL;
        hasDoor |= (event.type == DOOR_EVENT_TYPE_DOOR_OPEN || event.type == DOOR_EVENT_TYPE_DOOR_CLOSED);
        hasNearMotion |= event.type == DOOR_EVENT_TYPE_PIR_SENSOR;
        hasLaunching |= event.type == DOOR_EVENT_TYPE_ACTIVATION;
      }

      if(hasDoor) {
        type = FRAGMENT_TYPE_DOOR_SESSION;
      } else if(hasBell) {
        type = FRAGMENT_TYPE_BELL_ALERT;
      } else if(hasNearMotion) {
        type = FRAGMENT_TYPE_MOTION_NEAR;
      } else if(hasLaunching) {
        type = FRAGMENT_TYPE_LAUNCHING;
      } else {
        type = FRAGMENT_TYPE_UNKNOWN;
      }
    }
  }

  QuantityElements get numEvents => _events.length;

  DoorAlertEvent getEventAt(ListElemIndex index) {
    return _events[index];
  }

  String getStartTime(bool withData) {
    String dtFormat = withData ? 'dd/MM/yyyy, HH:mm:ss' : 'HH:mm:ss';
    final dt = DateFormat(dtFormat).format( DateTime.fromMillisecondsSinceEpoch(startTS) );
    return dt.toString();
  }

  String getEventTimeFromStartByIndex(ListElemIndex index) {
    final TimeStamp curTS = _events[index].timeStamp;
    TimeStamp deltaTS = curTS - startTS;
    if(deltaTS == 0) {
      return "-";
    }
    deltaTS ~/= 1000;
    int minutes = deltaTS ~/ 60;
    int seconds = deltaTS % 60;
    return  "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  String toString() {
    String str = "type= $type; startTS= ${getStartTime(true)}; events.size= ${_events.length}: ";

    for (ListElemIndex iEvent = 0; iEvent < _events.length; iEvent ++) {
      str += "[$iEvent => ${_events[iEvent].type}], ";
    }
    return str;
  }
}