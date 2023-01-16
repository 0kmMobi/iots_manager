// ignore_for_file: constant_identifier_names
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:iots_manager/locator_service.dart';


class UserFirebaseApi {
  /// !!! This 'channelId' needs to be changed manually in the 'manifest'-file -> <meta-data> / com.google.firebase.messaging.default_notification_channel_id
  static const String _androidNotificationChannelId = "mobi_0km_iot_manager";

  static const PathDevicesRoot = "/devices_list/";
  static const PathUsersRoot = "/users/";
  static const PathUserDevicesNode = "/devices/";
  static const PathUserTopicsNode = "/topics/";

  late final FirebaseDatabase _firebaseDB;

  UserFirebaseApi() {
    _firebaseDB = sl<FirebaseDatabase>();
  }

  Future<Map<String, String>?> queryUserDevicesList(String userUId) async {
    final String path = "$PathUsersRoot$userUId$PathUserDevicesNode";

    DataSnapshot snapshot = await _firebaseDB.ref(path).get();
    /// If user's storage already exists in DB, then get this data
    if(snapshot.value != null) {
      return (snapshot.value as Map<dynamic, dynamic>).cast<String,String>();
    }
    return null;
  }

  Future<void> setEmptyUserSection(String userUId, String email) async {
    final String path = "$PathUsersRoot$userUId/";

    final map = <String, dynamic>{}
      ..putIfAbsent("email", () => email)
      ..putIfAbsent("devices", () => {});

    await _firebaseDB.ref(path).set(map);
  }

  Future<int> queryIoTType(String sIoTId) async {
    String path = "$PathDevicesRoot$sIoTId/type";
    DataSnapshot dataSnapshot = await _firebaseDB.ref(path).get();
    int type = dataSnapshot.value as int;
    return type;
  }

  Future<void> addNewIoT(String userUId, String sNewIoTId, String iotName) async {
    String path = "$PathUsersRoot$userUId$PathUserDevicesNode";
    debugPrint("addNewIoT: path = $path");
    await _firebaseDB.ref(path).update({sNewIoTId: iotName});
  }

  Future<void> renameIoT(String userUId, String iotId, String iotNewName) async {
    final String path = "$PathUsersRoot$userUId$PathUserDevicesNode";
    await _firebaseDB.ref(path).update({iotId : iotNewName});
  }

  Future<void> deleteIoTDeviceById(String userUId, String iotId) async{
    final String path = "$PathUsersRoot$userUId/$PathUserDevicesNode";
    await _firebaseDB.ref(path).update({iotId : null});
  }


  Future<void> saveFCMToken(String userUId, String token) async {
    final String path = "$PathUsersRoot$userUId/";
    await _firebaseDB.ref(path).update({ "fcmToken" : token} );
  }

  Future<List<String>> getSubscriptionsList(String userUId) async {
    final String path = "$PathUsersRoot$userUId$PathUserTopicsNode";
    final listTopics = <String>[];

    DataSnapshot snapshot = await _firebaseDB.ref(path).get();
    if(snapshot.value != null) {
      final map = (snapshot.value as Map<dynamic, dynamic>).cast<String,bool>();
      map.forEach((topic, state) {
        if(state == true) {
          listTopics.add(topic);
        }
      });
    }
    return listTopics;
  }

  Future<void> updateTopicSubscription(String userUId, String topicName, bool enabled) async {
    final String path = "$PathUsersRoot$userUId$PathUserTopicsNode";
    await _firebaseDB.ref(path).update({topicName: enabled});
  }

  void sendMessageByWebApiToToken(String fcmServerWebApiKey, String recipientToken, String msgTitle, String msgBody) async {
    debugPrint("send message by token: $recipientToken / title: $msgTitle; body: $msgBody");
    try {
      await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-type': 'application/json',
            'Authorization': 'key=$fcmServerWebApiKey'
          },
          body: jsonEncode(
              <String, dynamic> {
                'priority': 'high',
                /// Notification payload
                'data': <String, dynamic>{
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK', /// Also this 'click_action' was defined in the 'manifest'-file in a 'intent-filter' section
                  'status': 'done',
                  'title': msgTitle,
                  'body': msgBody,
                },
                /// Notification content
                "notification": <String, dynamic>{
                  "title": msgTitle,
                  "body": msgBody,
                  "android_channel_id": _androidNotificationChannelId
                },
                "to": recipientToken
              }
          )
      );
    } catch (e) {
      debugPrint(" --- Error during send message by token --- ");
      debugPrint(" --- ${e.toString()}");
    }
  }

}