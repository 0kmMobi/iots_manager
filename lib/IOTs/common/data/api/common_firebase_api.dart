
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:iots_manager/locator_service.dart';

abstract class CommonFirebaseAPI {
  static const String sensorsNamesPath = "sensor_names";

  Future<DataSnapshot> getSensorsNames(String sIoTId) {
    final String path = "/devices_list/$sIoTId/$sensorsNamesPath";
    return sl<FirebaseDatabase>().ref(path).get();
  }

  Future<void> updateSensorName(String sIoTId, String sSensorAddress, String sNewName) async {
    final String path = "/devices_list/$sIoTId/$sensorsNamesPath";
    await sl<FirebaseDatabase>().ref(path).update({sSensorAddress: sNewName});
  }
}