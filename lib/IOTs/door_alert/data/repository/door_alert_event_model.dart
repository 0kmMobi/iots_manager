import 'package:iots_manager/IOTs/door_alert/data/door_alert_constants.dart';
import 'package:iots_manager/common/def_types.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoorAlertEvent {
  final TimeStamp timeStamp;
  late final DoorEventRawType type;

  DoorAlertEvent(this.timeStamp, String eventName, num eventValue) {
    eventName = eventName.toString().toUpperCase();
    switch(eventName) {
      case "ACT":     type = DOOR_EVENT_TYPE_ACTIVATION;      break;
      case "BELL":    type = DOOR_EVENT_TYPE_BELL;            break;
      case "PIR":     type = DOOR_EVENT_TYPE_PIR_SENSOR;      break;
      case "DOOR":    type = eventValue == 0? DOOR_EVENT_TYPE_DOOR_OPEN : DOOR_EVENT_TYPE_DOOR_CLOSED;    break;
      default:        type = DOOR_EVENT_UNKNOWN;
    }
  }
}