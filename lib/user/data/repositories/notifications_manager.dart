
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:iots_manager/user/data/api/user_firebase_api.dart';
import 'package:iots_manager/user/data/repositories/user_repository.dart';

/// Handle background messages by registering a onBackgroundMessage handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage msg) async {

  await Firebase.initializeApp();

  debugPrint('Handling a background message ${msg.messageId}');
  debugPrint('      Message notification.title: ${msg.notification?.title??"-"}');
  debugPrint('      Message notification.body: ${msg.notification?.body??"-"}');
  debugPrint('      Message notification.android.channelId: ${msg.notification?.android?.channelId??"-"}');
  debugPrint('      Message notification.android.clickAction: ${msg.notification?.android?.clickAction??"-"}');
  debugPrint('      Message notification.android.priority: ${msg.notification?.android?.priority}');
}


Future<void> initFirebaseCloudMessaging() async {
  /// Handle background messages by registering a onBackgroundMessage handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  /// Get any messages which caused the application to open from a terminated state.
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    debugPrint("initialMessage: ${initialMessage.data}");
    debugPrint('      Message ${initialMessage.toString()}');
  }

  /// Also handle any interaction when the app is in the background via a Stream listener
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint("initialMessage: ${message.data}");
    debugPrint('      Message ${message.toString()}');
  });
}



class NotificationsManager {
  final UserRepository _userRepo;
  final UserFirebaseApi _dbAPI;
  final FirebaseMessaging _firebaseMessaging;

  String? _thisDeviceFCMToken;

  final List<String> _subscriptionsTopics = <String>[];

  NotificationsManager._(this._userRepo, this._dbAPI, this._firebaseMessaging);

  static Future<NotificationsManager> create(UserRepository userRepository, UserFirebaseApi dbAPI, FirebaseMessaging firebaseMessaging) async {
    NotificationsManager notificationsManager = NotificationsManager._(userRepository, dbAPI, firebaseMessaging);
    await notificationsManager._requestFCMPermission();
    await notificationsManager._initFCMToken();
    await notificationsManager._initSubscriptionsList();
    return notificationsManager;
  }

  Future<bool> _requestFCMPermission() async {
    /// Request permission to receive messages (Apple and Web)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if(settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("User granted permission");
      return true;
    } else if(settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint("User granted provisional permission");
      return true;
    }
    debugPrint("User declined or has not accepted permission");
    return false;
  }

  Future<void> _initFCMToken() async{
    _thisDeviceFCMToken = await _firebaseMessaging.getToken();
    if(_thisDeviceFCMToken != null) {
      _saveFCMToken(_thisDeviceFCMToken!);
    }
  }

  void _saveFCMToken(String token) async {
    if(!_userRepo.hasUserId()) {
      debugPrint("Can't to store FCM token because user is not logged");
      return;
    }

    try {
      await _dbAPI.saveFCMToken(_userRepo.userUId, token);
    } catch(e) {
      debugPrint("Error during store FCM token");
    }
  }

  Future<void> _initSubscriptionsList() async {
    if(!_userRepo.hasUserId()) {
      debugPrint("The user is not logged");
      return;
    }

    try {
      List<String> listTopics = await _dbAPI.getSubscriptionsList(_userRepo.userUId);
      _subscriptionsTopics.clear();
      _subscriptionsTopics.addAll(listTopics);
    } catch(e) {
      debugPrint("Error during get list of subscriptions of topics: ${e.toString()}");
    }
  }

  bool isTopicSubscribed(String topicName) {
    return _subscriptionsTopics.contains(topicName);
  }

  Future<void> subscribeToTopic(String topicName, {bool enabled = true}) async {
    debugPrint("subscribeToTopic: subscribe = $enabled");

    if(enabled) {
      debugPrint("subscribe to topic: $topicName");
      await _firebaseMessaging.subscribeToTopic(topicName);
    } else {
      debugPrint("unSubscribe to topic: $topicName");
      await _firebaseMessaging.unsubscribeFromTopic(topicName);
    }

    if(_userRepo.hasUserId()) {
      debugPrint("The user is not logged");
      try {
        await _dbAPI.updateTopicSubscription(_userRepo.userUId, topicName, enabled);
      } catch(e) {
        debugPrint("Error during updating the topic subscription state");
      }
    }

    debugPrint("subscribeToTopic: $_subscriptionsTopics");
    if(!enabled) {
      _subscriptionsTopics.remove(topicName);
    } else {
      _subscriptionsTopics.add(topicName);
    }
  }

}