
import 'package:iots_manager/IOTs/common/presentation/iot_builder.dart';
import 'package:iots_manager/common/widgets/long_tap_slider.dart';
import 'package:iots_manager/user/data/model/iot_info.dart';
import 'package:iots_manager/user/presentation/home_page_side_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iots_manager/user/bloc/user_bloc.dart';
import 'package:iots_manager/user/presentation/add_new_iot_page.dart';
import 'package:iots_manager/user/presentation/log_in_page.dart';


class MainPage extends StatelessWidget {
  final List<IoTInfo> listIoTs;

  const MainPage({Key? key, required this.listIoTs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
          drawer: const HomePageSideMenu(),
          //drawerEnableOpenDragGesture: false,
          backgroundColor: Colors.grey,
          resizeToAvoidBottomInset: false, /// https://medium.com/zipper-studios/the-keyboard-causes-the-bottom-overflowed-error-5da150a1c660
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: AppBar(
              centerTitle: true,
              title: const Text('Temperature sensors on ESP8266', ),
              actions: [
                  IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: () {
                          // debugPrint("mainPage: press button 'add new IoT'");
                          BlocProvider.of<UserBloc>(context).add(NewIoT_InitPage_Event());
                        }
                  )
              ],
            ),
          ),
          body: BlocConsumer<UserBloc, UserState>(
            listener: (context, state) {
              if(state is MainPageViewState) {
                if(state.listIoTs != null) {
                  listIoTs.clear();
                  debugPrint("#### #### MainPage get MainPageViewState: STATE listIoTs= ${state.listIoTs}");
                  listIoTs.addAll(state.listIoTs!);
                  debugPrint("#### #### MainPage get MainPageViewState: listIoTs= $listIoTs");
                } else {
                  debugPrint("#### #### MainPage get MainPageViewState: No changes in ListIoTs: Own listIoTs contains: $listIoTs");
                }
              }
              else if(state is UnAuthenticatedState) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (routeContext) => const LogInPage()));
              }
              else if (state is NewIoT_InitPage_State) {
                // debugPrint("\n# # # MainPage->Navigator.push (AddNew IoT Page)");
                Navigator.push(context, MaterialPageRoute(builder: (routeContext) => const AddNewIOTPage()));
              }
            },
            buildWhen: (previous, current) {
              if(current is! MainPageViewState) {
                return false;
              }
              return current.listIoTs != null;
            },
            builder: (context, state) {
              return ListView.builder(
                itemCount: listIoTs.length,
                itemBuilder: (context, index) {
                final IoTInfo iotInfo = listIoTs[index];
                 return LongTapSlider(
                   actionCallback: () {
                     debugPrint("LongTapSlider callback");
                     BlocProvider.of<UserBloc>(context).add(DeleteIoTDeviceEvent(iotInfo.iotId));
                   },
                   actionIcon: Icon(Icons.delete, color: Colors.red.shade900),
                   child: Padding(
                     padding: const EdgeInsets.all(8.0),
                     child: PhysicalModel(
                       color: Colors.black,
                       borderRadius: BorderRadius.circular(8),
                       elevation: 8.0,
                       child: DecoratedBox(
                         decoration: BoxDecoration(
                             borderRadius: const BorderRadius.all(Radius.circular(8)),
                             color: Colors.blueGrey.shade900
                         ),
                         child: IoTBuilder(key: ValueKey(iotInfo.iotId), iotInfo: iotInfo)
                       )
                     ),
                   )
                 );
                },
              );
            },
          ),
      ),
    );
  }
}
