
import 'package:flutter/material.dart';

final _tecEditSensorName = TextEditingController();

Future<String?> displayTextInputDialog(BuildContext context, String sTitle, String sMsg, String sOldName) async {
  _tecEditSensorName.text = sOldName;
  return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))
          ),
          title: Text(sTitle, textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(sMsg),
              const Divider(thickness: 4),
              TextField( autofocus: true, controller: _tecEditSensorName,
                decoration: const InputDecoration(hintText: "Enter new name"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.green)),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
              onPressed: () {
                String? sName = _tecEditSensorName.value.text;
                if(sName == sOldName) {
                  sName = null;
                }
                Navigator.pop(context, sName);
              },
            ),
          ],
        );
      });
}