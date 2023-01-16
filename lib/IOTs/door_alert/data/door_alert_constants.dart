//
// ignore_for_file: constant_identifier_names
// import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

const TIME_1_SEC = 1000;
const TIME_1_MINUTE = 60 * TIME_1_SEC;
const TIME_1_HOUR =   60 * TIME_1_MINUTE;
const MAX_CACHE_DURATION_MSEC = 7 * 24 * TIME_1_HOUR; // 1 week

const MAX_CACHE_EVENTS_NUMBER = 200;

const DOOR_EVENT_UNKNOWN = -1;
const DOOR_EVENT_TYPE_ACTIVATION = 0; // The IoT-device started after power on
const DOOR_EVENT_TYPE_PIR_SENSOR = 1;
const DOOR_EVENT_TYPE_DOOR_OPEN = 2;
const DOOR_EVENT_TYPE_DOOR_CLOSED = 3;
const DOOR_EVENT_TYPE_BELL = 4;


const DEFAULT_MAX_TIME_BETWEEN_EVENTS_IN_SESSION = 2 * TIME_1_MINUTE;


const FRAGMENT_TYPE_UNKNOWN = -1;
const FRAGMENT_TYPE_LAUNCHING = 0;
const FRAGMENT_TYPE_MOTION_FAR = 1;   // @TODO: The camera has detected a light on
const FRAGMENT_TYPE_MOTION_NEAR = 2;  // The PIR sensor has detected a motion
const FRAGMENT_TYPE_DOOR_SESSION = 3; //
const FRAGMENT_TYPE_BELL_ALERT = 4;   //
const FRAGMENT_TYPE_INTERCOM = 5;   // @TODO: The intercom activated

const FRAGMENT_COLOR_TYPES = [
  Colors.white38,       // launching
  Colors.amberAccent,   // motion far
  Colors.amberAccent,   // motion near
  Colors.greenAccent,   // door
  Colors.redAccent,     // bell
  Colors.black12,       // intercom
];

const FRAGMENT_ICON_TYPES = [
  Icons.rocket_launch,       // launching
  Icons.camera_outdoor,   // motion far
  Icons.directions_walk,   // motion near
  Icons.door_front_door,   // door
  Icons.doorbell,     // bell
  Icons.phone_in_talk,       // intercom
];

