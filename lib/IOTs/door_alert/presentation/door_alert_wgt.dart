import 'dart:math';
import 'package:iots_manager/IOTs/door_alert/data/door_alert_constants.dart';
import 'package:iots_manager/IOTs/door_alert/data/repository/door_alert_events_repository.dart';
import 'package:iots_manager/IOTs/door_alert/data/repository/door_alert_session_model.dart';
import 'package:iots_manager/locator_service.dart';
import 'package:iots_manager/user/data/repositories/notifications_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DoorAlertWidget extends StatefulWidget {
  const DoorAlertWidget({Key? key}) : super(key: key);

  @override
  State<DoorAlertWidget> createState() => _DoorAlertWidgetState();
}

class _DoorAlertWidgetState extends State<DoorAlertWidget> with SingleTickerProviderStateMixin {
  static const String subscriptionTopicPrefix = "doorAlert_";

  @override
  void initState() {
    super.initState();
  }

  Future<void> changeSubscribeToNotifications(String sIoTId) async {
    final String topic = subscriptionTopicPrefix + sIoTId;
    NotificationsManager notificationsManager = sl<NotificationsManager>();
    bool isSubscribed = notificationsManager.isTopicSubscribed(topic);
    debugPrint("######### changeSubscribeToNotifications: isSubscribed= $isSubscribed");

    await notificationsManager.subscribeToTopic(topic, enabled: !isSubscribed);
  }

  void goToFullScreen(BuildContext context) {
    //Navigator.push(context, MaterialPageRoute(builder: (routeContext) => const DoorAlertFullscreenPage()));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DoorAlertWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
        stream: RepositoryProvider.of<DoorAlertEventsRepository>(context).initSensorsDataUpdatesStream(),
        builder: (context, snapshot) {
          final DoorAlertEventsRepository dataRepo = RepositoryProvider.of<DoorAlertEventsRepository>(context);
          final hasChartData = snapshot.hasData;
          if(hasChartData) {
            return Column(
              children: [
                /// Title: Action buttons and the last update date-time
                Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () async {
                          await changeSubscribeToNotifications(dataRepo.sIoTId);
                          setState((){});
                        },
                        icon: sl<NotificationsManager>().isTopicSubscribed(subscriptionTopicPrefix + dataRepo.sIoTId)?
                          const Icon(Icons.notifications_active, color: Colors.white,):
                          const Icon(Icons.notifications_none, color: Colors.grey,),
                      ),
                      Text(dataRepo.getLastDateTimeData(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => setState(() => goToFullScreen(context)),
                        icon: const Icon(
                          Icons.fullscreen, color: Colors.greenAccent,),
                      )
                    ],
                  ),
                ),

                /// List sessions of events
                Container(
                  color: Colors.grey,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: min(dataRepo.numSessions, 10) + 1,
                    itemBuilder: (context, inx) {
                      final index = dataRepo.numSessions-inx;
                      late final Color bkColor;
                      late final DoorAlertSession? alertSession;
                      late final List<String> colsText;
                      if(inx == 0) {
                        alertSession = null;
                        bkColor = Colors.transparent;
                        colsText = <String>[
                          "Index",
                          "Date/Time",
                          "Duration",
                          "Type",
                          "Count"
                        ];
                      } else {
                        alertSession = dataRepo.getSessionAt(index);
                        bkColor = FRAGMENT_COLOR_TYPES[alertSession.type];
                        colsText = <String>[
                            "${index+1}",
                            alertSession.getStartTime(true),
                            alertSession.getEventTimeFromStartByIndex(alertSession.numEvents-1),
                            "${alertSession.type}",
                            "${alertSession.numEvents}"
                        ];
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Container(
                          color: bkColor,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                                Expanded(flex: 1, child: Text(colsText[0], textAlign: TextAlign.center),),
                                Expanded(flex: 4, child: Text(colsText[1], textAlign: TextAlign.center) ),
                                Expanded(flex: 2, child: Text(colsText[2], textAlign: TextAlign.center) ),
                                Expanded(flex: 1, child:
                                  inx == 0?
                                    Text(colsText[3], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold),) :
                                    Icon(FRAGMENT_ICON_TYPES[alertSession!.type])
                                ),
                                Expanded(flex: 1, child: Text(colsText[4], textAlign: TextAlign.center) ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10,),
              ],
            );
          } else {
            return const SizedBox(
              height: 60,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        }
    );
  }
}


