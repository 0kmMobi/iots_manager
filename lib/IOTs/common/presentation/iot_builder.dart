
import 'package:iots_manager/IOTs/door_alert/data/repository/door_alert_events_repository.dart';
import 'package:iots_manager/IOTs/door_alert/presentation/door_alert_wgt.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/repository/temp_sens_chart_repository.dart';
import 'package:iots_manager/IOTs/temperature_sensors/domain/bloc/temp_sens_chart_mode_bloc.dart';
import 'package:iots_manager/IOTs/temperature_sensors/presentation/temp_sens_wgt.dart';
import 'package:iots_manager/locator_service.dart';
import 'package:iots_manager/user/data/model/iot_info.dart';
import 'package:iots_manager/user/data/repositories/notifications_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class IoTBuilder extends StatelessWidget {
  final IoTInfo iotInfo;
  const IoTBuilder({Key? key, required this.iotInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch(iotInfo.type) {
      case IOT_DEVICE_TYPE_DOOR_ALERT:
        return RepositoryProvider<DoorAlertEventsRepository>( create: (context) => DoorAlertEventsRepository(iotInfo.iotId),
          child: FutureBuilder( future: sl.isReady<NotificationsManager>(), builder: (context, snapshot) {
              if(snapshot.hasData) {
                return const DoorAlertWidget();
              } else {
                return const Center(child: CircularProgressIndicator(),);
              }
          }),
        );
      case IOT_DEVICE_TYPE_TEMPERATURE_SENSORS:
        return RepositoryProvider<TempSensChartRepository>( create: (context) => TempSensChartRepository(iotInfo.iotId),
          child: BlocProvider( create: (context) => TempSensChartModeBloc(chartRepository: RepositoryProvider.of<TempSensChartRepository>(context)),
            child: const TempSensWidget(),
          ),
        );
    }
    return Container(
      color: Colors.black,
      child: Center(
        child: Text("Unknown an IoT-device type ${iotInfo.type}", style: const TextStyle(color: Colors.yellow),),
      ),
    );
  }
}
