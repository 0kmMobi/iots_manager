import 'package:iots_manager/common/def_types.dart';

class TempSensOneRecord {
  final temperatures = <SensorValue>[];

  TempSensOneRecord.empty(List<String> addresses) {
    for (var i=0; i < addresses.length; i ++) {
      temperatures.add(double.nan);
    }
  }

  TempSensOneRecord.fromData(Map<dynamic, dynamic> mapData, List<String> addresses) {
    for (var keyAddress in addresses) {
      bool exist = mapData.containsKey(keyAddress);
      if(!exist || (exist && mapData[keyAddress] <= -127.0) ) {
        temperatures.add(double.nan);
      } else {
        temperatures.add(mapData[keyAddress]!);
      }
    }
  }

  List<SensorValue> get data => temperatures;

  @override
  String toString() {
    String str = "";
    for (ListElemIndex iSens = 0; iSens < temperatures.length; iSens ++) {
      str += "${iSens+1}=> ${temperatures[iSens]}; ";
    }
    return str;
  }
}