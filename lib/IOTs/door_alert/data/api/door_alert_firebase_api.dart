
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:iots_manager/IOTs/common/data/api/common_firebase_api.dart';
import 'package:iots_manager/IOTs/door_alert/data/door_alert_constants.dart';
import 'package:iots_manager/locator_service.dart';
import 'package:flutter/material.dart';

class DoorAlertFirebaseAPI extends CommonFirebaseAPI {
  static const String sensorsValuesPath = "values";
  static const String sortingKey = "time";

  Future<DataSnapshot> getEvents(String sIoTId, int lastTimeStamp) {
    final String path = "/devices_data/$sIoTId/$sensorsValuesPath";
    debugPrint("DoorAlert: FB_API: getSensorsData Path= $path");
    final fbStream = sl<FirebaseDatabase>()
        .ref(path)
        .orderByChild(sortingKey)
        .startAfter(lastTimeStamp)
        .limitToLast(MAX_CACHE_EVENTS_NUMBER)
        .onValue;

    Future<DataSnapshot> futSnapshot = fbStream
        .firstWhere((event) => event.snapshot.value != null)
        .then((event) => event.snapshot);

    return futSnapshot;
  }
}