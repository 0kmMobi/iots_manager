import 'package:iots_manager/IOTs/temperature_sensors/data/repository/temp_sens_repository.dart';
import 'package:iots_manager/IOTs/temperature_sensors/domain/bloc/temp_sens_chart_mode_bloc.dart';
import 'package:iots_manager/IOTs/temperature_sensors/presentation/temp_sens_chart_wgt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:iots_manager/common/widgets/dlg_edit_text.dart';
import 'package:iots_manager/IOTs/temperature_sensors/data/temp_sens_constants.dart';
import 'package:iots_manager/IOTs/temperature_sensors/domain/temp_sens_chart_mode.dart';

class TempSensWidget extends StatefulWidget {
  const TempSensWidget({Key? key}) : super(key: key);

  @override
  State<TempSensWidget> createState() => _TempSensWidgetState();
}

class _TempSensWidgetState extends State<TempSensWidget> with SingleTickerProviderStateMixin{
  final ValueNotifier<int> changeSensorNameCounter = ValueNotifier<int>(0);
  late final AnimationController expandController;
  late final Animation<double> animation;
  bool isExpand = true;

  @override
  void initState() {
    super.initState();
    prepareAnimations();
    setExpandAnimation(!isExpand);
  }

  /// Setting up the animation
  void prepareAnimations() {
    expandController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500)
    );
    animation = CurvedAnimation(
      parent: expandController,
      curve: Curves.fastOutSlowIn,
    );
  }

  void setExpandAnimation(expand) {
    if(isExpand == expand) {
      return;
    }
    isExpand = expand;
    if(isExpand) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  @override
  void dispose() {
    expandController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TempSensWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    setExpandAnimation(isExpand);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: RepositoryProvider.of<TempSensRepository>(context).initSensorsNames(),
      builder: (context, AsyncSnapshot <bool> snapshot) {
          if (snapshot.hasError) {
            return Text("Firebase access failure!\n ${snapshot.error.toString()}");
          } else if (snapshot.hasData) {
            debugPrint("initSensorsNames: hasData");
            return StreamBuilder<int>(
                stream: RepositoryProvider.of<TempSensRepository>(context).initSensorsDataUpdatesStream(),
                builder: (context, snapshot) {
                  final TempSensRepository sensRepo = RepositoryProvider.of<TempSensRepository>(context);
                  final hasChartData = snapshot.hasData;
                  return Column(
                    children: [
                      /// The section of a title as the last data date time and option button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(sensRepo.getLastDateTimeData(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey, fontSize: 25, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: () => setState(() => setExpandAnimation(!isExpand)),
                              icon: const Icon(Icons.area_chart, color: Colors.greenAccent,),
                            )
                          ],
                        ),
                      ),
                      /// The section of the chart and time-range modes buttons
                      SizeTransition(
                        axisAlignment: 1.0,
                        sizeFactor: animation,
                        child: Column(
                          children: [
                            /// Buttons of time-range modes
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                              child: ToggleSwitch(
                                activeBgColor: const [Colors.black],
                                activeFgColor: Colors.white,
                                inactiveBgColor: Colors.blueGrey,
                                inactiveFgColor: Colors.white70,
                                initialLabelIndex: sensRepo.chartRepo.chartMode,
                                totalSwitches: CHART_MODES.length,
                                labels: List.generate(CHART_MODES.length, (index) {
                                  return CHART_MODES[index].label;
                                }),
                                onToggle: (index) {
                                  BlocProvider.of<TempSensChartModeBloc>(context).add( TempSensChangeChartModeEvent(index!),);
                                },
                              ),
                            ),
                            /// The chart itself
                            BlocBuilder<TempSensChartModeBloc, TempSensChartModeState>(
                                builder: (context, state) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(40, 16, 40, 16),
                                    child: AspectRatio( aspectRatio: 3 / 2, child: TempSensChartWidget(hasChartData: hasChartData),),
                                  );
                                }),
                            const SizedBox(height: 10,),
                            /// Addition info
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Text("Updates: ${sensRepo.updatesCounter}", style: const TextStyle(color: Colors.white)),
                                Text("New recs: ${sensRepo.lastNumNewRecords}", style: const TextStyle(color: Colors.white)),
                                Text("Total recs: ${sensRepo.fullDataSize}", style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 10,),
                          ],
                        )
                      ),

                      /// Names of the sensors and their last data values
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: ValueListenableBuilder(
                          valueListenable: changeSensorNameCounter,
                          builder: (context, value, child) {
                            return Column(
                              children: List.generate(sensRepo.numSensors, (index) {
                                return Padding(
                                    padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 4.0),
                                    child: DecoratedBox(
                                        decoration: const BoxDecoration(
                                          borderRadius: BorderRadius.all( Radius.circular(4),),
                                          color: Colors.blueGrey,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(flex: 2,
                                                child: GestureDetector(
                                                  child: Text(
                                                    (sensRepo.getSensorNameByIndex(index)).toUpperCase(),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(color: CHART_COLORS[index], fontSize: 25, fontWeight: FontWeight.bold),
                                                  ),
                                                  onTap: () {
                                                    final String sSensorAddress = sensRepo.sensorAddresses[index];
                                                    const String sTitle = 'The sensor renaming';
                                                    final String sMsg = "The sensor addressed as \n$sSensorAddress";
                                                    displayTextInputDialog(context, sTitle, sMsg, sensRepo.sensorNames[sSensorAddress]! )
                                                        .then((sNewName) {
                                                      if(sensRepo.updateSensorName(sSensorAddress, sNewName) ) {
                                                        changeSensorNameCounter.value++;
                                                      }
                                                    });
                                                  },
                                                )
                                            ),
                                            Expanded(flex: 1,
                                                child: Text(
                                                  (sensRepo.chartRepo.getSensorLastData(index)).toStringAsFixed(2),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(color: CHART_COLORS[index], fontSize: 25, fontWeight: FontWeight.bold),)
                                            ),
                                          ],)
                                    )
                                );
                              }),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10,),
                    ],
                  );
                }
            );
          } else {
            return Center(
              child: Container(
                color: Colors.black87,
                child: Column(
                  children: const [
                    Text("Sensors names initialization...", style: TextStyle(fontSize: 20, color: Colors.white),),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          }
      }
    );
  }
}


