
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:iots_manager/IOTs/common/data/api/common_firebase_api.dart';
import 'package:iots_manager/locator_service.dart';

class TempSensFirebaseAPI extends CommonFirebaseAPI {
  static const String sensorsTemperaturesPath = "temperatures";
  static const String sensorsTemperaturesSortingKey = "time";

  Future<DataSnapshot> getSensorsData(String sIoTId, int lastTimeStamp) {
    final String path = "/devices_data/$sIoTId/$sensorsTemperaturesPath";
    final fbStream = sl<FirebaseDatabase>()
        .ref(path)
        .orderByChild(sensorsTemperaturesSortingKey)
        .startAfter(lastTimeStamp)
        .onValue;

    Future<DataSnapshot> futSnapshot = fbStream
        .firstWhere((event) => event.snapshot.value != null)
        .then((event) => event.snapshot);

    return futSnapshot;
  }
}