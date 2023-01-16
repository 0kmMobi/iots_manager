
// ignore_for_file: constant_identifier_names

const IOT_DEVICE_TYPE_DOOR_ALERT = 11;
const IOT_DEVICE_TYPE_TEMPERATURE_SENSORS = 12;

class IoTInfo {
  String iotId;
  final int type;
  String name = "";

  IoTInfo(this.iotId, this.type, String? sName_) {
    name = sName_ ?? "<no name>";
  }
  factory IoTInfo.dummy(String iotId) {
    return IoTInfo(iotId, 0, null);
  }

  @override
  String toString() {
    return '{ $iotId, $type, $name }';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IoTInfo && runtimeType == other.runtimeType && iotId == other.iotId;

  @override
  int get hashCode => iotId.hashCode;
}