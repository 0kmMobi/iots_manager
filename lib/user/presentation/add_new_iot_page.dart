// ignore_for_file: constant_identifier_names
import 'dart:ui';

import 'package:iots_manager/user/bloc/user_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class AddNewIOTPage extends StatefulWidget {
  const AddNewIOTPage({Key? key}) : super(key: key);

  @override
  State<AddNewIOTPage> createState() => _AddNewIOTPageState();
}

class _AddNewIOTPageState extends State<AddNewIOTPage> {
    static const ADD_NEW_IOT_ID_ERROR_MSG__EMPTY = "IOT-device Id is empty";

    late final TextEditingController _textControllerIoTId;
    late final MobileScannerController _cameraController;
    String? _errorMsgIoTValidation = ADD_NEW_IOT_ID_ERROR_MSG__EMPTY;
    bool _canToScan = true;

    @override
    void initState() {
      _cameraController = MobileScannerController(facing: CameraFacing.back);

      _textControllerIoTId = TextEditingController();
      _textControllerIoTId.addListener(() {
        String? errorIoTValidationNew = _validateIoTId(_textControllerIoTId.text);
        if(_errorMsgIoTValidation != errorIoTValidationNew) {
          setState(() {
            _errorMsgIoTValidation = errorIoTValidationNew;
          });
        }
      });
      BlocProvider.of<UserBloc>(context).add(NewIoT_WaitingId_Event());
      super.initState();
    }

    @override
    void dispose() {
      _textControllerIoTId.dispose();
      _cameraController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return WillPopScope(
        onWillPop: () async {
          BlocProvider.of<UserBloc>(context).add(NewIoT_BackHomeEvent(false));
          return false;
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false, /// https://medium.com/zipper-studios/the-keyboard-causes-the-bottom-overflowed-error-5da150a1c660
          backgroundColor: Colors.grey,
          appBar: AppBar(
            centerTitle: true,
            title: const Text("Adding a new IoT-device"),
            leading: BackButton(
              onPressed: () {
                BlocProvider.of<UserBloc>(context).add(NewIoT_BackHomeEvent(false));
                // debugPrint("BackButton pressed");
              },
              color: Colors.black,
            ),
            actions: [
              IconButton(
                color: Colors.white,
                icon: ValueListenableBuilder(
                  valueListenable: _cameraController.torchState,
                  builder: (context, state, child) {
                    switch (state as TorchState) {
                      case TorchState.off:
                        return const Icon(Icons.flash_off, color: Colors.grey);
                      case TorchState.on:
                        return const Icon(Icons.flash_on, color: Colors.yellow);
                    }
                  },
                ),
                iconSize: 32.0,
                onPressed: () => _cameraController.toggleTorch(),
              ),
            ]
          ),
          body: BlocListener<UserBloc, UserState>(
            listener: (context, state) {
              _canToScan = state is NewIoT_WaitId_State;

              debugPrint(" *** new Iot page: BlocListener state= ${state.toString()}");
              if (state is MainPageViewState) {
                Navigator.of(context).pop();
              }
              else {
                const String title = "Adding the new IoT-device";
                if(state is NewIoT_IdSuccessfulAdded_State) {
                  _showAlertBox(title, state.msg, Icon(Icons.task_alt, size: 48, color: Colors.green.shade600,))
                    .then((_) => BlocProvider.of<UserBloc>(context).add(NewIoT_BackHomeEvent(true)));
                } else if(state is NewIoT_IdNotAdded_State) {
                    _showAlertBox( title, state.msg, Icon( state.hasError? Icons.block: Icons.warning, size: 48, color: state.hasError? Colors.red.shade900: Colors.yellow.shade700,) )
                    .then((_) => BlocProvider.of<UserBloc>(context).add(NewIoT_WaitingId_Event()));
                }
              }
            },
            child: Stack(
              children: [
                /// The back-layer which contains two blocks: the edit form and the camera preview
                Column(
                  children: [
                    /// The form of manual entering of IoT id
                    Flexible(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                flex: 2,
                                child: TextField(
                                  keyboardType: TextInputType.text,
                                  controller: _textControllerIoTId,
                                  decoration: const InputDecoration( border: OutlineInputBorder(), labelText: 'IoT-device Id...', ),
                                ),
                              ),

                              const SizedBox( width: 5, ),
                              Flexible(
                                flex: 1,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    primary: _errorMsgIoTValidation == null? Colors.blueGrey :Colors.black,
                                    onPrimary: _errorMsgIoTValidation == null? Colors.white :Colors.white54,
                                  ),
                                  onPressed: () {
                                    _tryToAddCurrentIoTId(context);
                                  },
                                  child: const Text('Add'),
                                ),
                              ),
                            ],
                          ),
                        )
                    ),
                    /// The Camera scanner for automatic detecting QR-code with The IoT id
                    Flexible(
                      flex: 8,
                      child: MobileScanner(
                        fit: BoxFit.scaleDown,
                        allowDuplicates: false,
                        controller: _cameraController,
                        onDetect: (barcode, args) {
                          if(!_canToScan) {
                            debugPrint(" > > > Can't to scan while is it busy");
                            return;
                          }
                          if(barcode.format == BarcodeFormat.qrCode) {
                            if (barcode.rawValue == null) {
                              // debugPrint('Scan >>> Failed to scan Barcode');
                            } else {
                              final String code = barcode.rawValue!.trim();
                              if(code.length == 16 && code.startsWith("IoT-")) {
                                final String newIoTId = code.substring(4);
                                // debugPrint("1 controller.text= '${_textControllerIoTId.text}'; newIoTId= '$newIoTId'");
                                if(_textControllerIoTId.text == newIoTId) {
                                  // debugPrint('Scan >>> !!! Duplicate Id  : $newIoTId');
                                  return;
                                }
                                // debugPrint('Scan >>> The IoT Id was detected: $newIoTId');
                                _textControllerIoTId.text = newIoTId;
                                FlutterBeep.playSysSound(AndroidSoundIDs.TONE_CDMA_ABBR_ALERT);
                                _tryToAddCurrentIoTId(context);
                                return;
                              }
                            }
                          } else {
                            // debugPrint('Scan >>> It isn\'t a QR-code');
                          }
                          FlutterBeep.beep(false);
                        }
                      ),
                    ),
                  ],
                ),
                /// The front-layer which will contains progressbar for long time process of adding new IoT
                BlocBuilder<UserBloc, UserState>(
                  builder: (context, state) {
                    if(state is NewIoT_WaitId_State) {
                        return const Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              " Please enter the Id of your new IoT and press the 'Next' \n or scan QR-code on the IoT box. ",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, backgroundColor: Colors.white38),
                            ),
                          ),
                        );
                    } else if(state is NewIoT_TryToAdd_State) {
                        final String sNewIoTId = state.newIoTId;
                        return Center(
                          child: Container(
                            width: double.infinity,
                            color: Colors.blueGrey.shade700.withAlpha(128),
                            child:
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(sNewIoTId, style: const TextStyle(fontSize: 30, color: Colors.white),),
                                const SizedBox(height: 10,),
                                const CircularProgressIndicator(color: Colors.white),
                              ],
                            ),
                          ),
                        );
                    }
                    // debugPrint("Add New IoT: Unknown state: ${state.toString()}");
                    return Center(
                      child: Container(
                        width: double.infinity,
                        color: Colors.blueGrey.shade700.withAlpha(128),
                      ),
                      //child: Text("Unknown state", style: TextStyle(color: Colors.red, fontSize: 40),),
                    );
                  },
                ),
              ],
            )
          )
        ),
      );
    }

    Future<void> _showAlertBox(String title, String msg, Icon icon) async {
      msg = msg.length > 300 ? "${msg.substring(300)} ..." : msg;

      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: AlertDialog(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8.0))
              ),
              backgroundColor: Colors.blueGrey,
              title: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              contentPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 10.0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(thickness: 4),
                  const SizedBox(height: 4,),
                  icon,
                  const SizedBox(height: 6,),
                  Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 4,),
                  Container(
                    width: double.infinity,
                    color: Colors.grey,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white,
                        onPrimary: Colors.black,
                        minimumSize: const Size.fromHeight(50)
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK',),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    String? _validateIoTId(String sValue) {
      sValue = sValue.trim();
      if(sValue.isEmpty) {
        return ADD_NEW_IOT_ID_ERROR_MSG__EMPTY;
      }
      if(sValue.length != 12) {
        return "The length of the Id is incorrect.";
      }
      /// The process of parsing a MAC address step by step, one HEX byte per iteration.
      for (int i = 0; i < sValue.length; i += 2) {
        final sHex = sValue.substring(i, i + 2);
        int? iDec = int.tryParse(sHex, radix: 16);
        if(iDec == null) {
          return "Can't to parse the Id.";
        }
      }
      return null; /// No any errors
    }

    void _tryToAddCurrentIoTId(BuildContext context) {
      if(_errorMsgIoTValidation != null) { // There are some errors in the IoT-device Id
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.black,
                content: Text(_errorMsgIoTValidation!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold), )
            )
        );
      } else {
        BlocProvider.of<UserBloc>(context).add(NewIoT_Id_Entered_Event(_textControllerIoTId.text));
      }
    }
}
